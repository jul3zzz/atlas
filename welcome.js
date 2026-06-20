const { EmbedBuilder } = require('discord.js');
const { success, error, info } = require('../../utils/embed');
const { getWelcome, setWelcome } = require('../../utils/database');

module.exports = {
  name: 'welcome',
  aliases: ['accueil'],
  description: 'Configurer le système de bienvenue',
  usage: '*welcome <setchannel|setrole|setmessage|setgif|removegif|disable|test>',
  category: 'Accueil',
  async execute(message, args, client) {
    if (!message.member.permissions.has('ManageGuild'))
      return message.reply({ embeds: [error('Permission refusée', 'Tu n\'as pas la permission de gérer le serveur.')] });

    const sub = args[0];
    const current = getWelcome(message.guild.id) || {};

    if (!sub || sub === 'info') {
      return message.reply({
        embeds: [info('⚙️ Configuration Accueil', [
          `**Salon :** ${current.channelId ? `<#${current.channelId}>` : 'Non défini'}`,
          `**Rôle auto :** ${current.roleId ? `<@&${current.roleId}>` : 'Aucun'}`,
          `**Message :** ${current.message || 'Par défaut'}`,
          `**GIF :** ${current.gifUrl ? `[Lien](${current.gifUrl})` : 'Aucun'}`,
          '',
          '**Variables disponibles :** `{user}`, `{server}`, `{count}`, `{tag}`',
          '',
          '**Commandes :**',
          '`*welcome setchannel #salon` — définir le salon',
          '`*welcome setrole @rôle` — rôle automatique',
          '`*welcome setmessage <texte>` — personnaliser le message',
          '`*welcome setgif <url>` — définir un GIF sous le message',
          '`*welcome removegif` — supprimer le GIF',
          '`*welcome disable` — désactiver',
          '`*welcome test` — tester',
        ].join('\n'))]
      });
    }

    if (sub === 'setchannel') {
      const channel = message.mentions.channels.first();
      if (!channel) return message.reply({ embeds: [error('Erreur', 'Mentionne un salon.')] });
      setWelcome(message.guild.id, { ...current, channelId: channel.id });
      return message.reply({ embeds: [success('Salon défini', `Le salon de bienvenue est maintenant ${channel}.`)] });
    }

    if (sub === 'setrole') {
      const role = message.mentions.roles.first();
      if (!role) return message.reply({ embeds: [error('Erreur', 'Mentionne un rôle.')] });
      setWelcome(message.guild.id, { ...current, roleId: role.id });
      return message.reply({ embeds: [success('Rôle défini', `Le rôle ${role} sera automatiquement attribué aux nouveaux membres.`)] });
    }

    if (sub === 'setmessage') {
      const msg = args.slice(1).join(' ');
      if (!msg) return message.reply({ embeds: [error('Erreur', 'Écris le message de bienvenue.')] });
      setWelcome(message.guild.id, { ...current, message: msg });
      return message.reply({ embeds: [success('Message défini', 'Message de bienvenue mis à jour.')] });
    }

    if (sub === 'setgif') {
      const url = args[1];
      if (!url || !url.startsWith('http'))
        return message.reply({ embeds: [error('Erreur', 'Fournis une URL valide.\nEx: `*welcome setgif https://media.giphy.com/media/xxx/giphy.gif`')] });
      setWelcome(message.guild.id, { ...current, gifUrl: url });
      return message.reply({ embeds: [success('GIF défini', 'Le GIF s\'affichera sous le message de bienvenue.\nUtilise `*welcome test` pour voir le rendu.')] });
    }

    if (sub === 'removegif') {
      setWelcome(message.guild.id, { ...current, gifUrl: null });
      return message.reply({ embeds: [success('GIF supprimé', 'Le GIF de bienvenue a été retiré.')] });
    }

    if (sub === 'disable') {
      setWelcome(message.guild.id, { ...current, channelId: null });
      return message.reply({ embeds: [success('Désactivé', 'Le système de bienvenue a été désactivé.')] });
    }

    if (sub === 'test') {
      const config = getWelcome(message.guild.id);
      if (!config?.channelId) return message.reply({ embeds: [error('Erreur', 'Aucun salon de bienvenue configuré. Utilise `*welcome setchannel #salon` d\'abord.')] });
      const channel = message.guild.channels.cache.get(config.channelId);
      if (!channel) return message.reply({ embeds: [error('Erreur', 'Le salon configuré est introuvable.')] });

      const msg = (config.message || 'Bienvenue sur **{server}**, {user} ! Tu es le membre n°**{count}**.')
        .replace('{user}', `<@${message.author.id}>`)
        .replace('{server}', message.guild.name)
        .replace('{count}', message.guild.memberCount)
        .replace('{tag}', message.author.tag);

      const embed = new EmbedBuilder()
        .setColor(client.config.color)
        .setTitle(`👋 Bienvenue sur ${message.guild.name} !`)
        .setDescription(msg)
        .setThumbnail(message.author.displayAvatarURL({ dynamic: true }))
        .setTimestamp()
        .setFooter({ text: client.config.botName });

      if (config.gifUrl) embed.setImage(config.gifUrl);

      await channel.send({ embeds: [embed] });
      return message.reply({ embeds: [success('Test envoyé', `Message de bienvenue envoyé dans ${channel} !`)] });
    }

    return message.reply({ embeds: [error('Commande inconnue', 'Utilise `*welcome` pour voir les options disponibles.')] });
  },
};
