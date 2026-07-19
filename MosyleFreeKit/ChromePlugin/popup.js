const STORAGE_KEY = 'mosyleFreeUnlockEnabled';
const SESSION_COOKIE_NAMES = new Set(['PHPSESSID', 'credentials']);

const checkbox = document.getElementById('enabled');
const copyBtn = document.getElementById('copySession');
const statusEl = document.getElementById('status');

function setStatus(message, kind) {
  statusEl.textContent = message;
  statusEl.className = kind ? `status ${kind}` : 'status';
}

chrome.storage.sync.get({ [STORAGE_KEY]: true }, (result) => {
  checkbox.checked = result[STORAGE_KEY] !== false;
});

checkbox.addEventListener('change', () => {
  chrome.storage.sync.set({ [STORAGE_KEY]: checkbox.checked });
});

function pickSessionCookies(cookies) {
  const byName = new Map();
  for (const cookie of cookies) {
    if (!SESSION_COOKIE_NAMES.has(cookie.name)) continue;
    // Prefer host-scoped values when duplicates exist; otherwise keep the first.
    if (!byName.has(cookie.name) || cookie.hostOnly) {
      byName.set(cookie.name, cookie.value);
    }
  }
  return byName;
}

function formatCookieHeader(byName) {
  const parts = [];
  for (const name of ['PHPSESSID', 'credentials']) {
    if (byName.has(name)) {
      parts.push(`${name}=${byName.get(name)}`);
    }
  }
  return `Cookie: ${parts.join('; ')}`;
}

copyBtn.addEventListener('click', async () => {
  copyBtn.disabled = true;
  setStatus('Reading Mosyle session…');

  try {
    const cookies = await chrome.cookies.getAll({ domain: 'mosyle.com' });
    const byName = pickSessionCookies(cookies);

    if (byName.size === 0) {
      setStatus(
        'No PHPSESSID or credentials cookie found. Sign in to myschool.mosyle.com in this browser, then try again.',
        'error'
      );
      return;
    }

    const text = formatCookieHeader(byName);
    await navigator.clipboard.writeText(text);

    const names = [...byName.keys()].join(', ');
    setStatus(
      `Copied ${names} for Connect-MosyleFree. Paste into the PowerShell prompt (Enter on a blank line).`,
      'ok'
    );
  } catch (err) {
    setStatus(`Could not copy session: ${err.message || err}`, 'error');
  } finally {
    copyBtn.disabled = false;
  }
});
