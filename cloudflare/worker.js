/**
 * ScoreX Cricket API proxy for Cloudflare Workers.
 * Add CRICAPI_KEY as a Worker secret; never commit the API key here.
 */
const API_ORIGIN = 'https://api.cricapi.com/v1';

export default {
  async fetch(request, env) {
    const origin = request.headers.get('Origin') || '';
    const headers = {
      'Content-Type': 'application/json; charset=utf-8',
      'Cache-Control': 'no-store',
      'Access-Control-Allow-Origin': origin || '*',
      'Access-Control-Allow-Methods': 'GET, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
      'Vary': 'Origin',
    };

    if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers });
    const url = new URL(request.url);
    if (request.method !== 'GET') return json({ success: false, message: 'GET requests only' }, 405, headers);
    if (!url.pathname.endsWith('/matches')) return json({ success: false, message: 'Unknown ScoreX API route.' }, 404, headers);
    if (!env.CRICAPI_KEY) return json({ success: false, message: 'Server API token is not configured.' }, 503, headers);

    const upstream = new URL(API_ORIGIN + '/currentMatches');
    upstream.searchParams.set('apikey', env.CRICAPI_KEY);
    upstream.searchParams.set('offset', '0');

    try {
      const response = await fetch(upstream.toString(), { headers: { Accept: 'application/json' } });
      const body = await response.text();
      return new Response(body, { status: response.status, headers });
    } catch (_) {
      return json({ success: false, message: 'Cricket data provider is temporarily unavailable.' }, 502, headers);
    }
  }
};

function json(body, status, headers) {
  return new Response(JSON.stringify(body), { status, headers });
}
