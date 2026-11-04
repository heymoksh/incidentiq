const test = require('node:test');
const assert = require('node:assert');
const { createApp, suggestSeverity } = require('../app');

let server, base;
test.before(async () => {
  server = createApp({ dataFile: null }).listen(0);
  await new Promise((r) => server.once('listening', r));
  base = `http://127.0.0.1:${server.address().port}`;
});
test.after(() => server.close());

const send = (method, url, body) => fetch(base + url, { method, headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) });

test('health endpoint', async () => {
  const r = await fetch(base + '/health');
  assert.strictEqual(r.status, 200);
  assert.strictEqual((await r.json()).status, 'ok');
});

test('severity suggestion', () => {
  assert.strictEqual(suggestSeverity('Website is down for all users'), 'P1');
  assert.strictEqual(suggestSeverity('Checkout is slow'), 'P2');
  assert.strictEqual(suggestSeverity('Intermittent delay for some users'), 'P3');
  assert.strictEqual(suggestSeverity('Typo on about page'), 'P4');
});

test('create, update and resolve an incident', async () => {
  const r = await send('POST', '/api/incidents', { title: 'Payments API is down', service: 'Payments', reporter: 'Moksh' });
  assert.strictEqual(r.status, 201);
  const inc = await r.json();
  assert.match(inc.id, /^INC-\d{4}$/);
  assert.strictEqual(inc.severity, 'P1');
  assert.strictEqual(inc.status, 'Open');

  const u = await (await send('PATCH', `/api/incidents/${inc.id}`, { status: 'Investigating', note: 'Restarting payment pods' })).json();
  assert.strictEqual(u.status, 'Investigating');
  assert.strictEqual(u.timeline.length, 3);

  const done = await (await send('PATCH', `/api/incidents/${inc.id}`, { status: 'Resolved' })).json();
  assert.ok(done.resolvedAt);
});

test('validation errors', async () => {
  assert.strictEqual((await send('POST', '/api/incidents', { title: 'x', service: 'Payments', reporter: 'A' })).status, 400);
  assert.strictEqual((await send('POST', '/api/incidents', { title: 'Valid title', service: 'Mars', reporter: 'Ab' })).status, 400);
  assert.strictEqual((await send('PATCH', '/api/incidents/INC-9999', { status: 'Resolved' })).status, 404);
});

test('stats endpoint', async () => {
  const s = await (await fetch(base + '/api/stats')).json();
  assert.ok(s.total >= 1);
  assert.ok('P1' in s.openBySeverity);
});
