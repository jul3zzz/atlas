module.exports = {
  name: 'ready',
  once: true,
  execute(client) {
    console.log(`✅ ${client.config.botName} est connecté en tant que ${client.user.tag}`);
    client.user.setActivity(`*help | [*]Arukami`, { type: 3 });
  },
};
