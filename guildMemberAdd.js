const { EmbedBuilder } = require('discord.js');
const { getWelcome } = require('../utils/database');

module.exports = {
  name: 'guildMemberAdd',
  async execute(member, client) {
    const config = getWelcome(member.guild.id);
    if (!config || !config.channelId) return;

    const channel = member.guild.channels.cache.get(config.channelId);
    if (!channel) return;

    const message = (config.message || 'Bienvenue sur **{server}**, {user} ! Tu es le membre n°**{count}**.')
      .replace('{user}', `<@${member.id}>`)
      .replace('{server}', member.guild.name)
      .replace('{count}', member.guild.memberCount)
      .replace('{tag}', member.user.tag);

    const embed = new EmbedBuilder()
      .setColor(client.config.color)
      .setTitle(`👋 Bienvenue sur ${member.guild.name} !`)
      .setDescription(message)
      .setThumbnail(member.user.displayAvatarURL({ dynamic: true }))
      .setTimestamp()
      .setFooter({ text: client.config.botName });

    // GIF en image de l'embed (s'affiche en dessous du texte)
    if (config.gifUrl) embed.setImage(config.gifUrl);

    channel.send({ embeds: [embed] });

    // Rôle de bienvenue automatique
    if (config.roleId) {
      const role = member.guild.roles.cache.get(config.roleId);
      if (role) member.roles.add(role).catch(() => {});
    }
  },
};
