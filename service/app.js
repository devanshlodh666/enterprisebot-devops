const express = require("express");
const os = require("os");

const app = express();

const PORT = process.env.PORT || 8080;
const appName = process.env.APP_NAME;
const version = process.env.VERSION;

app.get("/", (req, res) => {
  res.json({
    app: appName || "devansh-app",
    version: version || "1.0",
    pod: os.hostname()
  });
});

app.get("/healthz", (req, res) => {
  res.status(200).json({
    status: "healthy"
  });
});

app.listen(PORT, "0.0.0.0", () => {
  console.log(`Server listening on port ${PORT}`);
});