# Module 10 — Blue Team & SOC

> **Objectif :** apprendre à **détecter et répondre** aux attaques des modules précédents.
> Le marché de l'emploi en défense (SOC, détection, threat hunting) est bien plus vaste que
> celui de l'offensive — et souvent la meilleure porte d'entrée dans le métier.
>
> **Durée :** 5 semaines · **Prérequis :** modules 00–09 (attaquer pour savoir détecter)

---

## 10.1 — Le SOC : organisation et rôles

Le **SOC** (Security Operations Center) est l'équipe qui surveille, détecte et répond aux
menaces en continu.

### Les niveaux

| Niveau | Rôle | Compétences |
|---|---|---|
| **Analyste N1** | Tri des alertes, qualification, escalade | Fondamentaux, rigueur, endurance |
| **Analyste N2** | Investigation approfondie, réponse initiale | Analyse, corrélation, forensics léger |
| **Analyste N3 / Threat Hunter** | Chasse proactive, détection avancée, ingénierie de détection | Expertise, créativité, dev |
| **Incident Responder / DFIR** | Gestion des incidents majeurs | Forensics, coordination (module 11) |
| **SOC Manager / CTI** | Pilotage, renseignement sur la menace | Vision, communication |

> **Conseil de carrière :** l'analyste SOC N1 est **la** porte d'entrée la plus accessible
> du domaine. On y apprend énormément, vite, sur des cas réels. Ne la dédaignez pas — beaucoup
> d'experts y ont commencé.

### Les métriques qui structurent le métier

- **MTTD** (Mean Time To Detect) — délai de détection
- **MTTR** (Mean Time To Respond) — délai de réponse
- **Taux de faux positifs** — le fléau du SOC ; trop d'alertes = fatigue = vraies alertes manquées
- **Couverture de détection** (via ATT&CK) — quelles techniques sait-on voir ?

---

## 10.2 — Les journaux : la matière première

**On ne détecte que ce qu'on journalise.** La première tâche défensive est de garantir une
collecte de logs pertinente et centralisée.

### Les sources essentielles

| Source | Ce qu'elle révèle |
|---|---|
| **Journaux Windows (Security)** | Authentification, Kerberos, accès, création de comptes |
| **Sysmon** | Création de processus (avec ligne de commande, hash, parent), connexions réseau, création de fichiers, modifications de registre — **la meilleure télémétrie Windows gratuite** |
| **Logs Linux** (auth, auditd, journald) | Auth, sudo, exécutions, syscalls |
| **Logs réseau** (firewall, proxy, DNS, NetFlow, Zeek) | Communications, C2, exfiltration |
| **Logs applicatifs / web** (nginx, WAF) | Attaques web, accès anormaux |
| **EDR** | Télémétrie riche sur les endpoints, détections comportementales |
| **Cloud** (CloudTrail, Azure AD/Entra sign-in logs) | Actions API, connexions, changements de config |

### Sysmon — à déployer et configurer

Sysmon (Sysinternals) enrichit massivement la journalisation Windows. Les Event ID clés :
- **1** — création de processus (image, ligne de commande, **processus parent**, hash)
- **3** — connexion réseau
- **7** — chargement de DLL (détecte le DLL hijacking)
- **8** — CreateRemoteThread (injection de processus)
- **11** — création de fichier
- **13** — modification de registre

Une configuration de référence : le [Sysmon config de SwiftOnSecurity](https://github.com/SwiftOnSecurity/sysmon-config)
ou celle d'Olaf Hartong. **Déployez Sysmon sur votre lab dès maintenant.**

### Les Windows Event ID à connaître par cœur

| ID | Événement | Détecte |
|---|---|---|
| 4624 / 4625 | Logon réussi / échoué | Brute force, PtH (type 3), accès anormal |
| 4634 / 4647 | Logoff | — |
| 4672 | Privilèges spéciaux au logon | Élévation, admin |
| 4688 | Création de processus (natif) | Exécution, commandes suspectes |
| 4720 / 4726 | Création / suppression de compte | Persistance |
| 4728 / 4732 / 4756 | Ajout à un groupe (global/local/universel) | Élévation de privilèges |
| 4768 / 4769 | TGT / TGS Kerberos | AS-REP roasting, Kerberoasting |
| 4662 | Opération sur objet AD | **DCSync** (GUID de réplication) |
| 7045 | Installation d'un service | Persistance, PsExec |
| 1102 | **Effacement du journal de sécurité** | Anti-forensics — toujours suspect |

---

## 10.3 — Le SIEM : centraliser, corréler, alerter

Le **SIEM** (Security Information and Event Management) agrège tous les logs, les normalise,
les corrèle et déclenche des alertes.

### Solutions

| SIEM | Note |
|---|---|
| **Splunk** | Leader du marché, langage SPL puissant — très demandé en compétence |
| **Elastic (ELK / Elastic Security)** | Open source, incontournable en lab et en PME |
| **Microsoft Sentinel** | Cloud-native, KQL, intégration Microsoft 365/Azure |
| **Wazuh** | Open source (fork OSSEC), HIDS + SIEM, **idéal pour le home lab** |
| **Graylog, QRadar, Chronicle** | Autres acteurs |

### Le pipeline

```
Sources → Collecte (agents, forwarders) → Normalisation/Parsing → Stockage/Index
   → Corrélation & règles de détection → Alertes → Tri analyste → Réponse
```

### Écrire des détections

L'ingénierie de détection est **la** compétence montante du Blue Team. On formalise :
« quel comportement, dans quels logs, avec quelle logique, déclenche quelle alerte ».

Exemple conceptuel (pseudo-requête) : *plus de 10 échecs de logon (4625) suivis d'un
succès (4624) pour un même compte en moins de 2 minutes* → brute force réussi.

```splunk
# Splunk (SPL) — détection de brute force réussi
index=windows EventCode=4625 | stats count by Account_Name, src
  | where count > 10
```

```kql
// Microsoft Sentinel / KQL — Kerberoasting potentiel (rafale de TGS RC4)
SecurityEvent
| where EventID == 4769 and TicketEncryptionType == "0x17"
| summarize count() by Account, bin(TimeGenerated, 5m)
| where count_ > 10
```

---

## 10.4 — Sigma : les détections portables

**Sigma** est un format YAML **agnostique** pour écrire des règles de détection, traduisibles
vers n'importe quel SIEM (Splunk, Elastic, Sentinel…). C'est le « langage commun » de la
détection, comme ATT&CK l'est pour les tactiques.

```yaml
title: Effacement du journal d'événements de sécurité
id: a12b...
status: stable
description: Détecte l'effacement des logs (anti-forensics)
logsource:
    product: windows
    service: security
detection:
    selection:
        EventID: 1102
    condition: selection
level: high
tags:
    - attack.defense_evasion
    - attack.t1070.001
```

Le dépôt **SigmaHQ** contient des milliers de règles prêtes à l'emploi et cartographiées sur
ATT&CK. Savoir **lire, adapter et écrire** du Sigma est une compétence directement
monnayable.

### YARA — détecter les fichiers/malwares

Complémentaire de Sigma (qui cible les logs), **YARA** décrit des motifs pour identifier des
fichiers malveillants (chaînes, séquences d'octets, structures). Essentiel en analyse de
malware (module 11).

```yara
rule Webshell_PHP_Suspect {
    strings:
        $a = "eval($_POST" nocase
        $b = "base64_decode(" nocase
        $c = "system($_GET" nocase
    condition:
        2 of them
}
```

---

## 10.5 — EDR et détection sur les endpoints

L'**EDR** (Endpoint Detection & Response) surveille en continu le comportement des postes et
serveurs : création de processus, injections, accès à LSASS, comportements de ransomware. Il
détecte, alerte, isole une machine, et permet l'investigation à distance.

- **Solutions :** CrowdStrike Falcon, Microsoft Defender for Endpoint, SentinelOne, Elastic Defend, Wazuh (basique)
- **XDR** — extension de l'EDR qui corrèle endpoints + réseau + cloud + mail
- **Ce qu'un EDR détecte bien :** dump LSASS, injection de processus, ransomware (chiffrement massif), living-off-the-land suspect, C2
- **Ce qu'il détecte mal :** attaques « sans malware » très discrètes, abus d'identifiants légitimes → d'où l'importance de la corrélation SIEM et du threat hunting

---

## 10.6 — Le threat hunting

La chasse **proactive** : au lieu d'attendre l'alerte, on **cherche** l'attaquant sous
l'hypothèse qu'il est déjà présent.

### La démarche hypothético-déductive

```
1. Hypothèse — « Un attaquant utilise peut-être PsExec pour se déplacer latéralement »
2. Données — quels logs le montreraient ? (7045, 4624 type 3, Sysmon 1)
3. Recherche — requêter, filtrer le légitime
4. Analyse — trier vrais/faux positifs
5. Résultat — soit une détection, soit une nouvelle règle pérenne, soit une lacune de visibilité identifiée
```

Le hunting s'appuie sur **ATT&CK** (quelles techniques chasser), sur la **CTI** (que fait
tel groupe), et sur la connaissance de son propre environnement (savoir ce qui est
« normal » est la clé — on détecte l'anomalie contre une baseline).

### La CTI (Cyber Threat Intelligence)

Le renseignement sur la menace nourrit la défense :
- **IOC** (indicateurs de compromission) — hashes, IP, domaines. Utiles mais **volatils** (Pyramid of Pain).
- **TTP** — comportements durables des groupes → détections robustes.
- **Sources** : MISP (plateforme de partage), flux commerciaux, CERT/CSIRT (CERT-FR en France), rapports d'éditeurs.

---

## 10.7 — La réponse à incident (introduction)

Détaillée au [module 11](11-dfir-malware.md). Le cadre **NIST SP 800-61** en 4 phases :

```
1. Préparation        — outils, procédures, playbooks, formation, sauvegardes
2. Détection & analyse — qualifier : est-ce un vrai incident ? périmètre ? gravité ?
3. Confinement, éradication & récupération — isoler, supprimer, restaurer
4. Post-incident (leçons apprises) — améliorer, documenter, corriger la cause racine
```

Un **playbook** est une procédure prête à l'emploi pour un type d'incident (phishing,
ransomware, compte compromis). En avoir **avant** l'incident fait toute la différence entre
une gestion maîtrisée et la panique.

> **Principe crucial du confinement :** **isoler avant d'éradiquer**, mais **préserver les
> preuves** (ne pas éteindre brutalement une machine → on perd la RAM ; isoler du réseau
> plutôt). L'équilibre entre « arrêter l'hémorragie » et « préserver l'investigation » est
> l'art de la réponse à incident.

---

## 10.8 — Le durcissement et la réduction de surface (synthèse défensive)

La meilleure détection ne remplace pas la prévention. Les mesures à plus fort impact :

1. **MFA partout** (surtout VPN, mail, admin) — arrête la majorité des intrusions par compte
2. **Patching** rigoureux et priorisé (surtout périmètre : VPN, serveurs exposés)
3. **Moindre privilège** et **tiering** (module 05)
4. **Segmentation réseau** — contient le mouvement latéral
5. **Sauvegardes** testées, hors ligne/immuables (la seule vraie défense anti-ransomware)
6. **EDR** déployé partout, en mode blocage
7. **Journalisation** centralisée et surveillée
8. **Désactivation** de ce qui est inutile (LLMNR, NTLM, macros Office, services legacy)
9. **Sensibilisation** continue (le phishing reste le vecteur n°1)
10. **Gestion des vulnérabilités** en cycle continu (scan → priorisation → remédiation → vérification)

Cadres de référence : **CIS Controls v8** (IG1 = hygiène de base), **NIST CSF 2.0**,
**guides ANSSI**.

---

## ✅ Labs du module 10

- [ ] **Lab 10.1 — Monter un SIEM.** Déployez **Wazuh** (ou ELK) dans votre lab. Faites remonter les logs de vos machines Linux et Windows. **Le lab fondateur du Blue Team.**
- [ ] **Lab 10.2 — Sysmon.** Installez Sysmon avec une config de référence sur vos machines Windows. Générez de l'activité et explorez la télémétrie produite.
- [ ] **Lab 10.3 — Détecter vos propres attaques.** Rejouez les attaques des modules 08/09 (brute force, Kerberoasting, PtH, PsExec) et **retrouvez-les dans votre SIEM**. Écrivez une règle de détection pour chacune.
- [ ] **Lab 10.4 — Sigma.** Écrivez 5 règles Sigma (dont l'effacement de log, le brute force, la création de compte, PsExec) et convertissez-les vers votre SIEM avec `sigma`/`pySigma`.
- [ ] **Lab 10.5 — YARA.** Écrivez une règle YARA qui détecte un webshell PHP simple, testez-la sur un jeu de fichiers.
- [ ] **Lab 10.6 — Blue Team CTF.** Faites [CyberDefenders](https://cyberdefenders.org) et [Blue Team Labs Online](https://blueteamlabs.online) : investigations réalistes sur des cas concrets.
- [ ] **Lab 10.7 — Threat hunting.** Formulez 3 hypothèses de chasse (ex : « exécution suspecte via PowerShell encodé »), cherchez-les dans vos logs, documentez la démarche.
- [ ] **Lab 10.8 — Playbook.** Rédigez un playbook de réponse pour « poste compromis par phishing » : détection, confinement, éradication, récupération, communication.

---

## 🎯 Auto-évaluation

1. Quels sont les niveaux d'un SOC et par lequel entre-t-on généralement ?
2. Pourquoi le taux de faux positifs est-il un problème central du SOC ?
3. Qu'apporte Sysmon par rapport à la journalisation Windows native ?
4. Quel Event ID pour : PtH, DCSync, effacement de log, création de compte, PsExec ?
5. Qu'est-ce que Sigma et pourquoi est-il « agnostique » ?
6. Différence entre Sigma et YARA ? Quand utiliser l'un ou l'autre ?
7. Décrivez la démarche du threat hunting hypothético-déductif.
8. Pourquoi « isoler avant d'éradiquer » et « préserver la RAM » en réponse à incident ?
9. Citez les 5 mesures de durcissement à plus fort impact et justifiez.

---

**Suivant → [Module 11 : Forensics & analyse de malware](11-dfir-malware.md)**
