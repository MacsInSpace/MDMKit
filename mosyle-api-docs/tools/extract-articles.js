// Mosyle paid-tenant API-docs overlay scraper (recovered 2026-07-23 from Cursor's
// globalStorage state.vscdb - the original extract-snippet.js was lost with the
// Jamf/mosyle-api-docs folder). This is the FAST revision: it closes each article
// dialog after grabbing (the slow first cut stacked dialogs and bogged down).
//
// Use: sign in to a PAID tenant, open the API docs overlay (MDMApi articles list),
// paste this in the DevTools console. Poll window.__mosyleExtractStatus until
// running=false, then copy(JSON.stringify(window.__mosyleExtract)) to save.

(() => {
  const sleep = ms => new Promise(r => setTimeout(r, ms));

  function listArticles() {
    const links = [...document.querySelectorAll('[onclick*="openArticle"]')];
    const arts = [], seen = new Set();
    for (const el of links) {
      const m = (el.getAttribute('onclick') || '').match(/openArticle\(['"](\d+)['"]\s*,\s*['"]([^'"]+)['"]/);
      if (m && !seen.has(m[1])) { seen.add(m[1]); arts.push({ id: m[1], title: m[2] }); }
    }
    return arts;
  }

  function grabOpenArticle(expectedTitle) {
    // Prefer the dialog whose title matches
    const dialogs = [...document.querySelectorAll('.md_dialog.loaded')];
    let dialog = dialogs.find(d => {
      const t = d.querySelector('.md_title')?.innerText?.trim();
      return t && expectedTitle && t === expectedTitle;
    });
    if (!dialog) {
      // fallback: last loaded dialog that isn't the Articles index
      dialog = [...dialogs].reverse().find(d => {
        const t = d.querySelector('.md_title')?.innerText?.trim();
        return t && t !== 'Articles';
      });
    }
    if (!dialog) return null;

    const title = dialog.querySelector('.md_title')?.innerText?.trim() || expectedTitle;
    const content = dialog.querySelector('.md_contentinside') || dialog.querySelector('.md_content');
    const text = content ? content.innerText : '';
    const html = content ? content.innerHTML : '';

    const codes = [];
    // CodeMirror instances inside this dialog
    for (const cm of content.querySelectorAll('.CodeMirror')) {
      if (cm.CodeMirror) codes.push(cm.CodeMirror.getValue());
    }
    // codeview textareas
    for (const t of content.querySelectorAll('.codeview textarea, textarea')) {
      if (t.value && t.value.trim()) codes.push(t.value);
    }
    // pre blocks not already covered
    for (const p of content.querySelectorAll('pre')) {
      const v = p.innerText;
      if (v && v.trim()) codes.push(v);
    }
    // dedupe
    const uniq = [...new Set(codes.map(c => c.trim()).filter(Boolean))];

    const tables = [...content.querySelectorAll('table')].map(t => ({
      html: t.outerHTML,
      text: t.innerText
    }));

    return { title, text, html, codes: uniq, tables };
  }

  const arts = listArticles();
  const opener = window.getObj('MDMApi');
  window.__mosyleExtract = [];
  window.__mosyleExtractStatus = { done: 0, total: arts.length, running: true, errors: [] };

  (async () => {
    for (const a of arts) {
      try {
        opener.openArticle(a.id, a.title);
        // wait until dialog title matches or content appears
        let grabbed = null;
        for (let i = 0; i < 30; i++) {
          await sleep(200);
          grabbed = grabOpenArticle(a.title);
          if (grabbed && grabbed.text && grabbed.text.length > 80) break;
        }
        if (!grabbed || !grabbed.text) {
          window.__mosyleExtractStatus.errors.push({ id: a.id, title: a.title, reason: 'empty' });
          window.__mosyleExtract.push({ id: a.id, title: a.title, text: '', html: '', codes: [], tables: [] });
        } else {
          window.__mosyleExtract.push({ id: a.id, title: a.title, ...grabbed });
        }
        // close the article dialog (back/close) so we don't stack forever
        const dlg = [...document.querySelectorAll('.md_dialog.loaded')].reverse().find(d => {
          const t = d.querySelector('.md_title')?.innerText?.trim();
          return t && t !== 'Articles';
        });
        if (dlg) {
          const back = dlg.querySelector('.md_back');
          const close = dlg.querySelector('.md_close');
          if (back) back.click();
          else if (close) close.click();
        }
        await sleep(300);
      } catch (e) {
        window.__mosyleExtractStatus.errors.push({ id: a.id, title: a.title, reason: String(e) });
      }
      window.__mosyleExtractStatus.done++;
    }
    window.__mosyleExtractStatus.running = false;
  })();

  return JSON.stringify({ started: true, total: arts.length });
})()