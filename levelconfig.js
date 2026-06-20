const { success, error, info } = require('../../utils/embed');
const { getLevelConfig, setLevelConfig } = require('../../utils/database');
const { EmbedBuilder } = require('discord.js');

module.exports = {
  name: 'levelconfig',
  aliases: ['lvlconfig', 'levelsetup'],
  description: '[Admin] Configurer le système de leveling',
  usage: '*levelconfig <setchannel|addreward|removereward|listrewards|reset>',
  category: 'Leveling',
  async execute(message, args, client) {
    if (!message.member.permissions.has('Administrator'))
      return message.reply({ embeds: [error('Permission refusée', 'Seuls les administrateurs peuvent utiliser cette commande.')] });

    const sub = args[0];
    const config = getLevelConfig(message.guild.id);

    // ── Afficher la config actuelle ──────────────────────────────────────────
    if (!sub || sub === 'info') {
      const rewards = Object.entries(config.rewards || {});
      const rewardList = rewards.length
        ? rewards.sort(([a], [b]) => a - b).map(([lvl, r]) => {
            const parts = [];
            if (r.coins) parts.push(`💰 ${r.coins.toLocaleString()} coins`);
            if (r.roleId) parts.push(`🎭 <@&${r.roleId}>`);
            return `Niveau **${lvl}** → ${parts.join(' + ')}`;
          }).join('\n')
        : 'Aucune récompense configurée.';

      return message.reply({
        embeds: [new EmbedBuilder()
          .setColor(client.config.color)
          .setTitle('⚙️ Configuration Leveling')
          .addFields(
            { name: '📢 Salon level up', value: config.channelId ? `<#${config.channelId}>` : 'Salon du message (défaut)' },
            { name: '🎁 Récompenses par niveau', value: rewardList },
          )
          .addFields({ name: '📋 Commandes', value: [
            '`*levelconfig setchannel #salon` — salon pour les level up',
            '`*levelconfig addreward <niveau> coins:<montant>` — récompense en coins',
            '`*levelconfig addreward <niveau> role:@rôle` — récompense en rôle',
            '`*levelconfig addreward <niveau> coins:<montant> role:@rôle` — les deux',
            '`*levelconfig removereward <niveau>` — supprimer une récompense',
            '`*levelconfig listrewards` — voir toutes les récompenses',
            '`*levelconfig resetchannel` — remettre le salon par défaut',
          ].join('\n') })
          .setTimestamp()
          .setFooter({ text: client.config.botName })]
      });
    }

    // ── Définir le salon ─────────────────────────────────────────────────────
    if (sub === 'setchannel') {
      const channel = message.mentions.channels.first();
      if (!channel) return message.reply({ embeds: [error('Erreur', 'Mentionne un salon.')] });
      config.channelId = channel.id;
      setLevelConfig(message.guild.id, config);
      return message.reply({ embeds: [success('Salon défini', `Les messages de level up seront envoyés dans ${channel}.`)] });
    }

    // ── Réinitialiser le salon ────────────────────────────────────────────────
    if (sub === 'resetchannel') {
      config.channelId = null;
      setLevelConfig(message.guild.id, config);
      return message.reply({ embeds: [success('Salon réinitialisé', 'Les messages de level up seront envoyés dans le salon du message.')] });
    }

    // ── Ajouter une récompense ────────────────────────────────────────────────
    if (sub === 'addreward') {
      const level = parseInt(args[1]);
      if (isNaN(level) || level < 1)
        return message.reply({ embeds: [error('Erreur', 'Précise un niveau valide (ex: `*levelconfig addreward 5 coins:500`)')] });

      const rest = args.slice(2).join(' ');
      const coinsMatch = rest.match(/coins:(\d+)/i);
      const roleMatch = message.mentions.roles.first();

      if (!coinsMatch && !roleMatch)
        return message.reply({ embeds: [error('Erreur', 'Précise au moins `coins:<montant>` et/ou mentionne un `@rôle`.\nEx: `*levelconfig addreward 10 coins:500 @Vétéran`')] });

      if (!config.rewards) config.rewards = {};
      config.rewards[level] = {};
      if (coinsMatch) config.rewards[level].coins = parseInt(coinsMatch[1]);
      if (roleMatch) config.rewards[level].roleId = roleMatch.id;

      setLevelConfig(message.guild.id, config);

      const parts = [];
      if (coinsMatch) parts.push(`💰 **${parseInt(coinsMatch[1]).toLocaleString()} coins**`);
      if (roleMatch) parts.push(`🎭 **${roleMatch.name}**`);
      return message.reply({ embeds: [success('Récompense ajoutée', `Niveau **${level}** → ${parts.join(' + ')}`)] });
    }

    // ── Supprimer une récompense ──────────────────────────────────────────────
    if (sub === 'removereward') {
      const level = parseInt(args[1]);
      if (isNaN(level) || !config.rewards?.[level])
        return message.reply({ embeds: [error('Erreur', 'Aucune récompense trouvée pour ce niveau.')] });

      delete config.rewards[level];
      setLevelConfig(message.guild.id, config);
      return message.reply({ embeds: [success('Récompense supprimée', `La récompense du niveau **${level}** a été supprimée.`)] });
    }

    // ── Lister les récompenses ────────────────────────────────────────────────
    if (sub === 'listrewards') {
      const rewards = Object.entries(config.rewards || {});
      if (!rewards.length)
        return message.reply({ embeds: [info('Récompenses', 'Aucune récompense configurée.')] });

      const list = rewards
        .sort(([a], [b]) => Number(a) - Number(b))
        .map(([lvl, r]) => {
          const parts = [];
          if (r.coins) parts.push(`💰 ${r.coins.toLocaleString()} coins`);
          if (r.roleId) parts.push(`🎭 <@&${r.roleId}>`);
          return `**Niveau ${lvl}** → ${parts.join(' + ')}`;
        }).join('\n');

      return message.reply({ embeds: [info('🎁 Récompenses de niveau', list)] });
    }

    return message.reply({ embeds: [error('Commande inconnue', 'Utilise `*levelconfig` pour voir les options.')] });
  },
};
