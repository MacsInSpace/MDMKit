/**
 * Runs in the page (MAIN) world on Mosyle Manager.
 *
 * Uniform Free Premium gate:
 *   checkPremium(origin, cb) → POST check_premium.php
 *   Free plan returns HTTP 503 with upsell HTML
 *   AnalisaError(503) injects #content_premium_feature / #alert_premium_feature
 *   checkPremium success callback never runs → feature blocked
 *
 * Devices "More" items often already call MDMBulkOperations directly (badge is
 * cosmetic). Features wrapped in checkPremium need this patch.
 */
(function () {
  'use strict';

  if (window.__mosyleFreeUnlockPage) return;
  window.__mosyleFreeUnlockPage = true;

  const FLAG = '__mosyleFreeUnlock';
  let enabled = true;
  let originalCheckPremium = null;
  let originalAnalisaError = null;

  function hidePremiumOverlay() {
    try {
      const box = document.getElementById('content_premium_feature');
      if (box) box.innerHTML = '';
      const alert = document.getElementById('alert_premium_feature');
      if (alert) alert.remove();
    } catch (_) { /* ignore */ }
  }

  function patchCheckPremium() {
    if (typeof window.checkPremium !== 'function') return false;
    if (window.checkPremium[FLAG]) return true;

    originalCheckPremium = window.checkPremium;
    window.checkPremium = function checkPremiumUnlocked(origin, callback) {
      if (!enabled) {
        return originalCheckPremium.call(this, origin, callback);
      }
      if (typeof callback === 'function') {
        try { callback(); } catch (_) { /* ignore */ }
      }
    };
    window.checkPremium[FLAG] = true;
    return true;
  }

  function patchAnalisaError() {
    if (typeof window.AnalisaError !== 'function') return false;
    if (window.AnalisaError[FLAG]) return true;

    originalAnalisaError = window.AnalisaError;
    window.AnalisaError = function AnalisaErrorUnlocked(responseText, textStatus, XMLHttpRequest, IsDepFlow) {
      if (enabled && responseText && responseText.status === 503) {
        try {
          if (typeof window.$ === 'function') window.$('#loading_box').hide();
        } catch (_) { /* ignore */ }
        hidePremiumOverlay();
        return false;
      }
      return originalAnalisaError.call(this, responseText, textStatus, XMLHttpRequest, IsDepFlow);
    };
    window.AnalisaError[FLAG] = true;
    return true;
  }

  function setBodyFlag() {
    try {
      document.documentElement.classList.toggle('mosyle-free-unlock-on', enabled);
      if (document.body) {
        document.body.classList.toggle('mosyle-free-unlock-on', enabled);
      }
    } catch (_) { /* ignore */ }
  }

  function apply() {
    const a = patchCheckPremium();
    const b = patchAnalisaError();
    setBodyFlag();
    if (enabled) hidePremiumOverlay();
    return a && b;
  }

  // Re-apply: Mosyle can redefine helpers after navigation / script loads
  const timer = setInterval(() => {
    apply();
  }, 400);

  window.addEventListener('message', (event) => {
    if (event.source !== window) return;
    const data = event.data;
    if (!data || data.source !== 'mosyle-free-unlock') return;

    if (data.type === 'setEnabled') {
      enabled = !!data.enabled;
      apply();
      window.postMessage({ source: 'mosyle-free-unlock', type: 'status', enabled }, '*');
    }
    if (data.type === 'ping') {
      window.postMessage({
        source: 'mosyle-free-unlock',
        type: 'status',
        enabled,
        patched: {
          checkPremium: !!(window.checkPremium && window.checkPremium[FLAG]),
          AnalisaError: !!(window.AnalisaError && window.AnalisaError[FLAG])
        }
      }, '*');
    }
  });

  apply();
  // Stop aggressive polling once both patches stick for a while
  setTimeout(() => {
    if (window.checkPremium && window.checkPremium[FLAG] &&
        window.AnalisaError && window.AnalisaError[FLAG]) {
      clearInterval(timer);
      // light keep-alive in case of late redefinition
      setInterval(apply, 3000);
    }
  }, 15000);
})();
