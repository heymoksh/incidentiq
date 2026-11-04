// Very small JSON-file store. The file lives on a Docker volume so data survives redeployments.
const fs = require('fs');
const path = require('path');

class Store {
  constructor(file) {
    this.file = file;
    this.data = { seq: 0, incidents: [] };
    if (file && fs.existsSync(file)) {
      try { this.data = JSON.parse(fs.readFileSync(file, 'utf8')); } catch { /* start fresh if corrupt */ }
    }
  }

  save() {
    if (!this.file) return;
    fs.mkdirSync(path.dirname(this.file), { recursive: true });
    const tmp = this.file + '.tmp';
    fs.writeFileSync(tmp, JSON.stringify(this.data, null, 2));
    fs.renameSync(tmp, this.file);
  }

  all() { return this.data.incidents; }
  get(id) { return this.data.incidents.find((i) => i.id === id); }

  add(incident) {
    this.data.seq += 1;
    incident.id = 'INC-' + String(1000 + this.data.seq);
    this.data.incidents.push(incident);
    this.save();
    return incident;
  }

  update() { this.save(); }
}

module.exports = { Store };
