const { success, error } = require('../../utils/embed');

module.exports = {
  name: 'clear',
  aliases: ['purge'],
  description: 'Supprimer des messages en masse',
  usage: '*clear <nombre> [@utilisateur]',
  category: 'Modération',
  async execute(message, args, client) {
    if (!message.member.permissions.has('ManageMessages'))
      return message.reply({ embeds: [error('Permission refusée', 'Tu n\'as pas la permission de supprimer des messages.')] });

    const amount = parseInt(args[0]);
    if (isNaN(amount) || amount < 1 || amount > 100)
      return message.reply({ embeds: [error('Erreur', 'Précise un nombre entre 1 et 100.')] });

    await message.delete().catch(() => {});

    const target = message.mentions.users.first();
    let messages = await message.channel.messages.fetch({ limit: 100 });
    messages = messages.filter(m => !m.pinned);

    if (target) messages = messages.filter(m => m.author.id === target.id);
    messages = [...messages.values()].slice(0, amount);

    if (!messages.length)
      return message.channel.send({ embeds: [error('Erreur', 'Aucun message à supprimer.')] }).then(m => setTimeout(() => m.delete(), 3000));

    await message.channel.bulkDelete(messages, true).catch(() => {});

    const reply = await message.channel.send({ embeds: [success('Messages supprimés', `**${messages.length}** message(s) ont été supprimés.`)] });
    setTimeout(() => reply.delete().catch(() => {}), 4000);
  },
};
