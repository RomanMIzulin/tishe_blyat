import { test, expect } from "@playwright/test";
import AxeBuilder from "@axe-core/playwright";

for (const locale of [
  {
    code: "en",
    language: "English",
    destinations: ["Now", "Journal", "Practices", "Why this is here"],
  },
  {
    code: "ru",
    language: "Русский",
    destinations: ["Сейчас", "Дневник", "Практики", "Почему это здесь"],
  },
]) {
  test(`main pages meet automated WCAG A/AA checks in ${locale.code}`, async ({
    page,
  }, testInfo) => {
    await page.goto("./");
    await page
      .getByRole("button", { name: locale.language, exact: true })
      .click();
    await expect(page.locator("html")).toHaveAttribute("lang", locale.code);
    for (const destination of locale.destinations) {
      await navigate(page, destination);
      if (locale.code === "en") {
        expect(
          (await page.locator("body").innerText()).replace("Русский", ""),
        ).not.toMatch(/[а-яё]/i);
      }
      await page.evaluate(() => document.fonts.ready);
      expect(
        await page.evaluate(
          () => document.documentElement.scrollWidth <= innerWidth,
        ),
      ).toBe(true);
      await page.screenshot({
        path: testInfo.outputPath(`page-${destination}.png`),
        fullPage: true,
      });
      const results = await new AxeBuilder({ page })
        .withTags(["wcag2a", "wcag2aa", "wcag21a", "wcag21aa"])
        .analyze();
      await testInfo.attach(`accessibility-${destination}`, {
        body: JSON.stringify(results.violations, null, 2),
        contentType: "application/json",
      });
      expect(
        results.violations.map((v) => ({
          id: v.id,
          nodes: v.nodes.map((n) => ({
            target: n.target,
            summary: n.failureSummary,
          })),
        })),
      ).toEqual([]);
    }
  });
}

const KEY = "tishe.entries.v1";
const LANGUAGE_KEY = "tishe.language.v1";
const navigate = (page, name) =>
  page
    .getByRole("navigation")
    .getByRole("button", { name, exact: true })
    .click();

async function saveEntry(
  page,
  note = "Хочу отдохнуть и боюсь подвести команду.",
) {
  await page.getByLabel("Tension level from 0 to 10").fill("7");
  await page.getByRole("button", { name: "Anxiety", exact: true }).click();
  await page.getByRole("button", { name: "Fatigue", exact: true }).click();
  await page.getByLabel("What’s on your mind?").fill(note);
  await page.getByRole("button", { name: "Save this moment" }).click();
  await expect(
    page.getByRole("button", { name: "Moment saved" }),
  ).toBeDisabled();
}

test("dashboard is local, responsive, and has no invented history", async ({
  page,
  baseURL,
}, testInfo) => {
  const errors = [];
  const outsideBaseRequests = [];
  const failedResponses = [];
  const requests = [];
  page.on("pageerror", (error) => errors.push(error.message));
  page.on("request", (request) => {
    requests.push(request.url());
    if (!request.url().startsWith(baseURL))
      outsideBaseRequests.push(request.url());
  });
  page.on("response", (response) => {
    if (response.status() >= 400) failedResponses.push(response.url());
  });
  await page.goto("./");
  await expect(
    page.getByRole("heading", { name: "How are you right now?" }),
  ).toBeVisible();
  await expect(
    page.getByText("Your own rhythm will appear here"),
  ).toBeVisible();
  await expect(page.locator(".sidebar")).not.toContainText("✳");
  await page.evaluate(() => document.fonts.ready);
  expect(
    await page.evaluate(
      () => document.documentElement.scrollWidth <= innerWidth,
    ),
  ).toBe(true);
  await page.screenshot({
    path: testInfo.outputPath("dashboard.png"),
    fullPage: true,
  });
  const favicon = await page.request.get(new URL("favicon.svg", baseURL).href);
  expect(favicon.ok()).toBe(true);
  expect(favicon.headers()["content-type"]).toContain("image/svg+xml");
  expect(requests).toContain(new URL("elm.js", baseURL).href);
  expect(errors).toEqual([]);
  expect(outsideBaseRequests).toEqual([]);
  expect(failedResponses).toEqual([]);
});

test("records, feelings, export, reload, and confirmed deletion", async ({
  page,
}) => {
  await page.goto("./");
  await saveEntry(page);
  await navigate(page, "Journal");
  await expect(page.getByText("Entries in this period: 1")).toBeVisible();
  await expect(page.locator(".journal-entry")).toContainText(
    "Хочу отдохнуть и боюсь подвести команду.",
  );
  await expect(page.locator(".entry-level strong")).toHaveText("7");
  await expect(page.locator(".entry-feelings")).toContainText("Anxiety");
  await expect(page.locator(".entry-feelings")).toContainText("Fatigue");
  const downloadPromise = page.waitForEvent("download");
  await page.getByRole("button", { name: "Download JSON" }).click();
  const download = await downloadPromise;
  expect(download.suggestedFilename()).toBe("tishe-journal.json");
  const stream = await download.createReadStream();
  const chunks = [];
  for await (const chunk of stream) chunks.push(chunk);
  const data = JSON.parse(Buffer.concat(chunks).toString("utf8"));
  expect(data[0]).toMatchObject({
    level: 7,
    feelings: ["anxiety", "fatigue"],
    note: "Хочу отдохнуть и боюсь подвести команду.",
  });
  await page.reload();
  await navigate(page, "Journal");
  await expect(page.getByText("Entries in this period: 1")).toBeVisible();
  await page.getByRole("button", { name: "Delete all data" }).click();
  await page.getByRole("button", { name: "Cancel", exact: true }).click();
  await expect(page.getByText("Entries in this period: 1")).toBeVisible();
  await page.getByRole("button", { name: "Delete all data" }).click();
  await page
    .getByRole("button", { name: "Yes, delete everything", exact: true })
    .click();
  await expect(
    page.getByRole("heading", { name: "A blank page for now" }),
  ).toBeVisible();
  expect(
    await page.evaluate((key) => localStorage.getItem(key), KEY),
  ).toBeNull();
});

test("practice pauses, resumes, completes, and resets without waiting a minute", async ({
  page,
}) => {
  await page.clock.install();
  await page.goto("./");
  await page.getByRole("button", { name: "Take a pause" }).click();
  await page.getByRole("button", { name: "Start practice" }).click();
  await page.clock.runFor(21000);
  await expect(page.locator(".timer-inner strong")).toHaveText("0:39");
  await expect(page.getByText("STEP 2 OF 3")).toBeVisible();
  await page.getByRole("button", { name: "Pause" }).click();
  await page.clock.runFor(10000);
  await expect(page.locator(".timer-inner strong")).toHaveText("0:39");
  await page.getByRole("button", { name: "Continue" }).click();
  await page.clock.runFor(40000);
  await expect(
    page.getByRole("button", { name: "How am I now?" }),
  ).toBeVisible();
  await expect(page.locator(".timer-inner strong")).toHaveText("0:00");
  await page.getByRole("button", { name: "Finish / reset" }).click();
  await expect(page.locator(".timer-inner strong")).toHaveText("1:00");
  await expect(
    page.getByRole("button", { name: "Start practice" }),
  ).toBeVisible();
});

test("body practices expose their steps and precautions without a timer", async ({
  page,
}, testInfo) => {
  await page.goto("./");
  await navigate(page, "Practices");
  await page
    .getByRole("button", { name: "Body and movement", exact: true })
    .click();
  await expect(page.locator(".practice-option")).toHaveCount(9);
  const labels = [
    "Walk on your toes",
    "Reach up through your crown",
    "Take a sensory walk",
    "Explore touch on your body",
    "Tap with your fingertips",
    "Massage your muscles by hand",
    "Massage your head and face",
    "Feel your breathing move",
    "Shade your eyes with your palms",
  ];
  for (const label of labels) {
    const option = page.getByRole("button", { name: label });
    await option.click();
    await expect(option).toHaveAttribute("aria-pressed", "true");
    await expect(
      page.locator(".practice-player").getByRole("heading", { name: label }),
    ).toBeVisible();
    await expect(page.locator(".steps-grid > div")).toHaveCount(3);
    await expect(page.locator(".practice-precaution")).not.toBeEmpty();
    await expect(page.locator(".timer-inner strong")).toHaveText("1:00");
    for (const step of await page.locator(".steps-grid p").allTextContents()) {
      expect(step.trim().length).toBeGreaterThan(0);
    }
  }
  await expect(page.locator(".practice-precaution")).toContainText(
    "No pressure on your eyes",
  );
  await expect(page.locator(".safety-note")).toContainText("not treatment");
  const results = await new AxeBuilder({ page })
    .withTags(["wcag2a", "wcag2aa", "wcag21a", "wcag21aa"])
    .analyze();
  expect(results.violations).toEqual([]);
  expect(
    await page.evaluate(
      () => document.documentElement.scrollWidth <= innerWidth,
    ),
  ).toBe(true);
  await page.evaluate(() => document.fonts.ready);
  await page.screenshot({
    path: testInfo.outputPath("body-practices.png"),
    fullPage: true,
  });
});

test("switching body practices or groups resets the timer", async ({
  page,
}) => {
  await page.clock.install();
  await page.goto("./");
  await navigate(page, "Practices");
  await page
    .getByRole("button", { name: "Body and movement", exact: true })
    .click();
  await page.getByRole("button", { name: "Tap with your fingertips" }).click();
  await page.getByRole("button", { name: "Start practice" }).click();
  await page.clock.runFor(21000);
  await expect(page.locator(".timer-inner strong")).toHaveText("0:39");
  await page.getByRole("button", { name: "Take a sensory walk" }).click();
  await expect(page.locator(".timer-inner strong")).toHaveText("1:00");
  await expect(page.locator(".practice-precaution")).toContainText(
    "put your phone away",
  );
  await expect(page.locator(".steps-grid")).toContainText("a creaking tree");
  await page
    .getByRole("button", { name: "Attention and choice", exact: true })
    .click();
  await expect(page.locator(".practice-option")).toHaveCount(3);
  await expect(
    page
      .locator(".practice-player")
      .getByRole("heading", { name: "Return to the present" }),
  ).toBeVisible();
  await page.clock.runFor(61000);
  await expect(page.locator(".timer-inner strong")).toHaveText("1:00");
  await expect(
    page.getByRole("button", { name: "Start practice" }),
  ).toBeVisible();
});

test("theory lenses disclose sources and optional practice guidance", async ({
  page,
}) => {
  await page.goto("./");
  await navigate(page, "Why this is here");
  await page
    .getByRole("button", { name: "Psychoanalysis", exact: true })
    .click();
  await expect(
    page.getByRole("heading", {
      name: "There can be more than one wish inside.",
    }),
  ).toBeVisible();
  await expect(page.locator(".source")).toContainText("Freud");
  await expect(
    page.getByText("Theory is not a promise of results"),
  ).toBeVisible();
  await page.getByText("When is it better to stop a practice?").click();
  await expect(
    page.getByText(/If a question or exercise feels unpleasant/),
  ).toBeVisible();
  await page
    .getByRole("button", { name: "Phenomenology", exact: true })
    .click();
  await expect(page.locator(".source")).toContainText("Husserl");
  expect(
    await page.evaluate(
      () => document.documentElement.scrollWidth <= innerWidth,
    ),
  ).toBe(true);
});

test("malformed storage is preserved until an explicit destructive confirmation", async ({
  page,
}) => {
  await page.addInitScript(
    (key) => localStorage.setItem(key, "{broken-json"),
    KEY,
  );
  await page.goto("./");
  await expect(page.getByRole("alert")).toContainText(
    "Could not read the saved data",
  );
  await expect(
    page.getByRole("button", { name: "Save this moment" }),
  ).toBeDisabled();
  expect(await page.evaluate((key) => localStorage.getItem(key), KEY)).toBe(
    "{broken-json",
  );
  await navigate(page, "Journal");
  await page.getByRole("button", { name: "Delete all data" }).click();
  await page.getByRole("button", { name: "Yes, delete everything" }).click();
  await expect(page.getByRole("alert")).toHaveCount(0);
  expect(
    await page.evaluate((key) => localStorage.getItem(key), KEY),
  ).toBeNull();
});

test("storage failures retain in-memory entries and warn about reload", async ({
  page,
}) => {
  await page.addInitScript(() => {
    Storage.prototype.setItem = () => {
      throw new DOMException("Full", "QuotaExceededError");
    };
  });
  await page.goto("./");
  await saveEntry(page, "Запись не должна исчезнуть из памяти.");
  await expect(page.getByRole("alert")).toContainText("Could not save data");
  await navigate(page, "Journal");
  await expect(page.locator(".journal-entry")).toContainText(
    "Запись не должна исчезнуть из памяти.",
  );
  await expect(
    page.getByRole("button", { name: "Download JSON" }),
  ).toBeEnabled();
});

test("date filters use real stored dates", async ({ page }) => {
  await page.addInitScript((key) => {
    localStorage.setItem(
      key,
      JSON.stringify(
        [1, 15, 45].map((days) => ({
          at: Date.now() - days * 86400000,
          level: 5,
          feelings: [],
          note: `Запись ${days}`,
        })),
      ),
    );
  }, KEY);
  await page.goto("./");
  await navigate(page, "Journal");
  await expect(page.locator(".journal-entry")).toHaveCount(1);
  await page.getByRole("button", { name: "30 days", exact: true }).click();
  await expect(page.locator(".journal-entry")).toHaveCount(2);
  await page.getByRole("button", { name: "All time", exact: true }).click();
  await expect(page.locator(".journal-entry")).toHaveCount(3);
});

test("a stale tab cannot overwrite another tab’s journal", async ({
  page,
  context,
}) => {
  await page.goto("./");
  const other = await context.newPage();
  await other.goto("./");
  await saveEntry(page, "Запись первой вкладки");
  await saveEntry(other, "Запись второй вкладки");
  await expect(other.getByRole("alert")).toContainText(
    "The journal changed in another tab",
  );
  const persisted = await page.evaluate(
    (key) => JSON.parse(localStorage.getItem(key)),
    KEY,
  );
  expect(persisted).toHaveLength(1);
  expect(persisted[0].note).toBe("Запись первой вкладки");
  await navigate(other, "Journal");
  await expect(other.locator(".journal-entry")).toContainText(
    "Запись второй вкладки",
  );
  await expect(
    other.getByRole("button", { name: "Download JSON" }),
  ).toBeEnabled();
});

test("a failed deletion keeps records visible and allows retry", async ({
  page,
}) => {
  await page.goto("./");
  await saveEntry(
    page,
    "Эту запись нельзя незаметно оставить после ошибки удаления.",
  );
  await page.evaluate(() => {
    Storage.prototype.removeItem = () => {
      throw new DOMException("Blocked", "SecurityError");
    };
  });
  await navigate(page, "Journal");
  await page.getByRole("button", { name: "Delete all data" }).click();
  await page.getByRole("button", { name: "Yes, delete everything" }).click();
  await expect(
    page.getByRole("alert").filter({ hasText: "Data was not deleted" }),
  ).toBeVisible();
  await expect(page.locator(".journal-entry")).toHaveCount(1);
  await expect(
    page.getByRole("button", { name: "Yes, delete everything" }),
  ).toBeEnabled();
  expect(
    await page.evaluate(
      (key) => JSON.parse(localStorage.getItem(key)).length,
      KEY,
    ),
  ).toBe(1);
});

test("high tension stays an ordinary observation without escalation", async ({
  page,
}) => {
  await page.goto("./");
  const level = page.getByLabel("Tension level from 0 to 10");
  for (const value of ["8", "9", "10"]) {
    await level.fill(value);
    await expect(page.locator(".level-number")).toHaveText(value);
    await expect(page.locator(".level-copy strong")).toHaveText("High tension");
    await expect(page.getByRole("alert")).toHaveCount(0);
    await expect(
      page.getByText(/emergency|safe place|contact someone/i),
    ).toHaveCount(0);
  }
  await page.getByRole("button", { name: "Save this moment" }).click();
  await expect(
    page.getByRole("button", { name: "Moment saved" }),
  ).toBeDisabled();
  await navigate(page, "Journal");
  await expect(page.locator(".entry-level strong")).toHaveText("10");
});

test("English is the default even when the browser prefers Russian", async ({
  page,
}) => {
  await page.addInitScript(() => {
    Object.defineProperty(navigator, "language", { get: () => "ru-RU" });
    Object.defineProperty(navigator, "languages", {
      get: () => ["ru-RU", "ru"],
    });
  });
  await page.goto("./");
  await expect(page.locator("html")).toHaveAttribute("lang", "en");
  await expect(page).toHaveTitle("Tishe — a place for yourself");
  await expect(page.locator('meta[name="description"]')).toHaveAttribute(
    "content",
    /personal space/,
  );
  await expect(
    page.getByRole("button", { name: "English", exact: true }),
  ).toHaveAttribute("aria-pressed", "true");
  await expect(
    page.getByRole("heading", { name: "How are you right now?" }),
  ).toBeVisible();
  await expect(page.locator(".date-label")).not.toContainText(/[а-яё]/i);
});

test("keyboard language selection preserves the draft and remembers the choice", async ({
  page,
}) => {
  await page.goto("./");
  await page.getByLabel("Tension level from 0 to 10").fill("8");
  await page.getByRole("button", { name: "Anger", exact: true }).click();
  await page
    .getByLabel("What’s on your mind?")
    .fill("A fictional note / Вымышленная заметка");
  const russian = page.getByRole("button", { name: "Русский", exact: true });
  await russian.focus();
  await expect(russian).toBeFocused();
  await russian.press("Space");
  await expect(page.locator("html")).toHaveAttribute("lang", "ru");
  await expect(page).toHaveTitle("Тише — место для себя");
  await expect(page.locator('meta[name="description"]')).toHaveAttribute(
    "content",
    /личное пространство/,
  );
  await expect(page.getByLabel("Уровень напряжения от 0 до 10")).toHaveValue(
    "8",
  );
  await expect(
    page.getByRole("button", { name: "Злость", exact: true }),
  ).toHaveAttribute("aria-pressed", "true");
  await expect(page.getByLabel("Что сейчас занимает тебя?")).toHaveValue(
    "A fictional note / Вымышленная заметка",
  );
  expect(
    await page.evaluate((key) => localStorage.getItem(key), KEY),
  ).toBeNull();
  await page.getByRole("button", { name: "Сохранить момент" }).click();
  await expect(
    page.getByRole("button", { name: "Момент записан" }),
  ).toBeDisabled();
  const raw = await page.evaluate((key) => localStorage.getItem(key), KEY);
  await page.getByRole("button", { name: "English", exact: true }).click();
  await navigate(page, "Journal");
  await expect(page.locator(".journal-entry")).toContainText(
    "A fictional note / Вымышленная заметка",
  );
  await expect(page.locator(".entry-feelings")).toHaveText("Anger");
  expect(await page.evaluate((key) => localStorage.getItem(key), KEY)).toBe(
    raw,
  );
  await page.getByRole("button", { name: "Русский", exact: true }).click();
  await expect(
    page.getByRole("heading", { name: "Дневник наблюдений." }),
  ).toBeVisible();
  await expect(page.locator(".entry-feelings")).toHaveText("Злость");
  await page.reload();
  await expect(page.locator("html")).toHaveAttribute("lang", "ru");
  await expect(
    page.getByRole("heading", { name: "Как ты сейчас?" }),
  ).toBeVisible();
  await navigate(page, "Дневник");
  await expect(page.locator(".journal-entry")).toContainText(
    "A fictional note / Вымышленная заметка",
  );
  await page.getByRole("button", { name: "English", exact: true }).click();
  await page.reload();
  await expect(page.locator("html")).toHaveAttribute("lang", "en");
  expect(
    await page.evaluate((key) => localStorage.getItem(key), LANGUAGE_KEY),
  ).toBe("en");
});

test("changing language keeps the selected practice and running timer", async ({
  page,
}, testInfo) => {
  await page.clock.install();
  await page.goto("./");
  await navigate(page, "Practices");
  await page
    .getByRole("button", { name: "Body and movement", exact: true })
    .click();
  await page
    .getByRole("button", { name: "Shade your eyes with your palms" })
    .click();
  await page.getByRole("button", { name: "Start practice" }).click();
  await page.clock.runFor(21000);
  await page.getByRole("button", { name: "Русский", exact: true }).click();
  await expect(page.locator(".timer-inner strong")).toHaveText("0:39");
  await expect(page.locator(".practice-player h2")).toHaveText(
    "Прикрыть глаза ладонями",
  );
  await expect(
    page.getByRole("button", { name: "Приостановить" }),
  ).toBeVisible();
  await expect(page.locator(".practice-precaution")).toContainText(
    "Никакого давления на глаза",
  );
  await expect(page.locator(".steps-grid")).toContainText(
    "Ладони не касаются глаз",
  );
  await page.clock.runFor(1000);
  await expect(page.locator(".timer-inner strong")).toHaveText("0:38");
  const results = await new AxeBuilder({ page })
    .withTags(["wcag2a", "wcag2aa", "wcag21a", "wcag21aa"])
    .analyze();
  expect(results.violations).toEqual([]);
  expect(
    await page.evaluate(
      () => document.documentElement.scrollWidth <= innerWidth,
    ),
  ).toBe(true);
  await page.evaluate(() => document.fonts.ready);
  await page.screenshot({
    path: testInfo.outputPath("body-practices-ru.png"),
    fullPage: true,
  });
});

test("unknown language preferences fall back to English without touching the journal", async ({
  page,
}) => {
  await page.addInitScript(
    ({ key, languageKey }) => {
      localStorage.setItem(languageKey, "de");
      localStorage.setItem(
        key,
        JSON.stringify([
          {
            at: Date.now(),
            level: 4,
            feelings: ["calm"],
            note: "Legacy / Старая запись",
          },
        ]),
      );
    },
    { key: KEY, languageKey: LANGUAGE_KEY },
  );
  await page.goto("./");
  await expect(page.locator("html")).toHaveAttribute("lang", "en");
  await expect(
    page.getByRole("heading", { name: "How are you right now?" }),
  ).toBeVisible();
  await navigate(page, "Journal");
  await expect(page.locator(".journal-entry")).toContainText(
    "Legacy / Старая запись",
  );
  await expect(page.locator(".entry-feelings")).toHaveText("Calm");
  await expect(page.getByRole("alert")).toHaveCount(0);
});

test("blocked language preference writes do not prevent switching or saving entries", async ({
  page,
}) => {
  await page.addInitScript((languageKey) => {
    const setItem = Storage.prototype.setItem;
    Storage.prototype.setItem = function (key, value) {
      if (key === languageKey)
        throw new DOMException("Blocked", "SecurityError");
      return setItem.call(this, key, value);
    };
  }, LANGUAGE_KEY);
  await page.goto("./");
  await page.getByRole("button", { name: "Русский", exact: true }).click();
  await expect(page.locator("html")).toHaveAttribute("lang", "ru");
  await expect(page.locator(".language-hint")).toContainText(
    "Не удалось запомнить язык",
  );
  await page.getByRole("button", { name: "English", exact: true }).click();
  await expect(page.locator("html")).toHaveAttribute("lang", "en");
  await expect(page.locator(".language-hint")).toContainText(
    "Could not remember the language",
  );
  await saveEntry(page, "Fictional entry with blocked preferences");
  await expect(page.getByRole("alert")).toHaveCount(0);
  await page.reload();
  await expect(page.locator("html")).toHaveAttribute("lang", "en");
  await navigate(page, "Journal");
  await expect(page.locator(".journal-entry")).toContainText(
    "Fictional entry with blocked preferences",
  );
});
