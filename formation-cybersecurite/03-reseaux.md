# Module 03 — Réseaux

> **Objectif :** comprendre en profondeur comment circule l'information, car **tout ce qui
> est attaqué transite par le réseau**. Un professionnel qui ne maîtrise pas TCP/IP est un
> professionnel qui devine.
>
> **Durée :** 4 semaines · **Prérequis :** modules 00, 01, 02

> Ce module est long et exigeant. C'est voulu : le réseau est le socle sur lequel reposent
> le pentest, le SOC, le cloud et le forensics. Ne le survolez pas.

---

## 3.1 — Les modèles en couches

Un modèle en couches découpe la communication en niveaux qui s'ignorent mutuellement :
chaque couche rend un service à celle du dessus et utilise celle du dessous.

### OSI vs TCP/IP

| OSI (7 couches) | TCP/IP (4) | Rôle | Unité (PDU) | Exemples |
|---|---|---|---|---|
| 7 Application | Application | Le service utilisateur | Données | HTTP, DNS, SSH, SMTP |
| 6 Présentation | ″ | Format, chiffrement | ″ | TLS, encodages |
| 5 Session | ″ | Dialogue | ″ | Sockets |
| 4 Transport | Transport | Bout-en-bout, fiabilité | Segment | **TCP, UDP** |
| 3 Réseau | Internet | Adressage, routage | Paquet | **IP, ICMP** |
| 2 Liaison | Accès réseau | Trame locale | Trame | **Ethernet, ARP, Wi-Fi** |
| 1 Physique | ″ | Signal | Bit | Câble, radio |

**Pourquoi c'est fondamental en sécurité :** chaque couche a ses attaques et ses défenses.
Un débutant qui sait situer une attaque dans la bonne couche comprend immédiatement les
contre-mesures. « ARP spoofing » → couche 2 → défense par port security. « SYN flood »
→ couche 4 → SYN cookies. Utilisez ce modèle comme boussole.

### L'encapsulation

Chaque couche ajoute son en-tête en descendant, les retire en remontant :

```
[ En-tête Ethernet [ En-tête IP [ En-tête TCP [ HTTP GET /... ] ] ] ]
   couche 2            couche 3     couche 4      couche 7
```

C'est **exactement** ce que vous voyez en dépliant un paquet dans Wireshark. Faites le
lien constamment entre la théorie et ce que l'outil vous montre.

---

## 3.2 — La couche 3 : IP, le cœur du routage

### Adressage IPv4

- 32 bits, notation décimale pointée : `192.168.1.10`
- **Partie réseau** + **partie hôte**, séparées par le **masque**
- CIDR : `/24` = 24 bits de réseau = masque `255.255.255.0`

### Le sous-réseautage (subnetting) — à maîtriser absolument

| CIDR | Masque | Hôtes utilisables | Usage typique |
|---|---|---|---|
| /30 | 255.255.255.252 | 2 | Liaison point-à-point |
| /29 | 255.255.255.248 | 6 | Petit segment |
| /24 | 255.255.255.0 | 254 | LAN classique |
| /16 | 255.255.0.0 | 65 534 | Grand réseau |
| /8 | 255.0.0.0 | 16 M | Très grand |

**Formule :** hôtes utilisables = 2^(32 − CIDR) − 2 (on retire l'adresse réseau et le broadcast).

**Exercice type de certification :** « la machine `192.168.1.130/26` peut-elle joindre
directement `192.168.1.200` ? »
→ `/26` = blocs de 64. `.130` est dans `192.168.1.128–191`. `.200` est dans `192.168.1.192–255`.
Réseaux différents ⇒ **non**, il faut passer par la passerelle. Ce raisonnement doit devenir automatique.

### Adresses spéciales

- **Privées** (RFC 1918) : `10/8`, `172.16/12`, `192.168/16` — non routables sur Internet
- **Loopback** : `127.0.0.0/8`
- **APIPA / link-local** : `169.254.0.0/16` (signe qu'un DHCP a échoué)
- **Broadcast** : dernière adresse du sous-réseau
- **Multicast** : `224.0.0.0/4`

### Le routage

Un routeur choisit le prochain saut selon sa **table de routage**. La **route par défaut**
(`0.0.0.0/0`) est la passerelle utilisée quand aucune route plus précise ne correspond
(la plus spécifique gagne — *longest prefix match*).

```bash
ip route          # afficher la table de routage
ip route get 8.8.8.8    # quelle route sera empruntée pour cette destination
traceroute 8.8.8.8      # visualiser les sauts successifs
```

### NAT — pourquoi votre `192.168.x.x` accède à Internet

Le **NAT** (Network Address Translation) traduit les adresses privées en une adresse
publique partagée. C'est ce qui a permis de survivre à la pénurie d'IPv4. Conséquence
sécurité : le NAT masque la structure interne (un léger bénéfice), mais **n'est pas un
pare-feu** — ne confondez jamais NAT et sécurité.

### IPv6 — l'oublié dangereux

IPv6 (128 bits) est **déjà actif** sur la plupart des systèmes, souvent sans supervision.
Problèmes de sécurité récurrents :
- Un pare-feu configuré uniquement en IPv4 laisse tout passer en IPv6
- Autoconfiguration (SLAAC) et attaques par *Router Advertisement* usurpés
- Tunnels IPv6 pour contourner des contrôles IPv4

> **Réflexe pro :** toujours vérifier la couverture IPv6 de vos règles de filtrage.
> « On n'utilise pas IPv6 » est presque toujours faux.

### ICMP

Le protocole de contrôle (ping, traceroute, messages d'erreur). Souvent filtré, mais utile
en reconnaissance et parfois détourné comme canal d'exfiltration (ICMP tunneling).

---

## 3.3 — La couche 4 : TCP et UDP

### TCP — fiable, orienté connexion

- **Établissement (3-way handshake) :** `SYN → SYN-ACK → ACK`
- **Fermeture :** `FIN → ACK → FIN → ACK` (ou `RST` brutal)
- Numéros de séquence, acquittements, retransmission, contrôle de flux et de congestion

```
Client                    Serveur
   │ ─────── SYN ────────▶ │     « je veux ouvrir une connexion »
   │ ◀───── SYN-ACK ─────  │     « d'accord, et moi aussi »
   │ ─────── ACK ────────▶ │     « confirmé » → connexion établie
```

**Ce handshake est le fondement du scan de ports :**

| Réponse à un SYN | État du port | Type de scan |
|---|---|---|
| SYN-ACK | **Ouvert** | Le service écoute |
| RST | **Fermé** | Rien n'écoute |
| Aucune réponse | **Filtré** | Un pare-feu bloque |

Le **scan SYN** (`nmap -sS`, « half-open ») envoie SYN, lit la réponse, puis RST sans finir
le handshake — plus rapide et discret.

### UDP — rapide, sans connexion

Pas de handshake, pas de garantie de livraison. Utilisé quand la vitesse prime : DNS, DHCP,
VoIP, streaming, jeux, syslog. Plus difficile à scanner (pas de réponse ≠ fermé). Vecteur
privilégié des **attaques par amplification** (DNS, NTP, memcached) car on peut usurper
l'adresse source.

### Attaques de la couche 4

- **SYN flood** — inonder de SYN sans jamais répondre, saturer la table de connexions. Défense : **SYN cookies**.
- **Amplification/réflexion UDP** — petite requête usurpée → grosse réponse vers la victime. Défense : filtrage d'usurpation (BCP38), désactiver les services amplificateurs ouverts.

---

## 3.4 — La couche 2 : le réseau local, terrain d'attaque privilégié

C'est ici que se jouent les attaques les plus efficaces une fois **à l'intérieur** d'un réseau.

### Ethernet et adresses MAC

- Adresse MAC : 48 bits, gravée sur la carte mais **facilement usurpable** (`macchanger`)
- Le **switch** apprend quelle MAC est sur quel port (table CAM)

### ARP — le protocole qui traduit IP → MAC (et le maillon faible)

Pour envoyer une trame sur le LAN, il faut la MAC correspondant à une IP. ARP demande
« qui a l'IP `192.168.1.1` ? » et attend la réponse. **Problème : ARP ne vérifie rien.**
N'importe qui peut répondre « c'est moi ».

**ARP spoofing / poisoning** — l'attaquant s'annonce comme étant la passerelle. Tout le
trafic de la victime passe alors par lui → **Man-in-the-Middle** de couche 2.

```
Victime ──trafic──▶ Attaquant (se fait passer pour la passerelle) ──▶ Vraie passerelle
                         │ intercepte, lit, modifie
```

**Défenses :** Dynamic ARP Inspection, DHCP snooping, port security sur les switchs,
détection (arpwatch), chiffrement de bout en bout (qui neutralise l'écoute même en cas de MITM).

### Les autres attaques de couche 2

| Attaque | Principe | Défense |
|---|---|---|
| **MAC flooding** | Saturer la table CAM → le switch diffuse tout (comme un hub) | Port security |
| **DHCP spoofing** | Faux serveur DHCP → distribuer une fausse passerelle/DNS | DHCP snooping |
| **VLAN hopping** | Sortir de son VLAN | Désactiver l'auto-trunk (DTP), VLAN natif dédié |
| **STP manipulation** | Devenir le pont racine | BPDU guard, root guard |

### VLAN et segmentation

Les **VLAN** découpent un switch physique en réseaux logiques isolés. C'est la brique de
base de la **segmentation** — une des mesures les plus efficaces pour limiter le mouvement
latéral d'un attaquant. Un réseau « plat » (tout le monde peut parler à tout le monde) est
le rêve d'un ransomware.

---

## 3.5 — Les services applicatifs à connaître

### DNS — l'annuaire d'Internet (et un vecteur majeur)

Traduit `exemple.fr` → `93.184.216.34`. Comprendre la résolution récursive est essentiel :

```
Client → Resolveur (FAI/entreprise) → serveur Racine (.) → serveur TLD (.fr)
       → serveur faisant autorité (exemple.fr) → réponse → mise en cache
```

**Types d'enregistrements utiles :** A/AAAA (adresse), MX (mail), NS (serveurs de noms),
TXT (SPF, DKIM, vérifications), CNAME (alias), PTR (inverse), SOA.

**Sécurité du DNS :**
- **Reconnaissance** : énumération de sous-domaines révèle la surface d'attaque
- **Exfiltration** : encoder des données dans des requêtes DNS (souvent non filtré)
- **DNS spoofing / cache poisoning** : injecter de fausses réponses
- **Sous-domaines orphelins (dangling)** : un CNAME pointant vers un service désaffecté → prise de contrôle
- **Défenses** : DNSSEC (signe les réponses), DoH/DoT (chiffre les requêtes), surveillance des logs DNS

```bash
dig exemple.fr ANY
dig +trace exemple.fr        # voir toute la chaîne de résolution
dig @8.8.8.8 exemple.fr      # interroger un resolveur précis
```

### HTTP — le protocole du web (détaillé au module 07)

Sans état, requête/réponse. À connaître dès maintenant :

```
GET /page HTTP/1.1
Host: exemple.fr
User-Agent: ...
Cookie: session=abc123

HTTP/1.1 200 OK
Content-Type: text/html
Set-Cookie: session=abc123; HttpOnly; Secure; SameSite=Strict
```

**Méthodes :** GET, POST, PUT, DELETE, PATCH, HEAD, OPTIONS.
**Codes :** 2xx succès · 3xx redirection · 4xx erreur client (401 non authentifié,
403 interdit, 404 introuvable, 429 trop de requêtes) · 5xx erreur serveur.

### Les autres protocoles à situer

| Protocole | Port | Rôle | Point sécurité |
|---|---|---|---|
| SSH | 22 | Administration chiffrée | Clés > mots de passe, cible du brute force |
| SMTP/IMAP | 25/143 | Mail | SPF/DKIM/DMARC contre l'usurpation |
| SMB | 445 | Partage Windows | Vecteur historique (EternalBlue, relais NTLM) |
| RDP | 3389 | Bureau distant | Cible n°1 ransomware, exiger MFA/VPN |
| LDAP | 389/636 | Annuaire (AD) | Cœur d'Active Directory (module 05, 09) |
| SNMP | 161 | Supervision | Communautés par défaut `public`/`private` = fuite d'info |
| NTP | 123 | Temps | Amplification, et l'heure juste est vitale pour les logs et Kerberos |

---

## 3.6 — Les équipements et architectures de défense

### Pare-feu (firewall)

| Type | Fonctionnement |
|---|---|
| **Stateless** | Filtre paquet par paquet selon IP/port |
| **Stateful** | Suit l'état des connexions (le standard) |
| **NGFW** | + inspection applicative (couche 7), IPS, filtrage URL |
| **WAF** | Spécialisé HTTP, protège les applications web (module 07) |

Règle d'or : **liste blanche par défaut** (tout est interdit sauf ce qui est explicitement
autorisé), jamais liste noire.

### IDS / IPS

- **IDS** — détecte et alerte (passif)
- **IPS** — détecte et **bloque** (en coupure)
- **Approche par signatures** (Snort, Suricata) vs **par anomalies** (comportemental)

### Architecture segmentée — la DMZ

```
Internet ─▶ [Pare-feu externe] ─▶ DMZ (serveurs exposés : web, mail)
                                    │
                              [Pare-feu interne]
                                    │
                            LAN interne (postes, AD, bases de données)
```

La **DMZ** isole les serveurs exposés : s'ils sont compromis, l'attaquant n'atteint pas
directement le réseau interne. Principe : **cloisonner pour contenir**.

### VPN

Crée un tunnel chiffré à travers un réseau non sûr.
- **IPsec** — niveau réseau, site-à-site
- **WireGuard** — moderne, simple, rapide, à privilégier
- **OpenVPN** — éprouvé, flexible
- **SSL/TLS VPN** — accès distant via navigateur

> Attention : un VPN d'entreprise mal configuré (pas de MFA, faille non patchée) est
> **la porte d'entrée n°1** des intrusions récentes. Un VPN n'est un atout que s'il est durci.

---

## 3.7 — L'analyse de trafic : Wireshark et tcpdump

Savoir lire le trafic est une compétence transversale (pentest, SOC, forensics). C'est
l'outil qui rend le réseau **visible**.

### tcpdump — capture en ligne de commande

```bash
tcpdump -i eth0                          # capturer sur une interface
tcpdump -i eth0 -w capture.pcap          # écrire dans un fichier
tcpdump -i eth0 'tcp port 80'            # filtre de capture (BPF)
tcpdump -i eth0 'host 192.168.1.10 and port 443'
tcpdump -i eth0 -A 'tcp port 80'         # afficher le contenu ASCII
```

### Wireshark — l'analyse graphique

- **Filtres d'affichage** (≠ filtres de capture) : `http`, `tcp.port == 443`,
  `ip.addr == 192.168.1.10`, `dns`, `tcp.flags.syn == 1 && tcp.flags.ack == 0`
- **Follow TCP/HTTP Stream** — reconstruire un échange complet
- **Statistics → Conversations / Protocol Hierarchy** — vue d'ensemble d'une capture
- **Export Objects** — extraire les fichiers transférés

**Ce que vous devez savoir faire :** repérer un handshake TCP, lire une requête HTTP en
clair, extraire des identifiants transmis sans chiffrement, reconnaître un scan de ports
(rafale de SYN), suivre une résolution DNS, repérer un transfert suspect.

> **Lab marquant :** capturez une connexion FTP ou HTTP basique et **retrouvez le mot de
> passe en clair** dans la capture. Refaites-le en HTTPS : vous ne voyez plus rien. La
> valeur du chiffrement devient tangible.

---

## 3.8 — Le sans-fil (introduction)

Approfondi si vous choisissez la spécialisation. Les bases :

- **WEP** — ☠️ cassé depuis 2001, ne devrait plus exister
- **WPA2-PSK** — vulnérable à la capture du *handshake* puis attaque par dictionnaire hors ligne ; **KRACK** (2017) sur la réinstallation de clé
- **WPA3** — SAE (Dragonfly), résiste au dictionnaire hors ligne — mais failles Dragonblood au lancement
- **Attaques** : *Evil Twin* (faux point d'accès), désauthentification, *rogue AP*, capture de PMKID
- **Le mode moniteur** d'un adaptateur compatible permet la capture ; nécessaire pour l'audit Wi-Fi (Alfa, etc.)

---

## ✅ Labs du module 03

- [ ] **Lab 3.1 — Subnetting.** 30 exercices de calcul de sous-réseaux (réseau, broadcast, plage utilisable, « ces deux IP communiquent-elles ? »). Entraînez-vous sur [subnetting.org](https://subnetting.org) jusqu'à la fluidité.
- [ ] **Lab 3.2 — Wireshark : le handshake.** Capturez et disséquez un 3-way handshake TCP complet. Identifiez chaque flag (SYN, SYN-ACK, ACK) et les numéros de séquence.
- [ ] **Lab 3.3 — Mot de passe en clair.** Sur votre lab isolé, capturez une authentification HTTP ou FTP et extrayez les identifiants. Refaites en HTTPS et constatez la différence.
- [ ] **Lab 3.4 — Scan et lecture réseau.** Scannez Metasploitable (`nmap -sS -sV`) **en capturant simultanément avec Wireshark**. Corrélez ce que nmap annonce avec ce que vous voyez passer.
- [ ] **Lab 3.5 — ARP spoofing (LAB ISOLÉ UNIQUEMENT).** Entre deux VM que vous possédez, réalisez un MITM ARP avec `ettercap`/`bettercap` et observez le trafic détourné. **Comprenez la défense (DAI, port security) autant que l'attaque.**
- [ ] **Lab 3.6 — DNS.** Explorez `dig +trace`, énumérez les enregistrements d'un domaine que vous possédez, et lisez le rôle de SPF/DKIM/DMARC dans un TXT réel.
- [ ] **Lab 3.7 — TryHackMe.** Parcours « Network Fundamentals » et « Wireshark » de THM.
- [ ] **Lab 3.8 — pcap forensique.** Prenez une capture d'exemple (malware-traffic-analysis.net) et reconstruisez l'histoire : qui parle à qui, quel protocole, quel fichier transféré.

---

## 🎯 Auto-évaluation

1. `192.168.10.75/28` : quelles sont l'adresse réseau, le broadcast, la plage utilisable ?
2. Décrivez le 3-way handshake et reliez chaque réponse possible à un état de port.
3. Pourquoi ARP est-il exploitable, et comment défend-on un LAN contre l'ARP spoofing ?
4. Différence entre NAT et pare-feu ? Pourquoi le NAT n'est-il pas une sécurité ?
5. Un pare-feu ne filtre qu'en IPv4. Quel est le risque ?
6. À quelle couche OSI situez-vous : SYN flood, ARP poisoning, XSS, VLAN hopping ?
7. Comment le DNS peut-il servir de canal d'exfiltration ?
8. Quel filtre Wireshark isole les requêtes DNS d'une IP donnée ?
9. Pourquoi WPA2-PSK est-il vulnérable même avec un « bon » mot de passe court ?

---

**Suivant → [Module 04 : Linux](04-linux.md)**
