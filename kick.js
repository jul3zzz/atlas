const { success, error } = require('../../utils/embed');

module.exports = {
  name: 'kick',
  description: 'Expulser un membre du serveur',
  usage: '*kick @utilisateur [raison]',
  category: 'Modération',
  async execute(message, args, client) {
    if (!message.member.permissions.has('KickMembers'))
      return message.reply({ embeds: [error('Permission refusée', 'Tu n\'as pas la permission d\'expulser des membres.')] });

    const target = message.mentions.members.first();
    if (!target)
      return message.reply({ embeds: [error('Erreur', 'Mentionne un utilisateur à expulser.')] });

    if (!target.kickable)
      return message.reply({ embeds: [error('Erreur', 'Je ne peux pas expulser cet utilisateur.')] });

    const reason = args.slice(1).join(' ') || 'Aucune raison fournie';

    try {
      await target.send({ embeds: [error('Tu as été expulsé', `**Serveur :** ${message.guild.name}\n**Raison :** ${reason}\n**Modérateur :** ${message.author.tag}`)] }).catch(() => {});
      await target.kick(reason);
      message.reply({ embeds: [success('Membre expulsé', `**${target.user.tag}** a été expulsé.\n**Raison :** ${reason}`)] });
    } catch {
      message.reply({ embeds: [error('Erreur', 'Impossible d\'expulser ce membre.')] });
    }
  },
};
