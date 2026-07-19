/**
 * Isolated content script: injects page.js into MAIN world and syncs enable flag.
 */
(function () {
  'use strict';

  const STORAGE_KEY = 'mosyleFreeUnlockEnabled';

  function injectPageScript() {
    if (document.documentElement.dataset.mosyleFreeUnlockInjected === '1') return;
    document.documentElement.dataset.mosyleFreeUnlockInjected = '1';

    const script = document.createElement('script');
    script.src = chrome.runtime.getURL('page.js');
    script.async = false;
    (document.documentElement || document.head).appendChild(script);
    script.addEventListener('load', () => script.remove());
  }

  function pushEnabled(enabled) {
    window.postMessage({ source: 'mosyle-free-unlock', type: 'setEnabled', enabled }, '*');
  }

  injectPageScript();

  chrome.storage.sync.get({ [STORAGE_KEY]: true }, (result) => {
    const enabled = result[STORAGE_KEY] !== false;
    document.documentElement.classList.toggle('mosyle-free-unlock-on', enabled);
    // page.js may not be ready yet
    const send = () => pushEnabled(enabled);
    send();
    setTimeout(send, 300);
    setTimeout(send, 1200);
  });

  chrome.storage.onChanged.addListener((changes, area) => {
    if (area !== 'sync' && area !== 'local') return;
    if (!changes[STORAGE_KEY]) return;
    const enabled = changes[STORAGE_KEY].newValue !== false;
    document.documentElement.classList.toggle('mosyle-free-unlock-on', enabled);
    pushEnabled(enabled);
  });
})();
