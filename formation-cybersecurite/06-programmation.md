# Module 06 — Programmation & scripting

> **Objectif :** savoir lire, écrire et modifier du code. Un professionnel de la sécurité qui
> ne programme pas est limité à cliquer sur les outils des autres. Programmer, c'est
> comprendre les failles de l'intérieur, automatiser son travail, et créer ce qui n'existe pas.
>
> **Durée :** 4 semaines (puis pratique continue) · **Prérequis :** modules 00–05

> **Objectif réaliste :** vous n'avez pas besoin d'être ingénieur logiciel. Vous avez besoin
> de : **Python** solide, **Bash** confortable, **PowerShell** fonctionnel, savoir **lire** du
> JavaScript/PHP/C, et maîtriser **Git**. La profondeur vient avec la pratique.

---

## 6.1 — Pourquoi et comment programmer en sécurité

| Vous programmez pour… | Exemple |
|---|---|
| **Automatiser** | Un script qui scanne, parse la sortie, et génère un rapport |
| **Comprendre les failles** | Écrire une appli vulnérable révèle *pourquoi* la SQLi marche |
| **Développer des outils** | Un fuzzer, un scanner custom, un décodeur |
| **Analyser** | Parser des logs, trier des IOC, corréler des événements |
| **Exploiter** | Adapter un exploit public, écrire un PoC |
| **Défendre** | Une règle de détection, un script de réponse, un durcissement automatisé |

**Principe pédagogique :** apprenez la programmation **par la sécurité**. Plutôt que de faire
un énième « to-do list », écrivez un scanner de ports, un cracker de hash, un analyseur de
logs. La motivation et la mémorisation en sont décuplées.

---

## 6.2 — Python : le langage de la cybersécurité

Python est **le** langage du domaine : lisible, immense écosystème (Scapy, Requests,
Impacket, pwntools), présent dans presque tous les outils.

### Les fondamentaux à maîtriser

```python
# Types et structures
nom = "cible"; port = 443; actif = True
liste = [22, 80, 443]; dico = {"host": "1.1.1.1", "port": 53}
ensemble = {1, 2, 3}                      # utile pour dédupliquer
tuple = (192, 168, 1, 1)                  # immuable

# Contrôle de flux
for port in range(1, 1025):
    if port in [22, 80, 443]:
        print(f"port courant : {port}")

# Fonctions
def scan_port(ip: str, port: int, timeout: float = 1.0) -> bool:
    import socket
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.settimeout(timeout)
        return s.connect_ex((ip, port)) == 0

# Compréhensions (idiomatique et puissant)
ouverts = [p for p in range(1, 1025) if scan_port("127.0.0.1", p)]

# Gestion d'erreurs
try:
    data = open("cible.txt").read()
except FileNotFoundError:
    print("[!] Fichier absent")
```

### Les bibliothèques indispensables

| Bibliothèque | Usage |
|---|---|
| `socket` | Communication réseau bas niveau (scanners, shells) |
| `requests` | Requêtes HTTP (web, API, automatisation) |
| `scapy` | Forger/capturer des paquets à tous les niveaux — l'outil réseau ultime |
| `impacket` | Protocoles Windows (SMB, Kerberos, LDAP) — cœur du pentest AD |
| `pwntools` | Développement d'exploits (module 13) |
| `beautifulsoup4` / `lxml` | Parser du HTML (scraping, reconnaissance) |
| `paramiko` | SSH programmatique |
| `cryptography` / `pycryptodome` | Crypto correcte (ne réimplémentez jamais AES) |
| `argparse` | Interfaces en ligne de commande propres |
| `re` | Expressions régulières |

### Un scanner de ports concurrent (projet type)

```python
#!/usr/bin/env python3
"""Scanner de ports TCP concurrent — usage pédagogique, cibles autorisées uniquement."""
import socket, argparse
from concurrent.futures import ThreadPoolExecutor

def scan(ip: str, port: int) -> int | None:
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(0.5)
    resultat = port if s.connect_ex((ip, port)) == 0 else None
    s.close()
    return resultat

def main() -> None:
    p = argparse.ArgumentParser(description="Scanner de ports simple")
    p.add_argument("ip")
    p.add_argument("-p", "--ports", default="1-1024")
    args = p.parse_args()
    debut, fin = map(int, args.ports.split("-"))

    with ThreadPoolExecutor(max_workers=100) as ex:
        resultats = ex.map(lambda port: scan(args.ip, port), range(debut, fin + 1))
    for port in filter(None, resultats):
        print(f"[+] {args.ip}:{port} ouvert")

if __name__ == "__main__":
    main()
```

Ce seul projet vous enseigne : sockets, concurrence, argparse, structure d'un programme.
Étendez-le : détection de bannière, sortie JSON, scan UDP.

### Scapy — manipuler les paquets

```python
from scapy.all import *
# Un ping ICMP
reponse = sr1(IP(dst="192.168.1.1")/ICMP(), timeout=2, verbose=0)
# Un scan SYN d'un port
rep = sr1(IP(dst="192.168.1.1")/TCP(dport=443, flags="S"), timeout=2, verbose=0)
if rep and rep.haslayer(TCP) and rep[TCP].flags == "SA":
    print("port ouvert")
# Sniffer
sniff(filter="tcp port 80", prn=lambda p: p.summary(), count=10)
```

Scapy vous fait *toucher* les concepts du module 03 : vous forgez un SYN et voyez la réponse.

---

## 6.3 — Bash : l'automatisation système

Vu au module 04. Points de scripting à consolider :

```bash
#!/usr/bin/env bash
set -euo pipefail

# Arguments
cible="${1:?Usage: $0 <cible>}"

# Boucle de découverte réseau (ping sweep)
for i in {1..254}; do
    ip="192.168.1.$i"
    (ping -c1 -W1 "$ip" &>/dev/null && echo "[+] $ip actif") &
done
wait

# Traitement de sortie d'outils
nmap -oG - -p- "$cible" | awk '/open/{print $2}'

# Fonctions et conditions robustes
verifier() {
    local hote="$1"
    if curl -sf "https://$hote" >/dev/null; then
        echo "$hote : joignable"
    else
        echo "$hote : injoignable" >&2
        return 1
    fi
}
```

**Quand Bash vs Python ?** Bash pour l'orchestration d'outils et le glue rapide entre
commandes. Python dès qu'il y a de la logique, du parsing structuré, du réseau bas niveau,
ou du code à maintenir.

---

## 6.4 — PowerShell : l'automatisation Windows

Indispensable pour l'administration Windows/AD et omniprésent en attaque (souvent la seule
« interface » disponible sur une machine compromise).

```powershell
# Objets, pas texte : la grande force de PowerShell
Get-Process | Where-Object { $_.CPU -gt 100 } | Sort-Object CPU -Descending | Select -First 5

# Réseau
Test-NetConnection -ComputerName 10.0.0.1 -Port 445
Resolve-DnsName exemple.fr
1..1024 | ForEach-Object { if (Test-NetConnection 10.0.0.1 -Port $_ -WarningAction SilentlyContinue -InformationLevel Quiet) { "Port $_ ouvert" } }

# Fichiers et système
Get-ChildItem -Recurse -Filter *.config -ErrorAction SilentlyContinue
Get-WinEvent -LogName Security -MaxEvents 100 | Where-Object Id -eq 4625   # échecs de logon

# Téléchargement (attention aux usages : sur machine autorisée uniquement)
Invoke-WebRequest -Uri http://exemple/outil.ps1 -OutFile outil.ps1
```

> **Aspect défensif à connaître :** PowerShell est très instrumenté (ScriptBlock Logging,
> Module Logging, Transcription, AMSI). C'est pourquoi les attaquants tentent de le
> contourner — et pourquoi le défenseur active ces journaux. On revoit cela aux modules 09/10.

---

## 6.5 — Lire du code : JavaScript, PHP, C

Vous n'écrirez pas forcément ces langages, mais vous devez les **lire** pour auditer.

### JavaScript — le langage du web (côté client et serveur)

```javascript
// À reconnaître en audit web
document.getElementById("out").innerHTML = userInput;   // ⚠️ DOM XSS potentiel
eval(donneeUtilisateur);                                 // ⚠️ exécution arbitraire
fetch(`/api/user/${id}`);                                // vérifier l'autorisation côté serveur
```

Node.js côté serveur : comprendre `require`, les callbacks/promesses, Express (routes,
middlewares) suffit pour auditer la majorité des applis modernes.

### PHP — encore massivement présent

```php
// Vulnérabilités classiques à repérer
$query = "SELECT * FROM users WHERE id = " . $_GET['id'];   // ⚠️ SQLi
include($_GET['page']);                                      // ⚠️ LFI/RFI
system($_GET['cmd']);                                        // ⚠️ command injection
echo $_GET['name'];                                          // ⚠️ XSS reflété
unserialize($_COOKIE['data']);                               // ⚠️ désérialisation
```

Savoir repérer ces motifs, c'est déjà faire de la revue de code sécurité (module 07).

### C — comprendre la mémoire et les failles bas niveau

```c
// La faille historique par excellence
char buffer[64];
strcpy(buffer, entree_utilisateur);   // ⚠️ pas de vérification de taille → buffer overflow
gets(buffer);                          // ⚠️ à bannir absolument
```

Lire du C permet de comprendre les buffer overflows, use-after-free, format strings —
la base du reverse engineering et de l'exploit dev (module 13). Pas besoin d'être expert,
mais comprendre pointeurs, pile et allocation mémoire est précieux.

---

## 6.6 — Le développement sécurisé (introduction au Secure Coding)

Même en tant qu'auditeur, connaître les bonnes pratiques d'écriture vous rend crédible.

### Les règles d'or

1. **Ne jamais faire confiance à l'entrée** — toute donnée externe est hostile jusqu'à validation.
2. **Valider en liste blanche** — définir ce qui est autorisé, pas ce qui est interdit.
3. **Séparer code et données** — requêtes préparées (SQL), échappement contextuel (HTML).
4. **Moindre privilège** — le code s'exécute avec le minimum de droits.
5. **Gérer les erreurs sans fuiter** — message générique à l'utilisateur, détail dans les logs.
6. **Ne jamais coder de secret en dur** — variables d'environnement, coffre-fort (Vault, KMS).
7. **Utiliser des bibliothèques éprouvées** — surtout pour la crypto et l'authentification.
8. **Dépendances à jour et auditées** — `pip-audit`, `npm audit`, SCA (module 12).

### La requête préparée — l'exemple canonique

```python
# ❌ VULNÉRABLE — injection SQL
cur.execute(f"SELECT * FROM users WHERE name = '{nom}'")

# ✅ SÛR — requête paramétrée : la donnée ne peut jamais devenir du code
cur.execute("SELECT * FROM users WHERE name = %s", (nom,))
```

Cette différence, comprise en profondeur, prévient à elle seule une des failles les plus
répandues et les plus graves du web.

### Gestion des secrets

```python
import os
API_KEY = os.environ["API_KEY"]     # ✅ depuis l'environnement
# JAMAIS : API_KEY = "sk-live-abc123..."   ← finit sur GitHub, scanné en secondes
```

---

## 6.7 — Git et la collaboration

Revu du module 00, avec l'angle sécurité :

```bash
git log --oneline --all --graph
git blame fichier.py           # qui a écrit quoi (utile en audit de code)
git diff HEAD~3                # examiner l'évolution
git stash                      # mettre de côté des modifs

# Chercher des secrets dans l'historique (attaquant ET défenseur)
git log -p | grep -i "password\|api_key\|secret"
# Outils dédiés : gitleaks, trufflehog
gitleaks detect --source .
```

> **Point crucial :** un secret commité **reste dans l'historique** même après suppression.
> Il faut le **révoquer** (changer la clé) et réécrire l'historique (`git filter-repo`).
> Supposez qu'un secret poussé publiquement est déjà compromis.

---

## ✅ Labs du module 06

- [ ] **Lab 6.1 — Scanner de ports Python.** Écrivez, puis améliorez le scanner : ajoutez la concurrence, la détection de bannière, une sortie JSON, `argparse`. **Votre premier vrai outil.**
- [ ] **Lab 6.2 — Cracker de hash.** Un script qui teste une wordlist contre un hash MD5/SHA (concept), puis contre un `/etc/shadow` de lab avec la bibliothèque adéquate. Comparez à John/Hashcat.
- [ ] **Lab 6.3 — Analyseur de logs.** En Python, parsez un `access.log` Apache : top IP, top URL, détection de codes 4xx/5xx anormaux, repérage de motifs d'attaque (`../`, `union select`, `<script>`).
- [ ] **Lab 6.4 — Scapy.** Écrivez un ping sweep et un mini scan SYN avec Scapy, en capturant en parallèle dans Wireshark pour vérifier vos paquets.
- [ ] **Lab 6.5 — PowerShell.** Un script qui énumère les processus suspects, les connexions réseau établies, et les tâches planifiées d'une machine Windows.
- [ ] **Lab 6.6 — Revue de code.** Prenez une appli PHP/Node vulnérable (DVWA source, ou un dépôt volontairement vulnérable) et **listez les failles par lecture du code seul**, avant de les exploiter.
- [ ] **Lab 6.7 — Requête préparée.** Écrivez une mini-API vulnérable à la SQLi, exploitez-la, puis corrigez-la avec des requêtes paramétrées. Constatez que l'attaque échoue.
- [ ] **Lab 6.8 — Git & secrets.** Committez « accidentellement » un faux secret, retrouvez-le avec gitleaks, puis nettoyez l'historique proprement.

---

## 🎯 Auto-évaluation

1. Quand choisir Bash plutôt que Python, et inversement ?
2. Que fait `ThreadPoolExecutor` dans le scanner, et pourquoi accélère-t-il le scan ?
3. Pourquoi la « grande force » de PowerShell est-elle de manipuler des objets, pas du texte ?
4. Repérez 3 failles dans un extrait PHP donné.
5. Expliquez pourquoi une requête préparée neutralise la SQLi.
6. Pourquoi ne jamais coder un secret en dur, même dans un dépôt « privé » ?
7. Un secret a été poussé sur GitHub puis supprimé au commit suivant. Que faites-vous ?
8. Quelle bibliothèque Python pour : forger un paquet, parler SMB/Kerberos, écrire un exploit ?

---

**Suivant → [Module 07 : Sécurité web & OWASP](07-securite-web.md)** — début du Niveau 2

---
*Ressources d'apprentissage recommandées pour ce module : « Automate the Boring Stuff with
Python » (gratuit en ligne), « Black Hat Python » (2ᵉ éd.), « Violent Python », et la
pratique quotidienne sur vos propres besoins.*
