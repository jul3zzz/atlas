const { EmbedBuilder } = require('discord.js');

module.exports = {
  name: 'serverinfo',
  aliases: ['si', 'server'],
  description: 'Voir les informations du serveur',
  usage: '*serverinfo',
  category: 'Général',
  async execute(message, args, client) {
    const guild = message.guild;
    await guild.members.fetch();

    const bots = guild.members.cache.filter(m => m.user.bot).size;
    const humans = guild.memberCount - bots;

    const embed = new EmbedBuilder()
      .setColor(client.config.color)
      .setTitle(`🏰 ${guild.name}`)
      .setThumbnail(guild.iconURL({ dynamic: true }))
      .addFields(
        { name: '🆔 ID', value: guild.id, inline: true },
        { name: '👑 Propriétaire', value: `<@${guild.ownerId}>`, inline: true },
        { name: '📅 Créé', value: `<t:${Math.floor(guild.createdTimestamp / 1000)}:R>`, inline: true },
        { name: '👥 Membres', value: `**${humans}** humains | **${bots}** bots`, inline: true },
        { name: '💬 Salons', value: `${guild.channels.cache.size}`, inline: true },
        { name: '🎭 Rôles', value: `${guild.roles.cache.size}`, inline: true },
        { name: '😀 Emojis', value: `${guild.emojis.cache.size}`, inline: true },
        { name: '🔒 Vérification', value: guild.verificationLevel.toString(), inline: true },
      )
      .setTimestamp()
      .setFooter({ text: client.config.botName });

    message.reply({ embeds: [embed] });
  },
};
