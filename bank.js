const { success, error } = require('../../utils/embed');
const { getEconomy, saveEconomy } = require('../../utils/database');

module.exports = {
  name: 'bank',
  aliases: ['banque'],
  description: 'Déposer ou retirer des coins de la banque',
  usage: '*bank <deposit|withdraw> <montant|all>',
  category: 'Économie',
  async execute(message, args, client) {
    const sub = args[0];
    const data = getEconomy(message.author.id);

    if (!sub || (sub !== 'deposit' && sub !== 'withdraw' && sub !== 'depot' && sub !== 'retrait'))
      return message.reply({ embeds: [error('Erreur', 'Usage : `*bank deposit <montant>` ou `*bank withdraw <montant>`')] });

    const isDeposit = sub === 'deposit' || sub === 'depot';
    const rawAmount = args[1];
    const max = isDeposit ? data.coins : data.bank;
    const amount = rawAmount === 'all' ? max : parseInt(rawAmount);

    if (isNaN(amount) || amount <= 0)
      return message.reply({ embeds: [error('Erreur', 'Précise un montant valide.')] });
    if (amount > max)
      return message.reply({ embeds: [error('Fonds insuffisants', `Tu n'as que **${max.toLocaleString()} coins** ${isDeposit ? 'dans ton portefeuille' : 'en banque'}.`)] });

    if (isDeposit) {
      data.coins -= amount;
      data.bank += amount;
    } else {
      data.bank -= amount;
      data.coins += amount;
    }
    saveEconomy(message.author.id, data);

    const action = isDeposit ? 'déposé' : 'retiré';
    message.reply({ embeds: [success('Transaction réussie', `Tu as ${action} **${amount.toLocaleString()} coins**.\n👛 Portefeuille : **${data.coins.toLocaleString()}** | 🏦 Banque : **${data.bank.toLocaleString()}**`)] });
  },
};
