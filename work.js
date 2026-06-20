const { success, warn } = require('../../utils/embed');
const { getEconomy, saveEconomy } = require('../../utils/database');

const jobs = [
  'as livré des pizzas', 'as codé toute la nuit', 'as vendu des potions', 'as gardé un château',
  'as enseigné à l\'académie', 'as chassé des monstres', 'as réparé des armures', 'as tenu une boutique',
  'as pêché au lac', 'as miné dans les montagnes', 'as fait du commerce à la foire',
];

module.exports = {
  name: 'work',
  aliases: ['travailler', 'boulot'],
  description: 'Travailler pour gagner des coins',
  usage: '*work',
  category: 'Économie',
  async execute(message, args, client) {
    const data = getEconomy(message.author.id);
    const now = Date.now();
    const cooldown = client.config.economy.workCooldown;
    const remaining = cooldown - (now - data.lastWork);

    if (remaining > 0) {
      const m = Math.floor(remaining / 60000);
      const s = Math.floor((remaining % 60000) / 1000);
      return message.reply({ embeds: [warn('Fatigué', `Tu as déjà travaillé récemment.\nReviens dans **${m}m ${s}s**.`)] });
    }

    const { workMin, workMax } = client.config.economy;
    const earned = Math.floor(Math.random() * (workMax - workMin + 1)) + workMin;
    const job = jobs[Math.floor(Math.random() * jobs.length)];

    data.coins += earned;
    data.lastWork = now;
    saveEconomy(message.author.id, data);

    message.reply({ embeds: [success('Travail terminé', `Tu ${job} et tu as gagné **${earned} coins** ! 💼\n💰 Solde : **${data.coins.toLocaleString()} coins**`)] });
  },
};
