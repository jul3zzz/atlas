const { EmbedBuilder } = require('discord.js');

module.exports = {
  name: 'userinfo',
  aliases: ['ui', 'profil'],
  description: 'Voir les informations d\'un utilisateur',
  usage: '*userinfo [@utilisateur]',
  category: 'Général',
  async execute(message, args, client) {
    const member = message.mentions.members.first() || message.member;
    const user = member.user;

    const roles = member.roles.cache
      .filter(r => r.id !== message.guild.id)
      .sort((a, b) => b.position - a.position)
      .map(r => r.toString())
      .slice(0, 5);

    const embed = new EmbedBuilder()
      .setColor(member.displayHexColor || client.config.color)
      .setTitle(`👤 ${user.tag}`)
      .setThumbnail(user.displayAvatarURL({ dynamic: true }))
      .addFields(
        { name: '🆔 ID', value: user.id, inline: true },
        { name: '📅 Compte créé', value: `<t:${Math.floor(user.createdTimestamp / 1000)}:R>`, inline: true },
        { name: '📥 A rejoint', value: `<t:${Math.floor(member.joinedTimestamp / 1000)}:R>`, inline: true },
        { name: `🎭 Rôles (${member.roles.cache.size - 1})`, value: roles.join(', ') || 'Aucun', inline: false },
      )
      .setTimestamp()
      .setFooter({ text: client.config.botName });

    message.reply({ embeds: [embed] });
  },
};
