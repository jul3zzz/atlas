const { EmbedBuilder } = require('discord.js');
const config = require('../config.json');

function success(title, description) {
  return new EmbedBuilder()
    .setColor(config.colorSuccess)
    .setTitle(`✅ ${title}`)
    .setDescription(description)
    .setTimestamp();
}

function error(title, description) {
  return new EmbedBuilder()
    .setColor(config.colorError)
    .setTitle(`❌ ${title}`)
    .setDescription(description)
    .setTimestamp();
}

function info(title, description) {
  return new EmbedBuilder()
    .setColor(config.color)
    .setTitle(title)
    .setDescription(description)
    .setTimestamp()
    .setFooter({ text: config.botName });
}

function warn(title, description) {
  return new EmbedBuilder()
    .setColor(config.colorWarn)
    .setTitle(`⚠️ ${title}`)
    .setDescription(description)
    .setTimestamp();
}

module.exports = { success, error, info, warn };
