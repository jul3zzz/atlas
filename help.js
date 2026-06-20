const { EmbedBuilder } = require('discord.js');

const CATEGORIES = {
  'Modération': '🔨',
  'Accueil': '👋',
  'Économie': '💰',
  'Jeux': '🎮',
  'Leveling': '📊',
  'Général': 'ℹ️',
};

module.exports = {
  name: 'help',
  aliases: ['aide', 'h'],
  description: 'Afficher la liste des commandes',
  usage: '*help [commande]',
  category: 'Général',
  async execute(message, args, client) {
    if (args[0]) {
      const cmd = client.commands.get(args[0].toLowerCase());
      if (!cmd)
        return message.reply(`❌ Commande \`${args[0]}\` introuvable.`);

      const embed = new EmbedBuilder()
        .setColor(client.config.color)
        .setTitle(`📖 ${cmd.name}`)
        .addFields(
          { name: 'Description', value: cmd.description || 'N/A' },
          { name: 'Usage', value: `\`${cmd.usage || `*${cmd.name}`}\`` },
          { name: 'Catégorie', value: cmd.category || 'Général' },
        );
      if (cmd.aliases?.length) embed.addFields({ name: 'Alias', value: cmd.aliases.map(a => `\`${a}\``).join(', ') });
      return message.reply({ embeds: [embed] });
    }

    const grouped = {};
    for (const [, cmd] of client.commands) {
      if (cmd.aliases?.includes(cmd.name) && cmd.name !== cmd.name) continue;
      const cat = cmd.category || 'Général';
      if (!grouped[cat]) grouped[cat] = new Set();
      grouped[cat].add(cmd.name);
    }

    const embed = new EmbedBuilder()
      .setColor(client.config.color)
      .setTitle(`📚 Commandes de ${client.config.botName}`)
      .setDescription(`Préfixe : \`${client.prefix}\` | Utilise \`*help <commande>\` pour plus de détails.`)
      .setThumbnail(client.user.displayAvatarURL())
      .setTimestamp()
      .setFooter({ text: client.config.botName });

    for (const [cat, cmds] of Object.entries(grouped)) {
      const icon = CATEGORIES[cat] || '•';
      embed.addFields({ name: `${icon} ${cat}`, value: [...cmds].map(c => `\`${c}\``).join(', ') });
    }

    message.reply({ embeds: [embed] });
  },
};
