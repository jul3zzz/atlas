# Module 01 — Fondamentaux de la sécurité

> **Objectif :** acquérir le vocabulaire et les modèles mentaux du métier. Savoir raisonner
> en termes de risque, de menace et de surface d'attaque, avant de toucher au moindre outil.
>
> **Durée :** 2 semaines · **Prérequis :** module 00

---

## 1.1 — Les propriétés de sécurité : DICP

Le modèle français **DICP** (le monde anglo-saxon dit **CIA + traçabilité**) définit ce
qu'on cherche à protéger. Toute mesure de sécurité sert au moins l'une de ces propriétés.

| Propriété | Définition | Atteinte typique | Contre-mesures |
|---|---|---|---|
| **D**isponibilité | L'information est accessible quand on en a besoin | DDoS, ransomware, panne | Redondance, sauvegardes, plan de reprise, anti-DDoS |
| **I**ntégrité | L'information n'est pas altérée de façon non autorisée | Défiguration, corruption, manipulation de transaction | Hash, signature, contrôle d'accès en écriture, journaux |
| **C**onfidentialité | Seuls les autorisés accèdent à l'information | Fuite de données, écoute réseau, vol de sauvegarde | Chiffrement, cloisonnement, moindre privilège |
| **P**reuve / traçabilité | On peut prouver qui a fait quoi, et quand | Effacement de logs, comptes partagés | Journalisation centralisée, horodatage, non-répudiation |

**Application concrète :** un hôpital privilégie D et I (un dossier patient indisponible
ou faux tue). Un cabinet d'avocats privilégie C. Une banque a besoin des quatre, avec
P au premier plan pour les preuves réglementaires. **Il n'existe pas de sécurité universelle :
il existe une sécurité adaptée à un contexte.**

### Les propriétés dérivées

- **Authenticité** — l'entité est bien celle qu'elle prétend être
- **Non-répudiation** — l'auteur d'une action ne peut pas la nier (signature électronique)
- **Imputabilité** — chaque action est rattachable à un individu identifié (⇒ jamais de compte partagé)

---

## 1.2 — Menace, vulnérabilité, risque : ne jamais confondre

C'est l'erreur de vocabulaire n°1 des débutants, et elle est éliminatoire en entretien.

```
RISQUE  =  MENACE  ×  VULNÉRABILITÉ  ×  IMPACT
                 (le tout modulé par la vraisemblance)
```

- **Actif (asset)** — ce qui a de la valeur : données, service, réputation, vies humaines.
- **Menace (threat)** — l'événement redouté ou l'acteur qui pourrait nuire. *Existe indépendamment de vous.*
- **Vulnérabilité** — la faiblesse exploitable. *Vous en êtes responsable.*
- **Exploit** — le moyen technique concret d'utiliser la vulnérabilité.
- **Impact** — les conséquences si ça arrive.
- **Risque** — la combinaison des précédents. *C'est ce qui se gère.*

> **Analogie :** la pluie est une menace. Un toit percé est une vulnérabilité. Le risque,
> c'est que vos meubles soient trempés. Vous ne pouvez pas empêcher la pluie ; vous pouvez
> réparer le toit, déplacer les meubles, ou souscrire une assurance.

### Les quatre traitements du risque

| Traitement | Description | Exemple |
|---|---|---|
| **Réduire** | Mettre en place des mesures | Patcher, chiffrer, segmenter |
| **Transférer** | Faire porter le risque par un tiers | Cyberassurance, infogérance |
| **Éviter** | Supprimer l'activité risquée | Arrêter un service legacy |
| **Accepter** | Assumer en connaissance de cause | Risque faible, coût de traitement disproportionné |

**Point clé souvent mal compris :** accepter un risque est une décision **légitime et
documentée**, prise par le métier, pas par la technique. Le rôle du RSSI est d'éclairer
la décision, pas de la prendre seul. Un risque accepté doit être tracé, daté, signé et réévalué.

### Le risque résiduel

Après traitement, il reste toujours du risque. Le risque zéro n'existe pas — quiconque
le promet est incompétent ou malhonnête. L'objectif est de ramener le risque à un niveau
**acceptable** au regard de l'appétence au risque de l'organisation.

---

## 1.3 — Les acteurs de la menace

| Acteur | Motivation | Moyens | Sophistication |
|---|---|---|---|
| **Script kiddie** | Amusement, ego | Outils publics | Faible |
| **Hacktiviste** | Idéologie | Défiguration, DDoS, fuites | Faible à moyenne |
| **Cybercriminel** | Argent | Ransomware, phishing, fraude, RaaS | Moyenne à élevée |
| **Initié (insider)** | Vengeance, argent, négligence | Accès légitime | Variable — **souvent le plus dangereux** |
| **Concurrent** | Espionnage économique | Sous-traitance à des groupes spécialisés | Moyenne |
| **État / APT** | Renseignement, sabotage, influence | 0-day, moyens quasi illimités, patience | Très élevée |

### Le modèle économique du cybercrime moderne

Comprendre l'écosystème permet de comprendre les tactiques :

```
Initial Access Broker  →  vend un accès (VPN, RDP, phishing réussi)
        ↓
Affilié Ransomware     →  loue le rançongiciel (RaaS), fait l'intrusion,
                          exfiltre puis chiffre (double extorsion)
        ↓
Opérateur RaaS         →  fournit le malware, le site de fuite, la négociation
        ↓
Blanchiment            →  mixers crypto, cash-out
```

**Conséquence défensive :** la plupart des intrusions ne sont pas ciblées. Elles sont
**opportunistes** — un scan de masse trouve un VPN non patché ou un RDP exposé avec un mot
de passe faible. C'est pourquoi l'hygiène de base (patching, MFA, moindre privilège)
arrête l'écrasante majorité des attaques réelles, bien plus que n'importe quel outil coûteux.

### APT — Advanced Persistent Threat

Un adversaire **financé, patient et déterminé**, généralement étatique. Caractéristiques :
objectif de long terme (mois ou années), discrétion maximale, usage d'outils légitimes
(*living off the land*), capacité à développer ses propres 0-day.

Face à un APT, la question n'est pas « comment empêcher l'intrusion » mais **« comment la
détecter vite et limiter sa progression »** — d'où la bascule du secteur vers la détection
et la réponse (EDR/XDR/SOC) plutôt que la seule prévention périmétrique.

---

## 1.4 — La modélisation de menace (threat modeling)

Se poser quatre questions, dans l'ordre, avant de concevoir ou d'auditer un système :

1. **Sur quoi travaillons-nous ?** (architecture, flux de données, périmètre de confiance)
2. **Qu'est-ce qui peut mal tourner ?** (identification des menaces)
3. **Qu'allons-nous faire ?** (contre-mesures)
4. **Avons-nous bien fait le travail ?** (validation, tests)

### STRIDE — la grille de Microsoft

Pour chaque composant et chaque flux, on passe la grille :

| Lettre | Menace | Propriété violée | Exemple | Contre-mesure |
|---|---|---|---|---|
| **S** | Spoofing (usurpation) | Authenticité | Se faire passer pour un admin | MFA, certificats mutuels |
| **T** | Tampering (altération) | Intégrité | Modifier un panier en transit | Signature, HTTPS, contrôle serveur |
| **R** | Repudiation | Non-répudiation | Nier une transaction | Journalisation signée |
| **I** | Information disclosure | Confidentialité | Fuite via message d'erreur | Chiffrement, gestion d'erreurs générique |
| **D** | Denial of service | Disponibilité | Saturation d'un endpoint | Rate limiting, quotas, autoscaling |
| **E** | Elevation of privilege | Autorisation | Utilisateur devenant admin | Contrôle d'accès côté serveur, moindre privilège |

**Méthode pratique :** dessinez le diagramme de flux de données (DFD) de votre application,
tracez les **frontières de confiance** (là où la donnée change de niveau de confiance :
Internet → DMZ → back-end → base). C'est **sur ces frontières** que se concentrent les
menaces. Puis appliquez STRIDE sur chaque flux traversant une frontière.

### Autres modèles utiles

- **DREAD** — scoring d'impact (Damage, Reproducibility, Exploitability, Affected users, Discoverability). Critiqué pour sa subjectivité, mais utile en interne.
- **PASTA** — approche en 7 étapes centrée sur la simulation d'attaque, orientée métier.
- **Attack Trees** — arbre logique : l'objectif de l'attaquant en racine, les moyens en branches. Excellent pour communiquer avec des non-techniques.
- **LINDDUN** — l'équivalent de STRIDE pour la **vie privée** (utile en contexte RGPD).

---

## 1.5 — MITRE ATT&CK : le langage commun

**ATT&CK** (Adversarial Tactics, Techniques & Common Knowledge) est une base de connaissances
des comportements réels d'attaquants, observés sur le terrain. C'est **le référentiel
structurant du métier** — vous l'utiliserez en offensive comme en défensive.

### La hiérarchie

```
Tactique  = le POURQUOI (l'objectif de l'attaquant à cette étape)
   └── Technique = le COMMENT (T1078 — Valid Accounts)
          └── Sous-technique = la variante précise (T1078.002 — Domain Accounts)
                 └── Procédure = l'implémentation d'un groupe donné
```

### Les 14 tactiques Enterprise, dans l'ordre d'une intrusion

| # | Tactique | Objectif de l'attaquant |
|---|---|---|
| 1 | **Reconnaissance** | Collecter de l'information sur la cible |
| 2 | **Resource Development** | Préparer l'infrastructure (domaines, malware, comptes) |
| 3 | **Initial Access** | Entrer (phishing, exploit public, compte valide) |
| 4 | **Execution** | Faire exécuter son code |
| 5 | **Persistence** | Survivre au redémarrage et à la remédiation |
| 6 | **Privilege Escalation** | Obtenir plus de droits |
| 7 | **Defense Evasion** | Ne pas être détecté (le plus gros catalogue) |
| 8 | **Credential Access** | Voler des identifiants |
| 9 | **Discovery** | Cartographier l'environnement interne |
| 10 | **Lateral Movement** | Se déplacer vers d'autres machines |
| 11 | **Collection** | Rassembler les données d'intérêt |
| 12 | **Command & Control** | Piloter les machines compromises |
| 13 | **Exfiltration** | Sortir les données |
| 14 | **Impact** | Chiffrer, détruire, manipuler |

> **À retenir :** ces tactiques ne sont pas strictement séquentielles. Un attaquant boucle
> (escalade → découverte → mouvement latéral → escalade…). Mais l'ordre général est un
> excellent modèle mental — et une grille de lecture pour toute analyse d'incident.

### Usages concrets d'ATT&CK

- **Red team** : construire un scénario réaliste calqué sur un groupe précis (émulation d'adversaire)
- **Blue team** : mesurer la **couverture de détection** (quelles techniques sais-je détecter ?)
- **Purple team** : rejouer des techniques et vérifier que la détection se déclenche
- **CTI** : décrire un groupe adverse dans un langage partagé
- **Direction** : justifier un budget avec une carte de chaleur des lacunes

**Outil :** [ATT&CK Navigator](https://mitre-attack.github.io/attack-navigator/) — permet de
colorier les techniques couvertes/non couvertes. Un livrable très apprécié en entreprise.

### Les modèles voisins

- **Cyber Kill Chain (Lockheed Martin)** — 7 étapes, plus ancienne et plus linéaire. Encore citée, mais moins opérationnelle qu'ATT&CK.
- **Diamond Model** — analyse un événement selon 4 axes : adversaire, capacité, infrastructure, victime. Très utile en CTI pour pivoter d'un indicateur à un autre.
- **Pyramid of Pain (David Bianco)** — hiérarchise les indicateurs selon la douleur infligée à l'attaquant quand on les bloque :

```
        TTPs                  ← très difficile à changer pour l'attaquant  ★ VISEZ ICI
        Outils
        Artefacts réseau/hôte
        Noms de domaine
        Adresses IP
        Hashes de fichiers    ← trivial à changer (1 octet modifié)
```

> **Leçon :** bloquer un hash ou une IP n'embête l'attaquant que quelques minutes.
> Détecter un **comportement** (une TTP) le force à repenser sa méthode. C'est pour cela
> que la détection moderne est comportementale, pas signaturale.

---

## 1.6 — Les principes de conception sécurisée

Ces principes, formalisés dès 1975 par Saltzer et Schroeder, restent la meilleure grille
de décision architecturale.

### Défense en profondeur

Plusieurs couches indépendantes, pour qu'aucune défaillance unique ne soit fatale.

```
Sensibilisation ▸ Périmètre (pare-feu, WAF) ▸ Segmentation réseau
▸ Durcissement des systèmes ▸ Contrôle d'accès ▸ EDR ▸ Chiffrement
▸ Journalisation & détection ▸ Sauvegardes ▸ Plan de réponse
```

**Test mental :** « si cette mesure tombe, que se passe-t-il ? » Si la réponse est
« tout est compromis », votre architecture est en château fort, pas en défense en profondeur.

### Moindre privilège

Chaque utilisateur, processus et service ne dispose **que** des droits strictement
nécessaires, **et uniquement pendant la durée nécessaire**.

En pratique : pas d'admin de domaine pour lire ses mails, comptes de service dédiés
sans droits interactifs, `sudo` ciblé plutôt que `root`, accès temporaires (JIT) plutôt que permanents.

> C'est la mesure qui a le **meilleur rapport efficacité/coût** de toute la sécurité
> informatique. Et la plus souvent négligée.

### Les autres principes essentiels

| Principe | Signification | Contre-exemple courant |
|---|---|---|
| **Fail secure** | En cas d'erreur, refuser par défaut | Un `catch` qui laisse passer la requête |
| **Sécurité par défaut** | La config d'usine est la config sûre | Base de données ouverte sur `0.0.0.0` |
| **Séparation des tâches** | Deux personnes pour une action critique | Le dev qui déploie seul en production |
| **Médiation complète** | Vérifier les droits à **chaque** accès | Autorisation vérifiée uniquement à la 1ʳᵉ page |
| **Économie de mécanisme** | Simple = auditable | Une politique d'accès de 400 règles |
| **Maillon faible** | La sécurité vaut celle de son point le plus faible | Firewall à 100 k€ et mot de passe `Ete2024!` |
| **Surface d'attaque minimale** | Désactiver ce qui n'est pas utilisé | 40 services actifs sur un serveur web |
| **Pas de sécurité par l'obscurité** | Le secret doit être la clé, pas l'algorithme | Un « chiffrement maison » |

### Principe de Kerckhoffs (1883)

> *Un système cryptographique doit rester sûr même si tout, sauf la clé, est public.*

Corollaire moderne : méfiez-vous de tout produit dont l'argument de vente est « notre
algorithme est secret ». La cryptographie solide est publique, revue, attaquée depuis
des décennies — c'est précisément ce qui fait sa solidité.

### Zero Trust

Modèle qui abandonne la notion de « réseau interne de confiance ».
**« Never trust, always verify »** :

- Chaque accès est authentifié, autorisé et chiffré, **quelle que soit sa provenance**
- L'identité devient le nouveau périmètre
- Vérification continue de la posture (santé de l'appareil, contexte, comportement)
- Micro-segmentation, accès juste-à-temps

**Pourquoi :** avec le télétravail, le cloud et le SaaS, le périmètre réseau n'existe plus.
Un attaquant qui franchit le pare-feu ne doit pas se retrouver dans un réseau plat où tout
se fait confiance — c'est exactement ce qui transforme une intrusion en ransomware généralisé.

---

## 1.7 — Identité et gestion des accès (IAM)

### Les trois A

- **Authentification** — prouver qui l'on est
- **Autorisation** — déterminer ce que l'on a le droit de faire
- **Accounting / Audit** — tracer ce qui a été fait

### Les facteurs d'authentification

| Facteur | Nature | Exemples | Faiblesses |
|---|---|---|---|
| **Savoir** | Ce que je sais | Mot de passe, PIN | Devinable, réutilisé, phishable |
| **Possession** | Ce que j'ai | Téléphone, token, carte | Vol, SIM swap, interception SMS |
| **Inhérence** | Ce que je suis | Empreinte, visage | Non révocable, contournable |
| *Contexte* | Où/quand je suis | IP, géoloc, horaire | Facteur d'appoint uniquement |

**MFA = au moins deux facteurs de catégories différentes.** Mot de passe + question secrète
= deux fois « savoir » = **pas** du MFA.

### Hiérarchie de robustesse du MFA

```
❌ SMS / appel vocal      — vulnérable au SIM swapping, à l'interception SS7
⚠️  Notification push      — vulnérable à la « MFA fatigue » (spam de notifications)
✅ TOTP (Google Auth…)     — bon niveau, mais phishable en temps réel via proxy (Evilginx)
✅✅ FIDO2 / WebAuthn      — RÉSISTANT AU PHISHING : la clé vérifie le domaine
                              cryptographiquement, un site clone ne peut pas obtenir de réponse valide
```

> **Recommandation professionnelle :** pour les comptes à privilèges, exigez FIDO2.
> C'est aujourd'hui la seule forme de MFA qui résiste structurellement au phishing —
> les campagnes d'AiTM (adversary-in-the-middle) contournent tout le reste.

### Modèles de contrôle d'accès

| Modèle | Principe | Où on le rencontre |
|---|---|---|
| **DAC** | Le propriétaire décide | Permissions de fichiers Unix/NTFS |
| **MAC** | Le système impose des niveaux | SELinux, AppArmor, contextes militaires |
| **RBAC** | Droits attribués via des rôles | Entreprise, Kubernetes, AD |
| **ABAC** | Droits calculés selon des attributs (heure, lieu, appareil) | Cloud moderne, accès conditionnel |

### Politique de mots de passe — ce qui a changé

Les recommandations NIST SP 800-63B et ANSSI actuelles renversent les vieilles habitudes :

✅ **Recommandé aujourd'hui :**
- Priorité à la **longueur** (≥ 12, idéalement ≥ 16 caractères) sur la complexité
- Phrases de passe : `cheval-agrafe-batterie-correct`
- Vérification contre les listes de mots de passe compromis (HIBP)
- Gestionnaire de mots de passe **obligatoire**, un mot de passe unique par service
- MFA partout où c'est possible

❌ **Abandonné (contre-productif) :**
- Expiration périodique forcée sans raison → pousse à `Ete2024!` puis `Ete2025!`
- Complexité imposée arbitraire → pousse à `P@ssw0rd`
- Questions secrètes (les réponses sont sur les réseaux sociaux)
- Interdiction du copier-coller (empêche les gestionnaires de mots de passe)

---

## 1.8 — La gouvernance de la sécurité (introduction)

Approfondi au [module 14](14-grc-conformite.md), mais posons les bases.

### Politique, standard, procédure

```
POLITIQUE (PSSI)  — le QUOI et le POURQUOI. Signée par la direction. Stable.
    └── STANDARD  — le niveau à atteindre. « TLS 1.2 minimum »
        └── PROCÉDURE — le COMMENT, pas à pas. « Comment configurer nginx »
            └── GUIDE / bonne pratique — recommandé, non obligatoire
```

### Le triptyque humain / organisationnel / technique

Une mesure purement technique échoue toujours si l'organisation ne suit pas.
Exemple : déployer un antivirus de pointe (technique) sans procédure de traitement
des alertes (organisationnel) ni sensibilisation (humain) ⇒ alertes ignorées, budget gaspillé.

**Le facteur humain reste le vecteur d'entrée majoritaire** (phishing, erreur de
configuration, mot de passe faible). Investir dans la sensibilisation a un rendement
supérieur à beaucoup d'outils — à condition qu'elle soit bienveillante et régulière,
pas culpabilisante et annuelle.

### Cadres de référence à connaître de nom

| Cadre | Origine | Usage |
|---|---|---|
| **ISO/IEC 27001 & 27002** | International | Certification d'un SMSI |
| **NIST CSF 2.0** | États-Unis | 6 fonctions : Govern, Identify, Protect, Detect, Respond, Recover |
| **CIS Controls v8** | CIS | 18 contrôles priorisés — **le meilleur point de départ opérationnel** |
| **EBIOS Risk Manager** | ANSSI (France) | Analyse de risque par scénarios |
| **NIS2** | Union européenne | Directive contraignante, transposée 2024-2025 |
| **RGPD** | Union européenne | Protection des données personnelles |
| **PCI-DSS** | Industrie bancaire | Obligatoire si traitement de cartes |

> **Pour un débutant :** les **CIS Controls v8** sont le document le plus utile à lire en
> entier. Ils sont concrets, priorisés (Implementation Groups 1/2/3), et le groupe IG1
> constitue une excellente définition de « l'hygiène cyber de base ».

---

## ✅ Labs du module 01

- [ ] **Lab 1.1 — Modélisation STRIDE.** Choisissez une application que vous connaissez (une boutique en ligne, une app bancaire). Dessinez son DFD avec les frontières de confiance, puis appliquez STRIDE à chaque flux traversant une frontière. Produisez un tableau menace / impact / contre-mesure. **Livrable : 2 pages.**
- [ ] **Lab 1.2 — Analyse de risque simplifiée.** Sur ce même système, listez 10 risques, cotez-les (vraisemblance × impact sur 4 niveaux), placez-les sur une matrice, et proposez un traitement pour chacun.
- [ ] **Lab 1.3 — ATT&CK Navigator.** Ouvrez la matrice Enterprise. Choisissez un groupe (APT29, FIN7, Lazarus), coloriez ses techniques connues. Puis, pour 5 techniques, cherchez comment vous les détecteriez. **Cet exercice est directement transposable en entretien.**
- [ ] **Lab 1.4 — Audit de votre propre hygiène.** Inventaire de vos comptes, activation du MFA (FIDO2 ou TOTP) sur les comptes critiques, migration vers un gestionnaire de mots de passe (Bitwarden/KeePassXC), vérification sur [haveibeenpwned.com](https://haveibeenpwned.com). **On ne peut pas défendre les autres sans se défendre soi-même.**
- [ ] **Lab 1.5 — CIS Controls.** Lisez l'IG1 des CIS Controls v8 et évaluez un système que vous connaissez (votre PC, un serveur personnel) contre ces contrôles.

---

## 🎯 Auto-évaluation

1. Différence exacte entre menace, vulnérabilité, exploit et risque ?
2. Un client dit « je veux le risque zéro ». Que répondez-vous ?
3. Citez les 6 lettres de STRIDE et une contre-mesure pour chacune.
4. Pourquoi la Pyramid of Pain conclut-elle qu'il faut détecter des TTP plutôt que des hashes ?
5. Mot de passe + question secrète : est-ce du MFA ? Justifiez.
6. Pourquoi le NIST déconseille-t-il désormais l'expiration périodique des mots de passe ?
7. Expliquez Zero Trust à un directeur financier, en 3 phrases, sans jargon.
8. Dans quel ordre placeriez-vous : segmentation réseau, achat d'un EDR, MFA sur le VPN, sensibilisation ? Justifiez par le rapport coût/efficacité.

---

**Suivant → [Module 02 : Cryptographie appliquée](02-cryptographie.md)**
