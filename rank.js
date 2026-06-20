const { EmbedBuilder } = require('discord.js');
const { getLevel, xpForLevel } = require('../../utils/database');

module.exports = {
  name: 'rank',
  aliases: ['niveau', 'level', 'xp'],
  description: 'Voir ton niveau ou celui d\'un autre membre',
  usage: '*rank [@utilisateur]',
  category: 'Leveling',
  async execute(message, args, client) {
    const target = message.mentions.members.first()?.user || message.author;
    const data = getLevel(target.id, message.guild.id);
    const needed = xpForLevel(data.level);
    const progress = Math.floor((data.xp / needed) * 20);
    const bar = '█'.repeat(progress) + '░'.repeat(20 - progress);

    const embed = new EmbedBuilder()
      .setColor(client.config.color)
      .setTitle(`📊 Rang de ${target.username}`)
      .setThumbnail(target.displayAvatarURL())
      .addFields(
        { name: '⭐ Niveau', value: `**${data.level}**`, inline: true },
        { name: '✨ XP', value: `**${data.xp} / ${needed}**`, inline: true },
      )
      .setDescription(`\`${bar}\` ${Math.floor((data.xp / needed) * 100)}%`)
      .setTimestamp()
      .setFooter({ text: client.config.botName });

    message.reply({ embeds: [embed] });
  },
};
