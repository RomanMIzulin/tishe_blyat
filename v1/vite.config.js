import { defineConfig } from "vite";
import { spawnSync } from "node:child_process";

export default defineConfig({
  base: process.env.VITE_BASE_PATH || "/",
  plugins: [
    {
      name: "elm-rebuild",
      handleHotUpdate({ file, server }) {
        if (!file.endsWith(".elm")) return;
        const result = spawnSync(process.execPath, ["scripts/build.mjs"], {
          encoding: "utf8",
        });
        if (result.status !== 0) {
          server.ws.send({
            type: "error",
            err: {
              message: result.stdout + result.stderr,
              stack: "",
              plugin: "elm-rebuild",
            },
          });
        } else {
          server.ws.send({ type: "full-reload" });
        }
        return [];
      },
    },
  ],
});
