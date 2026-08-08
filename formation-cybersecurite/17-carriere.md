# Module 17 — Carrière & bug bounty

> **Objectif :** transformer vos compétences en carrière. Comprendre les métiers, décrocher
> le premier poste, réussir les entretiens techniques, se lancer en bug bounty, et durer
> dans un domaine qui évolue vite.
>
> **Niveau 4 — en continu**

---

## 17.1 — La carte des métiers

La cybersécurité n'est pas un métier mais une **famille de métiers**. Vue d'ensemble :

### Défensif (Blue Team)
- **Analyste SOC (N1/N2/N3)** — surveillance, détection, réponse. **La porte d'entrée la plus accessible.**
- **Incident Responder / DFIR** — gestion des incidents, forensics
- **Threat Hunter** — chasse proactive
- **Detection Engineer** — ingénierie des règles de détection
- **CTI Analyst** — renseignement sur la menace
- **Security Engineer / Blue** — construction et durcissement des défenses

### Offensif (Red Team)
- **Pentester** (web, infra, interne, mobile…) — tests d'intrusion
- **Red Teamer** — simulation d'adversaire, furtivité
- **Bug Bounty Hunter** — chasse aux vulnérabilités (indépendant ou complément)
- **Exploit Developer / Vulnerability Researcher** — recherche de 0-day (rare, expert)

### Transverse / conseil / gouvernance
- **Architecte sécurité** — concevoir des systèmes sûrs
- **AppSec Engineer** — sécurité applicative, secure code, DevSecOps
- **Cloud Security Engineer** — sécurité des environnements cloud
- **Consultant sécurité** — audit, conseil, accompagnement
- **GRC / Risk / Compliance / Auditeur** — gouvernance, conformité, audit
- **RSSI / CISO** — direction de la sécurité (objectif de carrière long terme)

> **La réalité du marché :** les postes **défensifs, cloud, AppSec et GRC** sont les plus
> nombreux et les plus accessibles. Le pentest « pur » est prestigieux mais plus concurrentiel
> à l'entrée. Beaucoup de belles carrières commencent en **SOC** ou en **admin sys/DevOps**
> puis bifurquent.

---

## 17.2 — Décrocher le premier poste

C'est souvent l'étape la plus difficile. Le paradoxe « expérience demandée pour un poste
junior » se contourne par la **preuve de pratique**.

### Les voies d'entrée

1. **Alternance / stage** — la meilleure voie en reconversion ou sortie d'études
2. **SOC N1** — recrute en volume, forme sur le tas, excellent tremplin
3. **Poste IT connexe** (support, admin sys, dev, DevOps, réseau) puis transition interne —
   très courant et sous-estimé ; l'expérience IT est un atout majeur en sécurité
4. **Candidature directe** appuyée par un **portfolio solide** (module 15)

### Le CV qui passe

- **Concret et prouvé** : liez chaque compétence à une preuve (write-up, projet, GitHub, homelab)
- **Adapté au poste** : reprenez les mots-clés de l'offre (les filtres ATS)
- **Le homelab compte** : décrivez-le comme une expérience (« conçu et opéré un lab AD +
  SIEM, détecté X attaques »)
- **Certifications** pertinentes (module 16), sans les collectionner
- **Projets et contributions** open source, CTF notables, bug bounty

### Le portfolio (rappel module 15)
Blog technique + GitHub + write-ups = votre meilleur argument. Un lien vaut mille lignes de CV.

### Le réseau
- Conférences (en France : le **FIC**, **Le Hack**, **Barbhack**, **LeHack**, **BSides**,
  meetups **OWASP**), associations, Discord/forums spécialisés
- **CVE, write-ups, contributions** vous rendent visible
- Beaucoup de postes se pourvoient par recommandation avant d'être publiés

---

## 17.3 — Réussir l'entretien technique

Les entretiens sécurité mêlent théorie, pratique et posture.

### Ce qui est évalué
- **Fondamentaux** : réseau (TCP/IP, DNS, HTTP), crypto de base, OWASP, système Linux/Windows
- **Raisonnement** : « comment attaqueriez-vous X ? », « comment détecteriez-vous Y ? » —
  on juge la **démarche**, pas seulement la réponse
- **Pratique** : parfois un exercice (machine à compromettre, analyse de logs, revue de code)
- **Communication** : expliquer clairement, admettre ce qu'on ne sait pas, structurer sa pensée
- **Curiosité et éthique** : votre veille, votre lab, votre rapport à la légalité

### Questions types à préparer
- « Que se passe-t-il quand vous tapez une URL et appuyez sur Entrée ? » (réseau de bout en bout)
- « Expliquez la différence entre chiffrement et hachage. »
- « Comment fonctionne une injection SQL ? Comment la prévenir ? »
- « Décrivez une attaque d'Active Directory de bout en bout. »
- « Comment détecteriez-vous un mouvement latéral ? »
- « Différence entre TCP et UDP ? entre IDS et IPS ? »
- « Parlez-moi d'une vulnérabilité récente qui vous a marqué. » (⇒ **veille**)
- « Racontez-moi une machine/CTF que vous avez résolue. » (⇒ **portfolio**)

### La posture qui fait la différence
- **Structurez** votre raisonnement à voix haute
- **Dites « je ne sais pas »** quand c'est le cas, puis proposez comment vous chercheriez —
  c'est bien plus valorisé que de bluffer (le bluff est éliminatoire dans ce métier)
- Montrez votre **passion** (lab, veille, communauté) : elle compense l'expérience manquante
- Rappelez votre **éthique** : le cadre légal, l'autorisation, la déontologie

---

## 17.4 — Le bug bounty

Chercher des vulnérabilités sur des programmes qui **autorisent et récompensent** cette
recherche. Excellent complément (revenu, apprentissage, portfolio, réputation).

### Les plateformes
- **HackerOne**, **Bugcrowd**, **Intigriti** (fort en Europe), **YesWeHack** (français),
  **Synack** (sur sélection)
- Programmes publics (ouverts à tous) et privés (sur invitation, moins de concurrence)

### La règle absolue : le scope
Chaque programme définit un **périmètre** (domaines, applications autorisés), des **exclusions**,
et des **règles**. **Tout ce qui est hors scope est illégal**, exactement comme sans
autorisation. Lisez la politique **avant** de tester, respectez-la à la lettre. Pas de DoS,
pas d'accès aux données d'autres utilisateurs, pas d'exfiltration réelle.

### La démarche efficace
1. **Choisir un programme** adapté à vos compétences (souvent web au début)
2. **Reconnaissance** approfondie (module 08) — sous-domaines, endpoints, technologies. La
   recon est souvent ce qui distingue les bons chasseurs.
3. **Chercher les failles à fort impact** (module 07) : IDOR/access control (les plus
   rentables), SSRF, injections, prises de contrôle de compte, logique métier
4. **Reproduire proprement** et évaluer l'impact réel
5. **Rédiger un rapport clair** : résumé, étapes de reproduction, impact, remédiation —
   la qualité du rapport influence la prime et la réputation

### Attentes réalistes
Le bug bounty est **compétitif** et irrégulier. On ne devient pas riche en un mois. Vu comme
un **apprentissage rémunéré** et un **portfolio vivant**, il est excellent. Vu comme un
salaire garanti, il déçoit. Beaucoup le pratiquent en complément d'un emploi.

### La divulgation responsable (au-delà du bug bounty)
Si vous trouvez une faille **hors programme** (par hasard, sur un service que vous utilisez),
ne l'exploitez pas. Cherchez un contact sécurité (`security.txt`, CERT), signalez de façon
responsable, laissez le temps de corriger, ne divulguez pas publiquement sans coordination.
C'est l'éthique du chercheur — et votre protection juridique.

---

## 17.5 — La veille : rester à jour toute sa carrière

La cybersécurité évolue en permanence. **La veille n'est pas optionnelle**, c'est une part
du métier. Construisez une routine durable.

### Sources (voir aussi [annexes/ressources.md](annexes/ressources.md))
- **Actualité** : The Hacker News, BleepingComputer, Krebs on Security, Dark Reading, Risky Business (podcast)
- **France/institutionnel** : **CERT-FR** (bulletins et alertes ANSSI), avis CVE
- **Technique** : PortSwigger Research, Project Zero (Google), blogs d'éditeurs et de chercheurs
- **Communauté** : Reddit (r/netsec, r/blueteamsec), X/Twitter infosec, Mastodon infosec, Discord
- **Recherche** : conférences (DEF CON, Black Hat, SSTIC, Hardwear.io), leurs vidéos/actes
- **Newsletters** : tl;dr sec, Risky Biz News, This Week in 4n6 (forensics)

### La méthode
- **Agrégez** (RSS/Feedly, listes X) pour ne pas courir après l'info
- **Sélectionnez** : impossible de tout suivre ; ciblez votre voie
- **Approfondissez** régulièrement un sujet plutôt que de survoler mille titres
- **Pratiquez** ce que vous lisez (reproduire une technique récente en lab)
- **Partagez** (blog, résumés) : enseigner consolide et vous rend visible

---

## 17.6 — Éthique, déontologie et durabilité

### L'éthique, colonne vertébrale du métier
- **Autorisation systématique** — le fil rouge de toute la formation
- **Confidentialité** — vous accédez à des informations sensibles ; la discrétion est un devoir
- **Intégrité** — ne pas nuire, ne pas dépasser le mandat, signaler honnêtement
- **Responsabilité** — vos compétences peuvent nuire ; leur usage vous engage moralement et pénalement

### Prévenir le burnout
Le domaine est intense (astreintes SOC, pression des incidents, veille permanente, syndrome
de l'imposteur). Pour durer :
- **Rythme soutenable** (module README : régularité > intensité)
- **Déconnexion** réelle, hors astreinte
- **Communauté et pairs** — l'isolement use ; parler aide
- **Accepter de ne pas tout savoir** — personne ne maîtrise tout ce domaine ; le syndrome de
  l'imposteur est quasi universel ici, y compris chez les experts
- **Célébrer les progrès** — comparez-vous à vous-même d'il y a six mois, pas aux stars de Twitter

---

## 17.7 — Rémunération (ordres de grandeur)

Très variable selon pays, région, secteur, taille d'entreprise et spécialité. En **France**,
ordres de grandeur indicatifs (brut annuel, à prendre avec prudence, marché 2025) :

| Niveau | Fourchette indicative |
|---|---|
| Analyste SOC junior | ~ 32–42 k€ |
| Pentester / analyste confirmé (2-5 ans) | ~ 45–65 k€ |
| Senior / expert (5-10 ans) | ~ 60–90 k€ |
| Architecte / lead / manager | ~ 75–110 k€+ |
| RSSI (selon taille d'organisation) | ~ 80–150 k€+ |

Les salaires sont généralement plus élevés en région parisienne, dans la finance/tech, et
nettement plus hauts aux États-Unis. Le **freelance/consulting** et le **bug bounty** peuvent
compléter ou dépasser ces montants, avec plus de variabilité. Ces chiffres évoluent —
recoupez avec des sources récentes (études de rémunération, offres réelles).

---

## 17.8 — Votre plan d'action

Un fil conducteur pour transformer ce cursus en carrière :

```
1. Bâtir les fondations (modules 00-06) + premier lab
2. Choisir une orientation dominante (offensif / défensif / cloud / GRC)
3. Pratiquer intensément (module 15) et DOCUMENTER (portfolio)
4. Une certification pratique alignée (module 16)
5. Viser un premier poste réaliste (SOC, alternance, IT connexe)
6. Une fois en poste : monter en compétence, spécialiser, réseauter
7. Veille et pratique en continu, toute la carrière
```

> **Le mot de la fin :** ce domaine récompense la **curiosité persévérante** plus que le
> talent brut. Vous n'avez pas besoin d'être un génie — vous avez besoin d'être régulier,
> rigoureux, honnête et infatigablement curieux. Ce cursus vous a donné la carte. La route
> se marche un pas après l'autre, un lab après l'autre. Bon voyage. 🛡️

---

## 🎯 Auto-évaluation / réflexion finale

1. Quelle est votre voie cible et pourquoi ?
2. Quelles preuves de pratique pouvez-vous montrer *aujourd'hui* ? Quelles vous manquent ?
3. Préparez une réponse structurée à « comment attaqueriez-vous une application web ? »
4. Pourquoi « je ne sais pas, mais voici comment je chercherais » est-il une bonne réponse ?
5. Qu'est-ce que le scope en bug bounty, et pourquoi le respecter à la lettre ?
6. Quelle routine de veille allez-vous mettre en place, avec quelles sources ?
7. Écrivez votre plan de carrière personnel sur 12 et 24 mois.

---

**← Retour au [sommaire](README.md)** · Voir aussi la [ROADMAP](ROADMAP.md) et les [annexes](annexes/).
