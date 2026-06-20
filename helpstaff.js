const { EmbedBuilder } = require('discord.js');

module.exports = {
  name: 'helpstaff',
  aliases: ['staffhelp', 'adminhelp', 'helpAdmin'],
  description: '[Admin] Voir toutes les commandes réservées au staff',
  usage: '*helpstaff [page]',
  category: 'Général',
  async execute(message, args, client) {
    if (!message.member.permissions.has('Administrator'))
      return message.reply({ embeds: [new EmbedBuilder().setColor('#E74C3C').setTitle('❌ Permission refusée').setDescription('Seuls les administrateurs peuvent voir cette page.')] });

    const pages = [
      // PAGE 1 — Modération
      new EmbedBuilder()
        .setColor(client.config.color)
        .setTitle('👑 Commandes Staff — Page 1/4 — Modération')
        .setDescription('Utilise `*helpstaff <page>` pour naviguer entre les pages.')
        .setThumbnail(client.user.displayAvatarURL())
        .addFields(
          {
            name: '🔨 Modération',
            value: [
              '`*ban @utilisateur [raison]` — bannir un membre',
              '`*kick @utilisateur [raison]` — expulser un membre',
              '`*mute @utilisateur <durée> [raison]` — muter un membre *(ex: 10m, 2h, 1d)*',
              '`*unmute @utilisateur` — retirer le mute d\'un membre',
              '`*warn @utilisateur [raison]` — avertir un membre',
              '`*warn list @utilisateur` — voir les avertissements d\'un membre',
              '`*warn remove @utilisateur <id>` — supprimer un avertissement',
              '`*clear <nombre> [@utilisateur]` — supprimer des messages *(1-100)*',
              '`*slowmode <secondes>` — définir le slowmode *(0 = désactiver)*',
            ].join('\n'),
          },
        )
        .setTimestamp()
        .setFooter({ text: `${client.config.botName} • Staff | Page 1/4` }),

      // PAGE 2 — Accueil & Leveling
      new EmbedBuilder()
        .setColor(client.config.color)
        .setTitle('👑 Commandes Staff — Page 2/4 — Accueil & Leveling')
        .setDescription('Utilise `*helpstaff <page>` pour naviguer entre les pages.')
        .addFields(
          {
            name: '👋 Accueil — `*welcome`',
            value: [
              '`*welcome` — voir la configuration actuelle',
              '`*welcome setchannel #salon` — définir le salon de bienvenue',
              '`*welcome setrole @rôle` — rôle donné automatiquement aux nouveaux membres',
              '`*welcome setmessage <texte>` — personnaliser le message',
              '> Variables : `{user}` `{server}` `{count}` `{tag}`',
              '`*welcome setgif <url>` — ajouter un GIF sous le message de bienvenue',
              '`*welcome removegif` — supprimer le GIF de bienvenue',
              '`*welcome disable` — désactiver le système de bienvenue',
              '`*welcome test` — envoyer un message de test',
            ].join('\n'),
          },
          {
            name: '📊 Leveling — `*levelconfig`',
            value: [
              '`*levelconfig` — voir la configuration actuelle',
              '`*levelconfig setchannel #salon` — salon des messages de level up',
              '`*levelconfig resetchannel` — remettre le salon par défaut',
              '`*levelconfig addreward <niveau> coins:<montant>` — récompense coins',
              '`*levelconfig addreward <niveau> @rôle` — récompense rôle',
              '`*levelconfig addreward <niveau> coins:<montant> @rôle` — coins + rôle',
              '`*levelconfig removereward <niveau>` — supprimer la récompense d\'un niveau',
              '`*levelconfig listrewards` — voir toutes les récompenses',
              '`*addxp @utilisateur <montant>` — donner/retirer de l\'XP *(négatif pour retirer)*',
              '`*setxp @utilisateur <montant>` — définir l\'XP exact d\'un membre',
            ].join('\n'),
          },
        )
        .setTimestamp()
        .setFooter({ text: `${client.config.botName} • Staff | Page 2/4` }),

      // PAGE 3 — Économie & Boutique
      new EmbedBuilder()
        .setColor(client.config.color)
        .setTitle('👑 Commandes Staff — Page 3/4 — Économie & Boutique')
        .setDescription('Utilise `*helpstaff <page>` pour naviguer entre les pages.')
        .addFields(
          {
            name: '💰 Économie',
            value: [
              '`*addcoins @utilisateur <montant>` — donner des coins *(négatif pour retirer)*',
            ].join('\n'),
          },
          {
            name: '🛒 Boutique — `*shop`',
            value: [
              '`*shop add <prix> <nom>` — ajouter un article basique',
              '`*shop add <prix> <nom> | <description>` — avec une description',
              '`*shop add <prix> <nom> @rôle` — article qui donne un rôle',
              '`*shop add <prix> <nom> 👑` — avec un emoji personnalisé',
              '`*shop add 500 VIP | Accès salon VIP @VIP 👑` — exemple complet',
              '`*shop edit <id> prix <montant>` — modifier le prix',
              '`*shop edit <id> nom <nouveau nom>` — modifier le nom',
              '`*shop edit <id> description <texte>` — modifier la description',
              '`*shop edit <id> emoji <emoji>` — modifier l\'emoji',
              '`*shop edit <id> role @rôle` — modifier le rôle attribué',
              '`*shop remove <id>` — supprimer un article',
            ].join('\n'),
          },
          {
            name: '⚙️ Systèmes — `*toggle`',
            value: [
              '`*toggle` — voir l\'état actuel des systèmes',
              '`*toggle economy` — activer/désactiver l\'économie',
              '`*toggle leveling` — activer/désactiver le leveling',
            ].join('\n'),
          },
          {
            name: '📨 Embeds — `*embed`',
            value: [
              '`*embed` — ouvrir le créateur interactif d\'embed',
              '> **Titre** — définir le titre',
              '> **Description** — texte principal *(utilise `\\n` pour les sauts de ligne)*',
              '> **Couleur** — code hex ex: `#FF5733`',
              '> **Auteur** — texte affiché en haut de l\'embed',
              '> **Image** — grande image sous la description',
              '> **GIF** — GIF animé sous la description *(remplace l\'image)*',
              '> **Miniature** — petite image en haut à droite',
              '> **Footer** — texte en bas de l\'embed',
              '> **Salon cible** — salon où envoyer l\'embed',
              '> **Aperçu** — voir le rendu avant envoi',
              '`*embed send #salon Titre | Description` — envoi rapide sans menu',
            ].join('\n'),
          },
        )
        .setTimestamp()
        .setFooter({ text: `${client.config.botName} • Staff | Page 3/4` }),

      // PAGE 4 — Récapitulatif de toutes les commandes
      new EmbedBuilder()
        .setColor(client.config.color)
        .setTitle('👑 Commandes Staff — Page 4/4 — Récapitulatif')
        .setDescription('Vue rapide de toutes les commandes staff.')
        .addFields(
          {
            name: '🔨 Modération',
            value: '`*ban` `*kick` `*mute` `*unmute` `*warn` `*clear` `*slowmode`',
          },
          {
            name: '👋 Accueil',
            value: '`*welcome setchannel` `*welcome setrole` `*welcome setmessage` `*welcome disable` `*welcome test`',
          },
          {
            name: '📊 Leveling',
            value: '`*levelconfig setchannel` `*levelconfig resetchannel` `*levelconfig addreward` `*levelconfig removereward` `*levelconfig listrewards` `*addxp` `*setxp`',
          },
          {
            name: '💰 Économie & Boutique',
            value: '`*addcoins` `*shop add` `*shop edit` `*shop remove`',
          },
          {
            name: '⚙️ Systèmes',
            value: '`*toggle economy` `*toggle leveling`',
          },
          {
            name: '📨 Embeds',
            value: '`*embed` — créateur interactif | `*embed send #salon Titre | Description` — envoi rapide',
          },
        )
        .setTimestamp()
        .setFooter({ text: `${client.config.botName} • Staff | Page 4/4` }),
    ];

    const page = Math.max(1, Math.min(parseInt(args[0]) || 1, pages.length)) - 1;
    message.reply({ embeds: [pages[page]] });
  },
};
