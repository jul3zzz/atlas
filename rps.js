const { EmbedBuilder } = require('discord.js');
const { getEconomy, saveEconomy } = require('../../utils/database');
const { error } = require('../../utils/embed');

const CHOICES = { pierre: '🪨', feuille: '📄', ciseaux: '✂️', rock: '🪨', paper: '📄', scissors: '✂️' };
const WINS = { pierre: 'ciseaux', feuille: 'pierre', ciseaux: 'feuille' };
const NORMALIZE = { rock: 'pierre', paper: 'feuille', scissors: 'ciseaux' };
const BOT_CHOICES = ['pierre', 'feuille', 'ciseaux'];

module.exports = {
  name: 'rps',
  aliases: ['shifumi', 'chifoumi'],
  description: 'Pierre-Feuille-Ciseaux contre le bot',
  usage: '*rps <pierre|feuille|ciseaux> [mise]',
  category: 'Jeux',
  async execute(message, args, client) {
    let choice = args[0]?.toLowerCase();
    if (NORMALIZE[choice]) choice = NORMALIZE[choice];
    if (!['pierre', 'feuille', 'ciseaux'].includes(choice))
      return message.reply({ embeds: [error('Erreur', 'Choisis `pierre`, `feuille` ou `ciseaux`.')] });

    const botChoice = BOT_CHOICES[Math.floor(Math.random() * 3)];
    let result, color, net = 0;

    const data = getEconomy(message.author.id);
    let amountText = '';

    if (args[1]) {
      const amount = args[1] === 'all' ? data.coins : parseInt(args[1]);
      if (!isNaN(amount) && amount > 0 && amount <= data.coins) {
        if (WINS[choice] === botChoice) { net = amount; data.coins += amount; result = 'Gagné'; color = client.config.colorSuccess; }
        else if (choice === botChoice) { net = 0; result = 'Égalité'; color = client.config.colorWarn; }
        else { net = -amount; data.coins -= amount; result = 'Perdu'; color = client.config.colorError; }
        saveEconomy(message.author.id, data);
        amountText = `\n${net > 0 ? `🎉 +**${net.toLocaleString()} coins**` : net < 0 ? `💸 -**${Math.abs(net).toLocaleString()} coins**` : '🤝 Mise remboursée'}\n💰 Solde : **${data.coins.toLocaleString()} coins**`;
      }
    }

    if (!result) {
      if (WINS[choice] === botChoice) { result = 'Gagné'; color = client.config.colorSuccess; }
      else if (choice === botChoice) { result = 'Égalité'; color = client.config.colorWarn; }
      else { result = 'Perdu'; color = client.config.colorError; }
    }

    const embed = new EmbedBuilder()
      .setColor(color)
      .setTitle(`✂️ Pierre-Feuille-Ciseaux — ${result} !`)
      .setDescription(`${CHOICES[choice]} Toi **vs** Bot ${CHOICES[botChoice]}${amountText}`)
      .setTimestamp();

    message.reply({ embeds: [embed] });
  },
};
