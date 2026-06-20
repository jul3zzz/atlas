const fs = require('fs');
const path = require('path');

const DB_PATH = path.join(__dirname, '..', 'data');
const FILES = {
  economy: path.join(DB_PATH, 'economy.json'),
  levels: path.join(DB_PATH, 'levels.json'),
  warns: path.join(DB_PATH, 'warns.json'),
  welcome: path.join(DB_PATH, 'welcome.json'),
  levelconfig: path.join(DB_PATH, 'levelconfig.json'),
  shop: path.join(DB_PATH, 'shop.json'),
  settings: path.join(DB_PATH, 'settings.json'),
};

if (!fs.existsSync(DB_PATH)) fs.mkdirSync(DB_PATH, { recursive: true });

function load(file) {
  if (!fs.existsSync(file)) fs.writeFileSync(file, '{}');
  try {
    return JSON.parse(fs.readFileSync(file, 'utf8'));
  } catch {
    return {};
  }
}

function save(file, data) {
  fs.writeFileSync(file, JSON.stringify(data, null, 2));
}

// ─── ÉCONOMIE ─────────────────────────────────────────────────────────────────

function getEconomy(userId) {
  const db = load(FILES.economy);
  if (!db[userId]) db[userId] = { coins: 0, bank: 0, lastWork: 0, lastDaily: 0 };
  return db[userId];
}

function saveEconomy(userId, data) {
  const db = load(FILES.economy);
  db[userId] = data;
  save(FILES.economy, db);
}

// ─── LEVELING ──────────────────────────────────────────────────────────────────

function getLevel(userId, guildId) {
  const db = load(FILES.levels);
  const key = `${guildId}-${userId}`;
  if (!db[key]) db[key] = { xp: 0, level: 0, lastXp: 0 };
  return db[key];
}

function saveLevel(userId, guildId, data) {
  const db = load(FILES.levels);
  const key = `${guildId}-${userId}`;
  db[key] = data;
  save(FILES.levels, db);
}

function getLeaderboard(guildId) {
  const db = load(FILES.levels);
  return Object.entries(db)
    .filter(([key]) => key.startsWith(guildId))
    .map(([key, val]) => ({ userId: key.replace(`${guildId}-`, ''), ...val }))
    .sort((a, b) => b.xp - a.xp)
    .slice(0, 10);
}

function xpForLevel(level) {
  return 5 * level * level + 50 * level + 100;
}

// ─── AVERTISSEMENTS ────────────────────────────────────────────────────────────

function getWarns(userId, guildId) {
  const db = load(FILES.warns);
  const key = `${guildId}-${userId}`;
  if (!db[key]) db[key] = [];
  return db[key];
}

function addWarn(userId, guildId, reason, moderator) {
  const db = load(FILES.warns);
  const key = `${guildId}-${userId}`;
  if (!db[key]) db[key] = [];
  const warn = { reason, moderator, date: Date.now(), id: Date.now().toString(36) };
  db[key].push(warn);
  save(FILES.warns, db);
  return warn;
}

function removeWarn(userId, guildId, warnId) {
  const db = load(FILES.warns);
  const key = `${guildId}-${userId}`;
  if (!db[key]) return false;
  const before = db[key].length;
  db[key] = db[key].filter(w => w.id !== warnId);
  save(FILES.warns, db);
  return db[key].length < before;
}

// ─── WELCOME ──────────────────────────────────────────────────────────────────

function getWelcome(guildId) {
  const db = load(FILES.welcome);
  return db[guildId] || null;
}

function setWelcome(guildId, data) {
  const db = load(FILES.welcome);
  db[guildId] = data;
  save(FILES.welcome, db);
}

// ─── BOUTIQUE ─────────────────────────────────────────────────────────────────

function getShop(guildId) {
  const db = load(FILES.shop);
  if (!db[guildId]) db[guildId] = [];
  return db[guildId];
}

function saveShop(guildId, items) {
  const db = load(FILES.shop);
  db[guildId] = items;
  save(FILES.shop, db);
}

// ─── PARAMÈTRES SERVEUR ───────────────────────────────────────────────────────

function getSettings(guildId) {
  const db = load(FILES.settings);
  if (!db[guildId]) db[guildId] = { economyEnabled: true, levelingEnabled: true };
  return db[guildId];
}

function saveSettings(guildId, data) {
  const db = load(FILES.settings);
  db[guildId] = data;
  save(FILES.settings, db);
}

// ─── CONFIG LEVELING ──────────────────────────────────────────────────────────

function getLevelConfig(guildId) {
  const db = load(FILES.levelconfig);
  return db[guildId] || { channelId: null, rewards: {} };
}

function setLevelConfig(guildId, data) {
  const db = load(FILES.levelconfig);
  db[guildId] = data;
  save(FILES.levelconfig, db);
}

module.exports = {
  getEconomy, saveEconomy,
  getLevel, saveLevel, getLeaderboard, xpForLevel,
  getWarns, addWarn, removeWarn,
  getWelcome, setWelcome,
  getLevelConfig, setLevelConfig,
  getShop, saveShop,
  getSettings, saveSettings,
};
