const { createApp } = require('./app');

const port = Number(process.env.PORT || 3000);
const dataFile = process.env.DATA_FILE || '/data/incidents.json';
const server = createApp({ dataFile }).listen(port, () => {
  console.log(`incidentIQ ${process.env.APP_VERSION || 'dev'} listening on port ${port}`);
});
process.on('SIGTERM', () => server.close(() => process.exit(0)));
