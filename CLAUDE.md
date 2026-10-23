# aru-comms

Single-file static build of **ARU Comms** (All Risk Uniforms' internal chat / to-do /
inventory app), plus the kiosk setup for **Plato**, the always-on home laptop.
This repo is **public**: never commit passwords, tokens or customer data.

## Computers

- **Plato**: the home laptop (Windows), always on and plugged in, showing ARU 98 full
  screen. Code lives in `%USERPROFILE%\ARU\aru-comms` (+ `aru-membership-app` beside it).
  See `laptop/README.md`.
- **Ferdinand**: the other computer. LightBurn (the laser software) is set up there; Plato
  copies its LightBurn prefs and device profile (steps in `laptop/README.md`).

## Files

- `index.html`: the whole app in one file. No server; data lives in the browser's
  localStorage, and tabs on one device sync over BroadcastChannel. Login is a passphrase,
  then a phone number (admin is 530-720-6113).
- `laptop/lock.html`: Plato's lock screen. Matrix boot → Win98 logon → `../index.html`.
  The password is stored only as `sha256('aru98:' + password)` in `PASS_HASH`. A wrong
  password plays `laptop/nedry.{mp4,webm,gif}` if present, otherwise a built-in stand-in.
- `laptop/setup-laptop.ps1`: one-time Plato setup (power settings, Git, Claude Code, clone,
  Startup shortcut). Runs via `irm … | iex`, so it must never call `exit`.
- `laptop/start-kiosk.cmd`: run at sign-in. `git pull --ff-only`, then Edge `--kiosk`
  with its own profile in `%LOCALAPPDATA%\ARU98\edge`. The app's localStorage lives in
  that profile.
- `README.md` is an accidental copy of an old `index.html`. `old.jpg` and `index (3).html`
  are the same JPEG screenshot.

## Where index.html comes from

It's generated in the private repo `AllRiskUniforms/aru-membership-app`:
`docs/` (index.html, styles.css, matrix.js, app.js) → `node build-standalone.mjs` →
`dist/aru-comms.html`, copied here by hand. The real multi-user server version is
`comm-app/` in that repo ("ARU 98": Node/Express, deployed to Railway by
`.github/workflows/deploy-aru98.yml`).

Two bugs from that pipeline were fixed by hand in this repo's `index.html`. They still
exist upstream, so re-copying a fresh build brings them back:

1. `build-standalone.mjs` inlines JS with `String.replace(pattern, string)`, so `$$` in
   the code becomes `$`. That declares `const $` twice and the whole app script dies.
   Upstream fix: pass a function as the replacement (`() => …`).
2. Rules like `.login-wrap { display: flex }` override the `hidden` attribute, so the
   invisible login layer blocks every click after sign-in. Fixed with
   `[hidden] { display: none !important; }`. `docs/styles.css` and
   `comm-app/public/styles.css` need the same rule.

## Testing

No build or test tooling here. Open the HTML files directly (`file://`). For a headless
check, use Playwright's Chromium against `file:///…/laptop/lock.html` and walk the flow:
boot → dialog → wrong password (Nedry) → right password → app login.
