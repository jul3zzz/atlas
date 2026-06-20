const { EmbedBuilder } = require('discord.js');
const { getLevel, saveLevel, xpForLevel, getLevelConfig, getEconomy, saveEconomy, getSettings } = require('../utils/database');

module.exports = {
  name: 'messageCreate',
  async execute(message, client) {
    if (message.author.bot || !message.guild) return;

    const settings = getSettings(message.guild.id);

    // ─── XP / LEVELING ────────────────────────────────────────────────────────
    if (!settings.levelingEnabled) {
      const prefix = client.prefix;
      if (!message.content.startsWith(prefix)) return;
      const args = message.content.slice(prefix.length).trim().split(/ +/);
      const commandName = args.shift().toLowerCase();
      const command = client.commands.get(commandName);
      if (!command) return;
      try { await command.execute(message, args, client); } catch (err) { console.error(err); }
      return;
    }

    const levelData = getLevel(message.author.id, message.guild.id);
    const now = Date.now();
    const cooldown = client.config.leveling.xpCooldown;

    if (now - levelData.lastXp > cooldown) {
      const [min, max] = client.config.leveling.xpPerMessage;
      const gained = Math.floor(Math.random() * (max - min + 1)) + min;
      levelData.xp += gained;
      levelData.lastXp = now;

      const needed = xpForLevel(levelData.level);
      if (levelData.xp >= needed) {
        levelData.xp -= needed;
        levelData.level += 1;

        const config = getLevelConfig(message.guild.id);
        const newLevel = levelData.level;

        // Récompenses configurées pour ce niveau
        const reward = config.rewards?.[newLevel];
        let rewardText = '';

        if (reward) {
          if (reward.coins) {
            const eco = getEconomy(message.author.id);
            eco.coins += reward.coins;
            saveEconomy(message.author.id, eco);
            rewardText += `\n💰 Récompense : **+${reward.coins.toLocaleString()} coins**`;
          }
          if (reward.roleId) {
            const role = message.guild.roles.cache.get(reward.roleId);
            if (role) {
              await message.member.roles.add(role).catch(() => {});
              rewardText += `\n🎭 Rôle obtenu : **${role.name}**`;
            }
          }
        }

        const embed = new EmbedBuilder()
          .setColor(client.config.color)
          .setTitle('⬆️ Level Up !')
          .setDescription(`Félicitations ${message.author} ! Tu passes au **niveau ${newLevel}** !${rewardText}`)
          .setThumbnail(message.author.displayAvatarURL())
          .setTimestamp()
          .setFooter({ text: client.config.botName });

        // Envoyer dans le salon configuré ou dans le salon actuel
        const targetChannel = config.channelId
          ? message.guild.channels.cache.get(config.channelId) || message.channel
          : message.channel;

        targetChannel.send({ embeds: [embed] });
      }
      saveLevel(message.author.id, message.guild.id, levelData);
    }

    // ─── COMMANDES ────────────────────────────────────────────────────────────
    const prefix = client.prefix;
    if (!message.content.startsWith(prefix)) return;

    const args = message.content.slice(prefix.length).trim().split(/ +/);
    const commandName = args.shift().toLowerCase();

    const command = client.commands.get(commandName);
    if (!command) return;

    // Bloquer les commandes économie si désactivée
    const ecoCommands = ['balance', 'bal', 'money', 'coins', 'daily', 'work', 'travailler', 'boulot', 'bank', 'banque', 'pay', 'give', 'donner', 'richlist', 'topcoins', 'rich', 'addcoins', 'donnercoins', 'givecoins', 'shop', 'boutique', 'magasin', 'coinflip', 'cf', 'pile', 'slots', 'slot', 'machine', 'blackjack', 'bj', '21', 'rps', 'shifumi', 'chifoumi', 'duel'];
    const levelCmds = ['rank', 'niveau', 'level', 'xp', 'leaderboard', 'lb', 'top', 'classement', 'addxp', 'donnerxp', 'givexp', 'setxp'];
    const { error } = require('../utils/embed');

    if (ecoCommands.includes(commandName) && !settings.economyEnabled)
      return message.reply({ embeds: [error('Économie désactivée', 'Le système d\'économie est désactivé sur ce serveur.')] });

    if (levelCmds.includes(commandName) && !settings.levelingEnabled)
      return message.reply({ embeds: [error('Leveling désactivé', 'Le système de leveling est désactivé sur ce serveur.')] });

    try {
      await command.execute(message, args, client);
    } catch (err) {
      console.error(err);
      message.reply({ embeds: [error('Erreur', 'Une erreur est survenue lors de l\'exécution de la commande.')] });
    }
  },
};
