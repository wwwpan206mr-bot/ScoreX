// ScoreX server-side CricAPI proxy. Set CRICAPI_KEY as a Cloudflare Worker secret.
const ORIGIN = 'https://api.cricapi.com/v1/currentMatches';
const reply = (body, status = 200) => new Response(JSON.stringify(body), {
  status, headers: { 'Content-Type': 'application/json; charset=utf-8', 'Cache-Control': 'public, max-age=60' }
});
// Adapter for an authorised backend supplying ScoreX's documented live schema.
// This never calls paid CricAPI Fantasy endpoints under a free subscription.
async function liveFeed(url, env, ctx) {
  const matchId = url.searchParams.get('id');
  if (!matchId || !/^[a-zA-Z0-9-]{1,100}$/.test(matchId)) return reply({ error: 'Invalid match id' }, 400);
  if (!env.LIVE_FEED_URL) return reply({ data: null, available: false, reason: 'delivery_feed_unavailable' });
  try {
    const endpoint = new URL(env.LIVE_FEED_URL);
    if (endpoint.protocol !== 'https:') return reply({ error: 'Delivery source unavailable' }, 503);
    endpoint.searchParams.set('id', matchId);
    const cacheKey = new Request(url.origin + '/live?id=' + encodeURIComponent(matchId));
    const cached = await caches.default.match(cacheKey);
    if (cached) return cached;
    const headers = { Accept: 'application/json' };
    if (env.LIVE_FEED_TOKEN) headers.Authorization = 'Bearer ' + env.LIVE_FEED_TOKEN;
    const response = await fetch(endpoint, { headers, signal: AbortSignal.timeout(8000) });
    if (!response.ok) return reply({ error: 'Delivery source temporarily unavailable' }, 502);
    const text = await response.text();
    if (text.length > 1000000) return reply({ error: 'Delivery response too large' }, 502);
    const payload = JSON.parse(text);
    const data = payload.data;
    if (!data || data.matchId !== matchId || typeof data.source !== 'string' || !data.source.trim() ||
        typeof data.inningsId !== 'string' || !data.inningsId ||
        typeof data.updatedAt !== 'string' || !/Z$/.test(data.updatedAt) ||
        !Number.isFinite(Date.parse(data.updatedAt)) || !Array.isArray(data.deliveries)) {
      return reply({ error: 'Delivery source returned invalid data' }, 502);
    }
    const output = reply({ data, available: true });
    output.headers.set('Cache-Control', 'public, max-age=20, s-maxage=20');
    ctx.waitUntil(caches.default.put(cacheKey, output.clone()));
    return output;
  } catch (_) {
    return reply({ error: 'Delivery source temporarily unavailable' }, 502);
  }
}

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    if (request.method !== 'GET') return reply({ error: 'Method not allowed' }, 405);
    if (url.pathname === '/health') return reply({ status: 'ok', configured: Boolean(env.CRICAPI_KEY) });
    if (url.pathname === '/live') return liveFeed(url, env, ctx);
    const detail = url.pathname === '/match';
    if (url.pathname !== '/matches' && !detail) return reply({ error: 'Not found' }, 404);
    const matchId = url.searchParams.get('id');
    if (detail && (!matchId || !/^[a-zA-Z0-9-]{1,100}$/.test(matchId))) return reply({ error: 'Invalid match id' }, 400);
    if (!env.CRICAPI_KEY) return reply({ error: 'API secret is not configured' }, 503);
    const cache = caches.default;
    const cacheKey = new Request(url.origin + (detail ? '/match?id=' + encodeURIComponent(matchId) : '/matches'), { method: 'GET' });
    const cached = await cache.match(cacheKey);
    if (cached) return cached;
    try {
      const upstream = new URL(detail ? 'https://api.cricapi.com/v1/match_info' : ORIGIN);
      if (detail) upstream.searchParams.set('id', matchId);
      upstream.searchParams.set('apikey', env.CRICAPI_KEY);
      upstream.searchParams.set('offset', '0');
      const response = await fetch(upstream, { headers: { Accept: 'application/json' } });
      const payload = await response.json();
      if (!response.ok || payload.status === 'failure') {
        return reply({ error: 'Cricket data provider request failed', status: response.status }, 502);
      }
      let data = detail ? (payload.data ?? null) : payload.data;
      if (!detail && !Array.isArray(data)) {
        return reply({ error: 'Invalid cricket provider response' }, 502);
      }
      let partial = false;
      let pagesFetched = 1;
      if (!detail) {
        const seen = new Set(data.map(match => match.id));
        let page = data;
        let offset = page.length;
        let total = Number(payload.info?.totalRows);
        const maxPages = Math.max(1, Math.min(4, Number.parseInt(env.MAX_MATCH_PAGES ?? '3', 10) || 3));
        // Fetch a bounded number of pages only when the response indicates more.
        while (page.length === 25 && (!Number.isFinite(total) || offset < total)) {
          if (pagesFetched >= maxPages) { partial = true; break; }
          upstream.searchParams.set('offset', String(offset));
          try {
            const nextResponse = await fetch(upstream, { headers: { Accept: 'application/json' } });
            const next = await nextResponse.json();
            if (!nextResponse.ok || next.status === 'failure' || !Array.isArray(next.data)) {
              partial = true; break;
            }
            pagesFetched++;
            page = next.data;
            const unique = page.filter(match => match.id && !seen.has(match.id));
            for (const match of unique) seen.add(match.id);
            data = [...data, ...unique];
            offset += page.length;
            if (page.length && !unique.length) { partial = true; break; }
            if (Number.isFinite(Number(next.info?.totalRows))) total = Number(next.info.totalRows);
          } catch (_) { partial = true; break; }
        }
      }
      const output = reply({ data, updatedAt: new Date().toISOString(),
        ...(!detail ? { coverage: { partial, pagesFetched } } : {}) });
      output.headers.set('Cache-Control', 'public, max-age=60, s-maxage=60');
      ctx.waitUntil(cache.put(cacheKey, output.clone()));
      return output;
    } catch (_) {
      return reply({ error: 'Cricket data temporarily unavailable' }, 502);
    }
  }
};

