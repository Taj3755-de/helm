const express = require('express');
const os = require('os');

const app = express();
const port = process.env.PORT || 3000;

app.get('/', (req, res) => {
  const payload = {
    message: process.env.APP_MESSAGE || 'Hello from sample-k8s-node-app!',
    hostname: os.hostname(),
    node: process.env.NODE_NAME || 'unknown',
    timestamp: new Date().toISOString()
  };
  res.json(payload);
});

app.get('/healthz', (req, res) => res.status(200).send('ok'));

app.listen(port, () => {
  console.log(`Server listening on port ${port}`);
});
