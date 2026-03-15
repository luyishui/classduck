const express = require('express');
const cors = require('cors');
const crypto = require('crypto');

const { createConfigRoutes } = require('./routes/configRoutes');
const { createImportRoutes } = require('./routes/importRoutes');
const { createReleaseRoutes } = require('./routes/releaseRoutes');
const { createAdapterRuleRoutes } = require('./routes/adapterRuleRoutes');

function createApp() {
  const app = express();

  app.use(cors());
  app.use(express.json());

  app.use((req, res, next) => {
    req.traceId = crypto.randomUUID();
    res.setHeader('x-trace-id', req.traceId);
    next();
  });

  app.use(createConfigRoutes());
  app.use(createAdapterRuleRoutes());
  app.use(createImportRoutes());
  app.use(createReleaseRoutes());

  app.get('/healthz', (req, res) => {
    res.status(200).json({
      status: 'ok',
      traceId: req.traceId,
    });
  });

  app.use((req, res) => {
    res.status(404).json({
      traceId: req.traceId,
      errorCode: 'NOT_FOUND',
      message: 'Route not found.',
    });
  });

  return app;
}

module.exports = {
  createApp,
};
