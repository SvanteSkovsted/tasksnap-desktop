import React from "react";
import ReactDOM from "react-dom/client";
import { getCurrentWindow } from "@tauri-apps/api/window";
import App from "./App";
import LoginApp from "./LoginApp";
import "./index.css";

// Both windows share the same index.html / JS bundle.
// Route to the correct component by reading the window label,
// which is set synchronously from Tauri's injected metadata.
const isLoginWindow = getCurrentWindow().label === "login";

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    {isLoginWindow ? <LoginApp /> : <App />}
  </React.StrictMode>
);
