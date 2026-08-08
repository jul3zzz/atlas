# Module 13 — Spécialisations

> **Objectif :** présenter les domaines d'expertise vers lesquels se spécialiser une fois les
> fondations acquises. On ne fait pas *tout* dans une carrière — on choisit une ou deux voies
> et on les approfondit. Ce module donne les points d'entrée de chacune.
>
> **Durée :** variable (chaque spécialisation est un parcours en soi) · **Prérequis :** Niveaux 1 et 2

> **Conseil :** ne vous spécialisez pas trop tôt. Construisez d'abord un socle large
> (modules 00-12), puis approfondissez la voie qui vous passionne. La passion soutient
> l'effort long qu'exige l'expertise.

---

## 13.1 — Reverse Engineering (RE)

Comprendre un logiciel dont on n'a pas le code source, en lisant son code machine. Cœur de
l'analyse de malware avancée, de la recherche de vulnérabilités, du cracking (légitime :
analyse d'interopérabilité, audit).

### Prérequis
Assembleur (x86-64 surtout, ARM ensuite), architecture des processeurs, C, modèle mémoire
(pile, tas, registres, conventions d'appel), formats exécutables (PE, ELF, Mach-O).

### Outils
- **Ghidra** — décompilateur/désassembleur gratuit (NSA), la meilleure porte d'entrée
- **IDA Pro / IDA Free** — la référence commerciale
- **Binary Ninja**, **radare2/rizin/Cutter** — alternatives
- **Débogueurs** : x64dbg (Windows), GDB+GEF/pwndbg (Linux), WinDbg

### Progression
Crackmes (**crackmes.one**), challenges RE des CTF, **Nightmare** et **pwn.college** (RE+pwn),
livre « Practical Malware Analysis », puis échantillons réels en lab isolé.

---

## 13.2 — Exploit Development & Binary Exploitation (pwn)

Transformer un bug mémoire en exécution de code. La discipline la plus technique de
l'offensive, et la plus valorisée (recherche de 0-day, bug bounty bas niveau).

### Les vulnérabilités mémoire
- **Stack buffer overflow** — écraser l'adresse de retour → détourner l'exécution
- **Heap exploitation** — corruption du tas (use-after-free, double free, overflow de tas)
- **Format string** — `printf(user_input)` → lecture/écriture arbitraire
- **Integer overflow**, **off-by-one**, **type confusion**

### Les protections modernes et leur contournement
| Protection | But | Contournement |
|---|---|---|
| **DEP/NX** | Pile/tas non exécutables | **ROP** (Return-Oriented Programming) |
| **ASLR** | Adresses randomisées | Fuite d'info (info leak), brute force partiel |
| **Stack canary** | Détecter l'écrasement de pile | Fuite du canary, écrasement ciblé |
| **PIE** | Binaire à adresse randomisée | Leak d'adresse |
| **RELRO** | Protéger la GOT | Cibler d'autres primitives |

### Outils et progression
**pwntools** (Python), **GDB+pwndbg/GEF**, **ROPgadget/ropper**, **one_gadget**, **checksec**.
Parcours : **pwn.college** (le meilleur cursus gratuit, universitaire), **ROP Emporium**,
**Nightmare**, challenges pwn des CTF, **exploit.education** (Protostar/Phoenix).

> C'est un domaine à forte barrière d'entrée mais à très forte valeur. Comptez des mois de
> pratique dédiée. Le C et l'assembleur du module 06 sont ici indispensables.

---

## 13.3 — Sécurité mobile (Android / iOS)

### Android
- Architecture (APK, DEX, ART, permissions, IPC/Intents), rooting
- **Analyse statique** : `jadx`, `apktool`, MobSF ; **dynamique** : Frida (instrumentation),
  objection, Burp + certificat, émulateurs
- Failles typiques : stockage non sécurisé, secrets en dur, communications non chiffrées
  (certificate pinning contournable), export de composants, WebView non sûres, deep links

### iOS
- Écosystème plus fermé (jailbreak nécessaire pour l'analyse profonde), IPA, keychain
- Frida/objection, analyse du binaire (Mach-O), contournement de pinning

### Référence
**OWASP MASVS/MASTG** (Mobile Application Security Verification Standard / Testing Guide) —
le pendant mobile de l'ASVS/WSTG. Labs : **DIVA, InsecureBankv2, iGoat, OWASP MSTG crackmes**.

---

## 13.4 — IoT & systèmes embarqués

Objets connectés : caméras, routeurs, dispositifs médicaux, domotique. Surface souvent très
faible en maturité de sécurité.

- **Hardware hacking** : interfaces **UART/JTAG/SWI**, dump de firmware via **SPI flash**,
  analyse de PCB, glitching
- **Analyse de firmware** : `binwalk` (extraction), `firmwalker`, systèmes de fichiers
  embarqués, recherche de secrets/backdoors, émulation (QEMU, FirmAE)
- **Radio (SDR)** : capture et analyse de signaux (RTL-SDR, HackRF), protocoles sans fil
  propriétaires, Zigbee/Z-Wave/BLE
- **Matériel utile** : Bus Pirate, adaptateurs USB-UART, RTL-SDR, multimètre, (Flipper Zero
  pour le RFID/sub-GHz, une fois les bases acquises)
- Référence : **OWASP IoT Top 10**, **IoTGoat**, guides ANSSI embarqué

---

## 13.5 — Sécurité industrielle (ICS / OT / SCADA)

Les systèmes qui pilotent l'industrie, l'énergie, l'eau, les transports. Enjeux :
**sûreté physique et continuité** priment sur la confidentialité, systèmes anciens,
impossibilité de patcher facilement, conséquences potentiellement vitales.

- Composants : **PLC/API, RTU, HMI, SCADA, DCS**, historian
- Protocoles : **Modbus, DNP3, S7, Profinet, OPC-UA** — souvent sans authentification ni chiffrement
- Modèle **Purdue** (niveaux 0 à 5) pour la segmentation IT/OT
- Cadres : **IEC 62443**, MITRE **ATT&CK for ICS**, directives NIS2 (secteurs essentiels)
- Menaces emblématiques : Stuxnet, Industroyer, Triton
- Approche défensive : segmentation stricte IT/OT, DMZ industrielle, monitoring passif
  (ne pas perturber les process), gestion de l'obsolescence

> Domaine de niche à forte demande et forte responsabilité. Une erreur ne fait pas planter
> un serveur — elle peut arrêter une usine ou mettre en danger des personnes. Prudence maximale.

---

## 13.6 — Sécurité de l'IA / ML

Domaine émergent à croissance très rapide (à jour 2025-2026).

### Attaques sur les modèles
- **Prompt injection** (directe et indirecte) — détourner un LLM via ses entrées ; la faille
  n°1 des applications à base de LLM
- **Jailbreaking** — contourner les garde-fous
- **Data poisoning** — corrompre les données d'entraînement
- **Model / prompt extraction, inversion, inférence d'appartenance** — voler le modèle ou des données d'entraînement
- **Adversarial examples** — perturbations imperceptibles qui trompent un classifieur
- **Exfiltration via agents/outils** — abus des capacités d'un agent (accès fichiers, requêtes réseau)

### Cadres et défense
- **OWASP Top 10 for LLM Applications**, **MITRE ATLAS** (ATT&CK pour l'IA), **NIST AI RMF**
- Défenses : validation/segmentation des entrées, moindre privilège des outils d'agent,
  filtrage des sorties, isolation, garde-fous, supervision humaine, red teaming de modèles
- Côté **défense augmentée par l'IA** : détection assistée, triage d'alertes, analyse de
  code — avec vigilance sur les faux positifs et l'empoisonnement

> Compétence différenciante : peu de professionnels maîtrisent à la fois la cybersécurité
> classique **et** la sécurité de l'IA. Le croisement est très recherché.

---

## 13.7 — Ingénierie sociale & Red Team physique

L'humain reste le maillon exploité en priorité.

- **Phishing / spear phishing / whaling**, **vishing** (téléphone), **smishing** (SMS), **BEC** (fraude au président)
- **Pretexting** — construire un scénario crédible
- **Red team physique** — intrusion dans les locaux : tailgating, badges clonés (RFID),
  crochetage (lockpicking), dispositifs déposés (Rubber Ducky, dropbox réseau) — **toujours
  sous mandat écrit très précis, avec lettre d'autorisation sur soi**
- **OSINT** approfondi comme préparation
- Défense : sensibilisation, procédures de vérification, culture du signalement sans blâme,
  contrôles physiques

> Domaine où l'éthique est primordiale : on manipule des personnes. Le mandat, le périmètre
> et le débriefing bienveillant ne sont pas optionnels.

---

## 13.8 — Autres voies

| Voie | En bref |
|---|---|
| **Cryptographie / cryptanalyse** | Recherche, conception de protocoles, PQC — profil très mathématique |
| **Threat Intelligence (CTI)** | Suivi des groupes, analyse, attribution, production de renseignement |
| **GRC / Audit / Conformité** | Gouvernance, ISO 27001, EBIOS, audits (module 14) — voie moins technique mais essentielle |
| **AppSec / Secure Code Review** | Sécurité applicative en profondeur, revue de code, threat modeling |
| **Détection Engineering** | Ingénierie des détections, purple team à temps plein |
| **Sécurité blockchain / smart contracts** | Solidity, audit de contrats (reentrancy…), DeFi |
| **Recherche de vulnérabilités / bug bounty** | Chercheur indépendant ou en équipe produit |

---

## 13.9 — Comment choisir sa voie

Quelques questions pour vous orienter :

- **Aimez-vous casser ou construire/défendre ?** → offensive vs défensive (mais les meilleurs font les deux)
- **Aimez-vous le très bas niveau (assembleur, mémoire) ?** → RE / exploit dev / embarqué
- **Aimez-vous l'enquête et la reconstitution ?** → DFIR / forensics / CTI
- **Aimez-vous l'automatisation et le dev ?** → DevSecOps / détection engineering / outillage
- **Aimez-vous le contact, l'organisation, la stratégie ?** → GRC / management / conseil
- **Le marché** compte aussi : Blue Team, cloud, AppSec et GRC recrutent massivement ;
  l'exploit dev est prestigieux mais avec peu de postes.

**Rien n'est définitif.** Beaucoup de carrières commencent en SOC, bifurquent vers le
pentest, puis se stabilisent en AppSec ou en management. La polyvalence acquise aux niveaux
1-2 rend tous les mouvements possibles.

---

## ✅ Labs du module 13 (choisissez selon votre voie)

- [ ] **RE :** 10 crackmes de difficulté croissante sur crackmes.one, l'introduction de pwn.college (RE)
- [ ] **Pwn :** ROP Emporium (ret2win → ROP chains), les modules de base de pwn.college
- [ ] **Mobile :** analyser DIVA/InsecureBank avec MobSF + Frida, suivre l'OWASP MASTG
- [ ] **IoT :** extraire et analyser un firmware avec binwalk, chercher des secrets
- [ ] **ICS :** monter un lab avec un simulateur PLC (OpenPLC), parler Modbus, lire ATT&CK for ICS
- [ ] **IA :** faire les défis de prompt injection (Gandalf de Lakera, GPT prompt injection CTF), lire l'OWASP Top 10 LLM
- [ ] **Social :** monter une campagne de phishing de sensibilisation en lab (GoPhish) — cibles consentantes uniquement
- [ ] **Général :** choisir une voie et faire 3 machines/challenges spécialisés + un write-up

---

## 🎯 Auto-évaluation

1. Qu'est-ce que le ROP et quelle protection contourne-t-il ?
2. Citez trois vulnérabilités mémoire et leur principe.
3. Quels outils pour analyser un APK statiquement puis dynamiquement ?
4. Pourquoi la confidentialité passe-t-elle après la sûreté en ICS/OT ?
5. Qu'est-ce que la prompt injection et pourquoi est-ce la faille n°1 des applis LLM ?
6. Quel cadre pour la sécurité de l'IA ? Pour l'ICS ? Pour le mobile ?
7. Quelle voie vous attire, et quel serait votre plan d'apprentissage sur 6 mois ?

---

**Suivant → [Module 14 : GRC, normes & conformité](14-grc-conformite.md)**
