const { success, error } = require('../../utils/embed');
const { getEconomy, saveEconomy } = require('../../utils/database');

module.exports = {
  name: 'pay',
  aliases: ['give', 'donner'],
  description: 'Donner des coins à un autre utilisateur',
  usage: '*pay @utilisateur <montant>',
  category: 'Économie',
  async execute(message, args, client) {
    const target = message.mentions.users.first();
    if (!target || target.bot || target.id === message.author.id)
      return message.reply({ embeds: [error('Erreur', 'Mentionne un utilisateur valide différent de toi.')] });

    const amount = parseInt(args[1]);
    if (isNaN(amount) || amount <= 0)
      return message.reply({ embeds: [error('Erreur', 'Précise un montant valide.')] });

    const sender = getEconomy(message.author.id);
    if (sender.coins < amount)
      return message.reply({ embeds: [error('Fonds insuffisants', `Tu n'as que **${sender.coins.toLocaleString()} coins** dans ton portefeuille.`)] });

    const receiver = getEconomy(target.id);
    sender.coins -= amount;
    receiver.coins += amount;
    saveEconomy(message.author.id, sender);
    saveEconomy(target.id, receiver);

    message.reply({ embeds: [success('Transfert effectué', `Tu as envoyé **${amount.toLocaleString()} coins** à ${target}.\n💰 Ton solde : **${sender.coins.toLocaleString()} coins**`)] });
  },
};
