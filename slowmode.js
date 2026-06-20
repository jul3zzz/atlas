const { success, error } = require('../../utils/embed');

module.exports = {
  name: 'slowmode',
  description: 'Définir le slowmode d\'un salon',
  usage: '*slowmode <secondes>',
  category: 'Modération',
  async execute(message, args, client) {
    if (!message.member.permissions.has('ManageChannels'))
      return message.reply({ embeds: [error('Permission refusée', 'Tu n\'as pas la permission de gérer ce salon.')] });

    const seconds = parseInt(args[0]);
    if (isNaN(seconds) || seconds < 0 || seconds > 21600)
      return message.reply({ embeds: [error('Erreur', 'Précise une valeur entre 0 et 21600 secondes.')] });

    await message.channel.setRateLimitPerUser(seconds);
    const msg = seconds === 0
      ? 'Le slowmode a été désactivé.'
      : `Le slowmode est maintenant de **${seconds} seconde(s)**.`;
    message.reply({ embeds: [success('Slowmode mis à jour', msg)] });
  },
};
