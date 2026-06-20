const { info } = require('../../utils/embed');

module.exports = {
  name: 'ping',
  description: 'Vérifier la latence du bot',
  usage: '*ping',
  category: 'Général',
  async execute(message, args, client) {
    const msg = await message.reply({ embeds: [info('🏓 Pong !', 'Calcul en cours...')] });
    const latency = msg.createdTimestamp - message.createdTimestamp;
    msg.edit({ embeds: [info('🏓 Pong !', `📡 Latence : **${latency}ms**\n💓 API : **${Math.round(client.ws.ping)}ms**`)] });
  },
};
