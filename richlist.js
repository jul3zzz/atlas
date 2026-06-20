const { EmbedBuilder } = require('discord.js');
const fs = require('fs');
const path = require('path');

module.exports = {
  name: 'richlist',
  aliases: ['topcoins', 'rich'],
  description: 'Classement des plus riches du serveur',
  usage: '*richlist',
  category: 'Économie',
  async execute(message, args, client) {
    const file = path.join(__dirname, '../../data/economy.json');
    if (!fs.existsSync(file)) return message.reply('Aucune donnée économique pour l\'instant.');

    const db = JSON.parse(fs.readFileSync(file, 'utf8'));
    const sorted = Object.entries(db)
      .map(([id, d]) => ({ id, total: d.coins + d.bank }))
      .sort((a, b) => b.total - a.total)
      .slice(0, 10);

    const medals = ['🥇', '🥈', '🥉'];
    const lines = await Promise.all(sorted.map(async (entry, i) => {
      const user = await client.users.fetch(entry.id).catch(() => null);
      const name = user ? user.username : `Utilisateur inconnu`;
      return `${medals[i] || `**${i + 1}.**`} ${name} — **${entry.total.toLocaleString()} coins**`;
    }));

    const embed = new EmbedBuilder()
      .setColor(client.config.color)
      .setTitle('💰 Classement des plus riches')
      .setDescription(lines.join('\n'))
      .setTimestamp()
      .setFooter({ text: client.config.botName });

    message.reply({ embeds: [embed] });
  },
};
