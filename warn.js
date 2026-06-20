const { success, error, info } = require('../../utils/embed');
const { addWarn, getWarns, removeWarn } = require('../../utils/database');

module.exports = {
  name: 'warn',
  description: 'Avertir un membre',
  usage: '*warn @utilisateur [raison]',
  category: 'Modération',
  async execute(message, args, client) {
    if (!message.member.permissions.has('ModerateMembers'))
      return message.reply({ embeds: [error('Permission refusée', 'Tu n\'as pas la permission d\'avertir des membres.')] });

    const sub = args[0];

    // *warn list @user
    if (sub === 'list') {
      const target = message.mentions.users.first();
      if (!target) return message.reply({ embeds: [error('Erreur', 'Mentionne un utilisateur.')] });
      const warns = getWarns(target.id, message.guild.id);
      if (!warns.length) return message.reply({ embeds: [info('Avertissements', `**${target.tag}** n'a aucun avertissement.`)] });
      const list = warns.map((w, i) => `**#${i + 1}** \`${w.id}\` — ${w.reason} *(par ${w.moderator})*`).join('\n');
      return message.reply({ embeds: [info(`⚠️ Avertissements de ${target.tag}`, list)] });
    }

    // *warn remove @user <id>
    if (sub === 'remove') {
      const target = message.mentions.users.first();
      const warnId = args[2];
      if (!target || !warnId) return message.reply({ embeds: [error('Erreur', 'Usage : `*warn remove @user <id>`')] });
      const removed = removeWarn(target.id, message.guild.id, warnId);
      return message.reply({ embeds: removed ? success('Warn supprimé', `L'avertissement \`${warnId}\` a été supprimé.`) : error('Erreur', 'Aucun avertissement trouvé avec cet ID.') });
    }

    // *warn @user [raison]
    const target = message.mentions.members.first();
    if (!target) return message.reply({ embeds: [error('Erreur', 'Mentionne un utilisateur à avertir.')] });

    const reason = args.slice(1).join(' ') || 'Aucune raison fournie';
    const warn = addWarn(target.id, message.guild.id, reason, message.author.tag);
    const total = getWarns(target.id, message.guild.id).length;

    await target.send({ embeds: [error('Tu as reçu un avertissement', `**Serveur :** ${message.guild.name}\n**Raison :** ${reason}\n**Modérateur :** ${message.author.tag}\n**Total :** ${total} warn(s)`)] }).catch(() => {});
    message.reply({ embeds: [success('Avertissement envoyé', `**${target.user.tag}** a reçu un warn (ID: \`${warn.id}\`).\n**Raison :** ${reason}\n**Total :** ${total} warn(s)`)] });
  },
};
