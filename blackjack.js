const { EmbedBuilder, ActionRowBuilder, ButtonBuilder, ButtonStyle, ComponentType } = require('discord.js');
const { getEconomy, saveEconomy } = require('../../utils/database');
const { error } = require('../../utils/embed');

const SUITS = ['♠️', '♥️', '♦️', '♣️'];
const RANKS = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'];

function newDeck() {
  const deck = [];
  for (const s of SUITS) for (const r of RANKS) deck.push({ rank: r, suit: s });
  return deck.sort(() => Math.random() - 0.5);
}

function cardValue(card) {
  if (['J', 'Q', 'K'].includes(card.rank)) return 10;
  if (card.rank === 'A') return 11;
  return parseInt(card.rank);
}

function handValue(hand) {
  let total = hand.reduce((s, c) => s + cardValue(c), 0);
  let aces = hand.filter(c => c.rank === 'A').length;
  while (total > 21 && aces > 0) { total -= 10; aces--; }
  return total;
}

function showCards(hand, hideSecond = false) {
  return hand.map((c, i) => (hideSecond && i === 1) ? '🂠' : `${c.rank}${c.suit}`).join(' ');
}

module.exports = {
  name: 'blackjack',
  aliases: ['bj', '21'],
  description: 'Jouer au Blackjack contre le bot',
  usage: '*blackjack <montant>',
  category: 'Jeux',
  async execute(message, args, client) {
    const data = getEconomy(message.author.id);
    const amount = args[0] === 'all' ? data.coins : parseInt(args[0]);

    if (isNaN(amount) || amount <= 0)
      return message.reply({ embeds: [error('Erreur', 'Précise un montant valide.')] });
    if (amount > data.coins)
      return message.reply({ embeds: [error('Fonds insuffisants', `Tu n'as que **${data.coins.toLocaleString()} coins**.`)] });

    const deck = newDeck();
    const playerHand = [deck.pop(), deck.pop()];
    const dealerHand = [deck.pop(), deck.pop()];

    function buildEmbed(ended = false, resultText = '') {
      const pVal = handValue(playerHand);
      const dVal = handValue(dealerHand);
      return new EmbedBuilder()
        .setColor(client.config.color)
        .setTitle('🃏 Blackjack')
        .addFields(
          { name: `Tes cartes (${pVal})`, value: showCards(playerHand), inline: true },
          { name: `Croupier (${ended ? dVal : '?'})`, value: showCards(dealerHand, !ended), inline: true },
        )
        .setDescription(resultText || 'Que veux-tu faire ?')
        .setFooter({ text: `Mise : ${amount.toLocaleString()} coins` })
        .setTimestamp();
    }

    const row = new ActionRowBuilder().addComponents(
      new ButtonBuilder().setCustomId('hit').setLabel('🃏 Tirer').setStyle(ButtonStyle.Primary),
      new ButtonBuilder().setCustomId('stand').setLabel('✋ Rester').setStyle(ButtonStyle.Secondary),
    );

    const msg = await message.reply({ embeds: [buildEmbed()], components: [row] });
    const collector = msg.createMessageComponentCollector({ componentType: ComponentType.Button, time: 60000, filter: i => i.user.id === message.author.id });

    collector.on('collect', async (i) => {
      if (i.customId === 'hit') {
        playerHand.push(deck.pop());
        const pVal = handValue(playerHand);
        if (pVal > 21) {
          data.coins -= amount;
          saveEconomy(message.author.id, data);
          collector.stop();
          return i.update({ embeds: [buildEmbed(true, `💸 **Bust ! Tu as perdu ${amount.toLocaleString()} coins.**\n💰 Solde : ${data.coins.toLocaleString()} coins`)], components: [] });
        }
        await i.update({ embeds: [buildEmbed()], components: [row] });
      } else {
        // Dealer joue
        while (handValue(dealerHand) < 17) dealerHand.push(deck.pop());
        const pVal = handValue(playerHand);
        const dVal = handValue(dealerHand);
        let resultText, net;
        if (dVal > 21 || pVal > dVal) {
          net = amount; data.coins += amount;
          resultText = `🎉 **Tu gagnes ! +${amount.toLocaleString()} coins**`;
        } else if (pVal === dVal) {
          net = 0;
          resultText = `🤝 **Égalité ! Mise remboursée.**`;
        } else {
          net = -amount; data.coins -= amount;
          resultText = `💸 **Tu perds ! -${amount.toLocaleString()} coins**`;
        }
        saveEconomy(message.author.id, data);
        collector.stop();
        i.update({ embeds: [buildEmbed(true, `${resultText}\n💰 Solde : **${data.coins.toLocaleString()} coins**`)], components: [] });
      }
    });

    collector.on('end', (_, reason) => {
      if (reason === 'time') msg.edit({ components: [] }).catch(() => {});
    });
  },
};
