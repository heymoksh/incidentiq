let current = null;

function el(tag, text, cls) {
  const e = document.createElement(tag);
  if (text !== undefined) e.textContent = text;
  if (cls) e.className = cls;
  return e;
}

function when(iso) {
  return new Date(iso).toLocaleString('en-IN', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' });
}

async function loadMeta() {
  const meta = await (await fetch('/api/meta')).json();
  const sel = document.getElementById('service');
  sel.innerHTML = '<option value="">-- choose --</option>';
  meta.services.forEach((s) => sel.appendChild(el('option', s)));
  document.getElementById('footer').textContent = 'incidentIQ build ' + meta.version + ' | deployed by Jenkins on AWS EC2 (Docker)';
}

async function loadStats() {
  const s = await (await fetch('/api/stats')).json();
  document.getElementById('sOpen').textContent = s.open;
  document.getElementById('sP1').textContent = s.openBySeverity.P1;
  document.getElementById('sResolved').textContent = s.resolved;
  document.getElementById('sMttr').textContent = s.mttrMinutes + ' min';
}

async function loadList() {
  const f = document.getElementById('filter').value;
  const list = await (await fetch('/api/incidents' + (f ? '?status=' + f : ''))).json();
  const body = document.getElementById('rows');
  body.innerHTML = '';
  if (!list.length) {
    const tr = el('tr'); const td = el('td', 'No incidents yet', 'empty'); td.colSpan = 6; tr.appendChild(td); body.appendChild(tr);
    return;
  }
  list.forEach((i) => {
    const tr = el('tr');
    tr.appendChild(el('td', i.id));
    tr.appendChild(el('td', i.title));
    tr.appendChild(el('td', i.service));
    const sev = el('td'); sev.appendChild(el('span', i.severity, 'sev ' + i.severity)); tr.appendChild(sev);
    tr.appendChild(el('td', i.status, 'st ' + i.status));
    tr.appendChild(el('td', when(i.createdAt)));
    tr.onclick = () => openIncident(i.id);
    body.appendChild(tr);
  });
}

async function openIncident(id) {
  const i = await (await fetch('/api/incidents/' + id)).json();
  current = i.id;
  document.getElementById('detail').classList.remove('hidden');
  document.getElementById('dTitle').textContent = i.id + ' - ' + i.title;
  document.getElementById('dMeta').textContent = i.service + ' | ' + i.severity + ' | ' + i.status + ' | reported by ' + i.reporter + ' on ' + when(i.createdAt);
  document.getElementById('dDesc').textContent = i.description || 'No description';
  const tl = document.getElementById('timeline');
  tl.innerHTML = '';
  i.timeline.slice().reverse().forEach((t) => {
    const li = el('li'); li.appendChild(el('small', when(t.at))); li.appendChild(document.createTextNode(t.text)); tl.appendChild(li);
  });
}

async function update(body) {
  if (!current) return;
  await fetch('/api/incidents/' + current, { method: 'PATCH', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) });
  await openIncident(current);
  loadList(); loadStats();
}

async function suggest() {
  const title = document.getElementById('title').value;
  const description = document.getElementById('description').value;
  if (!title) return;
  const r = await (await fetch('/api/suggest', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ title, description }) })).json();
  document.getElementById('suggest').textContent = 'IQ suggestion: ' + r.severity;
}

document.getElementById('title').addEventListener('input', suggest);
document.getElementById('description').addEventListener('input', suggest);
document.getElementById('filter').addEventListener('change', loadList);
document.querySelectorAll('.actions button').forEach((b) => b.addEventListener('click', () => update({ status: b.dataset.status })));
document.getElementById('noteForm').addEventListener('submit', (e) => {
  e.preventDefault();
  const n = document.getElementById('note');
  update({ note: n.value }); n.value = '';
});

document.getElementById('form').addEventListener('submit', async function (e) {
  e.preventDefault();
  const msg = document.getElementById('msg');
  const body = {
    title: document.getElementById('title').value,
    description: document.getElementById('description').value,
    service: document.getElementById('service').value,
    severity: document.getElementById('severity').value,
    reporter: document.getElementById('reporter').value
  };
  const r = await fetch('/api/incidents', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) });
  const res = await r.json();
  if (r.ok) {
    msg.className = 'ok'; msg.textContent = res.id + ' created with severity ' + res.severity;
    this.reset(); document.getElementById('suggest').textContent = 'IQ suggestion: -';
    loadList(); loadStats(); openIncident(res.id);
  } else {
    msg.className = 'err'; msg.textContent = res.error;
  }
});

loadMeta(); loadStats(); loadList();
