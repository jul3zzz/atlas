const { success, error, info } = require('../../utils/embed');
const { getSettings, saveSettings } = require('../../utils/database');

module.exports = {
  name: 'toggle',
  aliases: ['activer', 'desactiver'],
  description: '[Admin] Activer ou désactiver l\'économie ou le leveling',
  usage: '*toggle <economy|leveling>',
  category: 'Général',
  async execute(message, args, client) {
    if (!message.member.permissions.has('Administrator'))
      return message.reply({ embeds: [error('Permission refusée', 'Seuls les administrateurs peuvent utiliser cette commande.')] });

    const sub = args[0]?.toLowerCase();
    const settings = getSettings(message.guild.id);

    if (!sub) {
      return message.reply({ embeds: [info('⚙️ État des systèmes', [
        `💰 **Économie :** ${settings.economyEnabled ? '✅ Activée' : '❌ Désactivée'}`,
        `📊 **Leveling :** ${settings.levelingEnabled ? '✅ Activé' : '❌ Désactivé'}`,
        '',
        '`*toggle economy` — activer/désactiver l\'économie',
        '`*toggle leveling` — activer/désactiver le leveling',
      ].join('\n'))] });
    }

    if (sub === 'economy' || sub === 'economie' || sub === 'eco') {
      settings.economyEnabled = !settings.economyEnabled;
      saveSettings(message.guild.id, settings);
      const state = settings.economyEnabled ? '✅ activée' : '❌ désactivée';
      return message.reply({ embeds: [success('Économie mise à jour', `L'économie est maintenant **${state}**.`)] });
    }

    if (sub === 'leveling' || sub === 'level' || sub === 'xp') {
      settings.levelingEnabled = !settings.levelingEnabled;
      saveSettings(message.guild.id, settings);
      const state = settings.levelingEnabled ? '✅ activé' : '❌ désactivé';
      return message.reply({ embeds: [success('Leveling mis à jour', `Le leveling est maintenant **${state}**.`)] });
    }

    return message.reply({ embeds: [error('Erreur', 'Utilise `*toggle economy` ou `*toggle leveling`.')] });
  },
};
