const { success, error } = require('../../utils/embed');
const { getEconomy, saveEconomy } = require('../../utils/database');

module.exports = {
  name: 'addcoins',
  aliases: ['donnercoins', 'givecoins'],
  description: '[Admin] Donner des coins à un membre',
  usage: '*addcoins @utilisateur <montant>',
  category: 'Économie',
  async execute(message, args, client) {
    if (!message.member.permissions.has('Administrator'))
      return message.reply({ embeds: [error('Permission refusée', 'Seuls les administrateurs peuvent utiliser cette commande.')] });

    const target = message.mentions.members.first();
    if (!target || target.user.bot)
      return message.reply({ embeds: [error('Erreur', 'Mentionne un utilisateur valide.')] });

    const amount = parseInt(args[1]);
    if (isNaN(amount) || amount === 0)
      return message.reply({ embeds: [error('Erreur', 'Précise un montant valide (positif pour donner, négatif pour retirer).')] });

    const data = getEconomy(target.id);
    data.coins += amount;
    if (data.coins < 0) data.coins = 0;
    saveEconomy(target.id, data);

    const action = amount >= 0 ? `reçu **+${amount.toLocaleString()} coins**` : `perdu **${Math.abs(amount).toLocaleString()} coins**`;
    message.reply({ embeds: [success('Coins modifiés', `${target} a ${action}.\n💰 Nouveau solde : **${data.coins.toLocaleString()} coins**`)] });
  },
};
