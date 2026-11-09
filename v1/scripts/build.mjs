import { spawnSync } from "node:child_process";
import { mkdirSync } from "node:fs";
mkdirSync("public", { recursive: true });
const result = spawnSync(
  "elm",
  [
    "make",
    "src/Main.elm",
    "--output=public/elm.js",
    ...(process.argv.includes("--optimize") ? ["--optimize"] : []),
  ],
  { stdio: "inherit", shell: process.platform === "win32" },
);
process.exit(result.status ?? 1);
