const { EmbedBuilder } = require('discord.js');
const { getLeaderboard } = require('../../utils/database');

module.exports = {
  name: 'leaderboard',
  aliases: ['lb', 'top', 'classement'],
  description: 'Voir le classement des membres par niveau',
  usage: '*leaderboard',
  category: 'Leveling',
  async execute(message, args, client) {
    const board = getLeaderboard(message.guild.id);
    if (!board.length)
      return message.reply('Aucun membre n\'a encore de niveau sur ce serveur.');

    const medals = ['🥇', '🥈', '🥉'];
    const lines = await Promise.all(board.map(async (entry, i) => {
      const user = await client.users.fetch(entry.userId).catch(() => null);
      const name = user ? user.username : 'Inconnu';
      return `${medals[i] || `**${i + 1}.**`} ${name} — Niveau **${entry.level}** (${entry.xp} XP)`;
    }));

    const embed = new EmbedBuilder()
      .setColor(client.config.color)
      .setTitle(`🏆 Classement de ${message.guild.name}`)
      .setDescription(lines.join('\n'))
      .setTimestamp()
      .setFooter({ text: client.config.botName });

    message.reply({ embeds: [embed] });
  },
};
