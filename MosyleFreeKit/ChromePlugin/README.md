# Mosyle Free Unlock

Chromium extension (MV3) for techs on **Mosyle Manager Free**. Puts aside the Premium UI gate (badges, trial bar, `checkPremium` / 503 upsell) so normal Mosyle dialogs can run, and can copy your browser session for **[MosyleFreeKit](../README.md)** (PowerShell).

Interactive use only (Chrome / Edge / Brave). For bulk or scripted work across schools, use MosyleFreeKit. Paid Manager API → **MosyleKit**.

---

## Copy session for MosyleFreeKit

Mosyle's `PHPSESSID` / `credentials` cookies are **HttpOnly**, so they never appear in
`document.cookie`. This extension reads them with the Chrome `cookies` API (same browser
profile you are signed into).

1. Sign in to `https://myschool.mosyle.com/` in Chrome / Edge / Brave
2. Click the extension icon → **Copy session for FreeKit**
3. In PowerShell: `Connect-MosyleFree` (or `Connect-MosyleFree -SaveCookie`) and paste
4. Press Enter on a blank line

The clipboard holds a live admin session — treat it like a password. Prefer
`-SaveCookie` so later runs pick up `~/.mosylefreekit/cookie.txt` until the cookie expires.

---

## What it unlocks

On Free, many Devices actions show an orange **Premium** badge or open an upgrade screen. That gate is mostly UI:

| Unlocked | Meaning |
|----------|---------|
| Premium badges hidden | More-menu items no longer look blocked |
| Yellow top upgrade bar hidden | “Unleash the full potential…” trial bar gone |
| Upgrade overlay suppressed | `check_premium.php` 503 upsell no longer blocks the flow |
| `checkPremium` bypassed | Features that wait on that check can open their normal Mosyle dialogs |

You still use Mosyle’s own screens: select devices → More → Lock / Restart / etc. → confirm (including **admin password** when Mosyle asks).

---

## What it does **not** unlock

| Not unlocked | Why |
|--------------|-----|
| Paid Manager API (`managerapi.mosyle.com`) | Different product / JWT API — use **MosyleKit** |
| Guaranteed command delivery | Offline / limbo devices only queue; they won’t run until check-in |
| Soft `OK` = really queued | Some Free ops return OK without a pending command (e.g. Restart). Check the device **Commands** tab |
| Server-side license limits | If Mosyle truly rejects an op on the server, this extension cannot invent Premium |
| Bulk automation | No CSV fan-out — use **MosyleFreeKit** |
| Skipping admin password | Security-confirm dialogs still apply |

---

## Install (load unpacked)

- [ ] Copy or clone the `mosyle-free-unlock` folder onto the tech’s Mac (keep the folder intact; do not open a single file inside)
- [ ] Open Chrome or Edge
- [ ] Go to `chrome://extensions` (Chrome/Brave) or `edge://extensions` (Edge)
- [ ] Turn **Developer mode** ON (top right)
- [ ] Click **Load unpacked**
- [ ] Select the `mosyle-free-unlock` folder (the one that contains `manifest.json`)
- [ ] Confirm **Mosyle Free Unlock** appears and is enabled
- [ ] Open `https://myschool.mosyle.com/` and sign in to the school
- [ ] **Refresh** the tab (required after install or update)
- [ ] Confirm green **Free Unlock** chip at bottom-right of the page
- [ ] Optional: click the extension icon → leave **Unlock Premium UI gate** checked

### Update later

1. Pull/replace the folder with the new version  
2. `chrome://extensions` → **Reload** on Mosyle Free Unlock  
3. Refresh the Mosyle tab  

### Uninstall

`chrome://extensions` → Remove **Mosyle Free Unlock** (or toggle off).

---

## Quick check it worked

1. Devices Overview → select a device → **More**  
2. Items that used to say “Lock Device Premium” should no longer show the orange Premium badge  
3. Choosing Lock should open Mosyle’s lock dialog (not the upgrade splash)  
4. Prefer a **stale / limbo** test device the first time  

---

## Safety

- Treat Erase / Lost Mode / Wipe as live production actions  
- Prefer limbo or long-offline devices when testing  
- This is an internal tech tool — not for students or school staff without approval  

---

## Support pointers

| Need | Use |
|------|------|
| Interactive Free console | **This extension** (Unlock toggle) |
| Session cookie for PowerShell | **This extension** → Copy session for FreeKit |
| Scripted Free bulk (serial allowlists, `-Verify`) | **MosyleFreeKit** |
| Paid Mosyle API | **MosyleKit** |

---

## Version

`0.3.0` — adds **Copy session for FreeKit** (`cookies` permission). After update:
`chrome://extensions` → Reload on Mosyle Free Unlock, then refresh the Mosyle tab.

## Layout

| File | Role |
|------|------|
| `manifest.json` | MV3 manifest |
| `content.js` / `page.js` | Inject + patch page gate |
| `unlock.css` | Hide badges / trial bar / overlay |
| `popup.html` | On/off toggle |
| `icons/` | Extension icons |
| `package-for-techs.sh` | Zip handout for techs |
