<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover" />
  <meta name="theme-color" content="#000000" />
  <title>ARU Comms</title>
  <style>
:root {
  --green: #00ff5f;
  --w98-face: #c0c0c0;
  --w98-shadow: #808080;
  --w98-dark: #000;
  --w98-light: #fff;
  --w98-blue: #000080;
  --bg: #0b0f0c;
  --panel: #11161300;
  --me: #075e54;
  --other: #202c33;
  --text: #e9edef;
}
* { box-sizing: border-box; }
html, body { height: 100%; margin: 0; }
body {
  font-family: -apple-system, Segoe UI, Roboto, Helvetica, Arial, sans-serif;
  background: #000; color: var(--text); overflow: hidden;
}
#matrix { position: fixed; inset: 0; z-index: 0; display: block; }
#matrix.hidden { display: none; }

/* ── Windows 98 login ──────────────────────────────────────────────────────── */
.login-wrap {
  position: fixed; inset: 0; z-index: 2;
  display: flex; align-items: center; justify-content: center; padding: 16px;
}
.win98 {
  width: 360px; max-width: 100%;
  background: var(--w98-face); color: #000;
  border: 2px solid; border-color: var(--w98-light) var(--w98-dark) var(--w98-dark) var(--w98-light);
  box-shadow: 2px 2px 0 #000, inset -1px -1px 0 var(--w98-shadow);
  font-family: "MS Sans Serif", Tahoma, Geneva, sans-serif;
}
.title-bar {
  background: linear-gradient(90deg, var(--w98-blue), #1084d0);
  color: #fff; display: flex; align-items: center; justify-content: space-between;
  padding: 3px 4px; font-weight: bold; font-size: 13px;
}
.title-bar-controls button {
  width: 16px; height: 14px; background: var(--w98-face);
  border: 1px solid; border-color: var(--w98-light) var(--w98-dark) var(--w98-dark) var(--w98-light);
}
.win98-body { padding: 16px; }
.prompt { margin: 0 0 12px; font-size: 13px; }
.win98-body input {
  width: 100%; padding: 6px; font-size: 14px; margin-bottom: 12px;
  border: 2px solid; border-color: var(--w98-dark) var(--w98-light) var(--w98-light) var(--w98-dark);
  background: #fff;
}
.row-right { display: flex; justify-content: flex-end; }
.w98btn {
  min-width: 75px; padding: 5px 12px; font-size: 13px; cursor: pointer;
  background: var(--w98-face);
  border: 2px solid; border-color: var(--w98-light) var(--w98-dark) var(--w98-dark) var(--w98-light);
}
.w98btn:active { border-color: var(--w98-dark) var(--w98-light) var(--w98-light) var(--w98-dark); }
.err { color: #b00; font-size: 12px; min-height: 16px; margin: 6px 0 0; }

/* ── App shell ─────────────────────────────────────────────────────────────── */
#app { position: fixed; inset: 0; z-index: 1; display: flex; flex-direction: column; background: var(--bg); }
.topbar {
  display: flex; align-items: center; gap: 12px; padding: 8px 12px;
  background: #0a0f0c; border-bottom: 1px solid #1f2a24;
  padding-top: max(8px, env(safe-area-inset-top));
}
.brand { color: var(--green); font-weight: 800; letter-spacing: 1px; font-family: monospace; }
.tabs { display: flex; gap: 4px; flex: 1; overflow-x: auto; }
.tab {
  background: transparent; color: #9fb3a8; border: none; padding: 6px 10px;
  border-radius: 6px; cursor: pointer; font-size: 14px; white-space: nowrap;
}
.tab.active { background: #16221b; color: var(--green); }
.badge {
  background: #ff3b30; color: #fff; border-radius: 10px; padding: 0 6px;
  font-size: 11px; margin-left: 4px;
}
.me { display: flex; align-items: center; gap: 8px; font-size: 13px; color: #9fb3a8; }
.iconbtn { background: none; border: none; font-size: 18px; cursor: pointer; }
.iconbtn.muted { opacity: 0.4; }

.inv-banner {
  background: #16221b; color: var(--green); border-bottom: 1px solid #1f2a24;
  padding: 8px 12px; font-size: 14px; font-weight: 600;
}

.view { flex: 1; display: none; flex-direction: column; min-height: 0; }
.view.active { display: flex; }

/* ── Chat ──────────────────────────────────────────────────────────────────── */
.presence { padding: 4px 12px; font-size: 12px; color: #7d9488; min-height: 20px; }
.messages { flex: 1; overflow-y: auto; padding: 8px 12px; display: flex; flex-direction: column; gap: 6px; }
.msg { max-width: 80%; padding: 6px 10px; border-radius: 10px; background: var(--other); align-self: flex-start; }
.msg.mine { background: var(--me); align-self: flex-end; }
.msg .author { font-size: 11px; color: var(--green); font-weight: 700; margin-bottom: 2px; }
.msg.mine .author { color: #b9f5cf; }
.msg .body { font-size: 14px; white-space: pre-wrap; word-break: break-word; }
.msg .body .mention { color: var(--green); font-weight: 700; }
.msg .time { font-size: 10px; color: #8aa; opacity: 0.7; text-align: right; margin-top: 2px; }
.msg img.photo { max-width: 100%; border-radius: 8px; margin-top: 4px; display: block; }
.reactions { display: flex; gap: 4px; margin-top: 4px; flex-wrap: wrap; }
.reactions .chip { background: #0008; border: 1px solid #2f3f37; border-radius: 10px; padding: 0 6px; font-size: 12px; cursor: pointer; }
.reactions .chip.on { border-color: var(--green); }
.msg .react-add { font-size: 12px; color: #7d9488; cursor: pointer; margin-top: 2px; display: inline-block; }
.new-divider { text-align: center; color: #ff6b6b; font-size: 11px; margin: 6px 0; border-top: 1px dashed #ff6b6b55; padding-top: 4px; }
.typing { min-height: 18px; padding: 0 12px 4px; font-size: 12px; color: #7d9488; font-style: italic; }

.composer { display: flex; gap: 8px; padding: 8px 12px; background: #0a0f0c; border-top: 1px solid #1f2a24; padding-bottom: max(8px, env(safe-area-inset-bottom)); }
.composer input { flex: 1; padding: 10px; border-radius: 20px; border: 1px solid #2f3f37; background: #11161330; color: var(--text); }
.composer .send { padding: 8px 16px; border-radius: 20px; border: none; background: var(--green); color: #042; font-weight: 700; cursor: pointer; }
.attach { display: flex; align-items: center; font-size: 20px; cursor: pointer; }

/* ── Lists (todo / inventory / roster) ─────────────────────────────────────── */
.list { flex: 1; overflow-y: auto; padding: 8px 12px; margin: 0; list-style: none; display: flex; flex-direction: column; gap: 8px; }
.list li, .inv-group { background: #131a16; border: 1px solid #1f2a24; border-radius: 8px; padding: 10px 12px; }
.todo-text { font-size: 14px; }
.todo.done .todo-text { text-decoration: line-through; color: #7d9488; }
.todo.claimed .todo-text { text-decoration: line-through; color: #cbb26b; }
.todo-meta { font-size: 11px; color: #7d9488; margin-top: 4px; }
.todo-actions { display: flex; gap: 6px; margin-top: 6px; flex-wrap: wrap; }
.minibtn { font-size: 12px; padding: 4px 10px; border-radius: 6px; border: 1px solid #2f3f37; background: #1b241e; color: var(--text); cursor: pointer; }
.minibtn.go { background: var(--green); color: #042; border: none; font-weight: 700; }
.minibtn.danger { color: #ff6b6b; }

.inv-group.active { border-color: var(--green); }
.inv-group .ig-head { display: flex; align-items: center; justify-content: space-between; }
.inv-group .ig-name { font-weight: 700; }
.inv-group .ig-status { font-size: 11px; padding: 2px 8px; border-radius: 10px; }
.ig-status.active { background: var(--green); color: #042; }
.ig-status.done { background: #2f3f37; color: #9fb3a8; }
.ig-status.pending { background: #1b241e; color: #9fb3a8; }
.ig-notes { margin-top: 6px; display: flex; flex-direction: column; gap: 4px; }
.ig-note { font-size: 12px; color: #cdd; }
.ig-note .who { color: var(--green); }
.ig-note-form { display: flex; gap: 6px; margin-top: 6px; }
.ig-note-form input { flex: 1; padding: 6px; border-radius: 6px; border: 1px solid #2f3f37; background: #0d120f; color: var(--text); }
.inv-admin { padding: 8px 12px; display: flex; flex-direction: column; gap: 8px; border-bottom: 1px solid #1f2a24; }
.advance { align-self: flex-start; }

</style>
</head>
<body>
  <canvas id="matrix"></canvas>

  <!-- ── LOGIN (Windows-98 dialog over Matrix rain) ─────────────────────────── -->
  <div id="login" class="login-wrap">
    <div class="win98">
      <div class="title-bar">
        <span class="title-bar-text">All Risk Uniforms — Secure Terminal</span>
        <span class="title-bar-controls"><button aria-label="Close"></button></span>
      </div>
      <div class="win98-body">
        <div id="step-pass">
          <p class="prompt">Enter passphrase to continue.</p>
          <input id="passphrase" type="password" autocomplete="off" placeholder="passphrase" />
          <div class="row-right"><button id="pass-btn" class="w98btn">OK</button></div>
          <p id="pass-err" class="err"></p>
        </div>
        <div id="step-phone" hidden>
          <p class="prompt">Access granted. Enter your phone number to identify this device.</p>
          <input id="phone" type="tel" inputmode="tel" placeholder="(530) 555-1234" />
          <div class="row-right"><button id="phone-btn" class="w98btn">Enter</button></div>
          <p id="phone-err" class="err"></p>
          <p class="prompt" style="margin-top:10px;font-size:11px;color:#333">Admin is 530-720-6113. Any other number joins as a member.</p>
        </div>
      </div>
    </div>
  </div>

  <!-- ── MAIN APP ────────────────────────────────────────────────────────────── -->
  <div id="app" hidden>
    <header class="topbar">
      <div class="brand">ARU&nbsp;Comms</div>
      <nav class="tabs">
        <button class="tab active" data-view="chat">Chat <span id="unread" class="badge" hidden>0</span></button>
        <button class="tab" data-view="todo">To-Do</button>
        <button class="tab" data-view="inventory">Inventory</button>
        <button class="tab" data-view="roster" id="roster-tab" hidden>Roster</button>
      </nav>
      <div class="me">
        <button id="mute-btn" class="iconbtn" title="Mute notifications">🔔</button>
        <span id="me-name"></span>
        <button id="logout-btn" class="iconbtn" title="Log out">⎋</button>
      </div>
    </header>

    <div id="demo-bar" style="background:#3a2a00;color:#ffd479;font-size:12px;padding:4px 12px;text-align:center">
      Demo build — data is saved on this device only. <a href="#" id="reset-demo" style="color:#ffd479;text-decoration:underline">reset</a>
    </div>
    <div id="inv-banner" class="inv-banner" hidden></div>

    <section id="view-chat" class="view active">
      <div id="presence" class="presence"></div>
      <div id="messages" class="messages"></div>
      <div id="typing" class="typing"></div>
      <form id="chat-form" class="composer">
        <label class="attach" title="Attach photo">📎<input id="file" type="file" accept="image/*" hidden /></label>
        <input id="chat-input" autocomplete="off" placeholder="Message the crew…" />
        <button class="send">Send</button>
      </form>
    </section>

    <section id="view-todo" class="view">
      <form id="todo-form" class="composer">
        <input id="todo-input" autocomplete="off" placeholder="Add a task…" />
        <button class="send">Add</button>
      </form>
      <ul id="todo-list" class="list"></ul>
    </section>

    <section id="view-inventory" class="view">
      <div id="inv-admin" class="inv-admin" hidden>
        <form id="inv-add-form" class="composer">
          <input id="inv-add-input" autocomplete="off" placeholder="Add inventory group…" />
          <button class="send">Add</button>
        </form>
        <button id="inv-advance" class="w98btn advance">Advance to next group ▶</button>
      </div>
      <div id="inv-list" class="list"></div>
    </section>

    <section id="view-roster" class="view">
      <form id="roster-form" class="composer">
        <input id="roster-name" autocomplete="off" placeholder="Name" />
        <input id="roster-phone" autocomplete="off" placeholder="Phone" />
        <button class="send">Add</button>
      </form>
      <ul id="roster-list" class="list"></ul>
    </section>
  </div>

  <script>
// Matrix digital rain for the login background. Pauses itself once the app
// is unlocked (the #matrix canvas gets hidden via CSS) to save battery.
(function () {
  const canvas = document.getElementById('matrix');
  const ctx = canvas.getContext('2d');
  const glyphs = '01ARUﾊﾐﾋｰｳｼﾅﾓﾆｻﾜｵﾘ0123456789@#$%'.split('');
  let cols, drops, fontSize;

  function resize() {
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
    fontSize = Math.max(12, Math.floor(window.innerWidth / 60));
    cols = Math.floor(canvas.width / fontSize);
    drops = new Array(cols).fill(0).map(() => Math.random() * -50);
  }
  resize();
  window.addEventListener('resize', resize);

  function draw() {
    if (canvas.classList.contains('hidden')) return; // stopped after login
    ctx.fillStyle = 'rgba(0,0,0,0.07)';
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    ctx.fillStyle = '#00ff5f';
    ctx.font = fontSize + 'px monospace';
    for (let i = 0; i < drops.length; i++) {
      const ch = glyphs[(Math.random() * glyphs.length) | 0];
      ctx.fillText(ch, i * fontSize, drops[i] * fontSize);
      if (drops[i] * fontSize > canvas.height && Math.random() > 0.975) drops[i] = 0;
      drops[i]++;
    }
  }
  setInterval(draw, 50);
})();

</script>
  <script>
// ARU Comms — static demo build. No server: all data lives in this browser
// (localStorage), and tabs on the same device sync live via BroadcastChannel.
// The Matrix/Win98 UI and every feature are the real thing; only the shared
// backend is swapped out for on-device storage.
const $ = (s) => document.querySelector(s);
const $ = (s) => document.querySelectorAll(s);
const PASSPHRASE = 'all risk uniforms';
const ADMIN_PHONE = '5307206113';
const KEY = 'aru_demo_v1';
const ME_KEY = 'aru_demo_me';
const bc = ('BroadcastChannel' in window) ? new BroadcastChannel('aru_demo') : null;

const normPhone = (s) => String(s || '').replace(/\D/g, '');
const now = () => new Date().toISOString();
const escapeHtml = (s) => String(s).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

// ── Store ────────────────────────────────────────────────────────────────────
function seed() {
  return {
    seq: 100,
    members: [{ id: 1, phone: ADMIN_PHONE, name: 'Admin', role: 'admin', muted: false }],
    messages: [],
    reactions: {},          // messageId -> { emoji: [memberId,...] }
    todos: [],
    invGroups: [
      { id: 1, name: 'Boot supplies', position: 0, status: 'active' },
      { id: 2, name: 'Nomex', position: 1, status: 'pending' },
      { id: 3, name: 'Cotton shirts', position: 2, status: 'pending' },
      { id: 4, name: 'Short sleeves', position: 3, status: 'pending' },
    ],
    invNotes: [],
  };
}
function load() {
  try { return JSON.parse(localStorage.getItem(KEY)) || seed(); } catch { return seed(); }
}
let db = load();
let me = null;
let newestId = 0, lastReadId = 0, firstUnreadId = null;

function save(broadcast = true) {
  localStorage.setItem(KEY, JSON.stringify(db));
  if (broadcast && bc) bc.postMessage('changed');
}
function reload() { db = load(); }
if (bc) bc.onmessage = () => { reload(); renderAll(); };
window.addEventListener('storage', (e) => { if (e.key === KEY) { reload(); renderAll(); } });

const nextId = () => ++db.seq;
const memberById = (id) => db.members.find((m) => m.id === id);

// ── Login ────────────────────────────────────────────────────────────────────
$('#pass-btn').onclick = () => {
  if ($('#passphrase').value.trim().toLowerCase() === PASSPHRASE) {
    $('#step-pass').hidden = true; $('#step-phone').hidden = false; $('#phone').focus();
  } else { $('#pass-err').textContent = 'Access denied.'; }
};
$('#passphrase').addEventListener('keydown', (e) => { if (e.key === 'Enter') $('#pass-btn').click(); });

$('#phone-btn').onclick = () => {
  const phone = normPhone($('#phone').value);
  if (phone.length < 7) { $('#phone-err').textContent = 'Enter a valid phone number.'; return; }
  reload();
  let m = db.members.find((x) => x.phone === phone);
  if (!m) {
    // Demo: any new number self-joins as a member (in the real app the admin adds you first).
    m = { id: nextId(), phone, name: 'Member ' + phone.slice(-4), role: phone === ADMIN_PHONE ? 'admin' : 'member', muted: false };
    db.members.push(m); save();
  }
  localStorage.setItem(ME_KEY, String(m.id));
  me = m; enterApp();
};
$('#phone').addEventListener('keydown', (e) => { if (e.key === 'Enter') $('#phone-btn').click(); });

$('#logout-btn').onclick = () => { localStorage.removeItem(ME_KEY); location.reload(); };
$('#reset-demo').onclick = (e) => {
  e.preventDefault();
  if (confirm('Reset all demo data on this device?')) { localStorage.removeItem(KEY); localStorage.removeItem(ME_KEY); location.reload(); }
};

function boot() {
  const id = Number(localStorage.getItem(ME_KEY));
  if (id) { const m = memberById(id); if (m) { me = m; enterApp(); return; } }
}
function enterApp() {
  $('#login').hidden = true; $('#app').hidden = false;
  $('#matrix').classList.add('hidden');
  $('#me-name').textContent = me.name;
  if (me.role === 'admin') { $('#roster-tab').hidden = false; $('#inv-admin').hidden = false; }
  $('#mute-btn').classList.toggle('muted', me.muted);
  renderAll();
  const ms = db.messages;
  lastReadId = (db.reads && db.reads[me.id]) || 0;
  newestId = ms.length ? ms[ms.length - 1].id : 0;
  markRead();
}

// ── Tabs ─────────────────────────────────────────────────────────────────────
$('.tab').forEach((t) => t.onclick = () => {
  $('.tab').forEach((x) => x.classList.remove('active'));
  $('.view').forEach((x) => x.classList.remove('active'));
  t.classList.add('active');
  $('#view-' + t.dataset.view).classList.add('active');
  if (t.dataset.view === 'chat') markRead();
  renderAll();
});

function renderAll() {
  if (!me) return;
  me = memberById(me.id) || me;
  renderMessages();
  renderTodos();
  renderInventory();
  renderRoster();
  $('#me-name').textContent = me.name;
}

// ── Chat ─────────────────────────────────────────────────────────────────────
const messagesEl = $('#messages');
function renderBody(text) { return escapeHtml(text).replace(/@([\w]+)/g, '<span class="mention">@$1</span>'); }

function renderMessages() {
  newestId = db.messages.length ? db.messages[db.messages.length - 1].id : 0;
  firstUnreadId = null;
  for (const msg of db.messages) {
    if (firstUnreadId === null && msg.id > lastReadId && msg.memberId !== me.id) firstUnreadId = msg.id;
  }
  const atBottom = messagesEl.scrollHeight - messagesEl.scrollTop - messagesEl.clientHeight < 120;
  messagesEl.innerHTML = '';
  for (const msg of db.messages) {
    if (firstUnreadId === msg.id) {
      const div = document.createElement('div');
      div.className = 'new-divider'; div.textContent = '— new messages —';
      messagesEl.appendChild(div);
    }
    const author = memberById(msg.memberId);
    const el = document.createElement('div');
    el.className = 'msg' + (msg.memberId === me.id ? ' mine' : '');
    const time = new Date(msg.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    const reacts = db.reactions[msg.id] || {};
    const chips = Object.entries(reacts).filter(([, ids]) => ids.length).map(([emoji, ids]) =>
      `<span class="chip ${ids.includes(me.id) ? 'on' : ''}" data-emoji="${emoji}">${emoji} ${ids.length}</span>`).join('');
    el.innerHTML = `
      ${msg.memberId !== me.id ? `<div class="author">${escapeHtml(author ? author.name : '—')}${author && author.role === 'admin' ? ' ★' : ''}</div>` : ''}
      ${msg.body ? `<div class="body">${renderBody(msg.body)}</div>` : ''}
      ${msg.attachment ? `<img class="photo" src="${msg.attachment}" />` : ''}
      <div class="reactions">${chips}<span class="react-add" title="React">＋</span></div>
      <div class="time">${time}</div>`;
    el.querySelectorAll('.chip').forEach((c) => c.onclick = () => react(msg.id, c.dataset.emoji));
    el.querySelector('.react-add').onclick = () => { const e = prompt('React with (emoji):', '👍'); if (e) react(msg.id, e.trim()); };
    messagesEl.appendChild(el);
  }
  if (atBottom) messagesEl.scrollTop = messagesEl.scrollHeight;
  updateUnreadBadge();
}

function postMessage(body, attachment) {
  reload();
  db.messages.push({ id: nextId(), memberId: me.id, body: body || '', attachment: attachment || null, createdAt: now() });
  save();
  renderMessages(); markRead();
}
function react(id, emoji) {
  reload();
  const r = db.reactions[id] || (db.reactions[id] = {});
  const arr = r[emoji] || (r[emoji] = []);
  const i = arr.indexOf(me.id);
  if (i >= 0) arr.splice(i, 1); else arr.push(me.id);
  save(); renderMessages();
}
$('#chat-form').onsubmit = (e) => { e.preventDefault(); const v = $('#chat-input').value.trim(); if (!v) return; $('#chat-input').value = ''; postMessage(v, null); };
$('#file').onchange = (e) => {
  const file = e.target.files[0]; if (!file) return;
  const reader = new FileReader();
  reader.onload = () => { postMessage($('#chat-input').value.trim(), reader.result); $('#chat-input').value = ''; };
  reader.readAsDataURL(file);
  e.target.value = '';
};

function updateUnreadBadge() {
  const unread = Math.max(0, newestId - lastReadId);
  const onChat = $('#view-chat').classList.contains('active');
  const badge = $('#unread');
  if (unread > 0 && !onChat) { badge.hidden = false; badge.textContent = unread; } else badge.hidden = true;
}
function markRead() {
  if (newestId > lastReadId) {
    lastReadId = newestId;
    reload(); db.reads = db.reads || {}; db.reads[me.id] = lastReadId; save(false);
  }
  updateUnreadBadge();
}

// ── Mute ─────────────────────────────────────────────────────────────────────
$('#mute-btn').onclick = () => {
  reload(); const m = memberById(me.id); m.muted = !m.muted; me.muted = m.muted; save();
  $('#mute-btn').classList.toggle('muted', m.muted);
};

// ── To-Do ────────────────────────────────────────────────────────────────────
function renderTodos() {
  const list = $('#todo-list'); if (!list) return;
  const sorted = [...db.todos].sort((a, b) => (a.status === 'done') - (b.status === 'done') || b.id - a.id);
  list.innerHTML = '';
  for (const t of sorted) {
    const li = document.createElement('li');
    li.className = 'todo ' + t.status;
    let actions = '';
    if (t.status === 'open') actions += `<button class="minibtn go" data-act="claim">I did this</button>`;
    if (t.status === 'claimed' && me.role === 'admin') {
      actions += `<button class="minibtn go" data-act="approve">Validate ✓</button><button class="minibtn" data-act="reject">Reject</button>`;
    }
    if (me.role === 'admin') actions += `<button class="minibtn danger" data-act="delete">Delete</button>`;
    const nm = (id) => { const m = memberById(id); return m ? m.name : '—'; };
    let meta = `Added by ${nm(t.createdBy)}`;
    if (t.status === 'claimed') meta = `${nm(t.claimedBy)} did this · awaiting admin validation`;
    if (t.status === 'done') meta = `Done by ${nm(t.claimedBy)} · validated by ${nm(t.validatedBy)}`;
    li.innerHTML = `<div class="todo-text">${escapeHtml(t.text)}</div><div class="todo-meta">${escapeHtml(meta)}</div><div class="todo-actions">${actions}</div>`;
    li.querySelectorAll('button').forEach((b) => b.onclick = () => todoAction(t.id, b.dataset.act));
    list.appendChild(li);
  }
}
function todoAction(id, act) {
  reload(); const t = db.todos.find((x) => x.id === id); if (!t) return;
  if (act === 'claim') { t.status = 'claimed'; t.claimedBy = me.id; t.claimedAt = now(); }
  else if (act === 'approve') { t.status = 'done'; t.validatedBy = me.id; }
  else if (act === 'reject') { t.status = 'open'; t.claimedBy = null; }
  else if (act === 'delete') { db.todos = db.todos.filter((x) => x.id !== id); }
  save(); renderTodos();
}
$('#todo-form').onsubmit = (e) => {
  e.preventDefault(); const v = $('#todo-input').value.trim(); if (!v) return;
  reload(); db.todos.push({ id: nextId(), text: v, status: 'open', createdBy: me.id, createdAt: now() }); save();
  $('#todo-input').value = ''; renderTodos();
};

// ── Inventory ────────────────────────────────────────────────────────────────
function renderInventory() {
  const active = db.invGroups.find((g) => g.status === 'active');
  const banner = $('#inv-banner');
  banner.hidden = false;
  banner.textContent = active ? `📦 Current inventory group: ${active.name}` : '📦 Inventory complete';
  const list = $('#inv-list'); list.innerHTML = '';
  const groups = [...db.invGroups].sort((a, b) => a.position - b.position);
  for (const g of groups) {
    const notes = db.invNotes.filter((n) => n.groupId === g.id);
    const div = document.createElement('div');
    div.className = 'inv-group ' + g.status;
    div.innerHTML = `
      <div class="ig-head"><span class="ig-name">${escapeHtml(g.name)}</span><span class="ig-status ${g.status}">${g.status}</span></div>
      <div class="ig-notes">${notes.map((n) => { const m = memberById(n.memberId); return `<div class="ig-note"><span class="who">${escapeHtml(m ? m.name : '—')}:</span> ${escapeHtml(n.text)}</div>`; }).join('')}</div>
      <form class="ig-note-form"><input placeholder="Add a note…" /><button class="minibtn">Note</button></form>
      ${me.role === 'admin' ? `<button class="minibtn danger ig-del">Delete group</button>` : ''}`;
    div.querySelector('.ig-note-form').onsubmit = (e) => {
      e.preventDefault(); const inp = e.target.querySelector('input'); const v = inp.value.trim(); if (!v) return;
      reload(); db.invNotes.push({ id: nextId(), groupId: g.id, memberId: me.id, text: v, createdAt: now() }); save(); inp.value = ''; renderInventory();
    };
    const del = div.querySelector('.ig-del');
    if (del) del.onclick = () => { if (confirm('Delete this group?')) { reload(); db.invGroups = db.invGroups.filter((x) => x.id !== g.id); save(); renderInventory(); } };
    list.appendChild(div);
  }
}
$('#inv-advance').onclick = () => {
  if (!confirm('Advance to the next inventory group?')) return;
  reload();
  const groups = [...db.invGroups].sort((a, b) => a.position - b.position);
  const active = groups.find((g) => g.status === 'active');
  if (active) active.status = 'done';
  const next = groups.find((g) => g.status === 'pending');
  if (next) next.status = 'active';
  save(); renderInventory();
};
$('#inv-add-form').onsubmit = (e) => {
  e.preventDefault(); const v = $('#inv-add-input').value.trim(); if (!v) return;
  reload();
  const max = db.invGroups.reduce((m, g) => Math.max(m, g.position), -1);
  const anyActive = db.invGroups.some((g) => g.status === 'active');
  db.invGroups.push({ id: nextId(), name: v, position: max + 1, status: anyActive ? 'pending' : 'active' });
  save(); $('#inv-add-input').value = ''; renderInventory();
};

// ── Roster (admin) ───────────────────────────────────────────────────────────
function renderRoster() {
  const list = $('#roster-list'); if (!list) return;
  list.innerHTML = '';
  for (const m of db.members) {
    const li = document.createElement('li');
    li.innerHTML = `<div><b>${escapeHtml(m.name)}</b>${m.role === 'admin' ? ' ★ (admin)' : ''}<div class="todo-meta">${escapeHtml(m.phone)}</div></div>`;
    if (m.role !== 'admin' && me.role === 'admin') {
      const btn = document.createElement('button');
      btn.className = 'minibtn danger'; btn.textContent = 'Remove'; btn.style.marginTop = '6px';
      btn.onclick = () => { if (confirm(`Remove ${m.name}?`)) { reload(); db.members = db.members.filter((x) => x.id !== m.id); save(); renderRoster(); } };
      li.appendChild(btn);
    }
    list.appendChild(li);
  }
}
$('#roster-form').onsubmit = (e) => {
  e.preventDefault();
  const name = $('#roster-name').value.trim(); const phone = normPhone($('#roster-phone').value);
  if (!name || phone.length < 7) return;
  reload();
  if (!db.members.some((m) => m.phone === phone)) db.members.push({ id: nextId(), phone, name, role: 'member', muted: false });
  save(); $('#roster-name').value = ''; $('#roster-phone').value = ''; renderRoster();
};

// Presence in the demo is just "you" (no shared server).
$('#presence').textContent = '🟢 Demo mode — you’re signed in on this device';

boot();

</script>
</body>
</html>
