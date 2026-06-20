const { success, error } = require('../../utils/embed');
const { getLevel, saveLevel } = require('../../utils/database');

module.exports = {
  name: 'setxp',
  description: '[Admin] Définir l\'XP d\'un membre',
  usage: '*setxp @utilisateur <xp>',
  category: 'Leveling',
  async execute(message, args, client) {
    if (!message.member.permissions.has('Administrator'))
      return message.reply({ embeds: [error('Permission refusée', 'Seuls les admins peuvent modifier l\'XP.')] });

    const target = message.mentions.members.first();
    const xp = parseInt(args[1]);

    if (!target || isNaN(xp) || xp < 0)
      return message.reply({ embeds: [error('Erreur', 'Usage : `*setxp @utilisateur <xp>`')] });

    const data = getLevel(target.id, message.guild.id);
    data.xp = xp;
    saveLevel(target.id, message.guild.id, data);

    message.reply({ embeds: [success('XP mis à jour', `L'XP de **${target.user.tag}** a été défini à **${xp}**.`)] });
  },
};
