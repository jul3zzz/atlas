const { success, warn } = require('../../utils/embed');
const { getEconomy, saveEconomy } = require('../../utils/database');

module.exports = {
  name: 'daily',
  description: 'Récupérer ta récompense quotidienne',
  usage: '*daily',
  category: 'Économie',
  async execute(message, args, client) {
    const data = getEconomy(message.author.id);
    const now = Date.now();
    const cooldown = client.config.economy.dailyCooldown;
    const remaining = cooldown - (now - data.lastDaily);

    if (remaining > 0) {
      const h = Math.floor(remaining / 3600000);
      const m = Math.floor((remaining % 3600000) / 60000);
      return message.reply({ embeds: [warn('Déjà réclamé', `Tu as déjà réclamé ta récompense quotidienne.\nReviens dans **${h}h ${m}m**.`)] });
    }

    const amount = client.config.economy.dailyAmount;
    data.coins += amount;
    data.lastDaily = now;
    saveEconomy(message.author.id, data);

    message.reply({ embeds: [success('Récompense quotidienne', `Tu as reçu **${amount} coins** ! 🎁\n💰 Nouveau solde : **${data.coins.toLocaleString()} coins**`)] });
  },
};
