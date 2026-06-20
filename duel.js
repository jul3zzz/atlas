const { EmbedBuilder, ActionRowBuilder, ButtonBuilder, ButtonStyle, ComponentType } = require('discord.js');
const { getEconomy, saveEconomy } = require('../../utils/database');
const { error, warn } = require('../../utils/embed');

module.exports = {
  name: 'duel',
  description: 'Défier un autre joueur pour des coins',
  usage: '*duel @utilisateur <montant>',
  category: 'Jeux',
  async execute(message, args, client) {
    const target = message.mentions.members.first();
    if (!target || target.user.bot || target.id === message.author.id)
      return message.reply({ embeds: [error('Erreur', 'Mentionne un autre joueur valide.')] });

    const amount = parseInt(args[1]);
    if (isNaN(amount) || amount <= 0)
      return message.reply({ embeds: [error('Erreur', 'Précise un montant valide.')] });

    const challengerData = getEconomy(message.author.id);
    const targetData = getEconomy(target.id);

    if (challengerData.coins < amount)
      return message.reply({ embeds: [error('Fonds insuffisants', `Tu n'as que **${challengerData.coins.toLocaleString()} coins**.`)] });

    const embed = new EmbedBuilder()
      .setColor(client.config.colorWarn)
      .setTitle('⚔️ Défi !')
      .setDescription(`${message.author} défie ${target} pour **${amount.toLocaleString()} coins** !\n\n${target}, acceptes-tu le défi ?`)
      .setTimestamp();

    const row = new ActionRowBuilder().addComponents(
      new ButtonBuilder().setCustomId('accept').setLabel('✅ Accepter').setStyle(ButtonStyle.Success),
      new ButtonBuilder().setCustomId('decline').setLabel('❌ Refuser').setStyle(ButtonStyle.Danger),
    );

    const msg = await message.reply({ embeds: [embed], components: [row] });
    const collector = msg.createMessageComponentCollector({ componentType: ComponentType.Button, time: 30000, filter: i => i.user.id === target.id });

    collector.on('collect', async (i) => {
      collector.stop();
      if (i.customId === 'decline') {
        return i.update({ embeds: [warn('Défi refusé', `${target.user.username} a refusé le défi.`)], components: [] });
      }

      if (targetData.coins < amount)
        return i.update({ embeds: [error('Fonds insuffisants', `${target.user.username} n'a pas assez de coins.`)], components: [] });

      const challengerRoll = Math.floor(Math.random() * 100) + 1;
      const targetRoll = Math.floor(Math.random() * 100) + 1;

      let winner, loser, winnerData, loserData;
      if (challengerRoll >= targetRoll) {
        [winner, loser, winnerData, loserData] = [message.author, target.user, challengerData, targetData];
      } else {
        [winner, loser, winnerData, loserData] = [target.user, message.author, targetData, challengerData];
      }

      winnerData.coins += amount;
      loserData.coins -= amount;
      saveEconomy(winner.id, winnerData);
      saveEconomy(loser.id, loserData);

      const resultEmbed = new EmbedBuilder()
        .setColor(client.config.colorSuccess)
        .setTitle('⚔️ Résultat du Duel !')
        .setDescription([
          `🎲 ${message.author.username} : **${challengerRoll}**`,
          `🎲 ${target.user.username} : **${targetRoll}**`,
          '',
          `🏆 **${winner.username}** remporte **${amount.toLocaleString()} coins** !`,
        ].join('\n'))
        .setTimestamp();

      i.update({ embeds: [resultEmbed], components: [] });
    });

    collector.on('end', (_, reason) => {
      if (reason === 'time') msg.edit({ embeds: [warn('Défi expiré', 'Le défi n\'a pas été accepté à temps.')], components: [] }).catch(() => {});
    });
  },
};
