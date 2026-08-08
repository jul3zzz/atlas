# Module 05 — Windows & Active Directory

> **Objectif :** comprendre l'environnement qui domine le monde de l'entreprise. **90 % des
> intrusions ciblées passent par Active Directory.** Ce module en pose les fondations
> (architecture, authentification, administration) ; l'attaque d'AD est traitée au
> [module 09](09-active-directory-offensive.md).
>
> **Durée :** 3 semaines · **Prérequis :** modules 00–04

---

## 5.1 — L'architecture Windows

### Les composants clés

| Composant | Rôle | Intérêt sécurité |
|---|---|---|
| **Noyau NT** | Cœur du système | Ring 0, cible des rootkits |
| **Registre** | Base de configuration hiérarchique | Persistance, secrets, énumération |
| **LSASS** | Gère l'authentification et **stocke les secrets en mémoire** | **Cible n°1** : Mimikatz y lit hash et tickets |
| **SAM** | Base des comptes **locaux** | Vol de hash locaux |
| **Services (services.exe)** | Démons Windows | Persistance, escalade par service mal configuré |
| **WMI** | Instrumentation/gestion | Exécution distante, persistance, reconnaissance |
| **PowerShell** | Shell et automatisation | Outil d'admin **et** d'attaque |

### Le registre

Structure en ruches (hives) :

| Ruche | Contenu |
|---|---|
| `HKLM` (Local Machine) | Configuration système, services, `Run` keys |
| `HKCU` (Current User) | Configuration de l'utilisateur courant |
| `HKCR`, `HKU`, `HKCC` | Classes, utilisateurs, config courante |

**Clés à connaître (persistance) :**
`HKLM\...\Run`, `HKCU\...\Run`, `...\RunOnce`, les services, les tâches planifiées.
Ce sont les emplacements qu'un attaquant utilise pour survivre au redémarrage — et que le
défenseur surveille.

### Les identifiants de sécurité (SID)

Chaque entité (utilisateur, groupe, machine) a un **SID** unique :
`S-1-5-21-<domaine>-<RID>`. Le **RID 500** = administrateur local intégré, **512** = Domain
Admins, **519** = Enterprise Admins. Reconnaître ces RID est un réflexe d'analyse.

### Les jetons d'accès (access tokens)

À la connexion, Windows crée un **jeton** contenant l'identité et les privilèges de
l'utilisateur. Chaque processus porte un jeton. **Le vol/l'usurpation de jeton** (token
impersonation) est un vecteur d'escalade majeur (privilèges `SeImpersonate`,
`SeAssignPrimaryToken` → attaques « Potato »).

---

## 5.2 — L'authentification Windows

### Où sont les secrets et sous quelle forme

| Secret | Emplacement | Utilisable pour |
|---|---|---|
| **Hash NT (NTLM)** | SAM (local), NTDS.dit (domaine), LSASS (mémoire) | **Pass-the-Hash**, cassage hors ligne |
| **Tickets Kerberos** | Mémoire LSASS | **Pass-the-Ticket**, Golden/Silver Ticket |
| **Mots de passe en clair** | Parfois en mémoire (WDigest, apps) | Réutilisation directe |
| **Secrets LSA / DPAPI** | Registre, profils | Comptes de service, données protégées |

> **Le hash NT ne contient pas de sel** et **suffit à s'authentifier** sans le mot de passe
> (Pass-the-Hash). C'est une différence fondamentale avec Linux, et la raison pour laquelle
> voler un hash Windows est si puissant.

### NTLM — l'ancien protocole (challenge/réponse)

```
1. Client → Serveur : « je veux m'authentifier »
2. Serveur → Client : challenge aléatoire
3. Client → Serveur : réponse = fonction(challenge, hash NT)
4. Serveur valide (ou relaie au DC)
```

**Faiblesses :** pas d'authentification mutuelle (⇒ **NTLM relay**), le hash suffit
(⇒ **Pass-the-Hash**), challenge/réponse capturable et crackable (responder + hashcat).
NTLM est obsolète mais **encore massivement présent** — c'est un talon d'Achille récurrent.

### Kerberos — le protocole moderne (à base de tickets)

Le cœur de l'authentification AD. Comprendre son fonctionnement est **indispensable** pour
le module 09.

```
Acteurs : Client · KDC (sur le DC : AS + TGS) · Service cible

1. AS-REQ / AS-REP : le client prouve son identité (horodatage chiffré avec son hash)
   → reçoit un TGT (Ticket Granting Ticket), chiffré avec la clé du compte krbtgt

2. TGS-REQ / TGS-REP : le client présente son TGT pour demander l'accès à un service (SPN)
   → reçoit un TGS (Service Ticket), chiffré avec le hash du compte du service

3. AP-REQ : le client présente le TGS au service, qui l'accepte (il fait confiance au KDC)
```

**Notions qui deviendront des attaques (module 09) :**
- Le **TGT** est chiffré avec la clé de `krbtgt` → qui connaît ce hash forge des TGT arbitraires (**Golden Ticket**)
- Le **TGS** est chiffré avec le hash du **compte de service** → on peut le capturer et le cracker hors ligne (**Kerberoasting**)
- Un compte **sans pré-authentification** livre un AS-REP crackable (**AS-REP Roasting**)
- Les **délégations** mal configurées permettent l'usurpation

> Ne cherchez pas à tout retenir maintenant. Retenez **la structure** : TGT du KDC, TGS par
> service, chiffrement par le hash du compte concerné. Le reste s'éclairera au module 09.

---

## 5.3 — Active Directory : le système nerveux de l'entreprise

### Qu'est-ce qu'AD

Un **annuaire** (basé sur LDAP) qui centralise l'identité et l'administration : comptes,
machines, groupes, politiques. Se connecter une fois donne accès à toutes les ressources
autorisées (SSO). **Compromettre AD = compromettre toute l'organisation**, d'où sa centralité.

### La hiérarchie logique

```
Forêt (frontière de sécurité ultime)
  └── Domaine(s) : entreprise.local
        └── Unités d'organisation (OU) : conteneurs pour organiser et appliquer des GPO
              └── Objets : utilisateurs, ordinateurs, groupes, imprimantes
```

- **Domaine** — unité d'administration et d'authentification
- **Arbre** — domaines partageant un espace de noms contigu
- **Forêt** — ensemble d'arbres ; **c'est la vraie frontière de sécurité** (une relation
  d'approbation entre forêts n'implique pas la confiance totale)
- **Relations d'approbation (trusts)** — permettent l'accès entre domaines/forêts ; mal
  maîtrisées, elles étendent la surface d'attaque

### Les contrôleurs de domaine (DC)

Serveurs qui hébergent AD, exécutent le **KDC** Kerberos et stockent la base **`NTDS.dit`**
(qui contient **tous les hash du domaine**). Extraire NTDS.dit (via DCSync ou copie), c'est
posséder l'ensemble des identités du domaine. Les DC sont les joyaux à protéger en priorité.

### Groupes à privilèges à connaître par cœur

| Groupe | Pouvoir |
|---|---|
| **Domain Admins** | Contrôle total du domaine |
| **Enterprise Admins** | Contrôle de toute la forêt |
| **Schema Admins** | Modifient le schéma AD |
| **Administrators** (local/DC) | Admin de la machine |
| **Account/Backup/Server Operators** | Privilèges élevés souvent sous-estimés (chemins d'escalade) |
| **DnsAdmins** | Historiquement → exécution de code sur le DC |

### GPO — Group Policy Objects

Les **stratégies de groupe** appliquent de la configuration (sécurité, scripts, logiciels)
à des OU. Puissantes pour durcir… et redoutables si un attaquant peut les modifier :
une GPO malveillante liée à une OU exécute du code sur **toutes** les machines concernées.

---

## 5.4 — Administrer et énumérer AD

### PowerShell — l'outil central

```powershell
# Module Active Directory
Get-ADUser -Filter * -Properties *
Get-ADGroup -Filter * | Select Name
Get-ADGroupMember "Domain Admins"
Get-ADComputer -Filter *
Get-ADDomain ; Get-ADForest

# Reconnaissance générale
whoami /all                       # utilisateur, groupes, privilèges
net user /domain
net group "Domain Admins" /domain
nltest /dclist:entreprise.local   # lister les DC
```

### LDAP — le protocole sous-jacent

AD est une base LDAP. Les requêtes LDAP permettent une énumération fine (comptes avec SPN,
comptes sans pré-auth, ACL…). Les outils offensifs (BloodHound, PowerView) s'appuient dessus.

```powershell
# PowerView (offensif, module 09)
Get-DomainUser -SPN                 # comptes kerberoastables
Get-DomainUser -PreauthNotRequired  # comptes AS-REP roastables
Get-DomainComputer -Unconstrained   # délégation non contrainte
```

### BloodHound — cartographier les chemins d'attaque

**BloodHound** collecte les relations AD (qui est admin de quoi, qui peut réinitialiser
quel mot de passe, quelles sessions ouvertes) et calcule par théorie des graphes le
**chemin le plus court vers Domain Admin**. C'est l'outil qui a transformé l'attaque d'AD.
Côté défense, il révèle les chemins à casser en priorité. (Détaillé au module 09.)

---

## 5.5 — Le durcissement d'Active Directory (Blue Team)

L'essentiel des bonnes pratiques défensives :

### Modèle en tiers (Tiering / PAW)
Séparer les niveaux d'administration pour empêcher le vol d'identifiants privilégiés :
```
Tier 0 : contrôleurs de domaine, ADCS, gestion des identités  ← le plus critique
Tier 1 : serveurs applicatifs, bases de données
Tier 2 : postes de travail
```
Un admin Tier 0 ne se connecte **jamais** sur un poste Tier 2 (où son ticket serait volé).
Les **PAW** (Privileged Access Workstations) sont des postes dédiés et durcis pour l'admin.

### Comptes et mots de passe
- **LAPS** — mot de passe administrateur local **unique et rotatif** par machine (tue le Pass-the-Hash latéral)
- **Protected Users**, **Authentication Policies/Silos** pour les comptes sensibles
- Comptes de service en **gMSA** (mots de passe gérés, longs, rotatifs) → neutralise le Kerberoasting
- Interdire les SPN sur des comptes utilisateurs à mot de passe faible

### Réduction de surface
- Désactiver **NTLM** là où c'est possible, sinon activer la **signature SMB/LDAP** (anti-relay)
- Désactiver **LLMNR/NBT-NS** (empêche l'empoisonnement par Responder)
- Restreindre les délégations, auditer les **ACL** (avec BloodHound)
- **Tiered ADCS** et correction des templates vulnérables (ESC1-ESC8)

### Détection
- Surveiller les événements clés : 4624/4625 (logon), 4768/4769 (Kerberos TGT/TGS),
  4662 (accès annuaire — DCSync), 4728/4732 (ajout à groupe privilégié), 4720 (création de compte)
- **Honeytokens** : un faux compte à SPN alléchant qui alerte s'il est kerberoasté
- Corréler dans un SIEM (module 10)

### Références
- **PingCastle** — audit gratuit de la posture AD, note de maturité, rapport lisible (à faire absolument)
- **Purple Knight** (Semperis), les guides ANSSI « Points de contrôle Active Directory »
- Microsoft « Securing Privileged Access »

---

## 5.6 — Le lab Active Directory (à monter maintenant, exploité au module 09)

Vous allez construire le terrain de jeu qui vous accompagnera longtemps.

**Architecture minimale :**
```
DC01  — Windows Server (Domain Controller)  entreprise.local
CLI01 — Windows 10/11 joint au domaine
KALI  — l'attaquant
        Réseau INTERNE isolé
```

**Deux façons de le monter :**
1. **À la main** — installer Windows Server, promouvoir en DC (`dcpromo`/Server Manager),
   joindre un client, créer des utilisateurs et groupes. **Long mais extrêmement formateur** :
   vous comprenez chaque brique.
2. **Automatisé** — [GOAD (Game Of Active Directory)](https://github.com/Orange-Cyberdefense/GOAD)
   déploie un environnement AD délibérément vulnérable et multi-domaines via Vagrant/Ansible.
   Idéal pour s'entraîner aux attaques du module 09.

> **Conseil :** montez-en un à la main **une fois** pour comprendre, puis utilisez GOAD pour
> vous exercer aux attaques. Les licences d'évaluation Windows Server/10 (180 jours) suffisent.

---

## ✅ Labs du module 05

- [ ] **Lab 5.1 — Monter un DC à la main.** Windows Server → promotion en contrôleur de domaine `entreprise.local`. Créez 5 utilisateurs, 3 groupes, 2 OU.
- [ ] **Lab 5.2 — Joindre un client** Windows 10/11 au domaine, ouvrir une session avec un compte de domaine, observer le SSO.
- [ ] **Lab 5.3 — GPO.** Créez une GPO qui impose une politique de mot de passe et déploie un fond d'écran. Liez-la à une OU et vérifiez son application (`gpresult /r`).
- [ ] **Lab 5.4 — Énumération.** Depuis le client, énumérez le domaine avec PowerShell (`Get-ADUser`, `Get-ADGroupMember "Domain Admins"`, `whoami /all`).
- [ ] **Lab 5.5 — Registre & persistance.** Ajoutez une clé `Run`, une tâche planifiée et un service ; puis retrouvez-les en position de défenseur (Autoruns de Sysinternals).
- [ ] **Lab 5.6 — Kerberos en pratique.** Avec `klist`, observez vos tickets (TGT, TGS) après accès à un partage. Reliez ce que vous voyez au schéma AS/TGS.
- [ ] **Lab 5.7 — Audit défensif.** Lancez **PingCastle** sur votre lab, lisez le rapport, et corrigez trois points faibles identifiés.
- [ ] **Lab 5.8 — TryHackMe.** « Windows Fundamentals 1-2-3 », « Active Directory Basics ».

---

## 🎯 Auto-évaluation

1. Pourquoi voler un hash NT est-il plus puissant que voler un hash de mot de passe Linux ?
2. Décrivez les échanges AS et TGS de Kerberos. Que contient un TGT, un TGS ?
3. Qu'est-ce que LSASS et pourquoi les attaquants le ciblent-ils ?
4. Différence entre domaine et forêt ? Où est la « vraie » frontière de sécurité ?
5. Que contient NTDS.dit et pourquoi est-ce le trésor du domaine ?
6. À quoi sert LAPS et quelle attaque neutralise-t-il ?
7. Citez 4 groupes AD à privilèges et leur pouvoir.
8. Qu'est-ce que le modèle en tiers et quel problème résout-il ?
9. Quels événements Windows surveilleriez-vous pour détecter une attaque Kerberos ?

---

**Suivant → [Module 06 : Programmation & scripting](06-programmation.md)**
