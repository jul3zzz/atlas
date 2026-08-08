# Module 12 — Cloud & DevSecOps

> **Objectif :** sécuriser les environnements modernes — cloud, conteneurs, CI/CD, chaîne
> d'approvisionnement logicielle. C'est là que se déplacent la majorité des systèmes, et où
> la demande de compétences explose.
>
> **Durée :** 5 semaines · **Prérequis :** modules 00–11

---

## 12.1 — Comprendre le cloud

### Les modèles de service et le partage de responsabilité

```
              Vous gérez ↓                    Le fournisseur gère ↓
On-premise :  TOUT
IaaS       :  OS, appli, données, config      Matériel, réseau physique, hyperviseur
PaaS       :  Appli, données, config          + OS, runtime
SaaS       :  Données, config, accès          + Application entière
```

**Le modèle de responsabilité partagée est LA notion fondamentale :** le cloud n'est pas
« sécurisé par défaut ». Le fournisseur sécurise **le** cloud (l'infrastructure) ; **vous**
sécurisez ce que vous mettez **dans** le cloud (config, IAM, données). L'écrasante majorité
des fuites cloud viennent d'**erreurs de configuration du client**, pas de failles du
fournisseur — un bucket S3 laissé public, une base ouverte sur Internet, des droits IAM excessifs.

### Les fournisseurs

| Fournisseur | Spécificités |
|---|---|
| **AWS** | Leader, le plus vaste catalogue, IAM très granulaire |
| **Azure** | Intégration Microsoft/AD (Entra ID), fort en entreprise |
| **GCP** | Data/IA, hiérarchie de projets |

Les concepts se transposent ; apprenez-en **un** en profondeur (AWS est le plus demandé),
les autres suivront.

---

## 12.2 — L'IAM cloud : le nouveau périmètre

Dans le cloud, **l'identité EST le périmètre**. Une politique IAM mal écrite est équivalente
à un pare-feu grand ouvert.

### Les concepts (exemple AWS)

- **Utilisateurs, groupes, rôles** — un **rôle** est assumé temporairement (par un service,
  un utilisateur, une machine), ce qui est plus sûr que des clés permanentes.
- **Politiques** (policies) — documents JSON décrivant qui peut faire quoi sur quoi.
- **Principe du moindre privilège** — le défi n°1 du cloud, car il est *facile* de tout
  autoriser (`Action: "*"`, `Resource: "*"`) et difficile de restreindre finement.

```json
// ❌ DANGEREUX — droits d'administrateur total
{ "Effect": "Allow", "Action": "*", "Resource": "*" }

// ✅ Moindre privilège — lecture d'un bucket précis
{ "Effect": "Allow", "Action": "s3:GetObject", "Resource": "arn:aws:s3:::mon-bucket/*" }
```

### Les erreurs et attaques IAM classiques

- **Privilege escalation IAM** — un utilisateur peu privilégié qui a le droit de modifier
  des politiques, créer des clés, ou assumer un rôle plus élevé peut s'auto-promouvoir
  (outils : `pacu`, `cloudsplaining`, ScoutSuite).
- **Clés d'accès exposées** (dans du code, des dépôts publics, des logs) — scannées par des
  bots en secondes → cryptominage ou pire en minutes.
- **Rôles trop permissifs** attachés à des instances/fonctions.
- **Confused deputy** / relations de confiance mal restreintes.

### La faille reine : SSRF → métadonnées → credentials

Rappel du module 07, ici en contexte : un **SSRF** sur une instance cloud permet d'atteindre
l'**IMDS** (`http://169.254.169.254/…`) et de voler les **credentials IAM temporaires** de
l'instance → l'attaquant hérite de ses droits. **IMDSv2** (qui exige un token en en-tête)
est la contre-mesure ; le déployer partout est prioritaire.

---

## 12.3 — Sécuriser les ressources cloud

### Le stockage

- Buckets/blobs **privés par défaut**, chiffrement au repos, blocage de l'accès public au niveau du compte
- Audit régulier (un bucket public = fuite classique)

### Le réseau

- **VPC/VNet**, sous-réseaux, groupes de sécurité (pare-feu virtuel), NACL
- Ne pas exposer bases de données, SSH/RDP, panneaux d'admin sur Internet
- Endpoints privés pour les services internes

### La détection et la journalisation cloud

| Fonction | AWS | Azure | GCP |
|---|---|---|---|
| Journal des actions API | **CloudTrail** | Activity Log | Cloud Audit Logs |
| Détection de menaces | GuardDuty | Defender for Cloud | Security Command Center |
| Posture / conformité | Security Hub, Config | Defender for Cloud | SCC |

Activez et **surveillez** CloudTrail (ou équivalent) — c'est le « journal de sécurité » du
cloud. Sans lui, une compromission cloud est invisible. Faites-le remonter dans votre SIEM.

### Outils d'audit de posture cloud (CSPM)

- **ScoutSuite, Prowler** (AWS/Azure/GCP), **CloudSploit** — audit gratuit de la configuration
- **Pacu** — framework d'exploitation AWS (l'équivalent Metasploit du cloud, pour le pentest cloud)
- **CloudGoat** (Rhino Security) — labs AWS délibérément vulnérables, **excellents pour apprendre**

---

## 12.4 — Les conteneurs : Docker

### Le modèle et ses implications

Un conteneur **partage le noyau de l'hôte** (contrairement à une VM). Conséquence sécurité :
l'isolation est plus faible qu'une VM — une évasion de conteneur ou un noyau vulnérable
expose l'hôte.

### Les risques et bonnes pratiques Docker

| Risque | Bonne pratique |
|---|---|
| Conteneur **privilégié** (`--privileged`) | Ne jamais l'utiliser sans nécessité absolue |
| Exécution en **root** dans le conteneur | `USER` non-root dans le Dockerfile |
| **Socket Docker monté** (`/var/run/docker.sock`) | = root sur l'hôte → à proscrire |
| Images **non fiables / obsolètes** | Images officielles minimales, scan de vulnérabilités |
| **Secrets** dans l'image ou les variables | Gestionnaire de secrets, jamais en dur |
| Capabilities excessives | `--cap-drop ALL` puis ajouter le strict nécessaire |
| Pas de limites de ressources | Limiter CPU/mémoire (anti-DoS) |

```bash
# Scanner une image
trivy image nginx:latest
grype nginx:latest
# Analyse des bonnes pratiques d'un conteneur en cours
docker scout / dockle
```

### L'évasion de conteneur (concept offensif)

Un conteneur mal configuré (privilégié, socket monté, capabilities dangereuses, montage
d'un chemin hôte) permet de « s'échapper » vers l'hôte. Lab d'entraînement : **DevSecOps /
container escape rooms**, et l'excellent site pédagogique de référence des évasions.

---

## 12.5 — Kubernetes

L'orchestrateur dominant. Sa surface d'attaque est vaste ; en maîtriser les bases est devenu
incontournable.

### L'architecture

```
Control Plane : API Server (le cœur), etcd (la base — contient TOUS les secrets),
                Scheduler, Controller Manager
Nodes         : kubelet, container runtime, kube-proxy, Pods
```

### Les points de sécurité clés

| Sujet | Enjeu |
|---|---|
| **RBAC** | Qui peut faire quoi dans le cluster — souvent trop permissif |
| **etcd** | Contient tous les secrets → chiffrer, isoler, restreindre |
| **API Server exposé** | Ne jamais exposer sur Internet sans auth forte |
| **Secrets K8s** | Encodés base64 ≠ chiffrés → activer le chiffrement des secrets |
| **Network Policies** | Par défaut, tous les pods communiquent (réseau plat) → segmenter |
| **Pod Security** | Pod Security Standards, éviter les pods privilégiés |
| **Images & supply chain** | Admission controllers, signature d'images |
| **Service accounts** | Tokens montés automatiquement → attention au vol |

```bash
# Audit de posture Kubernetes
kube-bench          # conformité CIS
kube-hunter         # recherche de vulnérabilités (offensif)
trivy k8s cluster
```

**Labs :** **Kubernetes Goat** (délibérément vulnérable), les scénarios K8s de plateformes CTF.

---

## 12.6 — DevSecOps : sécuriser la CI/CD

Le principe **« shift left »** : intégrer la sécurité **au plus tôt** dans le cycle de
développement, automatiquement, plutôt qu'en audit final.

### Le pipeline sécurisé

```
Code → Commit → Build → Test → Déploiement → Production
  │       │        │       │         │            │
 SAST  secrets   SCA     DAST      IaC scan    monitoring
 lint  scanning         (image)   (Terraform)  runtime/EDR
```

| Contrôle | Ce qu'il fait | Outils |
|---|---|---|
| **SAST** | Analyse le code source statiquement | Semgrep, SonarQube, CodeQL |
| **DAST** | Teste l'application en fonctionnement | OWASP ZAP, Burp (CI) |
| **SCA** | Analyse les dépendances/CVE | `npm audit`, `pip-audit`, Dependabot, Trivy, Snyk |
| **Secret scanning** | Détecte les secrets commités | gitleaks, trufflehog |
| **IaC scanning** | Vérifie la config Terraform/K8s/CloudFormation | Checkov, tfsec, KICS |
| **Container scanning** | Vulnérabilités des images | Trivy, Grype |

### La sécurité de la chaîne d'approvisionnement (supply chain)

Devenue **critique** (SolarWinds, Log4Shell, xz-utils, paquets npm/PyPI malveillants) :

- **Dépendances** — une bibliothèque compromise contamine tous ses utilisateurs
- **Typosquatting** — paquets aux noms proches de paquets légitimes
- **Intégrité du build** — signer les artefacts (**Sigstore/cosign**), builds reproductibles
- **SBOM** (Software Bill of Materials) — inventaire de tous les composants d'un logiciel
- **Cadre SLSA** — niveaux de garantie d'intégrité de la chaîne de build
- **Sécurité de la CI/CD elle-même** — les runners et secrets CI sont une cible de choix
  (un accès au pipeline = capacité d'injecter du code en production)

### La sécurité de l'Infrastructure as Code (IaC)

Terraform, Ansible, CloudFormation décrivent l'infra en code → on peut la **scanner avant
déploiement** (Checkov, tfsec) : détecter un bucket public, un groupe de sécurité ouvert, un
chiffrement absent — **avant** qu'ils existent. Puissant : la sécurité devient préventive et
automatisée.

---

## 12.7 — Secrets et gestion des identités machine

- **Ne jamais** de secret en dur (code, images, variables de CI en clair)
- **Coffres-forts** : HashiCorp Vault, AWS Secrets Manager, Azure Key Vault, GCP Secret Manager
- **Secrets à durée de vie courte**, rotation automatique
- **Identités de charge de travail** (workload identity, OIDC) plutôt que clés statiques —
  ex. GitHub Actions qui s'authentifie à AWS par OIDC sans clé stockée

---

## ✅ Labs du module 12

- [ ] **Lab 12.1 — Compte cloud gratuit.** Ouvrez un free tier (AWS/Azure/GCP). **Activez immédiatement le MFA, la facturation surveillée, et supprimez les clés inutiles** — pratiquez ce que vous prêchez.
- [ ] **Lab 12.2 — IAM.** Écrivez des politiques de moindre privilège, créez un rôle, et **cassez-le volontairement** (politique trop large) puis exploitez l'escalade avec Pacu/cloudsplaining.
- [ ] **Lab 12.3 — CloudGoat.** Déployez et résolvez plusieurs scénarios CloudGoat (dont un SSRF→IMDS→credentials). **L'entraînement cloud offensif de référence.**
- [ ] **Lab 12.4 — Audit de posture.** Lancez ScoutSuite/Prowler sur votre compte, lisez le rapport, corrigez les findings critiques.
- [ ] **Lab 12.5 — Docker.** Écrivez un Dockerfile non-root minimal, scannez l'image (Trivy), puis créez un conteneur mal configuré et réalisez une évasion en lab.
- [ ] **Lab 12.6 — Kubernetes Goat.** Déployez-le et exploitez plusieurs scénarios ; puis passez côté défense avec kube-bench.
- [ ] **Lab 12.7 — Pipeline DevSecOps.** Montez un pipeline (GitHub Actions/GitLab CI) intégrant secret scanning, SAST (Semgrep), SCA et IaC scanning. Faites-le échouer sur une vraie faille.
- [ ] **Lab 12.8 — Supply chain.** Générez un SBOM (`syft`), scannez-le (`grype`), signez un artefact avec cosign.

---

## 🎯 Auto-évaluation

1. Expliquez le modèle de responsabilité partagée. Qui sécurise quoi en IaaS/PaaS/SaaS ?
2. Pourquoi dit-on que « l'identité est le nouveau périmètre » dans le cloud ?
3. Décrivez la chaîne SSRF → IMDS → credentials IAM. Comment IMDSv2 la coupe-t-il ?
4. Pourquoi un conteneur est-il moins isolé qu'une VM ? Trois mauvaises pratiques Docker ?
5. Que contient etcd et pourquoi est-ce critique ?
6. Que signifie « shift left » ? Placez SAST, DAST, SCA dans un pipeline.
7. Pourquoi la sécurité de la supply chain est-elle devenue critique ? Citez SBOM, SLSA, Sigstore.
8. Qu'apporte le scan d'IaC par rapport à un audit post-déploiement ?

---

**Suivant → [Module 13 : Spécialisations](13-specialisations.md)**
