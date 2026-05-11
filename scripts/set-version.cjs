#!/usr/bin/env node
// Syncs the version from a git tag (e.g. v1.2.3) into package.json and
// src-tauri/tauri.conf.json so the built installers carry the right version.
// Usage: node scripts/set-version.cjs v1.2.3
"use strict";
const fs = require("fs");

const raw = process.argv[2];
if (!raw) {
  console.error("Usage: node scripts/set-version.cjs <tag|version>");
  process.exit(1);
}
const version = raw.replace(/^v/, "");

const files = [
  ["package.json",                  "version"],
  ["src-tauri/tauri.conf.json",     "version"],
];

for (const [file, key] of files) {
  const obj = JSON.parse(fs.readFileSync(file, "utf8"));
  obj[key] = version;
  fs.writeFileSync(file, JSON.stringify(obj, null, 2) + "\n");
  console.log(`  ${file}  →  ${version}`);
}
console.log("Version sync done.");
