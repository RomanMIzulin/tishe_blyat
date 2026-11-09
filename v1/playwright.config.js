import { defineConfig, devices } from "@playwright/test";

const baseURL = new URL(
  process.env.VITE_BASE_PATH || "/",
  "http://127.0.0.1:4173",
).href;

export default defineConfig({
  testDir: "./e2e",
  fullyParallel: true,
  workers: 2,
  use: { baseURL, trace: "retain-on-failure" },
  projects: [
    {
      name: "desktop",
      use: {
        ...devices["Desktop Chrome"],
        viewport: { width: 1440, height: 1100 },
      },
    },
    {
      name: "mobile",
      use: { ...devices["iPhone 13"], defaultBrowserType: "chromium" },
    },
  ],
  webServer: {
    command: "npm run build && npm run preview -- --port 4173 --strictPort",
    url: baseURL,
    reuseExistingServer: false,
  },
});
