// ScoreX server-side CricAPI proxy. Set CRICAPI_KEY as a Cloudflare Worker secret.
const ORIGIN = 'https://api.cricapi.com/v1/currentMatches';
const reply = (body, status = 200) => new Response(JSON.stringify(body), {
  status, headers: { 'Content-Type': 'application/json; charset=utf-8', 'Cache-Control': 'public, max-age=60' }
});
export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    if (request.method !== 'GET') return reply({ error: 'Method not allowed' }, 405);
    if (url.pathname === '/health') return reply({ status: 'ok', configured: Boolean(env.CRICAPI_KEY) });
    if (url.pathname !== '/matches') return reply({ error: 'Not found' }, 404);
    if (!env.CRICAPI_KEY) return reply({ error: 'API secret is not configured' }, 503);
    const cache = caches.default;
    const cacheKey = new Request(url.origin + '/matches', { method: 'GET' });
    const cached = await cache.match(cacheKey);
    if (cached) return cached;
    try {
      const upstream = new URL(ORIGIN);
      upstream.searchParams.set('apikey', env.CRICAPI_KEY);
      upstream.searchParams.set('offset', '0');
      const response = await fetch(upstream, { headers: { Accept: 'application/json' } });
      const payload = await response.json();
      if (!response.ok || payload.status === 'failure') {
        return reply({ error: 'Cricket data provider request failed', status: response.status }, 502);
      }
      const output = reply({ data: Array.isArray(payload.data) ? payload.data : [], updatedAt: new Date().toISOString() });
      output.headers.set('Cache-Control', 'public, max-age=60, s-maxage=60');
      ctx.waitUntil(cache.put(cacheKey, output.clone()));
      return output;
    } catch (_) {
      return reply({ error: 'Cricket data temporarily unavailable' }, 502);
    }
  }
};
