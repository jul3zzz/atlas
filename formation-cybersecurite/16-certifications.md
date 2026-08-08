# Module 16 — Certifications

> **Objectif :** vous aider à choisir un parcours de certification cohérent avec vos objectifs
> et votre budget, sans vous ruiner ni collectionner des sigles inutiles.
>
> **Niveau 4 — en continu**

> **Avertissement de bon sens :** une certification **ouvre des portes** (passage des filtres
> RH, validation d'un niveau), mais **ne remplace pas la compétence** ni la pratique. Le
> marché regorge de « certifiés » incapables de sortir un shell, et d'autodidactes
> redoutables sans le moindre papier. Visez la compétence ; la certification en est une
> conséquence et un accélérateur, pas un but.

---

## 16.1 — À quoi servent (vraiment) les certifications

- **Passer les filtres RH** — beaucoup d'offres exigent (à tort ou à raison) une certif
- **Valider un niveau** de façon reconnue par un tiers
- **Structurer l'apprentissage** — préparer une bonne certif *est* une formation
- **Négocier salaire et poste** — certaines certifs pèsent réellement
- **Obligations réglementaires** — certains contextes (défense, secteur public) les imposent

Ce qu'elles **ne font pas** : garantir que vous savez faire, remplacer un portfolio et de
l'expérience, justifier de s'endetter avant d'avoir les bases.

---

## 16.2 — Les certifications d'entrée (fondamentaux)

| Certification | Éditeur | Angle | Pour qui |
|---|---|---|---|
| **CompTIA Security+** | CompTIA | Généraliste, théorique, très reconnue en entrée | Le « standard » de première certif, bon pour le CV et les filtres RH |
| **CompTIA Network+ / A+** | CompTIA | Réseau / support (pré-sécurité) | Si les fondations réseau/système manquent |
| **Google/Microsoft Cybersecurity (Coursera)** | Google/MS | Découverte | Reconversion, tout premier pas |
| **ISC² CC (Certified in Cybersecurity)** | ISC² | Fondamentaux, **gratuit** (examen offert) | Excellent premier jalon gratuit |
| **SecNumAcadémie (ANSSI)** | ANSSI | Sensibilisation, **gratuit, en français** | Base gratuite, contexte français |

> **Recommandation débutant :** **ISC² CC** (gratuit) et/ou **Security+** posent une base
> théorique reconnue. Faites-les en parallèle des modules 00-06, pas avant.

---

## 16.3 — Les certifications offensives (pentest / red team)

| Certification | Éditeur | Format | Réputation |
|---|---|---|---|
| **eJPT** | INE/eLearnSecurity | Pratique, débutant | Excellente première certif offensive pratique, abordable |
| **PNPT** | TCM Security | Pratique + rapport + AD | Très bon rapport qualité/prix, réaliste, inclut un débrief |
| **CPTS** | Hack The Box | Pratique, exigeante | Montée en puissance, très complète, moderne |
| **OSCP** | OffSec | 24 h d'exam pratique + rapport | **La référence historique** du pentest, exigeante, « Try Harder » |
| **CRTP / CRTE** | Altered Security | Active Directory | Spécialisées AD, très pratiques et abordables |
| **OSEP / OSED / OSWE** | OffSec | Avancées (évasion / exploit / web) | Expert, après OSCP |
| **CRTO** | Zero-Point Security | Red team, C2 (Cobalt Strike) | Référence red team moderne |

### Sur l'OSCP
Longtemps le passage obligé du pentester. Examen de **24 heures** : compromettre des machines
puis **rédiger un rapport professionnel** (le rapport compte autant que les shells).
Métasploit y est restreint → force à comprendre. Exigeante mais formatrice. **Ne vous y
précipitez pas** : abordez-la après avoir résolu de nombreuses machines HTB/PWK en autonomie.

> **Parcours offensif recommandé (progressif et raisonnable en budget) :**
> eJPT ou PNPT (mise en jambe pratique) → CPTS ou OSCP (le vrai palier) → spécialisation
> (CRTP/CRTO pour l'AD/red team, OSWE pour le web).

---

## 16.4 — Les certifications défensives (Blue Team / SOC / DFIR)

| Certification | Éditeur | Angle |
|---|---|---|
| **CompTIA CySA+** | CompTIA | Analyste SOC, détection |
| **BTL1 / BTL2** (Blue Team Level) | Security Blue Team | **Pratique**, SOC/DFIR, excellent rapport qualité/prix |
| **CDSA** | Hack The Box | Analyste défense, pratique, moderne |
| **GCIH / GCIA / GCFA / GNFA** | SANS/GIAC | Incident handling / détection / forensics — **excellentes mais très chères** |
| **GREM** | SANS/GIAC | Reverse de malware (référence) |
| **CCD** (Certified CyberDefender) | CyberDefenders | DFIR pratique |

> **Parcours défensif recommandé :** Security+ → CySA+ ou **BTL1** (très bon pour débuter le
> SOC) → BTL2/CDSA → spécialisation DFIR (GCFA/GREM si le budget suit, sinon CyberDefenders CCD).
> Les certifs **SANS/GIAC** sont d'excellente qualité mais coûtent plusieurs milliers d'euros
> — visez-les via un financement employeur.

---

## 16.5 — Cloud, management et spécialités

### Cloud
| Certification | Angle |
|---|---|
| **AWS Certified Security – Specialty** | Sécurité AWS |
| **AZ-500** (Azure Security Engineer) | Sécurité Azure |
| **Google Professional Cloud Security Engineer** | Sécurité GCP |
| **CCSK** (Cloud Security Alliance) | Cloud générique, bon point d'entrée |

### Management / GRC / audit
| Certification | Angle |
|---|---|
| **CISSP** (ISC²) | **La** référence management/senior (5 ans d'expérience requis) — large, stratégique |
| **CISM** (ISACA) | Management de la sécurité |
| **CISA** (ISACA) | Audit des SI |
| **ISO 27001 Lead Implementer / Lead Auditor** | Mise en place / audit de SMSI |
| **CCSP** (ISC²) | Sécurité cloud, orienté management |

> **CISSP** est un objectif de milieu/fin de carrière (il faut de l'expérience). Ne la
> visez pas en débutant : elle valide une largeur de vue managériale, pas la technique.

---

## 16.6 — Choisir sa stratégie de certification

### Principes

1. **Compétence d'abord, certif ensuite.** Préparez-vous par la pratique ; la certif valide.
2. **Alignez sur votre objectif de poste.** SOC → CySA+/BTL1. Pentest → eJPT/PNPT/OSCP.
   Cloud → AZ-500/AWS. GRC → ISO 27001 LI. Ne collectionnez pas au hasard.
3. **Regardez qui finance.** Beaucoup d'employeurs paient les certifs. En reconversion,
   certains dispositifs (CPF en France, financements formation) peuvent aider. **Ne vous
   endettez pas lourdement pour une certif en tout début de parcours.**
4. **Privilégiez le pratique en offensive/défense** (eJPT, PNPT, BTL1, CPTS, OSCP) : elles
   prouvent un *savoir-faire*, plus convaincant qu'un QCM.
5. **Une bonne certif à la fois.** Préparer sérieusement vaut mieux que d'accumuler.

### Un parcours type sur ~24 mois (exemple, à adapter)

```
Mois 0-6   : (pendant les modules 00-07) — ISC² CC (gratuit), viser Security+
Mois 6-12  : selon la voie — eJPT (offensif) ou CySA+/BTL1 (défensif)
Mois 12-18 : PNPT/CPTS (offensif) ou BTL2/CDSA (défensif)
Mois 18-24 : OSCP (offensif) ou une GIAC via l'employeur (défensif), ou une certif cloud
Ensuite    : spécialisation (CRTO, OSWE, GREM, AZ-500…) puis, plus tard, CISSP/CISM
```

> Ce calendrier suppose une pratique intense en parallèle (module 15). Une certif sans
> pratique derrière ne tient pas la route en entretien technique.

---

## 16.7 — Ce qui compte autant que les certifications

- **Le portfolio** (module 15) — write-ups, GitHub, blog, contributions
- **L'expérience** — stage, alternance, premier poste (même en support/admin sys), homelab documenté
- **Le réseau** — communauté, conférences, associations, Discord/forums
- **Le bug bounty** (module 17) — résultats réels et vérifiables
- **La capacité à communiquer** — expliquer, rédiger, présenter

Un candidat avec un blog actif, quelques machines HTB documentées, une contribution open
source et **une** certif pratique bat souvent un candidat avec cinq certifs et aucune preuve
de pratique. **La certification est un multiplicateur, pas un substitut.**

---

## 🎯 Auto-évaluation / réflexion

1. Quelle est votre voie cible (SOC, pentest, cloud, GRC…) ?
2. Quelle serait votre **première** certification, et pourquoi celle-là ?
3. Pourquoi ne pas viser l'OSCP ou le CISSP dès le début ?
4. Comment financer vos certifications sans vous endetter ?
5. Qu'est-ce qui, dans une candidature, peut valoir autant qu'une certification ?
6. Écrivez votre plan de certification personnel sur 24 mois.

---

**Suivant → [Module 17 : Carrière & bug bounty](17-carriere.md)**
