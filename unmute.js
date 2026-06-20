const { success, error } = require('../../utils/embed');

module.exports = {
  name: 'unmute',
  description: 'Retirer le mute d\'un membre',
  usage: '*unmute @utilisateur',
  category: 'Modération',
  async execute(message, args, client) {
    if (!message.member.permissions.has('ModerateMembers'))
      return message.reply({ embeds: [error('Permission refusée', 'Tu n\'as pas la permission de démuter des membres.')] });

    const target = message.mentions.members.first();
    if (!target) return message.reply({ embeds: [error('Erreur', 'Mentionne un utilisateur.')] });

    try {
      await target.timeout(null);
      message.reply({ embeds: [success('Membre démute', `**${target.user.tag}** n'est plus en sourdine.`)] });
    } catch {
      message.reply({ embeds: [error('Erreur', 'Impossible de démuter ce membre.')] });
    }
  },
};
