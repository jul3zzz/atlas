const { success, error } = require('../../utils/embed');

module.exports = {
  name: 'ban',
  description: 'Bannir un membre du serveur',
  usage: '*ban @utilisateur [raison]',
  category: 'Modération',
  async execute(message, args, client) {
    if (!message.member.permissions.has('BanMembers'))
      return message.reply({ embeds: [error('Permission refusée', 'Tu n\'as pas la permission de bannir des membres.')] });

    const target = message.mentions.members.first();
    if (!target)
      return message.reply({ embeds: [error('Erreur', 'Mentionne un utilisateur à bannir.')] });

    if (!target.bannable)
      return message.reply({ embeds: [error('Erreur', 'Je ne peux pas bannir cet utilisateur.')] });

    const reason = args.slice(1).join(' ') || 'Aucune raison fournie';

    try {
      await target.send({ embeds: [error('Tu as été banni', `**Serveur :** ${message.guild.name}\n**Raison :** ${reason}\n**Modérateur :** ${message.author.tag}`)] }).catch(() => {});
      await target.ban({ reason });
      message.reply({ embeds: [success('Membre banni', `**${target.user.tag}** a été banni.\n**Raison :** ${reason}`)] });
    } catch (err) {
      message.reply({ embeds: [error('Erreur', 'Impossible de bannir ce membre.')] });
    }
  },
};
