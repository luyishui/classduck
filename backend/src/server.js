const { createApp } = require('./app');

const port = Number(process.env.PORT || 3100);
const app = createApp();

app.listen(port, () => {
  // Keep startup log concise for operational visibility.
  console.log(`[classduck-backend] listening on http://localhost:${port}`);
});
