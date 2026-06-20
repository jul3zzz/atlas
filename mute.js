const { success, error } = require('../../utils/embed');

function parseDuration(str) {
  const match = str.match(/^(\d+)(s|m|h|d)$/);
  if (!match) return null;
  const val = parseInt(match[1]);
  const unit = match[2];
  const mult = { s: 1000, m: 60000, h: 3600000, d: 86400000 };
  return val * mult[unit];
}

module.exports = {
  name: 'mute',
  aliases: ['timeout'],
  description: 'Mettre en sourdine un membre (ex: *mute @user 10m raison)',
  usage: '*mute @utilisateur <durée: 10s/5m/2h/1d> [raison]',
  category: 'Modération',
  async execute(message, args, client) {
    if (!message.member.permissions.has('ModerateMembers'))
      return message.reply({ embeds: [error('Permission refusée', 'Tu n\'as pas la permission de muter des membres.')] });

    const target = message.mentions.members.first();
    if (!target) return message.reply({ embeds: [error('Erreur', 'Mentionne un utilisateur.')] });

    const durationStr = args[1];
    if (!durationStr) return message.reply({ embeds: [error('Erreur', 'Précise une durée (ex: `10m`, `2h`, `1d`).')] });

    const duration = parseDuration(durationStr);
    if (!duration) return message.reply({ embeds: [error('Erreur', 'Durée invalide. Exemples : `30s`, `10m`, `2h`, `1d`.')] });

    const reason = args.slice(2).join(' ') || 'Aucune raison fournie';

    try {
      await target.timeout(duration, reason);
      const until = new Date(Date.now() + duration).toLocaleString('fr-FR');
      message.reply({ embeds: [success('Membre muté', `**${target.user.tag}** a été mis en sourdine jusqu'au **${until}**.\n**Raison :** ${reason}`)] });
    } catch {
      message.reply({ embeds: [error('Erreur', 'Impossible de muter ce membre.')] });
    }
  },
};
