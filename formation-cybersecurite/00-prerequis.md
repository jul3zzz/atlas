# Module 00 — Prérequis informatiques

> **Objectif :** être capable de comprendre ce qui se passe dans une machine, de naviguer
> en ligne de commande sans y réfléchir, et de monter un environnement de travail virtualisé.
>
> **Durée :** 3 à 4 semaines · **Niveau :** grand débutant accepté

Si vous savez déjà ce qu'est un inode, une IP privée et un pipe Unix, survolez ce module
et faites directement l'auto-évaluation en fin de page.

---

## 0.1 — Comment fonctionne un ordinateur

### Les composants et leur rôle en sécurité

| Composant | Rôle | Pourquoi ça compte en sécu |
|---|---|---|
| **CPU** | Exécute les instructions | Anneaux de privilèges (ring 0 = noyau, ring 3 = userland) : toute élévation de privilège consiste à passer d'un anneau à l'autre. Failles Spectre/Meltdown = fuite via l'exécution spéculative. |
| **RAM** | Mémoire volatile de travail | Les mots de passe, clés de chiffrement et malwares « fileless » y vivent en clair → c'est le premier endroit qu'on capture en forensics. |
| **Disque (HDD/SSD)** | Stockage persistant | Contient les traces (logs, fichiers supprimés récupérables, slack space). Un SSD avec TRIM détruit les preuves plus vite qu'un HDD. |
| **Carte réseau (NIC)** | Communication | Possède une adresse MAC (usurpable). Le mode promiscuous/moniteur permet la capture de trafic. |
| **BIOS/UEFI** | Initialisation matérielle | Cible des bootkits. Secure Boot vérifie les signatures au démarrage. |
| **TPM** | Puce cryptographique | Stocke les clés BitLocker, atteste de l'intégrité du boot. |

### Le cycle de démarrage (à connaître par cœur)

```
Alimentation → UEFI/BIOS → POST → Secure Boot (vérif. signature)
    → Bootloader (GRUB / Windows Boot Manager)
    → Noyau (kernel) chargé en mémoire
    → Init system (systemd / wininit) → services → session utilisateur
```

**Pourquoi :** chaque étape est un point d'attaque persistant. Un attaquant qui compromet
le bootloader survit à une réinstallation de l'OS. C'est la base de la « chaîne de confiance ».

### Binaire, hexadécimal, encodage

Vous manipulerez ces représentations tous les jours.

- **Binaire** : base 2. `1011` = 8+0+2+1 = 11
- **Hexadécimal** : base 16, noté `0x`. Un octet = 2 caractères hex. `0xFF` = 255
- **ASCII** : `A` = 65 = `0x41` · `a` = 97 = `0x61` · `0` = 48 = `0x30`
- **UTF-8** : encodage variable 1–4 octets, rétrocompatible ASCII
- **Base64** : encode du binaire en texte, **ce n'est pas du chiffrement**. Reconnaissable au padding `=` et à l'alphabet `A-Za-z0-9+/`
- **URL encoding** : `%20` = espace, `%2F` = `/`. Central dans les contournements de filtres web

```bash
echo -n "hello" | base64            # aGVsbG8=
echo -n "aGVsbG8=" | base64 -d      # hello
echo -n "hello" | xxd               # 68656c6c6f
printf '%d\n' 0x41                  # 65
```

> **Réflexe à acquérir :** devant une chaîne inconnue, se demander « c'est encodé, chiffré,
> ou hashé ? ». Encodé = réversible sans clé. Chiffré = réversible avec clé. Hashé = non réversible.

---

## 0.2 — Les systèmes d'exploitation

### Rôle du noyau

Le noyau est l'intermédiaire obligatoire entre les programmes et le matériel. Un programme
qui veut lire un fichier ne parle pas au disque : il fait un **appel système** (syscall)
et le noyau exécute l'opération pour lui, après vérification des droits.

```
Application (ring 3)  →  syscall (open, read, write, execve…)  →  Noyau (ring 0)  →  Matériel
```

**En sécurité :** tracer les syscalls, c'est voir la vérité du comportement d'un programme.
C'est le fondement de `strace` (Linux), de Sysmon (Windows) et de la plupart des EDR.

```bash
strace -f -e trace=openat,execve ls   # observe ce que fait réellement `ls`
```

### Processus, threads, mémoire

- **Processus** : programme en cours d'exécution, avec son espace mémoire isolé, un PID, un utilisateur propriétaire.
- **Thread** : fil d'exécution à l'intérieur d'un processus, partageant sa mémoire.
- **Espace d'adressage** : chaque processus croit disposer de toute la mémoire (mémoire virtuelle). L'isolement entre processus est une garantie du noyau — le casser, c'est une faille critique.
- **Segments mémoire** : code (`.text`), données initialisées (`.data`), non initialisées (`.bss`), **tas** (heap, allocation dynamique), **pile** (stack, variables locales et adresses de retour).

> La pile est l'endroit historique des buffer overflows : écraser l'adresse de retour
> permet de détourner le flux d'exécution. Voir [module 13](13-specialisations.md).

### Systèmes de fichiers

| FS | OS | Particularité sécurité |
|---|---|---|
| **ext4** | Linux | Inodes, timestamps (atime/mtime/ctime), journal |
| **XFS** | Linux (RHEL) | Journalisé, performant sur gros volumes |
| **NTFS** | Windows | ACL fines, **ADS** (Alternate Data Streams — cachette classique), MFT, USN Journal |
| **APFS** | macOS | Snapshots, chiffrement natif |
| **FAT32/exFAT** | Amovible | Aucune permission → tout est lisible par tous |

**Les Alternate Data Streams** — une spécificité NTFS très utilisée en attaque :

```powershell
# Cacher des données dans un flux alternatif (ne modifie pas la taille apparente)
echo "donnee cachee" > fichier.txt:cache
Get-Item fichier.txt -Stream *          # les révèle
```

**Les timestamps MACB** (Modified, Accessed, Changed, Birth) sont la colonne vertébrale du
forensics. Un attaquant qui les altère fait du *timestomping* — détectable en comparant
les timestamps `$STANDARD_INFORMATION` et `$FILE_NAME` de la MFT.

---

## 0.3 — La ligne de commande : votre outil principal

Il n'existe pas de professionnel de la sécurité qui ne vive pas dans un terminal. Objectif
de cette section : que la ligne de commande devienne un réflexe, pas un effort.

### Les 30 commandes Linux à automatiser dans vos doigts

```bash
# Navigation & fichiers
pwd                     # où suis-je
ls -lah                 # lister (long, cachés, tailles lisibles)
cd -                    # revenir au dossier précédent
find / -name "*.conf" -type f 2>/dev/null    # chercher
find / -perm -4000 -type f 2>/dev/null       # binaires SUID ← réflexe pentest
locate passwd           # recherche indexée (rapide)
tree -L 2               # arborescence

# Lecture & manipulation de texte
cat / less / head -n 20 / tail -f fichier.log
grep -rin "password" /etc/                   # récursif, insensible à la casse, numéroté
grep -E "^[0-9]{1,3}\." fichier              # avec regex étendue
awk -F: '{print $1, $3}' /etc/passwd         # découpe par champ
sed 's/ancien/nouveau/g' fichier             # substitution
cut -d: -f1 /etc/passwd                      # extraction de colonne
sort | uniq -c | sort -rn                    # LE combo d'analyse de logs
wc -l fichier                                # compter les lignes
tr 'a-z' 'A-Z'                               # transformer des caractères

# Processus & système
ps aux                  # tous les processus
top / htop              # temps réel
kill -9 PID
lsof -i                 # quels processus ouvrent quels ports/fichiers
ss -tulpn               # sockets en écoute (remplace netstat)
df -h / du -sh *        # espace disque
free -h                 # mémoire
uname -a                # version du noyau
id / whoami / groups    # qui suis-je et avec quels droits

# Permissions
chmod 640 fichier       # rw- r-- ---
chown user:group fichier
umask                   # masque par défaut

# Réseau
ip a / ip r             # adresses et routes
ping / traceroute
curl -I https://exemple.fr        # en-têtes HTTP seulement
wget -r URL
dig exemple.fr ANY / nslookup
ssh user@hote -p 2222
scp fichier user@hote:/tmp/

# Archives & transfert
tar -czvf arch.tar.gz dossier/    # créer
tar -xzvf arch.tar.gz             # extraire
```

### Les concepts qui font la puissance du shell

**Redirections et pipes** — c'est ici que la ligne de commande dépasse toute interface graphique :

```bash
commande > fichier      # stdout écrase
commande >> fichier     # stdout ajoute
commande 2> erreurs.txt # stderr
commande &> tout.txt    # les deux
commande 2>/dev/null    # ignorer les erreurs (indispensable avec find)
commande1 | commande2   # pipe : la sortie de l'une alimente l'autre
```

**Exercice mental type :** « quelles sont les 10 IP qui ont le plus généré d'erreurs 404
dans ce log Apache ? »

```bash
grep " 404 " access.log | awk '{print $1}' | sort | uniq -c | sort -rn | head -10
```

Cette seule ligne est du travail d'analyste SOC. Comprenez-la en profondeur.

### Les expressions régulières (regex)

Incontournables pour l'analyse de logs, les règles de détection et le filtrage.

| Motif | Sens | Exemple |
|---|---|---|
| `.` | n'importe quel caractère | `a.c` → abc, a1c |
| `*` `+` `?` | 0+, 1+, 0 ou 1 | `ab+` → ab, abb |
| `^` `$` | début / fin de ligne | `^root` |
| `[abc]` `[^abc]` | classe / négation | `[0-9]` |
| `\d` `\w` `\s` | chiffre / mot / espace | `\d{1,3}` |
| `{n,m}` | entre n et m fois | `\d{4}` |
| `(...)` | groupe de capture | `(\d+)-(\d+)` |
| `\|` | ou | `error\|fail` |

```bash
# Extraire toutes les IPv4 d'un fichier
grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' fichier.log
# Extraire les adresses e-mail
grep -oE '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-z]{2,}' fichier
```

**Lab :** entraînez-vous sur [regex101.com](https://regex101.com) (mode PCRE) et
[regexcrossword.com](https://regexcrossword.com) — 2 h suffisent pour être opérationnel.

---

## 0.4 — Réseau : le strict minimum (approfondi au module 03)

Quatre notions à intégrer dès maintenant, sinon rien de la suite n'aura de sens.

**1. Adresse IP** — identifiant d'une machine sur un réseau.
- IPv4 : `192.168.1.10` (4 octets). IPv6 : `2001:db8::1`
- **Plages privées** (non routables sur Internet) : `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`
- **Loopback** : `127.0.0.1` — votre propre machine

**2. Masque et CIDR** — sépare la partie réseau de la partie machine.
`192.168.1.0/24` = 256 adresses, de `.0` (réseau) à `.255` (broadcast), 254 utilisables.
`/16` = 65 536 adresses. Retenez : **chaque bit retiré double la taille du réseau**.

**3. Port** — identifie un service sur une machine (0–65535).

| Port | Service | Note sécurité |
|---|---|---|
| 21 | FTP | En clair |
| 22 | SSH | Chiffré — cible n°1 du brute force |
| 23 | Telnet | En clair — ne devrait plus exister |
| 25/587 | SMTP | Mail sortant |
| 53 | DNS | UDP surtout — vecteur d'exfiltration |
| 80 / 443 | HTTP / HTTPS | Le web |
| 135/139/445 | RPC/NetBIOS/SMB | Partages Windows — historiquement dévastateur (EternalBlue) |
| 389 / 636 | LDAP / LDAPS | Annuaire, Active Directory |
| 3306 / 5432 | MySQL / PostgreSQL | Bases de données |
| 3389 | RDP | Bureau à distance — cible majeure de ransomware |
| 5985/5986 | WinRM | Administration distante Windows |

**4. DNS** — traduit un nom en adresse IP. Comprendre la résolution récursive
(resolveur → racine → TLD → serveur faisant autorité) est indispensable : le DNS est
à la fois un outil de reconnaissance, un canal d'exfiltration et un vecteur d'attaque.

```bash
dig exemple.fr A +short
dig exemple.fr MX
dig -x 8.8.8.8            # résolution inverse
```

---

## 0.5 — Monter son environnement de travail

C'est le premier livrable concret du cursus. Vous ne toucherez jamais un outil offensif
depuis votre système principal.

### Architecture cible

```
        Machine hôte (votre PC quotidien — jamais d'outil offensif dessus)
                             │
                     Hyperviseur (VirtualBox / VMware / Proxmox)
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
   Kali Linux           Cibles vulnérables    (plus tard)
   (attaquant)          Metasploitable2       Windows Server → DC
                        DVWA / Juice Shop     Windows 10/11 client
                        │                     Ubuntu Server → SIEM
        └──── Réseau « Host-Only » / « Interne » — ISOLÉ d'Internet ────┘
```

### Choix de l'hyperviseur

| Solution | Pour qui | Remarque |
|---|---|---|
| **VirtualBox** | Débutants | Gratuit, multiplateforme, suffisant |
| **VMware Workstation Pro** | Confort | Gratuit pour usage personnel depuis 2024, snapshots plus rapides |
| **Proxmox VE** | Home lab sérieux | Sur machine dédiée, type 1, la meilleure option à terme |
| **Hyper-V** | Windows Pro | Attention : incompatible avec VirtualBox si activé |

### ⚠️ Les modes réseau — la règle de sécurité la plus importante du module

| Mode | Comportement | Usage |
|---|---|---|
| **NAT** | La VM accède à Internet, invisible depuis le réseau local | Kali, pour les mises à jour |
| **Host-Only** | VM ↔ hôte uniquement, **pas d'Internet** | ✅ Vos cibles vulnérables |
| **Interne** | VM ↔ VM uniquement, hôte exclu | ✅ Le plus sûr pour un lab d'attaque |
| **Bridge** | La VM est une machine du réseau local | ❌ **JAMAIS pour une cible vulnérable** |

> **Une VM vulnérable en mode Bridge est une porte ouverte sur votre box, votre réseau
> domestique et celui de vos voisins de palier si vous êtes en colocation.** Metasploitable
> compromise en 4 minutes par un bot depuis Internet, c'est une histoire vraie très courante.
> Host-Only ou Interne. Toujours.

### Installation pas à pas

**1. Vérifier la virtualisation matérielle**
BIOS/UEFI → activer `Intel VT-x` / `AMD-V` (parfois nommé SVM).

**2. Kali Linux** — [kali.org/get-kali](https://www.kali.org/get-kali/) → image préconstruite VirtualBox/VMware (plus simple que l'ISO).
- Identifiants par défaut : `kali` / `kali` → **changez-les immédiatement**
- 4 Go RAM, 2 vCPU, 80 Go disque
- Après démarrage : `sudo apt update && sudo apt full-upgrade -y`
- **Prenez un snapshot** nommé « base propre ». Vous y reviendrez souvent.

> **Alternative :** Parrot OS Security (plus léger) ou une Debian que vous outillez
> vous-même. Cette dernière option est très formatrice, à faire au module 04.

**3. Metasploitable 2** — cible délibérément vulnérable
[sourceforge.net/projects/metasploitable](https://sourceforge.net/projects/metasploitable/) → réseau **Host-Only**, identifiants `msfadmin`/`msfadmin`.

**4. Cibles web** — via Docker sur Kali :

```bash
sudo apt install -y docker.io
sudo systemctl enable --now docker

sudo docker run -d -p 8080:80 vulnerables/web-dvwa        # DVWA
sudo docker run -d -p 3000:3000 bkimminich/juice-shop     # OWASP Juice Shop
sudo docker run -d -p 8081:80 citizenstig/nowasp          # Mutillidae
```

**5. Vérification finale**

```bash
ip a                         # noter l'IP de Kali sur le réseau host-only
ping <ip_metasploitable>     # doit répondre
nmap -sV <ip_metasploitable> # doit lister des services
```

Si ces trois commandes fonctionnent, votre laboratoire est opérationnel.

### Discipline de laboratoire

- **Snapshot avant chaque manipulation risquée.** Un snapshot coûte 10 secondes, une réinstallation 2 heures.
- **Journal de bord.** Un fichier par lab : ce que j'ai fait, ce qui a marché, ce que j'ai compris. Il deviendra votre portfolio.
- **Aucune donnée personnelle dans les VM offensives.** Pas de session mail, pas de mot de passe réutilisé.
- **Éteignez les cibles vulnérables** quand vous ne les utilisez pas.

---

## 0.6 — Git et la gestion de version

Vous en aurez besoin pour vos scripts, vos notes et votre portfolio public.

```bash
git init
git clone https://github.com/utilisateur/depot.git
git status
git add fichier.py
git commit -m "Ajout du script d'énumération"
git log --oneline
git branch feature-x && git checkout feature-x
git push origin main
git diff
```

> **Piège classique et grave :** ne **jamais** committer de secrets (clés API, mots de passe,
> fichiers `.env`). Un secret poussé sur GitHub, même supprimé ensuite, reste dans
> l'historique et est scanné par des bots en quelques secondes. Utilisez un `.gitignore`
> et un outil comme `gitleaks` en pre-commit hook.

```bash
# .gitignore minimal
.env
*.pem
*.key
config.local.*
```

---

## ✅ Labs du module 00

- [ ] **Lab 0.1** — Installer l'hyperviseur, créer Kali, faire un snapshot « base propre »
- [ ] **Lab 0.2** — Installer Metasploitable 2 en Host-Only, vérifier l'isolement (`ping 8.8.8.8` depuis la cible doit **échouer**)
- [ ] **Lab 0.3** — Déployer DVWA et Juice Shop en Docker, y accéder depuis le navigateur de Kali
- [ ] **Lab 0.4** — [OverTheWire — Bandit](https://overthewire.org/wargames/bandit/), niveaux 0 à 20. **Le meilleur exercice de ligne de commande qui existe.** Prévoyez 8 à 12 h.
- [ ] **Lab 0.5** — Écrire un one-liner qui extrait les 10 IP les plus fréquentes d'un log Apache et sauvegarde le résultat
- [ ] **Lab 0.6** — S'entraîner 2 h aux regex sur regex101.com
- [ ] **Lab 0.7** — Créer un dépôt Git de vos notes de formation, avec un `.gitignore` correct

---

## 🎯 Auto-évaluation — passez au module 01 si vous savez répondre

1. Que fait `find / -perm -4000 -type f 2>/dev/null` et pourquoi un attaquant le lance-t-il ?
2. Quelle est la différence entre encoder, chiffrer et hasher ?
3. Combien d'adresses utilisables dans un `/26` ?
4. Pourquoi ne jamais mettre une VM vulnérable en mode Bridge ?
5. Que se passe-t-il entre l'appui sur le bouton d'alimentation et l'écran de connexion ?
6. Expliquez `grep " 404 " access.log | awk '{print $1}' | sort | uniq -c | sort -rn | head`
7. Qu'est-ce qu'un appel système, et pourquoi les EDR s'y intéressent-ils ?
8. Quelle est la différence entre la pile et le tas ?

> Moins de 6 bonnes réponses → refaites les labs 0.4 et 0.5 avant de continuer.
> Ce module est la fondation ; une fissure ici se propagera à tout le reste.

---

**Suivant → [Module 01 : Fondamentaux de la sécurité](01-fondamentaux-securite.md)**
