const { success, error } = require('../../utils/embed');
const { getLevel, saveLevel, xpForLevel } = require('../../utils/database');
const { EmbedBuilder } = require('discord.js');

module.exports = {
  name: 'addxp',
  aliases: ['donnerxp', 'givexp'],
  description: '[Admin] Donner de l\'XP à un membre',
  usage: '*addxp @utilisateur <montant>',
  category: 'Leveling',
  async execute(message, args, client) {
    if (!message.member.permissions.has('Administrator'))
      return message.reply({ embeds: [error('Permission refusée', 'Seuls les administrateurs peuvent utiliser cette commande.')] });

    const target = message.mentions.members.first();
    if (!target || target.user.bot)
      return message.reply({ embeds: [error('Erreur', 'Mentionne un utilisateur valide.')] });

    const amount = parseInt(args[1]);
    if (isNaN(amount) || amount === 0)
      return message.reply({ embeds: [error('Erreur', 'Précise un montant valide (positif pour donner, négatif pour retirer).')] });

    const data = getLevel(target.id, message.guild.id);
    const oldLevel = data.level;
    data.xp += amount;
    if (data.xp < 0) data.xp = 0;

    // Gérer les level up / level down
    while (data.xp >= xpForLevel(data.level)) {
      data.xp -= xpForLevel(data.level);
      data.level += 1;
    }
    while (data.level > 0 && data.xp < 0) {
      data.level -= 1;
      data.xp += xpForLevel(data.level);
    }

    saveLevel(target.id, message.guild.id, data);

    const action = amount >= 0 ? `reçu **+${amount} XP**` : `perdu **${Math.abs(amount)} XP**`;
    let desc = `${target} a ${action}.\n⭐ Niveau : **${data.level}** | ✨ XP : **${data.xp}**`;

    if (data.level > oldLevel) desc += `\n\n⬆️ **Level Up ! Niveau ${oldLevel} → ${data.level}**`;
    if (data.level < oldLevel) desc += `\n\n⬇️ **Level Down ! Niveau ${oldLevel} → ${data.level}**`;

    message.reply({ embeds: [success('XP modifié', desc)] });
  },
};
