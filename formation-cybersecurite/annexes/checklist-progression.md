# Checklist de progression

> Cochez au fur et à mesure. Cette liste mesure des **compétences démontrables**, pas des
> modules « lus ». La règle : ne cochez que si vous savez **faire**, pas seulement reconnaître.
>
> Copiez ce fichier dans vos notes personnelles et tenez-le à jour.

---

## 🟢 Niveau 1 — Fondations

### Environnement & ligne de commande
- [ ] J'ai un lab virtualisé isolé, fonctionnel, avec snapshots
- [ ] Je vérifie l'isolement réseau de mes cibles (Host-Only/Interne, jamais Bridge)
- [ ] J'ai terminé OverTheWire Bandit
- [ ] Je manipule find/grep/awk/sed/sort/uniq sans réfléchir
- [ ] J'écris des regex pour extraire IP, e-mails, motifs de logs
- [ ] J'utilise Git au quotidien et je ne committe jamais de secret

### Fondamentaux de sécurité
- [ ] J'explique menace / vulnérabilité / exploit / risque sans les confondre
- [ ] Je sais appliquer STRIDE à un système avec un DFD
- [ ] Je navigue dans MITRE ATT&CK et j'explique la Pyramid of Pain
- [ ] J'ai sécurisé mes propres comptes (MFA FIDO2/TOTP, gestionnaire de mots de passe)

### Cryptographie
- [ ] J'explique la différence encoder / chiffrer / hasher
- [ ] Je sais pourquoi on hache un mot de passe avec Argon2, pas SHA-256
- [ ] Je comprends l'AEAD et « chiffrer ≠ authentifier »
- [ ] J'ai monté une PKI et servi un site HTTPS local
- [ ] Je repère les erreurs crypto classiques (ECB, IV réutilisé, clé en dur, `==` sur signature)

### Réseaux
- [ ] Le subnetting est fluide (réseau, broadcast, plage, « ces IP communiquent-elles ? »)
- [ ] Je dissèque un handshake TCP dans Wireshark
- [ ] J'ai capturé un mot de passe en clair et constaté l'effet du HTTPS
- [ ] J'explique et je défends contre l'ARP spoofing
- [ ] Je situe une attaque dans la bonne couche OSI

### Systèmes
- [ ] Je maîtrise les permissions Linux (dont SUID/SGID/sticky)
- [ ] J'ai obtenu un shell root via un SUID + GTFOBins
- [ ] J'énumère les vecteurs de privesc Linux à la main
- [ ] J'ai durci une VM (SSH par clés, fail2ban, ufw) et amélioré son score lynis
- [ ] J'ai monté un contrôleur de domaine AD à la main
- [ ] J'explique Kerberos (AS/TGS, TGT/TGS) et pourquoi voler un hash NT est puissant

### Programmation
- [ ] J'ai écrit un scanner de ports Python (concurrent, argparse, sortie structurée)
- [ ] J'écris du Bash robuste (`set -euo pipefail`, variables guillemetées)
- [ ] Je lis du PHP/JS/C et j'y repère des failles
- [ ] Je comprends pourquoi une requête préparée neutralise la SQLi

---

## 🟡 Niveau 2 — Cœur de métier

### Sécurité web
- [ ] Je connais l'OWASP Top 10 de mémoire
- [ ] J'ai fini les parcours SQLi, XSS, Access Control, SSRF de PortSwigger Academy
- [ ] J'exploite une SQLi entièrement à la main (UNION + blind)
- [ ] J'ai réalisé un vol de cookie via XSS stocké, puis je l'ai corrigé (échappement + CSP + HttpOnly)
- [ ] Je trouve des IDOR systématiquement
- [ ] Je maîtrise Burp (Proxy, Repeater, Intruder, Decoder)
- [ ] J'ai rédigé un rapport de pentest web complet

### Pentest
- [ ] Je maîtrise nmap (types de scan, NSE, formats de sortie)
- [ ] Je fais de l'OSINT structuré (sous-domaines, Shodan, dorks, GitHub)
- [ ] J'ai compromis Metasploitable par ≥ 3 vecteurs, dont un sans Metasploit
- [ ] J'obtiens et je **stabilise** un reverse shell
- [ ] Je fais du pivoting vers un réseau interne
- [ ] J'ai résolu ≥ 10 machines HTB/THM en autonomie, avec write-ups
- [ ] Je comprends les documents légaux préalables à une mission

### Active Directory offensif
- [ ] J'ai déployé GOAD et cartographié avec BloodHound
- [ ] Je réalise Responder + NTLM relay, et je sais m'en défendre
- [ ] Je fais du Kerberoasting et de l'AS-REP roasting de bout en bout
- [ ] Je fais du Pass-the-Hash et du mouvement latéral (evil-winrm/psexec)
- [ ] J'ai fait un DCSync → Golden Ticket
- [ ] Pour chaque attaque AD, je connais la détection ET la défense

### Blue Team & SOC
- [ ] J'ai monté un SIEM (Wazuh/ELK) qui reçoit mes logs
- [ ] J'ai déployé Sysmon avec une config de référence
- [ ] **Je détecte mes propres attaques dans mon SIEM**
- [ ] J'écris des règles Sigma et une règle YARA
- [ ] Je connais les Event ID clés (4624/4625/4662/4688/4720/4768/4769/7045/1102)
- [ ] Je pratique le threat hunting hypothético-déductif
- [ ] J'ai rédigé un playbook de réponse à incident

### DFIR & malware
- [ ] J'analyse un dump mémoire avec Volatility (processus, réseau, injection)
- [ ] Je construis une timeline disque avec Autopsy
- [ ] Je comprends l'ordre de volatilité et la chaîne de conservation
- [ ] J'analyse un malware statiquement (strings, imports PE, Ghidra) et dynamiquement (lab isolé)
- [ ] J'extrais des IOC et j'écris des détections à partir de mon analyse
- [ ] Je décris le déroulé d'un ransomware et sa défense décisive

---

## 🔵 Niveau 3 — Environnements modernes & spécialisation

### Cloud & DevSecOps
- [ ] J'explique le modèle de responsabilité partagée
- [ ] J'écris des politiques IAM de moindre privilège et je repère les escalades
- [ ] J'ai exploité une chaîne SSRF → IMDS → credentials (CloudGoat)
- [ ] J'audite une posture cloud (ScoutSuite/Prowler) et je corrige
- [ ] Je durcis Docker et je comprends l'évasion de conteneur
- [ ] Je connais les points de sécurité Kubernetes (RBAC, etcd, secrets, network policies)
- [ ] J'ai monté un pipeline DevSecOps (SAST, SCA, secret/IaC scanning)
- [ ] Je comprends les enjeux de la supply chain (SBOM, SLSA, Sigstore)

### Spécialisation & GRC
- [ ] J'ai choisi une voie de spécialisation et commencé ses labs dédiés
- [ ] Je comprends les bases de ma spécialisation (RE/pwn/mobile/IoT/ICS/IA…)
- [ ] Je déroule une analyse de risque (EBIOS RM simplifié)
- [ ] Je connais ISO 27001, RGPD (72 h, sanctions, AIPD), NIS2, CIS Controls
- [ ] Je distingue RTO/RPO et je sais ce qu'est un PCA/PRA
- [ ] J'ai rédigé une politique de sécurité lisible par des non-techniques

---

## 🟣 Niveau 4 — Professionnalisation

### Pratique & portfolio
- [ ] Je tiens un journal de bord de lab depuis ≥ 3 mois sans interruption
- [ ] J'ai un blog / GitHub public avec des write-ups de qualité
- [ ] J'ai participé à au moins un CTF en ligne
- [ ] J'ai résolu ≥ 20 machines/challenges documentés
- [ ] Je refais des labs « à froid » pour ancrer les compétences

### Certification & carrière
- [ ] J'ai une stratégie de certification alignée sur ma voie
- [ ] Je prépare/j'ai obtenu une première certification pratique (eJPT/PNPT/BTL1/CPTS…)
- [ ] Mon CV lie chaque compétence à une preuve concrète
- [ ] Je sais répondre aux questions techniques types d'entretien
- [ ] J'ai une routine de veille structurée (sources sélectionnées, agrégées)
- [ ] Je comprends le bug bounty et l'importance du scope
- [ ] J'ai un plan de carrière écrit à 12 et 24 mois

---

## 📊 Auto-bilan trimestriel

Tous les 3 mois, répondez par écrit :

1. **Qu'est-ce que je sais faire maintenant que je ne savais pas faire il y a 3 mois ?**
2. **Sur quoi ai-je le plus buté, et comment m'en suis-je sorti ?**
3. **Quelle compétence de la checklist est ma prochaine priorité ?**
4. **Mon rythme est-il soutenable ? Que faut-il ajuster ?**
5. **Ma pratique est-elle visible (portfolio) ? Sinon, comment y remédier ?**

> Comparez-vous à **vous-même d'il y a 3 mois**, jamais aux experts de Twitter. La progression
> régulière, mesurée honnêtement, est le seul indicateur qui compte.

---

**← [Sommaire](../README.md)** · [ROADMAP](../ROADMAP.md) · [Cheatsheet](cheatsheet-commandes.md)
