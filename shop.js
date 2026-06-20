const { EmbedBuilder } = require('discord.js');
const { getShop, saveShop, getEconomy, saveEconomy, getSettings } = require('../../utils/database');
const { success, error, info } = require('../../utils/embed');

module.exports = {
  name: 'shop',
  aliases: ['boutique', 'magasin'],
  description: 'Afficher la boutique ou la gérer (admin)',
  usage: '*shop | *shop add | *shop remove | *shop buy',
  category: 'Économie',
  async execute(message, args, client) {
    const settings = getSettings(message.guild.id);
    if (!settings.economyEnabled)
      return message.reply({ embeds: [error('Économie désactivée', 'Le système d\'économie est désactivé sur ce serveur.')] });

    const sub = args[0]?.toLowerCase();
    const isAdmin = message.member.permissions.has('Administrator');
    const items = getShop(message.guild.id);

    // ── Afficher la boutique ─────────────────────────────────────────────────
    if (!sub || sub === 'list') {
      if (!items.length)
        return message.reply({ embeds: [info('🛒 Boutique', 'La boutique est vide.\n\nUn administrateur peut ajouter des articles avec `*shop add`.')] });

      const embed = new EmbedBuilder()
        .setColor(client.config.color)
        .setTitle(`🛒 Boutique de ${message.guild.name}`)
        .setDescription('Utilise `*shop buy <id>` pour acheter un article.')
        .setTimestamp()
        .setFooter({ text: client.config.botName });

      for (const item of items) {
        const parts = [];
        if (item.roleId) parts.push(`🎭 Rôle : <@&${item.roleId}>`);
        if (item.description) parts.push(`📝 ${item.description}`);
        embed.addFields({
          name: `[${item.id}] ${item.emoji || '🛍️'} ${item.name} — 💰 ${item.price.toLocaleString()} coins`,
          value: parts.join('\n') || '​',
        });
      }

      return message.reply({ embeds: [embed] });
    }

    // ── Ajouter un article (admin) ────────────────────────────────────────────
    if (sub === 'add') {
      if (!isAdmin) return message.reply({ embeds: [error('Permission refusée', 'Seuls les administrateurs peuvent ajouter des articles.')] });

      // *shop add <prix> <nom> [description]
      // Options: role:@role emoji:🎭
      const price = parseInt(args[1]);
      if (isNaN(price) || price <= 0)
        return message.reply({ embeds: [error('Erreur', 'Usage : `*shop add <prix> <nom> [description]`\nEx: `*shop add 500 VIP Accès au salon VIP @VIP 👑`')] });

      const rest = args.slice(2).join(' ');
      const roleMatch = message.mentions.roles.first();
      const emojiMatch = rest.match(/(\p{Emoji_Presentation}|\p{Extended_Pictographic})/u);

      // Nettoyer le nom de l'emoji et la mention
      let name = rest
        .replace(/<@&\d+>/g, '')
        .replace(/(\p{Emoji_Presentation}|\p{Extended_Pictographic})/gu, '')
        .trim();

      if (!name) return message.reply({ embeds: [error('Erreur', 'Précise un nom pour l\'article.')] });

      // Séparer nom et description (séparé par | )
      const [itemName, ...descParts] = name.split('|');
      const description = descParts.join('|').trim() || null;

      const id = items.length ? Math.max(...items.map(i => i.id)) + 1 : 1;
      const item = {
        id,
        name: itemName.trim(),
        price,
        emoji: emojiMatch ? emojiMatch[0] : '🛍️',
        description,
        roleId: roleMatch?.id || null,
      };

      items.push(item);
      saveShop(message.guild.id, items);

      const parts = [];
      if (item.roleId) parts.push(`🎭 Rôle : <@&${item.roleId}>`);
      if (item.description) parts.push(`📝 ${item.description}`);

      return message.reply({ embeds: [success('Article ajouté', `**[${id}] ${item.emoji} ${item.name}** ajouté à la boutique pour **${price.toLocaleString()} coins**${parts.length ? '\n' + parts.join('\n') : ''}`)] });
    }

    // ── Modifier un article (admin) ───────────────────────────────────────────
    if (sub === 'edit') {
      if (!isAdmin) return message.reply({ embeds: [error('Permission refusée', 'Seuls les administrateurs peuvent modifier des articles.')] });

      const id = parseInt(args[1]);
      const idx = items.findIndex(i => i.id === id);
      if (isNaN(id) || idx === -1)
        return message.reply({ embeds: [error('Erreur', 'Article introuvable. Utilise `*shop` pour voir les IDs.')] });

      const field = args[2]?.toLowerCase();
      const value = args.slice(3).join(' ');

      if (field === 'prix' || field === 'price') {
        const p = parseInt(value);
        if (isNaN(p) || p <= 0) return message.reply({ embeds: [error('Erreur', 'Prix invalide.')] });
        items[idx].price = p;
      } else if (field === 'nom' || field === 'name') {
        if (!value) return message.reply({ embeds: [error('Erreur', 'Précise un nom.')] });
        items[idx].name = value;
      } else if (field === 'description') {
        items[idx].description = value || null;
      } else if (field === 'emoji') {
        items[idx].emoji = value || '🛍️';
      } else if (field === 'role') {
        const role = message.mentions.roles.first();
        items[idx].roleId = role?.id || null;
      } else {
        return message.reply({ embeds: [error('Erreur', 'Champs modifiables : `prix`, `nom`, `description`, `emoji`, `role`')] });
      }

      saveShop(message.guild.id, items);
      return message.reply({ embeds: [success('Article modifié', `L'article **[${id}] ${items[idx].name}** a été mis à jour.`)] });
    }

    // ── Supprimer un article (admin) ──────────────────────────────────────────
    if (sub === 'remove' || sub === 'delete' || sub === 'supprimer') {
      if (!isAdmin) return message.reply({ embeds: [error('Permission refusée', 'Seuls les administrateurs peuvent supprimer des articles.')] });

      const id = parseInt(args[1]);
      const idx = items.findIndex(i => i.id === id);
      if (isNaN(id) || idx === -1)
        return message.reply({ embeds: [error('Erreur', 'Article introuvable. Utilise `*shop` pour voir les IDs.')] });

      const removed = items.splice(idx, 1)[0];
      saveShop(message.guild.id, items);
      return message.reply({ embeds: [success('Article supprimé', `**${removed.emoji} ${removed.name}** a été retiré de la boutique.`)] });
    }

    // ── Acheter un article ────────────────────────────────────────────────────
    if (sub === 'buy' || sub === 'acheter') {
      const id = parseInt(args[1]);
      const item = items.find(i => i.id === id);
      if (isNaN(id) || !item)
        return message.reply({ embeds: [error('Erreur', 'Article introuvable. Utilise `*shop` pour voir les IDs.')] });

      const eco = getEconomy(message.author.id);
      if (eco.coins < item.price)
        return message.reply({ embeds: [error('Fonds insuffisants', `Cet article coûte **${item.price.toLocaleString()} coins** et tu n'as que **${eco.coins.toLocaleString()} coins**.`)] });

      eco.coins -= item.price;
      saveEconomy(message.author.id, eco);

      let rewardText = `💰 **-${item.price.toLocaleString()} coins** | Solde restant : **${eco.coins.toLocaleString()} coins**`;

      if (item.roleId) {
        const role = message.guild.roles.cache.get(item.roleId);
        if (role) {
          await message.member.roles.add(role).catch(() => {});
          rewardText += `\n🎭 Rôle **${role.name}** attribué !`;
        }
      }

      return message.reply({ embeds: [success(`Achat réussi — ${item.emoji} ${item.name}`, rewardText)] });
    }

    return message.reply({ embeds: [error('Commande inconnue', 'Utilise `*shop` pour voir la boutique.')] });
  },
};
