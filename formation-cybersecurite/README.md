# Formation Cybersécurité — de Débutant à Professionnel

> Un cursus complet, autonome et gratuit (ou presque), conçu pour amener une personne
> sans aucune base informatique jusqu'à un niveau professionnel employable en
> cybersécurité, offensive comme défensive.

---

## ⚖️ Avertissement légal — à lire avant tout

Cette formation enseigne des techniques d'attaque **dans le seul but de savoir s'en défendre**.
Leur usage sans autorisation est un **délit**.

En France :
- **Article 323-1 du Code pénal** — accès ou maintien frauduleux dans un système de traitement automatisé de données : jusqu'à **3 ans de prison et 100 000 €** d'amende (5 ans / 150 000 € si les données sont altérées ou s'il s'agit d'un système de l'État).
- **Article 323-2** — entrave au fonctionnement d'un système : **5 ans et 150 000 €**.
- **Article 323-3** — introduction, modification, suppression frauduleuse de données : **5 ans et 150 000 €**.
- **Article 323-3-1** — détention ou mise à disposition d'outils conçus pour commettre ces infractions (l'usage légitime — recherche, sécurité — est une exception reconnue).

**Règles non négociables :**
1. Vous ne testez **que** ce qui vous appartient, ou ce pour quoi vous détenez une **autorisation écrite, datée et signée** définissant le périmètre exact.
2. Les plateformes d'entraînement (HTB, THM, RootMe…) et votre home lab sont vos terrains de jeu — pas le Wi-Fi du voisin, pas le site de votre lycée, pas l'infra de votre employeur « pour rendre service ».
3. Un programme de bug bounty = une autorisation, **limitée à son scope**. Hors scope = illégal.
4. En cas de doute : vous n'avez pas l'autorisation.

La curiosité technique n'est pas une excuse juridique. La différence entre un professionnel et un délinquant, c'est un document signé.

---

## À qui s'adresse ce cursus

| Profil | Point d'entrée |
|---|---|
| Aucune base informatique | Module 00 (prérequis) — obligatoire, ne le sautez pas |
| Dev / admin sys en reconversion | Module 01, en survolant 00 et 06 |
| Étudiant en info | Module 01 → 03, puis choix de voie au module 08/10 |
| Déjà junior en SOC/pentest | Modules 08+ et spécialisations (13), certifications (16) |

**Durée réaliste :** 12 à 18 mois à raison de 10–15 h/semaine pour atteindre un niveau
« junior employable ». 3 à 5 ans pour le niveau « senior ». Quiconque vous promet
« expert en 3 mois » vous vend quelque chose.

---

## Philosophie : 70 % pratique, 30 % théorie

La cybersécurité ne s'apprend pas en regardant des vidéos. **Chaque module contient des
labs obligatoires.** Règle d'or : pour 1 heure de lecture, 2 à 3 heures de clavier.

Un principe qui structure tout le cursus : **on ne peut pas attaquer ce qu'on ne comprend pas,
et on ne peut pas défendre ce qu'on ne sait pas attaquer.** D'où l'ordre : fondations
techniques → offensive → défensive → spécialisation.

---

## Plan du cursus

### 🟢 Niveau 1 — Fondations (mois 1 à 4)

| # | Module | Contenu | Durée |
|---|---|---|---|
| [00](00-prerequis.md) | **Prérequis informatiques** | Matériel, OS, systèmes de fichiers, virtualisation, ligne de commande | 3–4 sem. |
| [01](01-fondamentaux-securite.md) | **Fondamentaux de la sécurité** | DICP, modèles de menace, gestion du risque, défense en profondeur, IAM | 2 sem. |
| [02](02-cryptographie.md) | **Cryptographie appliquée** | Symétrique, asymétrique, hash, PKI, TLS, erreurs classiques | 2–3 sem. |
| [03](03-reseaux.md) | **Réseaux** | TCP/IP, OSI, routage, DNS, HTTP, Wireshark, attaques réseau | 4 sem. |
| [04](04-linux.md) | **Linux** | Système, permissions, processus, services, durcissement, logs | 3 sem. |
| [05](05-windows-active-directory.md) | **Windows & Active Directory** | Architecture, registre, GPO, Kerberos, LDAP, durcissement | 3 sem. |
| [06](06-programmation.md) | **Programmation & scripting** | Bash, Python offensif/défensif, PowerShell, Git, un peu de C | 4 sem. |

### 🟡 Niveau 2 — Compétences cœur de métier (mois 5 à 9)

| # | Module | Contenu | Durée |
|---|---|---|---|
| [07](07-securite-web.md) | **Sécurité web & OWASP** | Top 10, XSS, SQLi, SSRF, IDOR, désérialisation, Burp Suite | 5–6 sem. |
| [08](08-pentest-offensive.md) | **Pentest & Red Team** | Méthodologie, OSINT, scan, exploitation, post-exploitation, C2, rapport | 6 sem. |
| [09](09-active-directory-offensive.md) | **Attaque d'Active Directory** | Kerberoasting, AS-REP, NTLM relay, délégations, ACL, ADCS, forêts | 4 sem. |
| [10](10-blue-team-soc.md) | **Blue Team & SOC** | SIEM, EDR, détection, MITRE ATT&CK, Sigma, threat hunting, purple team | 5 sem. |
| [11](11-dfir-malware.md) | **Forensics & analyse de malware** | Réponse à incident, mémoire, disque, timeline, analyse statique/dynamique | 4 sem. |

### 🔵 Niveau 3 — Environnements modernes & spécialisation (mois 10 à 15)

| # | Module | Contenu | Durée |
|---|---|---|---|
| [12](12-cloud-devsecops.md) | **Cloud & DevSecOps** | AWS/Azure/GCP, IAM cloud, conteneurs, Kubernetes, CI/CD, supply chain | 5 sem. |
| [13](13-specialisations.md) | **Spécialisations** | Reverse engineering, exploit dev, mobile, IoT/embarqué, ICS/OT, IA | variable |
| [14](14-grc-conformite.md) | **GRC, normes & conformité** | ISO 27001, NIS2, RGPD, EBIOS RM, audit, gestion de crise, cyberassurance | 3 sem. |

### 🟣 Niveau 4 — Professionnalisation (en continu)

| # | Module | Contenu |
|---|---|---|
| [15](15-labs-home-lab.md) | **Labs & home lab** | Monter son propre laboratoire, plateformes d'entraînement, CTF |
| [16](16-certifications.md) | **Certifications** | Quel parcours, quel budget, quel ordre, ce qui vaut vraiment le coup |
| [17](17-carriere.md) | **Carrière & bug bounty** | Métiers, salaires, CV, entretiens techniques, bug bounty, veille |

### 📎 Annexes

- [Cheatsheet des commandes](annexes/cheatsheet-commandes.md) — l'aide-mémoire à garder ouvert
- [Glossaire](annexes/glossaire.md) — 200+ termes et acronymes expliqués
- [Ressources](annexes/ressources.md) — livres, chaînes, blogs, podcasts, outils
- [Checklist de progression](annexes/checklist-progression.md) — cochez, mesurez, avancez
- [ROADMAP semaine par semaine](ROADMAP.md) — le planning concret sur 12 mois

---

## Comment travailler ce cursus

1. **Lisez le module**, en prenant des notes dans votre propre système (Obsidian, CherryTree, Notion — peu importe, mais un seul endroit).
2. **Faites les labs.** Ils ne sont pas optionnels. Un module sans lab = un module non acquis.
3. **Écrivez.** Rédigez un write-up de chaque lab, même court. Écrire révèle ce que vous n'avez pas compris — et constitue votre portfolio.
4. **Répétez à froid.** Refaites un lab 3 semaines plus tard sans les notes. C'est là que la compétence se forme.
5. **Cochez** la [checklist de progression](annexes/checklist-progression.md).

### Le piège n°1 : la « tutorial hell »

Enchaîner les vidéos donne l'illusion de progresser. Vous progressez quand vous êtes
**bloqué et que vous vous débloquez seul**. Si un lab vous prend 6 heures et beaucoup de
frustration, c'est le signe que ça fonctionne. Cherchez l'inconfort.

### Le piège n°2 : sauter les fondations

90 % des personnes qui échouent dans ce domaine ont voulu commencer par « hacker »
sans savoir ce qu'est une table de routage, un descripteur de fichier ou une requête HTTP.
Le pentest n'est pas un point de départ, c'est une conséquence.

---

## Matériel nécessaire

**Minimum viable :** un PC avec 16 Go de RAM, 500 Go SSD, CPU récent avec virtualisation
(VT-x/AMD-V) activée dans le BIOS. 8 Go de RAM sont jouables mais douloureux dès qu'on
lance 2 VM.

**Confortable :** 32 Go de RAM, 1 To NVMe. Permet de faire tourner un lab AD complet
(DC + 2 clients + attaquant + SIEM).

**Optionnel mais utile plus tard :** un adaptateur Wi-Fi supportant le mode moniteur
(Alfa AWUS036ACM), un Raspberry Pi, un Proxmox sur machine dédiée (un vieux PC d'occasion
suffit), une clé YubiKey pour comprendre le FIDO2 de l'intérieur.

**Ce dont vous n'avez PAS besoin pour commencer :** un Flipper Zero, un Pwnagotchi,
un abonnement à 5 plateformes simultanées. Achetez du matériel quand un lab précis
l'exige, pas avant.

---

## Un mot sur le rythme

Ce cursus est long. Il est conçu pour être long, parce que la compétence l'est.
Trois principes pour tenir la distance :

- **La régularité bat l'intensité.** 1 h par jour pendant un an >>> 10 h le samedi pendant deux mois.
- **Le plateau est normal.** Vous stagnerez vers le mois 4 et le mois 9. C'est l'assimilation, pas l'échec.
- **Trouvez une communauté.** Un Discord CTF, une association locale, un collègue. L'isolement est la première cause d'abandon.

Bonne route. 🛡️

---

*Cursus rédigé pour un usage éducatif et défensif. Chaque technique offensive présentée
l'est dans le cadre de tests autorisés.*
