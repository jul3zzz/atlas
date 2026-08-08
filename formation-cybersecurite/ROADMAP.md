# ROADMAP — Le planning sur 12 mois

> Un calendrier **concret**, semaine par semaine, pour transformer le cursus en habitude.
> Base : **10 à 15 h/semaine**. Adaptez à votre rythme réel — la régularité prime sur la vitesse.

> **Comment l'utiliser :** ce planning mène à un niveau « junior employable » en ~12 mois.
> Le niveau « pro confirmé » vient ensuite avec l'expérience (2-5 ans). Si vous avez déjà des
> bases (dev, admin sys), compressez les premiers mois. Si vous partez de zéro, ne culpabilisez
> pas de prendre 15-18 mois : mieux vaut solide et lent que rapide et creux.

---

## Vue d'ensemble

| Trimestre | Focus | Modules | Jalon |
|---|---|---|---|
| **T1 (mois 1-3)** | Fondations | 00-04 | Lab opérationnel, Bandit fini, bases réseau/Linux |
| **T2 (mois 4-6)** | Cœur technique | 05-08 | Première machine HTB seul, bases web+pentest |
| **T3 (mois 7-9)** | Offensif + défensif | 09-11 | Purple team, 10+ machines, SIEM opérationnel |
| **T4 (mois 10-12)** | Moderne + carrière | 12-17 | Portfolio, 1ʳᵉ certif pratique, candidatures |

---

## T1 — Fondations (mois 1 à 3)

### Mois 1 — Démarrage
- **S1** : Module 00 (§0.1-0.3). Installer l'hyperviseur, Kali, snapshot. Commencer OverTheWire Bandit.
- **S2** : Module 00 (§0.4-0.6). Lab complet (Metasploitable, DVWA, Juice Shop en Host-Only). Bandit 0-15. Regex.
- **S3** : Module 01 (fondamentaux). DICP, menace/risque, STRIDE, ATT&CK Navigator. Lab modélisation.
- **S4** : Module 01 (fin) + audit de sa propre hygiène (MFA, gestionnaire de mots de passe). Finir Bandit.

### Mois 2 — Crypto & réseau
- **S5** : Module 02 (§2.1-2.4). Hachage, symétrique, AEAD. Lab pingouin ECB, cassage de hash.
- **S6** : Module 02 (fin). PKI, TLS, JWT. Lab PKI maison, audit SSL Labs, début Cryptopals.
- **S7** : Module 03 (§3.1-3.4). OSI, IP, subnetting (beaucoup de pratique), TCP/UDP, couche 2.
- **S8** : Module 03 (fin). DNS, Wireshark, tcpdump. Lab capture mot de passe en clair, ARP spoofing (lab isolé).

### Mois 3 — Systèmes
- **S9** : Module 04 (§4.1-4.4). Architecture, permissions, SUID, processus, systemd.
- **S10** : Module 04 (fin). Logs, privesc, hardening. Lab chasse aux SUID, lynis, THM Linux PrivEsc.
- **S11** : Module 05 (§5.1-5.3). Windows, authentification, Kerberos (théorie), AD.
- **S12** : Module 05 (fin). Monter un DC à la main, joindre un client, GPO, PingCastle. **Consolidation + révision T1.**

> **Jalon T1 :** lab fonctionnel et isolé · Bandit terminé · subnetting fluide · Wireshark maîtrisé ·
> privesc Linux compris · un mini-domaine AD monté à la main.

---

## T2 — Cœur technique (mois 4 à 6)

### Mois 4 — Programmation & web (début)
- **S13** : Module 06 (§6.1-6.3). Python fondamentaux, scanner de ports (projet), Bash.
- **S14** : Module 06 (fin). PowerShell, lecture de code, secure coding, Git/secrets. Labs 6.1-6.3.
- **S15** : Module 07 (§7.1-7.3). Rappels web, OWASP Top 10, injections. **Démarrer PortSwigger Academy.**
- **S16** : Module 07 (§7.4-7.5). XSS, Broken Access Control/IDOR. PortSwigger + DVWA.

### Mois 5 — Web (suite) & Burp
- **S17** : Module 07 (§7.6-7.7). SSRF, CSRF, désérialisation, misconfig. PortSwigger.
- **S18** : Module 07 (§7.8-7.9). Burp Suite à fond, méthodologie. Juice Shop.
- **S19** : Consolidation web : SQLi manuelle puis sqlmap, XSS complet avec vol de cookie, rapport web.
- **S20** : Module 08 (§8.1-8.4). Méthodo pentest, OSINT, nmap en profondeur, énumération.

### Mois 6 — Pentest
- **S21** : Module 08 (§8.5-8.6). Vulnérabilités, Metasploit, reverse shells (stabilisation), password attacks.
- **S22** : Module 08 (§8.7-8.9). Post-exploitation, pivoting, C2, **le rapport**.
- **S23** : Metasploitable de A à Z (3 vecteurs dont 1 manuel). Premières machines HTB/THM faciles.
- **S24** : **5 machines faciles** en autonomie + write-ups. **Consolidation + révision T2.**

> **Jalon T2 :** un vrai outil Python écrit · PortSwigger (SQLi/XSS/Access Control/SSRF) fini ·
> Burp maîtrisé · Metasploitable compromise de plusieurs façons · premières machines HTB seul ·
> premiers rapports rédigés.

---

## T3 — Offensif avancé + défensif (mois 7 à 9)

### Mois 7 — Active Directory offensif
- **S25** : Module 09 (§9.1-9.3). Déployer GOAD, BloodHound, Responder/relay.
- **S26** : Module 09 (§9.4-9.5). Kerberos (Kerberoasting, AS-REP), Mimikatz, PtH.
- **S27** : Module 09 (§9.6-9.7). Mouvement latéral, DCSync, Golden Ticket, ADCS.
- **S28** : Module 09 (§9.8). **Purple team** : rejouer chaque attaque et préparer la détection.

### Mois 8 — Blue Team & SOC
- **S29** : Module 10 (§10.1-10.3). SOC, logs, Sysmon, SIEM. **Monter Wazuh/ELK dans le lab.**
- **S30** : Module 10 (§10.4-10.5). Sigma, YARA, EDR. Écrire des règles de détection.
- **S31** : Module 10 (§10.6-10.8). Threat hunting, CTI, réponse à incident, durcissement.
- **S32** : **Détecter ses propres attaques** du mois 7 dans le SIEM. CyberDefenders/BTLO.

### Mois 9 — DFIR & malware
- **S33** : Module 11 (§11.1-11.3). Réponse à incident, volatilité, forensics mémoire (Volatility).
- **S34** : Module 11 (§11.4-11.5). Forensics disque, timeline, forensics réseau.
- **S35** : Module 11 (§11.6-11.7). Analyse de malware (statique/dynamique), ransomware. Lab isolé.
- **S36** : CTF forensics + write-ups. **Consolidation + révision T3.**

> **Jalon T3 :** chaîne d'attaque AD complète maîtrisée (jusqu'au Golden Ticket) · SIEM opérationnel ·
> capable de détecter ses propres attaques · 15+ machines résolues · bases forensics/malware ·
> premières investigations Blue Team.

---

## T4 — Environnements modernes + carrière (mois 10 à 12)

### Mois 10 — Cloud & DevSecOps
- **S37** : Module 12 (§12.1-12.3). Cloud, responsabilité partagée, IAM, SSRF→IMDS. Compte free tier (MFA !).
- **S38** : Module 12 (§12.4-12.5). Docker, Kubernetes. CloudGoat, Kubernetes Goat.
- **S39** : Module 12 (§12.6-12.7). DevSecOps, pipeline sécurisé, supply chain, secrets.
- **S40** : Consolidation cloud : CloudGoat scénarios, audit de posture (ScoutSuite/Prowler), pipeline CI/CD.

### Mois 11 — Spécialisation & GRC
- **S41** : Module 13. Explorer les spécialisations, **choisir une voie**, commencer ses labs dédiés.
- **S42** : Module 13 (suite). Approfondir la voie choisie (RE/pwn/mobile/cloud/IA…).
- **S43** : Module 14 (§14.1-14.5). GRC, ISO 27001, RGPD, NIS2, EBIOS RM.
- **S44** : Module 14 (fin). Audit, continuité, gestion de crise. Lab analyse de risque + politique.

### Mois 12 — Professionnalisation
- **S45** : Module 15 (révision) + finaliser le **portfolio** (blog, GitHub, write-ups nettoyés).
- **S46** : Module 16. Choisir et **commencer à préparer une certification pratique** (eJPT/PNPT/BTL1…).
- **S47** : Module 17. CV, préparation entretiens, veille structurée, (option) premier programme bug bounty.
- **S48** : **Bilan complet** : refaire à froid 3 labs marquants, auto-évaluations des modules, plan des 12 mois suivants. **Commencer à candidater.**

> **Jalon T4 (fin de cursus) :** bases cloud/DevSecOps · une voie de spécialisation entamée ·
> culture GRC · portfolio public · une certification pratique en préparation/obtenue ·
> CV et posture d'entretien prêts · candidatures lancées.

---

## Après les 12 mois

Le cursus vous a mené au seuil de l'employabilité junior. La suite :
- **Décrocher le premier poste** (SOC, alternance, IT connexe — module 17)
- **Approfondir sa spécialisation** et passer des certifications alignées
- **Continuer la pratique** (HTB, CTF, bug bounty) et la **veille** — à vie
- Viser, sur 2-5 ans, le niveau confirmé puis l'expertise ou le management

---

## Conseils pour tenir le rythme

1. **Bloquez des créneaux fixes** dans votre agenda — traitez-les comme des rendez-vous non négociables.
2. **Chaque semaine : au moins un lab pratique.** Pas de semaine « 100 % lecture ».
3. **Documentez au fil de l'eau** — le portfolio se construit en continu, pas à la fin.
4. **Acceptez les plateaux** (vers les mois 4 et 9) — c'est de l'assimilation, pas de l'échec.
5. **Révisez à froid** — les semaines de « consolidation » (S12, S24, S36, S48) ne sont pas optionnelles.
6. **Rejoignez une communauté** dès le mois 1 — l'isolement est la première cause d'abandon.
7. **Ajustez sans culpabiliser** — ce planning est une boussole, pas une prison. Un mois de retard
   n'a aucune importance ; abandonner en a.

---

**← [Sommaire](README.md)** · [Checklist de progression](annexes/checklist-progression.md)
