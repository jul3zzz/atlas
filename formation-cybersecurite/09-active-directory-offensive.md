# Module 09 — Attaque d'Active Directory

> **Objectif :** maîtriser le chemin d'attaque le plus emprunté dans le monde réel. La quasi-
> totalité des intrusions en entreprise et des campagnes de ransomware passent par la
> compromission d'Active Directory. Savoir l'attaquer, c'est savoir le défendre.
>
> **Durée :** 4 semaines · **Prérequis :** modules 05 (AD), 08 (pentest), et un lab AD (GOAD)

> **Rappel :** lab isolé ou mandat écrit **uniquement**. Ces techniques sont exactement
> celles des groupes de ransomware — leur usage non autorisé est un crime grave.

---

## 9.1 — Le déroulé type d'une attaque AD

```
Accès initial (phishing, service exposé, compte faible)
   → Reconnaissance interne (utilisateurs, machines, groupes, ACL)
      → Vol d'identifiants (Responder, Kerberoasting, LSASS)
         → Escalade (chemins BloodHound, délégations, ADCS)
            → Mouvement latéral (Pass-the-Hash, WMI, PsExec, WinRM)
               → Domination du domaine (DCSync, Golden Ticket)
                  → Persistance & objectif (ransomware, exfiltration)
```

Chaque flèche correspond à des techniques concrètes ci-dessous. **BloodHound** relie le tout
en trouvant le chemin le plus court vers l'objectif.

---

## 9.2 — Reconnaissance et énumération interne

Une fois un premier pied dans le domaine (même un simple compte utilisateur), on cartographie.

### Les outils

```bash
# Depuis Linux/Kali (Impacket, NetExec/CrackMapExec)
netexec smb 10.0.0.0/24                            # découverte du domaine
netexec smb 10.0.0.10 -u user -p pass --users      # énumérer les comptes
netexec smb 10.0.0.10 -u user -p pass --shares
ldapsearch -x -H ldap://10.0.0.10 -D 'user@dom' -w pass -b 'dc=dom,dc=local'
```

```powershell
# Depuis Windows (PowerView / module AD)
Get-DomainUser | select samaccountname
Get-DomainGroupMember "Domain Admins"
Get-DomainComputer | select dnshostname
Get-DomainUser -SPN                          # comptes kerberoastables
Get-DomainUser -PreauthNotRequired           # comptes AS-REP roastables
Find-InterestingDomainAcl                    # ACL exploitables
```

### BloodHound — l'arme décisive

```bash
# Collecte des données (SharpHound / bloodhound-python)
bloodhound-python -u user -p pass -d dom.local -ns 10.0.0.10 -c All
```

On importe le résultat dans BloodHound et on utilise les requêtes intégrées :
« Shortest paths to Domain Admins », « Find principals with DCSync rights », « Kerberoastable
users », « Dangerous ACLs ». BloodHound transforme un labyrinthe d'ACL en un **graphe** où
le chemin d'attaque apparaît visuellement.

> **Côté Blue Team :** BloodHound est aussi votre meilleur outil défensif. Il révèle les
> chemins d'attaque **avant** l'attaquant. « Casser » ces chemins (retirer des droits
> excessifs) est l'un des travaux de durcissement AD les plus rentables.

---

## 9.3 — Attaques sans identifiants ou avec compte faible

### LLMNR/NBT-NS Poisoning (Responder)

Quand une machine cherche un nom qu'un DNS ne résout pas, elle diffuse une requête
**LLMNR/NBT-NS** sur le LAN. **Responder** y répond « c'est moi » et capture le
**challenge/réponse NetNTLM** de la victime, crackable hors ligne.

```bash
responder -I eth0                             # empoisonner et capturer
hashcat -m 5600 captured.txt rockyou.txt      # cracker le NetNTLMv2
```

**Défense :** désactiver LLMNR et NBT-NS (GPO) — mesure à fort impact, souvent oubliée.

### NTLM Relay

Plutôt que de cracker le hash capturé, on le **relaie** en temps réel vers un autre service
qui accepte NTLM (SMB, LDAP, ADCS). Si la **signature SMB/LDAP n'est pas exigée**, on
s'authentifie comme la victime sans jamais connaître son mot de passe.

```bash
ntlmrelayx.py -tf targets.txt -smb2support        # relayer vers SMB
ntlmrelayx.py -t ldaps://dc --escalate-user user  # relayer vers LDAP/ADCS
```

**Défense :** **signature SMB et LDAP obligatoire**, désactivation de NTLM, EPA sur les
services web (ADCS).

---

## 9.4 — Attaques Kerberos

Reprend la théorie du module 05. Ce sont les techniques les plus emblématiques d'AD.

### Kerberoasting

Tout compte de service avec un **SPN** peut se voir demander un **TGS** par n'importe quel
utilisateur authentifié. Ce TGS est **chiffré avec le hash du compte de service** → on le
capture et on le casse **hors ligne**. Si le compte a un mot de passe faible, on le récupère.

```bash
GetUserSPNs.py dom.local/user:pass -dc-ip 10.0.0.10 -request   # Impacket
hashcat -m 13100 tgs.txt rockyou.txt                            # cracker
```

**Défense :** comptes de service en **gMSA** (mot de passe de 120+ caractères, non
crackable), mots de passe longs, surveillance des événements 4769 anormaux, honeytokens.

### AS-REP Roasting

Les comptes marqués « **ne pas exiger la pré-authentification Kerberos** » livrent, sur
simple demande, un AS-REP chiffré avec le hash du compte → crackable hors ligne, **sans même
avoir de compte valide** (juste la liste des utilisateurs).

```bash
GetNPUsers.py dom.local/ -usersfile users.txt -dc-ip 10.0.0.10   # Impacket
hashcat -m 18200 asrep.txt rockyou.txt
```

**Défense :** ne jamais désactiver la pré-authentification ; mots de passe forts ; détection.

### Pass-the-Ticket, Golden & Silver Ticket

- **Pass-the-Ticket** — voler un ticket Kerberos en mémoire (Mimikatz) et le réutiliser.
- **Silver Ticket** — avec le hash d'un **compte de service**, forger un TGS valide pour ce service (accès ciblé, très discret, ne touche pas le DC).
- **Golden Ticket** — avec le hash du compte **`krbtgt`** (obtenu par DCSync), forger des **TGT arbitraires** : n'importe quel utilisateur, n'importe quel groupe, validité choisie. **C'est la domination totale et persistante du domaine.**

```bash
# Golden Ticket (Impacket) — nécessite le hash krbtgt
ticketer.py -nthash <krbtgt_hash> -domain-sid <SID> -domain dom.local Administrator
```

**Défense :** protéger le DC (le krbtgt volé = partie perdue), **rotation double du mot de
passe krbtgt** en cas de compromission, détection d'anomalies de tickets (durée de vie
aberrante, chiffrement RC4).

---

## 9.5 — Vol d'identifiants sur les machines

### Mimikatz — l'outil emblématique

Une fois administrateur local d'une machine, on extrait de **LSASS** les secrets en mémoire :

```
sekurlsa::logonpasswords       # hash NT, parfois mots de passe en clair, tickets Kerberos
lsadump::sam                    # comptes locaux (SAM)
lsadump::dcsync /user:krbtgt    # DCSync (voir plus bas)
sekurlsa::pth                   # Pass-the-Hash
```

**Défense :** **Credential Guard** (isole LSASS via virtualisation), désactiver WDigest
(plus de mot de passe en clair), **LAPS** (mots de passe locaux uniques), modèle en tiers
(un admin de domaine ne se connecte jamais sur un poste où son ticket serait volable),
détection d'accès à LSASS (EDR).

### Pass-the-Hash (PtH)

Le hash NT **suffit** à s'authentifier via NTLM, **sans connaître le mot de passe**. Si le
même compte administrateur local existe sur plusieurs machines (mot de passe identique),
un seul hash ouvre tout le parc → **mouvement latéral massif**.

```bash
netexec smb 10.0.0.0/24 -u Administrator -H <hash_NT>       # spraying du hash
psexec.py -hashes :<hash_NT> Administrator@10.0.0.20        # exécution distante
```

**Défense :** **LAPS** (tue la réutilisation de mot de passe local), moindre privilège,
tiering, désactivation de NTLM.

---

## 9.6 — Mouvement latéral

Se déplacer de machine en machine avec les identifiants collectés :

| Technique | Outil | Port |
|---|---|---|
| **PsExec** | `psexec.py`, PsExec | SMB 445 |
| **WMI** | `wmiexec.py` | RPC 135 |
| **WinRM** | `evil-winrm`, `Enter-PSSession` | 5985/5986 |
| **DCOM, SMB, scheduled tasks** | Impacket, atexec | divers |

```bash
evil-winrm -i 10.0.0.20 -u Administrator -H <hash>
wmiexec.py dom.local/user@10.0.0.20 -hashes :<hash>
```

**Défense :** segmentation, restriction des comptes admin locaux (LAPS + désactivation du
logon réseau des admins locaux — « Deny access from network »), détection des exécutions
distantes anormales, journalisation (4624 type 3, création de services 7045).

---

## 9.7 — Domination du domaine

### DCSync

Un compte disposant des droits de **réplication** (naturellement les Domain Controllers,
mais parfois délégué par erreur à d'autres comptes — BloodHound le révèle) peut demander au
DC de **répliquer les secrets**, dont le hash de **tous** les comptes, y compris `krbtgt`.

```bash
secretsdump.py dom.local/user@10.0.0.10 -just-dc            # dump complet du domaine
# ou via Mimikatz : lsadump::dcsync /user:krbtgt
```

DCSync + hash krbtgt → **Golden Ticket** → contrôle total et persistant.

**Défense :** auditer et restreindre les droits de réplication (`DS-Replication-Get-Changes*`),
surveiller l'événement **4662** avec les GUID de réplication, alerter sur toute réplication
provenant d'une IP non-DC.

### AD CS (ADCS) — les attaques ESC1-ESC8

Les services de certificats Active Directory, mal configurés, offrent des chemins
d'escalade dévastateurs (un template autorisant un utilisateur à spécifier n'importe quel
sujet → certificat d'admin de domaine). Outils : **Certipy**, Certify.

```bash
certipy find -u user@dom -p pass -dc-ip 10.0.0.10 -vulnerable   # repérer les templates vulnérables
```

**Défense :** auditer les templates (Certipy/PSPKI), corriger ESC1-ESC8, EPA, tiering de l'ADCS.

### Délégations Kerberos

- **Non contrainte (unconstrained)** — une machine peut usurper n'importe quel utilisateur qui s'y connecte → capture de TGT (dont potentiellement un admin de domaine)
- **Contrainte / basée sur les ressources (RBCD)** — chaînes d'escalade plus subtiles

**Défense :** proscrire la délégation non contrainte, marquer les comptes sensibles
« Account is sensitive and cannot be delegated », auditer avec BloodHound.

---

## 9.8 — La bascule vers la défense (Purple Team)

Ce module est une mine d'or défensive. Pour **chaque** attaque, la question à se poser :

1. **Quel journal la trace ?** (4768/4769 Kerberos, 4662 DCSync, 4624/4625 logon, 5140/5145 partages, 7045 service, 4720 création de compte…)
2. **Quelle règle de détection ?** (Sigma, requête SIEM — voir module 10)
3. **Quel durcissement l'empêche en amont ?** (LAPS, gMSA, signature SMB/LDAP, tiering, désactivation LLMNR/NTLM…)

> **Faites l'exercice systématiquement.** Attaquer dans GOAD puis chasser la même attaque
> dans les logs de votre lab défensif (module 10) est l'entraînement **purple team** le plus
> formateur qui existe — et exactement ce que valorisent les employeurs.

### Tableau récapitulatif attaque → détection → défense

| Attaque | Détection clé | Défense principale |
|---|---|---|
| LLMNR poisoning | Trafic LLMNR/NBT-NS anormal | Désactiver LLMNR/NBT-NS |
| NTLM relay | Auth NTLM inter-machines | Signature SMB/LDAP, désactiver NTLM |
| Kerberoasting | 4769 en masse, chiffrement RC4 | gMSA, mots de passe longs, honeytoken |
| AS-REP roasting | 4768 sans pré-auth | Exiger la pré-auth |
| Pass-the-Hash | 4624 type 3 anormaux | LAPS, tiering, désactiver NTLM |
| DCSync | 4662 GUID réplication depuis non-DC | Restreindre droits de réplication |
| Golden Ticket | Tickets à durée aberrante, RC4 | Protéger le DC, rotation krbtgt |
| ADCS ESC | Émission de certificats anormale | Corriger les templates |

---

## ✅ Labs du module 09

- [ ] **Lab 9.1 — Déployer GOAD** (ou un lab AD vulnérable maison) et cartographier avec BloodHound. Identifiez visuellement un chemin vers Domain Admin.
- [ ] **Lab 9.2 — Responder + relay.** Capturez un NetNTLMv2 avec Responder, crackez-le, puis réalisez un NTLM relay vers SMB. Ensuite, **désactivez LLMNR/exigez la signature SMB** et constatez l'échec.
- [ ] **Lab 9.3 — Kerberoasting de bout en bout.** Trouvez les comptes à SPN, demandez les TGS, crackez-les. Puis convertissez le compte en gMSA et vérifiez que l'attaque devient inutile.
- [ ] **Lab 9.4 — AS-REP roasting.** Identifiez un compte sans pré-auth, récupérez et crackez l'AS-REP.
- [ ] **Lab 9.5 — PtH & mouvement latéral.** Extrayez un hash (Mimikatz/secretsdump), faites du Pass-the-Hash et pivotez avec evil-winrm/psexec vers d'autres machines.
- [ ] **Lab 9.6 — DCSync → Golden Ticket.** Obtenez les droits de réplication, faites un DCSync, récupérez le hash krbtgt, forgez un Golden Ticket, et démontrez le contrôle total.
- [ ] **Lab 9.7 — ADCS.** Avec Certipy, trouvez un template vulnérable, exploitez-le (ESC1), obtenez un certificat d'admin.
- [ ] **Lab 9.8 — Purple team.** **Le lab le plus important :** rejouez 3 attaques ci-dessus en collectant les logs Windows, puis écrivez pour chacune une règle de détection et vérifiez qu'elle se déclenche (transition vers le module 10).

---

## 🎯 Auto-évaluation

1. Décrivez le déroulé complet d'une attaque AD, de l'accès initial au Golden Ticket.
2. Comment Responder capture-t-il des identifiants, et comment l'en empêche-t-on ?
3. Différence entre cracker un hash NTLM capturé et le relayer ? Que faut-il pour le relay ?
4. Expliquez le Kerberoasting : pourquoi le TGS est-il crackable, et que change le gMSA ?
5. Qu'est-ce que le DCSync et quel événement le trahit ?
6. Golden vs Silver Ticket : quelle clé, quelle portée, quelle discrétion ?
7. Pourquoi LAPS neutralise-t-il le mouvement latéral par Pass-the-Hash ?
8. Qu'apporte BloodHound à l'attaquant ET au défenseur ?
9. Pour 3 attaques de ce module, donnez la détection et la défense associées.

---

**Suivant → [Module 10 : Blue Team & SOC](10-blue-team-soc.md)**
