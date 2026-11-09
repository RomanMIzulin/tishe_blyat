import "./styles.css";

const KEY = "tishe.entries.v1";
const LANGUAGE_KEY = "tishe.language.v1";
let language = null;
try {
  language = localStorage.getItem(LANGUAGE_KEY);
} catch {
  // The app still works in English when browser preferences are unavailable.
}
let saved = null;
let lastRaw = null;
let unavailable = false;
try {
  lastRaw = localStorage.getItem(KEY);
} catch {
  unavailable = true;
}
try {
  saved = JSON.parse(lastRaw ?? "null");
} catch {
  saved = { malformed: true };
}

const script = document.createElement("script");
script.src = `${import.meta.env.BASE_URL}elm.js`;
script.onload = () => {
  const app = window.Elm.Main.init({
    node: document.getElementById("app"),
    flags: { saved, unavailable, language },
  });

  app.ports.localeChanged.subscribe((locale) => {
    document.documentElement.lang = locale.code;
    document.title = locale.title;
    document.querySelector('meta[name="description"]').content =
      locale.description;
  });

  app.ports.rememberLanguage.subscribe((code) => {
    try {
      localStorage.setItem(LANGUAGE_KEY, code);
      app.ports.languageResult.send({ code, success: true });
    } catch {
      app.ports.languageResult.send({ code, success: false });
    }
  });

  // Serialize writes across tabs, then compare against the snapshot this tab read.
  // Without Web Locks (e.g. insecure HTTP), keep new entries in memory rather
  // than risk an unprotected overwrite of this sensitive journal.
  const withStorageLock = async (operation) => {
    try {
      if (!navigator.locks) throw new Error("Web Locks unavailable");
      await navigator.locks.request(KEY, operation);
    } catch {
      app.ports.storageResult.send(false);
    }
  };

  app.ports.persist.subscribe((entries) => {
    void withStorageLock(() => {
      if (localStorage.getItem(KEY) !== lastRaw) {
        app.ports.storageConflict.send(null);
        return;
      }
      const encoded = JSON.stringify(entries);
      localStorage.setItem(KEY, encoded);
      lastRaw = encoded;
      app.ports.storageResult.send(true);
    });
  });

  app.ports.clearStorage.subscribe(() => {
    void withStorageLock(() => {
      localStorage.removeItem(KEY);
      lastRaw = null;
      app.ports.storageResult.send(true);
    });
  });

  app.ports.download.subscribe((entries) => {
    const url = URL.createObjectURL(
      new Blob([JSON.stringify(entries, null, 2)], {
        type: "application/json",
      }),
    );
    const link = document.createElement("a");
    link.href = url;
    link.download = "tishe-journal.json";
    link.click();
    setTimeout(() => URL.revokeObjectURL(url), 1000);
  });
};
script.onerror = () => {
  document.getElementById("app").textContent =
    "Could not load the app. Try refreshing the page.";
};
document.body.append(script);
