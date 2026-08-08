# Module 14 — GRC, normes & conformité

> **Objectif :** comprendre le versant gouvernance, risque et conformité. Même le
> professionnel le plus technique doit savoir dans quel cadre légal et normatif il opère. Et
> la GRC est une voie de carrière à part entière, en forte demande.
>
> **Durée :** 3 semaines · **Prérequis :** module 01 (fondamentaux)

> La technique sans gouvernance ne s'aligne sur rien ; la gouvernance sans technique est
> déconnectée du réel. Les meilleurs professionnels comprennent les deux mondes et les font
> dialoguer.

---

## 14.1 — Qu'est-ce que la GRC

**GRC** = Gouvernance, Risque, Conformité.

- **Gouvernance** — qui décide, selon quelles règles, avec quelles responsabilités (rôles,
  politiques, comités, reporting à la direction)
- **Risque** — identifier, évaluer, traiter et suivre les risques (module 01)
- **Conformité** — respecter les obligations légales, réglementaires et contractuelles

La sécurité n'est pas qu'un sujet technique : c'est une **décision de gestion** qui engage
la direction. La GRC est ce qui relie la technique aux enjeux de l'organisation, et à sa
responsabilité juridique.

---

## 14.2 — Le SMSI et l'ISO/IEC 27001

Un **SMSI** (Système de Management de la Sécurité de l'Information) est un dispositif
organisé et **continu** de gestion de la sécurité — pas un projet ponctuel.

### ISO/IEC 27001

La norme internationale certifiable pour un SMSI. Elle impose une démarche fondée sur le
risque et l'amélioration continue (roue de **Deming — PDCA** : Plan-Do-Check-Act).

- **Clauses 4 à 10** — les exigences du système de management (contexte, leadership,
  planification, support, fonctionnement, évaluation, amélioration)
- **Annexe A** — les mesures de sécurité (contrôles), détaillées dans l'**ISO/IEC 27002**
  (édition 2022 : 93 contrôles en 4 thèmes — organisationnel, humain, physique, technologique)
- **SoA** (Statement of Applicability / Déclaration d'applicabilité) — quels contrôles
  s'appliquent et pourquoi

### La famille ISO 27000
27005 (gestion des risques), 27017/27018 (cloud, données personnelles cloud), 27701 (vie
privée), 27035 (gestion d'incident), 27037 (preuve numérique)…

---

## 14.3 — Les autres cadres et référentiels

| Cadre | Nature | À retenir |
|---|---|---|
| **NIST CSF 2.0** | Volontaire, très répandu | 6 fonctions : **Govern, Identify, Protect, Detect, Respond, Recover** |
| **NIST SP 800-53 / 800-171** | Catalogue de contrôles (secteur public US, sous-traitants) | Très détaillé |
| **CIS Controls v8** | 18 contrôles priorisés (IG1/2/3) | **Le plus concret pour démarrer** |
| **EBIOS Risk Manager** | Méthode d'analyse de risque ANSSI | Approche par scénarios et sources de risque |
| **MITRE ATT&CK** | Base de connaissances des TTP | Le pont technique/gouvernance |
| **PCI-DSS** | Obligatoire si traitement de cartes | Sanctions contractuelles lourdes |
| **SOC 2** | Rapport d'attestation (fournisseurs) | Fréquent dans le SaaS B2B |
| **HDS** | Hébergement de données de santé (France) | Obligatoire pour la santé |

---

## 14.4 — Le cadre légal et réglementaire (France / UE)

### RGPD — protection des données personnelles

Le **Règlement Général sur la Protection des Données** encadre le traitement des données
personnelles dans l'UE. Points structurants pour un professionnel de la sécurité :

- **Principes** : licéité, minimisation, limitation des finalités, exactitude, limitation de
  conservation, **intégrité et confidentialité (sécurité)**, responsabilité (accountability)
- **Droits des personnes** : accès, rectification, effacement, portabilité, opposition
- **Rôles** : responsable de traitement, sous-traitant, **DPO** (délégué à la protection des données)
- **Sécurité (art. 32)** : mesures techniques et organisationnelles appropriées
- **Notification de violation** : à la **CNIL sous 72 h**, et aux personnes si risque élevé
- **Sanctions** : jusqu'à **20 M€ ou 4 %** du chiffre d'affaires mondial
- **AIPD/PIA** : analyse d'impact obligatoire pour les traitements à risque élevé

> Un incident de sécurité impliquant des données personnelles a **toujours** une dimension
> RGPD. Savoir déclencher la notification et documenter est une compétence de réponse à incident.

### NIS2 — la directive qui change l'échelle

La directive **NIS2** (transposée en droit national 2024-2025) élargit considérablement les
obligations de cybersécurité :
- **Champ élargi** : bien plus d'entités concernées (secteurs « essentiels » et « importants »),
  y compris de taille moyenne
- **Obligations** : gestion des risques, mesures minimales, **notification d'incident**
  (alerte précoce sous 24 h, notification sous 72 h), sécurité de la chaîne d'approvisionnement
- **Responsabilité des dirigeants** engagée, sanctions significatives
- En France, l'**ANSSI** est l'autorité de référence

### Autres textes à connaître de nom

- **DORA** — résilience opérationnelle numérique du secteur financier (UE)
- **Cyber Resilience Act (CRA)** — exigences de sécurité des produits numériques (UE)
- **AI Act** — encadrement de l'IA (UE)
- **Code pénal (art. 323-x)** — les infractions informatiques (voir README)
- **LPM / dispositions OIV-OSE** — opérateurs d'importance vitale/de services essentiels

---

## 14.5 — La gestion des risques en pratique

### La démarche générale

```
1. Établir le contexte (périmètre, enjeux, critères d'acceptation)
2. Identifier les risques (actifs, menaces, vulnérabilités, scénarios)
3. Analyser (vraisemblance × impact)
4. Évaluer (comparer aux critères, prioriser)
5. Traiter (réduire, transférer, éviter, accepter — module 01)
6. Suivre et réviser (le risque évolue en continu)
```

### EBIOS Risk Manager (ANSSI)

Méthode française structurée en 5 ateliers :
1. **Cadrage et socle de sécurité** — périmètre, valeurs métier, événements redoutés
2. **Sources de risque** — qui pourrait attaquer, avec quelles motivations
3. **Scénarios stratégiques** — chemins d'attaque de haut niveau (écosystème, parties prenantes)
4. **Scénarios opérationnels** — déclinaison technique des chemins (proche d'ATT&CK)
5. **Traitement du risque** — plan d'action, risques résiduels acceptés

EBIOS RM est appréciée car elle relie explicitement le **métier** (ateliers 1-2) et la
**technique** (atelier 4) — exactement le pont que ce module cherche à construire.

### Registre des risques et matrice

Le **registre des risques** consigne chaque risque, son évaluation, son traitement, son
propriétaire et son statut. La **matrice** (vraisemblance × impact) visualise les priorités.
Ces livrables sont le langage de la direction — savoir les produire vous rend crédible au-delà
de la technique.

---

## 14.6 — L'audit de sécurité

### Types d'audit

- **Audit organisationnel** — conformité à une norme (ISO 27001), à une politique
- **Audit technique** — configuration, architecture, code
- **Test d'intrusion** — l'audit offensif (module 08)
- **Audit de conformité** — RGPD, PCI-DSS, NIS2

### Le déroulé
Cadrage → collecte de preuves (entretiens, documents, tests) → analyse des écarts → rapport
(constats, non-conformités, recommandations priorisées) → plan d'action → suivi.

### Les trois lignes de maîtrise
```
1ʳᵉ ligne : opérationnels (qui gèrent le risque au quotidien)
2ᵉ ligne : fonctions de contrôle (RSSI, conformité, risque)
3ᵉ ligne : audit interne (assurance indépendante)
```
Comprendre ce modèle situe votre rôle et vos interlocuteurs dans l'organisation.

---

## 14.7 — Continuité, résilience et gestion de crise

- **PCA** (Plan de Continuité d'Activité) — maintenir les activités critiques pendant un sinistre
- **PRA/PRI** (Plan de Reprise) — restaurer les systèmes après sinistre
- **BIA** (Business Impact Analysis) — identifier les activités critiques et leurs délais tolérables
- **RTO** (Recovery Time Objective) — durée max d'interruption acceptable
- **RPO** (Recovery Point Objective) — perte de données max acceptable (⇒ fréquence des sauvegardes)
- **Gestion de crise** — cellule de crise, communication (interne, clients, autorités, médias),
  décisions sous pression, **exercices réguliers**

> Un plan jamais testé est un plan qui échouera. Les exercices de crise (table-top,
> simulations) valent plus que la documentation la plus soignée.

### La cyberassurance
Transfert de risque (module 01). Couvre certains coûts (réponse, pertes, rançon parfois),
mais **exige** un niveau d'hygiène minimal (MFA, sauvegardes, EDR) pour indemniser — et
n'indemnise pas la négligence. À comprendre comme un **complément**, jamais un substitut à
la sécurité.

---

## 14.8 — La sensibilisation et la culture de sécurité

Le facteur humain est le vecteur majoritaire (module 01). Une politique de sensibilisation
efficace :
- **Régulière** (pas une formation annuelle oubliée le lendemain)
- **Concrète et contextualisée** (exemples du métier réel des collaborateurs)
- **Bienveillante** — on cultive le réflexe de signalement, on ne punit pas l'erreur (sinon
  les incidents sont cachés, ce qui est bien pire)
- **Mesurée** (simulations de phishing pour évaluer, pas pour piéger ou humilier)
- **Portée par la direction** (l'exemplarité descend du haut)

---

## ✅ Labs du module 14

- [ ] **Lab 14.1 — Analyse de risque EBIOS RM.** Sur une organisation fictive (ou votre projet perso), déroulez les 5 ateliers de façon simplifiée. Produisez un registre des risques et une matrice.
- [ ] **Lab 14.2 — SoA ISO 27001.** À partir de l'annexe A / ISO 27002, sélectionnez les contrôles applicables à une PME fictive et justifiez les exclusions.
- [ ] **Lab 14.3 — CIS Controls.** Évaluez un système réel que vous gérez contre l'IG1 des CIS Controls v8. Établissez un plan de remédiation priorisé.
- [ ] **Lab 14.4 — RGPD.** Rédigez la procédure de notification de violation (72 h CNIL) et une AIPD simplifiée pour un traitement de données à risque.
- [ ] **Lab 14.5 — NIS2.** Déterminez si une entreprise fictive est concernée par NIS2, et listez ses obligations principales.
- [ ] **Lab 14.6 — Politique de sécurité.** Rédigez une PSSI courte (usage acceptable, mots de passe, mobilité, incident) lisible par des non-techniques.
- [ ] **Lab 14.7 — Exercice de crise.** Écrivez le scénario et le déroulé d'un exercice table-top « ransomware » : qui fait quoi, quelles décisions, quelle communication.

---

## 🎯 Auto-évaluation

1. Que signifie GRC et comment ces trois piliers s'articulent-ils ?
2. Qu'est-ce qu'un SMSI ? Que certifie l'ISO 27001 ? Rôle de l'annexe A / SoA ?
3. Citez les 6 fonctions du NIST CSF 2.0.
4. RGPD : délai de notification à la CNIL, sanction maximale, qu'est-ce qu'une AIPD ?
5. Qu'apporte NIS2 par rapport à NIS1 ? Quels délais de notification ?
6. Décrivez les 5 ateliers d'EBIOS RM. Pourquoi cette méthode fait-elle le pont technique/métier ?
7. Différence entre RTO et RPO ? Comment le RPO influence-t-il les sauvegardes ?
8. Pourquoi une politique de sensibilisation doit-elle être bienveillante et non punitive ?

---

**Suivant → [Module 15 : Labs & home lab](15-labs-home-lab.md)** — début du Niveau 4
