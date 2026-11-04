// incidentIQ - Cloud-Native Incident Management System
const express = require('express');
const path = require('path');
const { Store } = require('./store');

const VERSION = process.env.APP_VERSION || 'dev';
const SEVERITIES = ['P1', 'P2', 'P3', 'P4'];
const STATUSES = ['Open', 'Investigating', 'Resolved'];
const SERVICES = ['Website', 'Payments', 'Database', 'Login / Auth', 'Email', 'Network', 'Other'];

// "IQ" part: suggest a severity from the words used in the title/description
const RULES = [
  { sev: 'P1', words: ['down', 'outage', 'not working', 'crash', 'data loss', 'breach', 'all users'] },
  { sev: 'P2', words: ['slow', 'timeout', 'error', 'failed', 'failing', 'payment', 'disk', 'full', 'memory', 'cpu'] },
  { sev: 'P3', words: ['some users', 'intermittent', 'delay', 'warning'] }
];
function suggestSeverity(text) {
  const t = String(text || '').toLowerCase();
  for (const r of RULES) if (r.words.some((w) => t.includes(w))) return r.sev;
  return 'P4';
}

function createApp({ dataFile } = {}) {
  const app = express();
  const store = new Store(dataFile);

  app.disable('x-powered-by');
  app.use(express.json({ limit: '20kb' }));
  app.use((req, res, next) => {
    res.set({ 'X-Content-Type-Options': 'nosniff', 'X-Frame-Options': 'DENY', 'Referrer-Policy': 'no-referrer' });
    next();
  });

  app.get('/health', (req, res) => res.json({ status: 'ok', version: VERSION, incidents: store.all().length }));
  app.get('/api/meta', (req, res) => res.json({ version: VERSION, severities: SEVERITIES, statuses: STATUSES, services: SERVICES }));
  app.post('/api/suggest', (req, res) => res.json({ severity: suggestSeverity(`${req.body.title} ${req.body.description}`) }));

  app.get('/api/incidents', (req, res) => {
    let list = store.all().slice().reverse();
    if (req.query.status) list = list.filter((i) => i.status === req.query.status);
    if (req.query.severity) list = list.filter((i) => i.severity === req.query.severity);
    res.json(list);
  });

  app.get('/api/incidents/:id', (req, res) => {
    const inc = store.get(req.params.id);
    if (!inc) return res.status(404).json({ error: 'Incident not found' });
    res.json(inc);
  });

  app.post('/api/incidents', (req, res) => {
    const { title, description, service, severity, reporter } = req.body || {};
    if (!title || String(title).trim().length < 5) return res.status(400).json({ error: 'Title must be at least 5 characters' });
    if (!SERVICES.includes(service)) return res.status(400).json({ error: 'Please choose an affected service' });
    if (!reporter || String(reporter).trim().length < 2) return res.status(400).json({ error: 'Please enter the reporter name' });
    const sev = SEVERITIES.includes(severity) ? severity : suggestSeverity(`${title} ${description}`);
    const now = new Date().toISOString();
    const inc = store.add({
      title: String(title).trim().slice(0, 120),
      description: String(description || '').trim().slice(0, 1000),
      service,
      severity: sev,
      status: 'Open',
      reporter: String(reporter).trim().slice(0, 60),
      createdAt: now,
      resolvedAt: null,
      timeline: [{ at: now, text: `Incident reported by ${String(reporter).trim()} (${sev})` }]
    });
    res.status(201).json(inc);
  });

  app.patch('/api/incidents/:id', (req, res) => {
    const inc = store.get(req.params.id);
    if (!inc) return res.status(404).json({ error: 'Incident not found' });
    const { status, note } = req.body || {};
    const now = new Date().toISOString();
    if (status) {
      if (!STATUSES.includes(status)) return res.status(400).json({ error: 'Invalid status' });
      if (status !== inc.status) {
        inc.timeline.push({ at: now, text: `Status changed: ${inc.status} -> ${status}` });
        inc.status = status;
        inc.resolvedAt = status === 'Resolved' ? now : null;
      }
    }
    if (note && String(note).trim()) inc.timeline.push({ at: now, text: String(note).trim().slice(0, 500) });
    store.update();
    res.json(inc);
  });

  app.get('/api/stats', (req, res) => {
    const all = store.all();
    const open = all.filter((i) => i.status !== 'Resolved');
    const resolved = all.filter((i) => i.status === 'Resolved' && i.resolvedAt);
    const mttrMin = resolved.length
      ? Math.round(resolved.reduce((s, i) => s + (Date.parse(i.resolvedAt) - Date.parse(i.createdAt)), 0) / resolved.length / 60000)
      : 0;
    const bySeverity = Object.fromEntries(SEVERITIES.map((s) => [s, open.filter((i) => i.severity === s).length]));
    res.json({ total: all.length, open: open.length, resolved: resolved.length, mttrMinutes: mttrMin, openBySeverity: bySeverity });
  });

  app.use(express.static(path.join(__dirname, 'public')));
  app.use((req, res) => res.status(404).json({ error: 'Not found' }));
  return app;
}

module.exports = { createApp, suggestSeverity };
