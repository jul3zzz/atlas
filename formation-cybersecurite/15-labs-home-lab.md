# Module 15 — Labs & home lab

> **Objectif :** rassembler tout ce qu'il faut pour **pratiquer** — le vrai moteur de la
> progression. Ce module est une boîte à outils permanente, à consulter tout au long du
> cursus, pas une étape linéaire.
>
> **Niveau 4 — en continu**

> **Le principe qui fonde ce module :** en cybersécurité, on n'apprend qu'en faisant.
> 70 % de votre temps doit être du clavier, pas de la lecture. Ce module vous dit où mettre
> ce temps.

---

## 15.1 — Construire son home lab

### Le lab minimal (rappel du module 00)

```
Hyperviseur (VirtualBox/VMware) sur votre PC
 ├── Kali Linux (attaquant)
 ├── Cibles vulnérables (Metasploitable, DVWA, Juice Shop) — réseau ISOLÉ
 └── Snapshots systématiques
```

### Le lab intermédiaire — un mini-domaine

```
 ├── Windows Server → Contrôleur de domaine (entreprise.local)
 ├── Windows 10/11 client(s) joint(s)
 ├── Kali (attaquant)
 ├── Ubuntu Server → SIEM (Wazuh/ELK) + collecte des logs
 └── Réseau interne isolé, segmenté en VLAN si possible
```

C'est le lab **purple team** de référence : attaquer depuis Kali, détecter dans le SIEM.
Il vous accompagnera des modules 05 à 11.

### Le lab avancé — Proxmox sur machine dédiée

Un vieux PC/serveur d'occasion + **Proxmox VE** (hyperviseur type 1 gratuit) offre un lab
permanent, plus proche du réel :
- Plusieurs domaines et relations d'approbation (avec **GOAD**)
- pfSense/OPNsense comme pare-feu et segmentation
- Un vrai SIEM avec agents partout, EDR (Wazuh, Elastic Defend)
- Services exposés (web, mail) pour la reconnaissance
- Snapshots, clonage, templates

> **Conseil budget :** commencez avec ce que vous avez. Un PC 16 Go suffit pour démarrer.
> N'investissez dans du matériel dédié que lorsque les VM sur votre poste deviennent une
> vraie limite. Le meilleur lab est celui que vous utilisez, pas le plus cher.

### Automatiser son lab
- **GOAD** (Game of Active Directory) — environnement AD vulnérable clé en main
- **DetectionLab** — lab avec télémétrie et détection préconfigurées
- **Ludus** — déploiement de labs reproductibles
- **Vagrant + Ansible / Terraform** — infrastructure as code pour recréer son lab à volonté

---

## 15.2 — Les plateformes d'entraînement

### Pour débuter (guidé, pédagogique)

| Plateforme | Points forts |
|---|---|
| **TryHackMe** | Parcours guidés, très progressif, idéal grand débutant. Suivez les « Learning Paths » |
| **PortSwigger Web Security Academy** | **Gratuit**, la référence absolue du web, labs officiels OWASP |
| **OverTheWire** (Bandit, Natas, Leviathan…) | Wargames Linux/web fondamentaux, gratuits |
| **picoCTF** | CTF pédagogique (créé par CMU), excellent pour débuter les CTF |
| **Hack The Box Academy** | Cursus structurés et certifiants (CPTS, CBBH…) |

### Pour progresser (moins guidé, plus réaliste)

| Plateforme | Points forts |
|---|---|
| **Hack The Box** | Machines réalistes, communauté immense, la référence du pentest |
| **VulnHub** | Machines téléchargeables à héberger dans son lab (hors ligne) |
| **PentesterLab** | Web en profondeur, parcours structurés |
| **Root-Me** | Grande variété (FR/EN), du web au réseau au stégano |
| **PWK/OSCP labs** | Le lab officiel de la certification OSCP (module 16) |

### Défense / Blue Team

| Plateforme | Points forts |
|---|---|
| **CyberDefenders** | Investigations DFIR/SOC réalistes sur cas concrets |
| **Blue Team Labs Online** | Scénarios défensifs, forensics, IR |
| **LetsDefend** | Simulateur de SOC (alertes, tickets) |
| **Splunk BOTS** (Boss of the SOC) | Datasets réalistes pour l'analyse SIEM |
| **CyberChef** | « Le couteau suisse » du data (encodages, crypto simple) — outil quotidien |

### Cloud / Spécialisations

CloudGoat, Kubernetes Goat, flAWS/flAWS2 (AWS), pwn.college (RE/pwn), crackmes.one (RE),
Gandalf/Lakera (IA), malware-traffic-analysis.net (forensics réseau).

---

## 15.3 — Les CTF (Capture The Flag)

Compétitions où l'on résout des défis pour trouver des « flags ». **Le meilleur accélérateur
de progression** et un excellent moyen de rejoindre une communauté.

### Les catégories
- **Web** — vulnérabilités applicatives (module 07)
- **Pwn / Binary** — exploitation mémoire (module 13)
- **Reverse** — rétro-ingénierie (module 13)
- **Crypto** — casser des implémentations crypto (module 02)
- **Forensics** — analyse de fichiers, mémoire, réseau (module 11)
- **OSINT** — recherche d'information (module 08)
- **Misc / Stegano / Hardware** — divers

### Les formats
- **Jeopardy** — défis indépendants par catégorie (le plus courant)
- **Attack-Defense** — équipes qui attaquent et défendent des services simultanément
- **King of the Hill** — garder le contrôle d'une machine

### Où jouer
- **CTFtime.org** — calendrier de tous les CTF, classements d'équipes
- picoCTF (débutant), les CTF universitaires, les CTF de grandes entreprises/éditeurs
- Rejoindre ou monter une **équipe** — l'aspect collaboratif décuple l'apprentissage

> **Après chaque CTF :** lisez les **write-ups** des autres, même pour les défis résolus.
> On apprend souvent plus des solutions élégantes des autres que de sa propre approche.
> Et **rédigez les vôtres** — c'est votre portfolio et cela ancre l'apprentissage.

---

## 15.4 — La méthode : comment pratiquer efficacement

### La boucle d'apprentissage vertueuse

```
1. Théorie ciblée (juste ce qu'il faut pour démarrer)
2. Pratique immédiate (un lab sur le concept)
3. Blocage → recherche autonome (docs, pas la solution tout de suite)
4. Déblocage → compréhension profonde
5. Write-up (expliquer = maîtriser)
6. Répétition à froid (refaire sans les notes, semaines plus tard)
```

### Les règles d'or

- **Cherchez l'inconfort.** Si c'est facile, vous n'apprenez pas. La zone de progression est
  celle où vous êtes bloqué mais capable de vous débloquer avec effort.
- **Time-box les indices.** Bloqué 30-45 min ? Cherchez un indice, pas la solution complète.
  Se débloquer soi-même est la compétence à entraîner ; copier une solution ne l'entraîne pas.
- **Documentez tout.** Chaque lab = quelques lignes minimum : contexte, ce que j'ai fait,
  ce qui a marché, ce que j'ai appris. Ces notes deviennent votre référentiel personnel.
- **Refaites à froid.** La compétence se forme par la répétition espacée, pas par la
  première résolution.
- **Variez.** Alternez offensive et défensive, web et système, guidé et libre. La
  polyvalence protège de l'oubli et enrichit la compréhension.

### Éviter la « tutorial hell »
Enchaîner des vidéos donne l'illusion du progrès. Le vrai apprentissage est **actif** :
tapez, cassez, réparez, cherchez. Pour chaque heure de contenu consommé, passez-en deux à
trois à pratiquer par vous-même.

---

## 15.5 — Le portfolio : transformer la pratique en preuve

Votre pratique doit être **visible** pour servir votre carrière (module 17).

- **GitHub** — vos scripts, outils, configurations de lab (⚠️ jamais de secret, jamais de
  contenu illégal ou de données réelles de cibles)
- **Blog / write-ups** — machines HTB (celles qui sont *retirées* uniquement, respectez les
  règles de la plateforme), CTF, projets, analyses. Un blog technique régulier vaut mieux
  qu'un CV.
- **Contributions** — outils open source, règles Sigma/YARA publiées, documentation
- **Certifications** (module 16) — la validation formelle
- **Bug bounty** (module 17) — des trouvailles réelles (dans les règles des programmes)

> Un recruteur qui voit un blog actif, un GitHub soigné et quelques write-ups de qualité en
> apprend plus sur vous qu'avec n'importe quel diplôme. **La preuve du faire prime sur la
> déclaration du savoir.**

---

## ✅ Objectifs pratiques du module 15

- [ ] Monter le lab intermédiaire (DC + client + Kali + SIEM) et le documenter
- [ ] Compléter au moins un **Learning Path** complet sur TryHackMe
- [ ] Finir les parcours SQLi, XSS, Access Control de PortSwigger Academy
- [ ] Résoudre **20 machines** Hack The Box de difficulté croissante, avec write-up
- [ ] Participer à **au moins un CTF** en ligne (via CTFtime), même modestement
- [ ] Faire 5 investigations Blue Team (CyberDefenders / BTLO)
- [ ] Publier votre premier write-up sur un blog ou GitHub
- [ ] Tenir un journal de bord de lab pendant 3 mois sans interruption

---

## 🎯 Auto-évaluation

1. Décrivez l'architecture d'un lab purple team et à quoi sert chaque VM.
2. Quelle plateforme recommanderiez-vous à un grand débutant, et pourquoi ?
3. Pourquoi rédiger des write-ups, même pour des défis déjà résolus ?
4. Qu'est-ce que la « tutorial hell » et comment l'éviter ?
5. Pourquoi « refaire à froid » est-il plus formateur que la première résolution ?
6. Quelles règles respecter en publiant des write-ups de HTB/CTF sur son blog ?

---

**Suivant → [Module 16 : Certifications](16-certifications.md)**
