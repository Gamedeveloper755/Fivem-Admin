'use strict';

// ============================================================
// STATE
// ============================================================
let playersList  = [];
let banList      = {};
let whitelistData= {};
let adminList    = [];
let selectedPlayer = null;
let currentAction  = null;
let adminRank      = 0;
let panelOpen      = false;

// ============================================================
// NUI MESSAGE HANDLER
// ============================================================
window.addEventListener('message', (event) => {
  const msg = event.data;
  if (!msg || !msg.action) return;

  switch (msg.action) {
    case 'open':
      adminRank = msg.rank || 0;
      showPanel();
      break;
    case 'close':
      hidePanel();
      break;
    case 'playersList':
      playersList = msg.data || [];
      renderPlayers();
      break;
    case 'banList':
      banList = msg.data || {};
      renderBans();
      break;
    case 'whitelist':
      whitelistData = msg.data || {};
      renderWhitelist();
      break;
    case 'adminList':
      adminList = msg.data || [];
      renderStaff();
      break;
    case 'playerMoney':
      showMoneyResult(msg.data);
      break;
    case 'notify':
      showToast(msg.message, msg.type);
      break;
  }
});

// ============================================================
// PANEL OPEN / CLOSE
// ============================================================
function showPanel() {
  panelOpen = true;
  document.getElementById('overlay').classList.remove('hidden');
  switchTab('players');
  refreshPlayers();
}

function hidePanel() {
  panelOpen = false;
  document.getElementById('overlay').classList.add('hidden');
  closeModal();
}

function closePanel() {
  fetch('https://fivem-admin/closeMenu', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({})
  });
  hidePanel();
}

// ============================================================
// TABS
// ============================================================
document.querySelectorAll('.tab').forEach(tab => {
  tab.addEventListener('click', () => switchTab(tab.dataset.tab));
});

function switchTab(name) {
  document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
  document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
  document.querySelector(`.tab[data-tab="${name}"]`)?.classList.add('active');
  document.getElementById(`tab-${name}`)?.classList.add('active');
}

// ============================================================
// PLAYERS
// ============================================================
function refreshPlayers() {
  fetch('https://fivem-admin/refreshPlayers', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({})
  });
}

function renderPlayers() {
  const container = document.getElementById('players-list');
  const query = document.getElementById('search-players').value.toLowerCase();

  const filtered = playersList.filter(p =>
    p.name.toLowerCase().includes(query) ||
    String(p.id).includes(query)
  );

  if (filtered.length === 0) {
    container.innerHTML = '<div class="muted" style="text-align:center;padding:20px;">Nessun player trovato.</div>';
    return;
  }

  container.innerHTML = filtered.map(p => {
    const pingClass = p.ping < 80 ? 'ping-good' : p.ping < 180 ? 'ping-mid' : 'ping-bad';
    const rankColor = getRankColor(p.rank);
    const rankName  = p.rankName || 'Giocatore';
    const rankHtml  = p.rank > 0
      ? `<span class="player-rank" style="color:${rankColor};border-color:${rankColor}">${rankName}</span>`
      : '';
    return `
      <div class="player-row" onclick="openPlayerModal(${p.id})">
        <span class="player-id">[${p.id}]</span>
        <span class="player-name">${escHtml(p.name)}</span>
        ${rankHtml}
        <span class="player-ping ${pingClass}">${p.ping}ms</span>
      </div>
    `;
  }).join('');
}

function filterPlayers() { renderPlayers(); }

function getRankColor(rank) {
  const colors = { 1: '#3B82F6', 2: '#10B981', 3: '#F59E0B', 4: '#EF4444' };
  return colors[rank] || '#6b7698';
}

// ============================================================
// PLAYER MODAL
// ============================================================
function openPlayerModal(id) {
  selectedPlayer = playersList.find(p => p.id === id);
  if (!selectedPlayer) return;

  document.getElementById('modal-player-name').textContent = selectedPlayer.name;
  document.getElementById('modal-player-info').textContent =
    `ID: ${selectedPlayer.id}  |  Ping: ${selectedPlayer.ping}ms  |  Rank: ${selectedPlayer.rankName || 'Giocatore'}`;

  resetActionForm();
  document.getElementById('action-modal').classList.remove('hidden');
}

function closeModal() {
  selectedPlayer = null;
  currentAction  = null;
  document.getElementById('action-modal').classList.add('hidden');
  resetActionForm();
}

function resetActionForm() {
  document.getElementById('action-form').classList.add('hidden');
  document.getElementById('action-reason').value   = '';
  document.getElementById('action-duration').value = '';
  document.getElementById('action-amount').value   = '';
  currentAction = null;
}

function doAction(action) {
  currentAction = action;
  const form     = document.getElementById('action-form');
  const reason   = document.getElementById('action-reason');
  const duration = document.getElementById('action-duration');
  const amount   = document.getElementById('action-amount');
  const rankSel  = document.getElementById('action-rank');

  reason.style.display   = 'block';
  duration.style.display = 'none';
  amount.style.display   = 'none';
  rankSel.style.display  = 'none';

  if (action === 'ban') {
    reason.placeholder   = 'Motivo del ban...';
    duration.style.display = 'block';
    duration.placeholder = 'Durata (7d, 24h, 30m, perm)';
  } else if (action === 'kick') {
    reason.placeholder = 'Motivo del kick...';
  } else if (action === 'warn') {
    reason.placeholder = 'Motivo del warn...';
  } else if (action === 'freeze') {
    sendAction();
    return;
  } else if (action === 'bring' || action === 'goto' || action === 'revive' || action === 'spectate') {
    sendAction();
    return;
  } else if (action === 'money') {
    reason.style.display = 'none';
    amount.style.display = 'block';
    amount.placeholder   = 'Importo da aggiungere...';
  } else if (action === 'setrank') {
    reason.style.display  = 'none';
    rankSel.style.display = 'block';
  }

  form.classList.remove('hidden');
}

function confirmAction() {
  if (!selectedPlayer || !currentAction) return;

  const id       = selectedPlayer.id;
  const reason   = document.getElementById('action-reason').value   || 'Nessun motivo';
  const duration = document.getElementById('action-duration').value || 'perm';
  const amount   = document.getElementById('action-amount').value;
  const rank     = document.getElementById('action-rank').value;

  sendAction(id, reason, duration, amount, rank);
  closeModal();
}

function sendAction(id, reason, duration, amount, rank) {
  const target = id || (selectedPlayer && selectedPlayer.id);
  if (!target) return;

  const endpoints = {
    ban:      { ep: 'banPlayer',    data: { targetId: target, reason, duration } },
    kick:     { ep: 'kickPlayer',   data: { targetId: target, reason } },
    warn:     { ep: 'warnPlayer',   data: { targetId: target, reason } },
    freeze:   { ep: 'freezePlayer', data: { targetId: target, state: true } },
    bring:    { ep: 'bringPlayer',  data: { targetId: target } },
    goto:     { ep: 'gotoPlayer',   data: { targetId: target } },
    revive:   { ep: 'revivePlayer', data: { targetId: target } },
    money:    { ep: 'giveMoney',    data: { targetId: target, amount: parseInt(amount), accountType: 'cash' } },
    setrank:  { ep: 'setRank',      data: { targetId: target, rank: parseInt(rank) } },
    spectate: { ep: 'spectatePlayer', data: { targetId: target } },
  };

  const cfg = endpoints[currentAction];
  if (!cfg) return;

  fetch(`https://fivem-admin/${cfg.ep}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(cfg.data)
  });

  showToast(`Azione "${currentAction}" eseguita su ${selectedPlayer?.name || target}`, 'success');
}

// ============================================================
// BAN LIST
// ============================================================
function requestBanList() {
  fetch('https://fivem-admin/getBanList', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({})
  });
}

function renderBans() {
  const container = document.getElementById('ban-list');
  const query = (document.getElementById('search-bans')?.value || '').toLowerCase();
  const entries = Object.entries(banList);

  const filtered = entries.filter(([id, ban]) =>
    (ban.name || id).toLowerCase().includes(query) ||
    (ban.reason || '').toLowerCase().includes(query)
  );

  if (filtered.length === 0) {
    container.innerHTML = '<div class="muted" style="text-align:center;padding:20px;">Nessun ban trovato.</div>';
    return;
  }

  container.innerHTML = filtered.map(([id, ban]) => `
    <div class="ban-row">
      <div class="ban-info">
        <div class="ban-name">${escHtml(ban.name || id)}</div>
        <div class="ban-reason">${escHtml(ban.reason || 'Nessun motivo')} &mdash; bannato da ${escHtml(ban.bannedBy || 'Sistema')}</div>
        <div class="ban-expiry">${ban.expiry === 0 ? 'PERMANENTE' : formatExpiry(ban.expiry)}</div>
      </div>
      <button class="ban-remove" onclick="unbanPlayer('${id}')">Rimuovi</button>
    </div>
  `).join('');
}

function filterBans() { renderBans(); }

function unbanPlayer(identifier) {
  fetch('https://fivem-admin/unbanPlayer', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ identifier })
  });
  delete banList[identifier];
  renderBans();
  showToast('Ban rimosso.', 'success');
}

function formatExpiry(ts) {
  if (!ts || ts === 0) return 'Permanente';
  const diff = ts - Math.floor(Date.now() / 1000);
  if (diff <= 0) return 'Scaduto';
  const d = Math.floor(diff / 86400);
  const h = Math.floor((diff % 86400) / 3600);
  const m = Math.floor((diff % 3600) / 60);
  if (d > 0) return `${d}g ${h}h`;
  if (h > 0) return `${h}h ${m}m`;
  return `${m} minuti`;
}

// ============================================================
// ECONOMY
// ============================================================
function giveMoney() {
  const target  = document.getElementById('econ-target').value;
  const amount  = parseInt(document.getElementById('econ-amount').value);
  const account = document.getElementById('econ-account').value;
  if (!target || !amount) { showToast('Compila tutti i campi!', 'error'); return; }
  fetch('https://fivem-admin/giveMoney', {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ targetId: target, amount, accountType: account })
  });
  showToast(`Dati $${amount} [${account}] a player ${target}`, 'success');
}

function setMoney() {
  const target  = document.getElementById('econ-target').value;
  const amount  = parseInt(document.getElementById('econ-amount').value);
  const account = document.getElementById('econ-account').value;
  if (!target || amount === undefined) { showToast('Compila tutti i campi!', 'error'); return; }
  fetch('https://fivem-admin/setMoney', {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ targetId: target, amount, accountType: account })
  });
  showToast(`Soldi di player ${target} impostati a $${amount} [${account}]`, 'info');
}

function getMoney() {
  const target = document.getElementById('econ-target').value;
  if (!target) { showToast('Inserisci un ID/nome!', 'error'); return; }
  fetch('https://fivem-admin/getMoney', {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ targetId: target })
  });
}

function showMoneyResult(data) {
  const box = document.getElementById('econ-result');
  box.classList.remove('hidden');
  box.innerHTML = `
    <strong>${escHtml(data.name)}</strong> [ID: ${data.target}]<br>
    Cash: <span style="color:#10b981">$${data.cash?.toLocaleString() || 0}</span> &nbsp;|&nbsp;
    Banca: <span style="color:#2196f3">$${data.bank?.toLocaleString() || 0}</span>
  `;
}

// ============================================================
// WHITELIST
// ============================================================
function whitelistAdd() {
  const id   = document.getElementById('white-id').value.trim();
  const name = document.getElementById('white-name').value.trim();
  if (!id) { showToast('Inserisci un identifier!', 'error'); return; }
  fetch('https://fivem-admin/whitelistAdd', {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ identifier: id, name })
  });
  showToast(`Aggiunto in whitelist: ${id}`, 'success');
}

function whitelistRemove() {
  const id = document.getElementById('white-id').value.trim();
  if (!id) { showToast('Inserisci un identifier!', 'error'); return; }
  fetch('https://fivem-admin/whitelistRemove', {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ identifier: id })
  });
  showToast(`Rimosso dalla whitelist: ${id}`, 'success');
}

function requestWhitelist() {
  fetch('https://fivem-admin/getWhitelist', {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({})
  });
}

function renderWhitelist() {
  const container = document.getElementById('whitelist-result');
  const entries   = Object.entries(whitelistData);
  if (entries.length === 0) {
    container.textContent = 'Whitelist vuota.';
    return;
  }
  container.innerHTML = entries.map(([id, entry]) => `
    <div class="ban-row">
      <div class="ban-info">
        <div class="ban-name">${escHtml(entry.name || id)}</div>
        <div class="ban-reason">${escHtml(id)}</div>
        <div class="ban-expiry">Aggiunto da ${escHtml(entry.addedBy || 'Sistema')}</div>
      </div>
      <button class="ban-remove" onclick="quickWhiteRemove('${id}')">Rimuovi</button>
    </div>
  `).join('');
}

function quickWhiteRemove(id) {
  fetch('https://fivem-admin/whitelistRemove', {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ identifier: id })
  });
  delete whitelistData[id];
  renderWhitelist();
  showToast('Rimosso dalla whitelist.', 'success');
}

// ============================================================
// STAFF LIST
// ============================================================
function requestAdminList() {
  fetch('https://fivem-admin/getAdminList', {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({})
  });
}

function renderStaff() {
  const container = document.getElementById('staff-list');
  if (adminList.length === 0) {
    container.innerHTML = '<div class="muted" style="text-align:center;padding:20px;">Nessuno staff online.</div>';
    return;
  }
  container.innerHTML = adminList.map(a => `
    <div class="staff-row">
      <div class="staff-dot"></div>
      <span class="staff-name">${escHtml(a.name)}</span>
      <span class="staff-rank-badge" style="color:${a.color};border-color:${a.color}">
        ${escHtml(a.rankName)}
      </span>
      <span class="muted">[${a.source}]</span>
    </div>
  `).join('');
}

// ============================================================
// TOAST NOTIFICATIONS
// ============================================================
let toastTimeout = null;
function showToast(msg, type = 'info') {
  const toast = document.getElementById('toast');
  toast.textContent = msg;
  toast.className = `toast toast-${type}`;
  toast.classList.remove('hidden');
  if (toastTimeout) clearTimeout(toastTimeout);
  toastTimeout = setTimeout(() => toast.classList.add('hidden'), 3500);
}

// ============================================================
// UTILITIES
// ============================================================
function escHtml(str) {
  if (!str) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

// Aggiorna lista admins ogni 30s mentre il menu è aperto
setInterval(() => {
  if (panelOpen) requestAdminList();
}, 30000);
