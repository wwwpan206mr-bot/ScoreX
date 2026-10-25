import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { test } from 'node:test';

const source = await readFile(new URL('./worker.js', import.meta.url), 'utf8');
const { default: worker } = await import(`data:text/javascript;base64,${Buffer.from(source).toString('base64')}`);
const rows = (start, count) => Array.from({ length: count }, (_, i) => ({ id: `match-${start + i}` }));

async function run(pages, env = {}, path = '/matches') {
  const originalFetch = globalThis.fetch;
  const originalCaches = globalThis.caches;
  const offsets = [];
  const pending = [];
  globalThis.caches = { default: { match: async () => null, put: async () => {} } };
  globalThis.fetch = async input => {
    offsets.push(input.searchParams.get('offset'));
    const payload = pages.shift();
    if (payload instanceof Error) throw payload;
    assert.ok(payload, 'Unexpected extra upstream request');
    return Response.json(payload);
  };
  try {
    const response = await worker.fetch(new Request('https://scorex.test' + path),
      { CRICAPI_KEY: 'test-only', ...env }, { waitUntil: p => pending.push(p) });
    await Promise.all(pending);
    return { response, body: await response.json(), offsets };
  } finally {
    globalThis.fetch = originalFetch;
    globalThis.caches = originalCaches;
  }
}

test('loads page two and preserves live fixtures beyond the first 25', async () => {
  const result = await run([
    { data: rows(0, 25), info: { totalRows: 26 } },
    { data: [{ id: 'live', matchStarted: true, matchEnded: false }], info: { totalRows: 26 } },
  ]);
  assert.equal(result.body.data.length, 26);
  assert.equal(result.body.data[25].id, 'live');
  assert.deepEqual(result.offsets, ['0', '25']);
  assert.equal(result.body.coverage.partial, false);
});

test('does not spend an extra request on a complete first page', async () => {
  const result = await run([{ data: rows(0, 25), info: { totalRows: 25 } }]);
  assert.deepEqual(result.offsets, ['0']);
});

test('bounds requests and labels a capped listing as partial', async () => {
  const result = await run([
    { data: rows(0, 25), info: { totalRows: 100 } },
    { data: rows(25, 25), info: { totalRows: 100 } },
  ], { MAX_MATCH_PAGES: '2' });
  assert.equal(result.body.data.length, 50);
  assert.equal(result.body.coverage.partial, true);
  assert.deepEqual(result.offsets, ['0', '25']);
});

test('retains the first page if a later page fails', async () => {
  const result = await run([{ data: rows(0, 25) }, new Error('provider unavailable')]);
  assert.equal(result.response.status, 200);
  assert.equal(result.body.data.length, 25);
  assert.equal(result.body.coverage.partial, true);
});

test('stops if provider ignores offset instead of duplicating matches', async () => {
  const result = await run([{ data: rows(0, 25) }, { data: rows(0, 25) }]);
  assert.equal(result.body.data.length, 25);
  assert.equal(result.body.coverage.partial, true);
});


test('live route does not call a paid provider when no delivery source is configured', async () => {
  const result = await run([], {}, '/live?id=m1');
  assert.equal(result.response.status, 200);
  assert.equal(result.body.available, false);
  assert.equal(result.body.data, null);
  assert.deepEqual(result.offsets, []);
});

test('live route accepts a verified match-bound normalised feed', async () => {
  const result = await run([{ data: { matchId: 'm1', inningsId: '2', source: 'Test source',
    updatedAt: '2026-10-25T18:00:00Z', deliveries: [] } }],
    { LIVE_FEED_URL: 'https://feed.test/live' }, '/live?id=m1');
  assert.equal(result.response.status, 200);
  assert.equal(result.body.available, true);
  assert.equal(result.body.data.matchId, 'm1');
  assert.match(result.response.headers.get('cache-control'), /max-age=20/);
});

test('live route rejects a different match and an invalid ID', async () => {
  const mismatch = await run([{ data: { matchId: 'other', inningsId: '2', source: 'Test source',
    updatedAt: '2026-10-25T18:00:00Z', deliveries: [] } }],
    { LIVE_FEED_URL: 'https://feed.test/live' }, '/live?id=m1');
  assert.equal(mismatch.response.status, 502);
  const invalid = await run([], {}, '/live?id=../private');
  assert.equal(invalid.response.status, 400);
  assert.deepEqual(invalid.offsets, []);
});
