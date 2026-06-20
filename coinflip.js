const { EmbedBuilder } = require('discord.js');
const { getEconomy, saveEconomy } = require('../../utils/database');
const { error } = require('../../utils/embed');

module.exports = {
  name: 'coinflip',
  aliases: ['cf', 'pile'],
  description: 'Parie des coins sur pile ou face',
  usage: '*coinflip <pile|face> <montant>',
  category: 'Jeux',
  async execute(message, args, client) {
    const choice = args[0]?.toLowerCase();
    if (!['pile', 'face', 'heads', 'tails'].includes(choice))
      return message.reply({ embeds: [error('Erreur', 'Choisis `pile` ou `face`.')] });

    const data = getEconomy(message.author.id);
    const amount = args[1] === 'all' ? data.coins : parseInt(args[1]);

    if (isNaN(amount) || amount <= 0)
      return message.reply({ embeds: [error('Erreur', 'Précise un montant valide.')] });
    if (amount > data.coins)
      return message.reply({ embeds: [error('Fonds insuffisants', `Tu n'as que **${data.coins.toLocaleString()} coins**.`)] });

    const result = Math.random() < 0.5 ? 'pile' : 'face';
    const playerChoice = (choice === 'heads') ? 'pile' : (choice === 'tails') ? 'face' : choice;
    const win = playerChoice === result;

    if (win) data.coins += amount;
    else data.coins -= amount;
    saveEconomy(message.author.id, data);

    const embed = new EmbedBuilder()
      .setColor(win ? client.config.colorSuccess : client.config.colorError)
      .setTitle(win ? '🪙 Tu as gagné !' : '🪙 Tu as perdu !')
      .setDescription([
        `**Ton choix :** ${playerChoice} | **Résultat :** ${result}`,
        win ? `🎉 +**${amount.toLocaleString()} coins**` : `💸 -**${amount.toLocaleString()} coins**`,
        `💰 Nouveau solde : **${data.coins.toLocaleString()} coins**`,
      ].join('\n'))
      .setTimestamp();

    message.reply({ embeds: [embed] });
  },
};
