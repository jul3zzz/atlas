const { info, error } = require('../../utils/embed');
const { getEconomy, getSettings } = require('../../utils/database');
const { EmbedBuilder } = require('discord.js');

module.exports = {
  name: 'balance',
  aliases: ['bal', 'money', 'coins'],
  description: 'Voir ton solde ou celui d\'un autre membre',
  usage: '*balance [@utilisateur]',
  category: 'Économie',
  async execute(message, args, client) {
    if (!getSettings(message.guild.id).economyEnabled)
      return message.reply({ embeds: [error('Économie désactivée', 'Le système d\'économie est désactivé sur ce serveur.')] });
    const target = message.mentions.users.first() || message.author;
    const data = getEconomy(target.id);
    const total = data.coins + data.bank;

    const embed = new EmbedBuilder()
      .setColor(client.config.color)
      .setTitle(`💰 Solde de ${target.username}`)
      .setThumbnail(target.displayAvatarURL())
      .addFields(
        { name: '👛 Portefeuille', value: `**${data.coins.toLocaleString()}** coins`, inline: true },
        { name: '🏦 Banque', value: `**${data.bank.toLocaleString()}** coins`, inline: true },
        { name: '📊 Total', value: `**${total.toLocaleString()}** coins`, inline: true },
      )
      .setTimestamp()
      .setFooter({ text: client.config.botName });

    message.reply({ embeds: [embed] });
  },
};
