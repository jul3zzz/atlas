const { EmbedBuilder } = require('discord.js');
const { getEconomy, saveEconomy } = require('../../utils/database');
const { error } = require('../../utils/embed');

const SYMBOLS = ['🍒', '🍋', '🍊', '🍇', '⭐', '💎', '7️⃣'];
const MULTIPLIERS = { '7️⃣': 10, '💎': 7, '⭐': 5, '🍇': 4, '🍊': 3, '🍋': 2, '🍒': 1.5 };

function spin() {
  return [0, 1, 2].map(() => SYMBOLS[Math.floor(Math.random() * SYMBOLS.length)]);
}

module.exports = {
  name: 'slots',
  aliases: ['slot', 'machine'],
  description: 'Jouer à la machine à sous',
  usage: '*slots <montant>',
  category: 'Jeux',
  async execute(message, args, client) {
    const data = getEconomy(message.author.id);
    const amount = args[0] === 'all' ? data.coins : parseInt(args[0]);

    if (isNaN(amount) || amount <= 0)
      return message.reply({ embeds: [error('Erreur', 'Précise un montant valide.')] });
    if (amount > data.coins)
      return message.reply({ embeds: [error('Fonds insuffisants', `Tu n'as que **${data.coins.toLocaleString()} coins**.`)] });

    const result = spin();
    const [a, b, c] = result;
    let multiplier = 0;
    let description;

    if (a === b && b === c) {
      multiplier = MULTIPLIERS[a] || 2;
      description = `🎰 **JACKPOT ! Triple ${a} !**\nMultiplicateur : **x${multiplier}**`;
    } else if (a === b || b === c || a === c) {
      multiplier = 0.5;
      description = `🎰 **Paire !** Demi-remboursement.`;
    } else {
      description = `🎰 **Perdu !**`;
    }

    const won = Math.floor(amount * multiplier);
    data.coins -= amount;
    data.coins += won;
    saveEconomy(message.author.id, data);

    const net = won - amount;
    const embed = new EmbedBuilder()
      .setColor(multiplier >= 1 ? client.config.colorSuccess : client.config.colorError)
      .setTitle('🎰 Machine à Sous')
      .setDescription(`[ ${a} | ${b} | ${c} ]\n\n${description}\n\n${net >= 0 ? `🎉 +**${net.toLocaleString()} coins**` : `💸 -**${Math.abs(net).toLocaleString()} coins**`}\n💰 Solde : **${data.coins.toLocaleString()} coins**`)
      .setTimestamp();

    message.reply({ embeds: [embed] });
  },
};
