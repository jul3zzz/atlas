# Glossaire

> Plus de 200 termes et acronymes de la cybersécurité, expliqués simplement. Cherchez avec
> Ctrl-F. Renvois aux modules entre parenthèses.

---

## A

- **ABAC** — Attribute-Based Access Control. Droits calculés selon des attributs (heure, lieu, appareil). (01)
- **ACL** — Access Control List. Liste de permissions sur un objet (fichier, réseau, AD). (04, 09)
- **AEAD** — Authenticated Encryption with Associated Data. Chiffrement qui garantit *aussi* l'intégrité (AES-GCM, ChaCha20-Poly1305). (02)
- **AES** — Advanced Encryption Standard. Chiffrement symétrique standard. (02)
- **AMSI** — Antimalware Scan Interface. Interface Windows d'inspection des scripts. (06, 09)
- **ANSSI** — Agence Nationale de la Sécurité des Systèmes d'Information (France). (01, 14)
- **APT** — Advanced Persistent Threat. Adversaire sophistiqué, souvent étatique, patient. (01)
- **ARP** — Address Resolution Protocol. Traduit IP → MAC sur le LAN ; usurpable (spoofing). (03)
- **AS-REP Roasting** — Attaque Kerberos sur les comptes sans pré-authentification. (09)
- **ASLR** — Address Space Layout Randomization. Randomise les adresses mémoire (protection). (13)
- **ASVS** — Application Security Verification Standard (OWASP). (07)
- **ATT&CK** — Base de connaissances MITRE des tactiques et techniques d'attaque. (01)

## B

- **BIA** — Business Impact Analysis. Analyse d'impact sur l'activité. (14)
- **BloodHound** — Outil de cartographie des chemins d'attaque dans AD (graphes). (05, 09)
- **Bug bounty** — Programme récompensant la découverte autorisée de vulnérabilités. (17)
- **Buffer overflow** — Débordement de tampon mémoire, faille d'exploitation. (00, 13)
- **Burp Suite** — Proxy d'interception, outil central du pentest web. (07)

## C

- **C2 / C&C** — Command & Control. Infrastructure de pilotage des machines compromises. (08)
- **CIA / DICP** — Confidentialité, Intégrité, Disponibilité (+ Preuve/traçabilité). (01)
- **CIS Controls** — 18 contrôles de sécurité priorisés (référence pratique). (01, 14)
- **CISO / RSSI** — Responsable de la sécurité des SI (direction). (14, 17)
- **CSPM** — Cloud Security Posture Management. Audit de configuration cloud. (12)
- **CSRF** — Cross-Site Request Forgery. Forcer une action au nom d'une victime authentifiée. (07)
- **CTF** — Capture The Flag. Compétition de sécurité par défis. (15)
- **CTI** — Cyber Threat Intelligence. Renseignement sur la menace. (10)
- **CVE** — Common Vulnerabilities and Exposures. Identifiant unique d'une vulnérabilité publique. (08)
- **CVSS** — Common Vulnerability Scoring System. Score de gravité (0-10). (08)

## D

- **DAC** — Discretionary Access Control. Le propriétaire décide des permissions. (01)
- **DAST** — Dynamic Application Security Testing. Test de l'appli en fonctionnement. (12)
- **DCSync** — Attaque AD : répliquer les secrets du domaine (dont krbtgt). (09)
- **Défense en profondeur** — Plusieurs couches indépendantes de protection. (01)
- **DEP/NX** — Data Execution Prevention. Mémoire non exécutable (protection). (13)
- **DevSecOps** — Intégration de la sécurité dans le cycle DevOps. (12)
- **DFIR** — Digital Forensics & Incident Response. (11)
- **DMZ** — Zone démilitarisée. Segment isolant les serveurs exposés. (03)
- **DNS** — Domain Name System. Traduit noms ↔ IP ; vecteur d'exfiltration. (03)
- **DNSSEC** — Extensions de sécurité du DNS (signature des réponses). (03)
- **DoH / DoT** — DNS over HTTPS / over TLS. DNS chiffré. (03)
- **DoS / DDoS** — Déni de service (distribué). Atteinte à la disponibilité. (03)
- **DORA** — Digital Operational Resilience Act (finance UE). (14)
- **DPAPI** — Data Protection API (Windows). Protège des secrets utilisateur. (05)
- **DPO** — Délégué à la Protection des Données (RGPD). (14)

## E

- **EBIOS RM** — Méthode d'analyse de risque de l'ANSSI. (14)
- **EDR** — Endpoint Detection & Response. Surveillance comportementale des postes. (10)
- **EPP** — Endpoint Protection Platform (antivirus nouvelle génération). (10)
- **Exploit** — Code/technique tirant parti d'une vulnérabilité. (01, 08)
- **Exfiltration** — Sortie non autorisée de données. (08, 11)

## F

- **FIDO2 / WebAuthn** — Standard d'authentification forte résistant au phishing. (01)
- **Forensics** — Investigation numérique post-incident. (11)
- **Forward secrecy (PFS)** — Les clés de session passées restent sûres même si la clé long-terme fuit. (02)
- **Fuzzing** — Envoi massif d'entrées malformées pour trouver des bugs. (07, 13)

## G

- **GDPR / RGPD** — Règlement européen sur la protection des données. (14)
- **Ghidra** — Décompilateur/désassembleur gratuit (NSA). (11, 13)
- **gMSA** — Group Managed Service Account. Comptes de service à mot de passe géré (anti-Kerberoast). (05, 09)
- **Golden Ticket** — Faux TGT forgé avec le hash krbtgt → domination du domaine. (09)
- **GPO** — Group Policy Object. Stratégie de groupe AD. (05)
- **GRC** — Governance, Risk, Compliance. (14)
- **GTFOBins** — Base de détournements de binaires Unix pour l'escalade. (04)

## H

- **Hardening** — Durcissement d'un système. (04, 10)
- **Hash** — Empreinte de taille fixe, non réversible. (02)
- **HIDS/NIDS** — Host/Network Intrusion Detection System. (03, 10)
- **HMAC** — Hash-based Message Authentication Code. Intégrité + authenticité avec clé. (02)
- **HSTS** — HTTP Strict Transport Security. Force le HTTPS. (02, 07)
- **HTB** — Hack The Box. Plateforme d'entraînement. (15)

## I

- **IAM** — Identity & Access Management. (01, 12)
- **IDOR** — Insecure Direct Object Reference. Accès à un objet sans contrôle d'autorisation. (07)
- **IDS/IPS** — Intrusion Detection/Prevention System. (03)
- **IMDS** — Instance Metadata Service (cloud). Cible du SSRF pour voler des credentials. (12)
- **IOC** — Indicator of Compromise. Hash, IP, domaine trahissant une compromission. (10)
- **IaC** — Infrastructure as Code (Terraform, Ansible…). (12)
- **ISO 27001** — Norme de management de la sécurité de l'information (SMSI). (14)

## J-K

- **JWT** — JSON Web Token. Jeton signé (souvent mal implémenté). (02, 07)
- **KDC** — Key Distribution Center. Cœur de Kerberos (sur le DC). (05)
- **Kerberoasting** — Attaque : cracker hors ligne le TGS d'un compte de service. (09)
- **Kerberos** — Protocole d'authentification AD à base de tickets. (05, 09)
- **Kill chain** — Modèle des étapes d'une attaque (Lockheed Martin). (01)

## L

- **LAPS** — Local Administrator Password Solution. Mot de passe admin local unique/rotatif. (05, 09)
- **Lateral movement** — Mouvement latéral entre machines. (09)
- **LDAP** — Protocole d'annuaire (base d'AD). (03, 05)
- **LFI/RFI** — Local/Remote File Inclusion. Inclusion de fichier non contrôlée. (07)
- **LLMNR** — Protocole de résolution de noms local, cible de Responder. (09)
- **LOLBins / LOLBAS** — Living-Off-the-Land Binaries. Binaires légitimes détournés. (10)
- **LSASS** — Processus Windows stockant les secrets en mémoire (cible n°1). (05, 09)

## M

- **MAC** — 1) Mandatory Access Control (modèle). 2) Media Access Control (adresse réseau). (01, 03)
- **MFA / 2FA** — Authentification multi/à deux facteurs. (01)
- **Metasploit** — Framework d'exploitation. (08)
- **Meterpreter** — Payload avancé de Metasploit. (08)
- **MFT** — Master File Table (NTFS). Métadonnées de tous les fichiers. (00, 11)
- **Mimikatz** — Outil d'extraction de secrets Windows. (09)
- **MITM** — Man-in-the-Middle. Interception entre deux parties. (02, 03)
- **MTTD / MTTR** — Mean Time To Detect / Respond. (10)

## N

- **NAC** — Network Access Control. (03)
- **NAT** — Network Address Translation. Traduit adresses privées ↔ publique. (03)
- **NIS2** — Directive UE de cybersécurité (obligations élargies). (14)
- **NIST CSF** — Cadre de cybersécurité du NIST (Govern, Identify, Protect, Detect, Respond, Recover). (01, 14)
- **Nmap** — Scanner de ports/réseau de référence. (03, 08)
- **NTLM** — Ancien protocole d'authentification Windows (challenge/réponse). (05, 09)
- **NTDS.dit** — Base AD contenant tous les hash du domaine. (05, 09)

## O

- **OSINT** — Open Source Intelligence. Renseignement en sources ouvertes. (08)
- **OSCP** — Offensive Security Certified Professional. Certification pentest de référence. (16)
- **OT** — Operational Technology. Systèmes industriels (ICS/SCADA). (13)
- **OWASP** — Open Worldwide Application Security Project. (07)
- **OWASP Top 10** — Classement des risques web majeurs. (07)

## P

- **PAM** — 1) Privileged Access Management. 2) Pluggable Authentication Modules (Linux). (04)
- **Pass-the-Hash (PtH)** — S'authentifier avec un hash NT sans le mot de passe. (09)
- **Pass-the-Ticket** — Réutiliser un ticket Kerberos volé. (09)
- **PAW** — Privileged Access Workstation. Poste durci dédié à l'administration. (05)
- **PCA/PRA** — Plan de Continuité / Reprise d'Activité. (14)
- **Pentest** — Test d'intrusion. (08)
- **PKI** — Public Key Infrastructure. Gestion des certificats. (02)
- **PoC** — Proof of Concept. Preuve d'exploitabilité. (08)
- **Post-exploitation** — Actions après l'accès initial (escalade, persistance, pivot). (08)
- **PowerShell** — Shell et langage d'automatisation Windows. (06)
- **Privilege escalation** — Élévation de privilèges. (04, 05, 08)
- **Purple team** — Collaboration Red/Blue pour améliorer la détection. (08, 09)
- **Pyramid of Pain** — Hiérarchie des indicateurs selon la « douleur » infligée à l'attaquant. (01)

## R

- **RaaS** — Ransomware as a Service. (01, 11)
- **Ransomware** — Rançongiciel (chiffrement + extorsion). (11)
- **RBAC** — Role-Based Access Control. (01)
- **RCE** — Remote Code Execution. Exécution de code à distance. (07, 08)
- **Red team** — Simulation d'adversaire réaliste. (08)
- **Reverse engineering (RE)** — Rétro-ingénierie de code. (13)
- **Reverse shell** — Shell où la cible se connecte à l'attaquant. (08)
- **ROP** — Return-Oriented Programming. Contournement de DEP/NX. (13)
- **RTO/RPO** — Recovery Time/Point Objective. (14)

## S

- **SAML / OAuth / OIDC** — Protocoles d'authentification/autorisation fédérée. (12)
- **SAST** — Static Application Security Testing. (12)
- **SBOM** — Software Bill of Materials. Inventaire des composants logiciels. (12)
- **SCA** — Software Composition Analysis. Analyse des dépendances. (12)
- **SCADA / ICS** — Systèmes de contrôle industriel. (13)
- **Scapy** — Bibliothèque Python de manipulation de paquets. (06)
- **SIEM** — Security Information and Event Management. Centralisation et corrélation des logs. (10)
- **Sigma** — Format de règles de détection agnostique (logs). (10)
- **SID** — Security Identifier (Windows). (05)
- **SLSA** — Cadre d'intégrité de la chaîne de build logicielle. (12)
- **SMB** — Server Message Block. Partage de fichiers Windows (port 445). (03, 08)
- **SMSI** — Système de Management de la Sécurité de l'Information (ISO 27001). (14)
- **SOAR** — Security Orchestration, Automation and Response. (10)
- **SOC** — Security Operations Center. (10)
- **SOP** — Same-Origin Policy. Pilier de sécurité du navigateur. (07)
- **Spear phishing** — Hameçonnage ciblé. (13, 17)
- **SPN** — Service Principal Name (Kerberos). Cible du Kerberoasting. (05, 09)
- **SQLi** — SQL Injection. (07)
- **SSRF** — Server-Side Request Forgery. (07, 12)
- **SSTI** — Server-Side Template Injection. (07)
- **STRIDE** — Grille de modélisation de menace (Spoofing, Tampering, Repudiation, Info disclosure, DoS, Elevation). (01)
- **SUID/SGID** — Bits de permission spéciaux Unix (vecteur d'escalade). (04)
- **Sysmon** — Outil de journalisation Windows enrichie. (10)

## T

- **TGT / TGS** — Ticket Granting Ticket / Service (Kerberos). (05, 09)
- **Threat hunting** — Chasse proactive aux menaces. (10)
- **Threat modeling** — Modélisation de menace. (01)
- **TLS** — Transport Layer Security. Chiffrement des communications (HTTPS). (02)
- **TPM** — Trusted Platform Module. Puce cryptographique. (00)
- **TTP** — Tactics, Techniques & Procedures. Comportements d'attaquant. (01)

## U-V

- **UAC** — User Account Control (Windows). (05)
- **UEFI** — Firmware de démarrage moderne (remplace le BIOS). (00)
- **VLAN** — Virtual LAN. Segmentation réseau logique. (03)
- **Volatility** — Framework d'analyse de mémoire (forensics). (11)
- **VPN** — Virtual Private Network. Tunnel chiffré. (03)
- **Vulnérabilité** — Faiblesse exploitable. (01)

## W-X-Y-Z

- **WAF** — Web Application Firewall. (03, 07)
- **Wazuh** — SIEM/HIDS open source (idéal home lab). (10)
- **WebAuthn** — voir FIDO2. (01)
- **Wireshark** — Analyseur de trafic réseau. (03)
- **XDR** — Extended Detection and Response. (10)
- **XSS** — Cross-Site Scripting. (07)
- **XXE** — XML External Entity injection. (07)
- **YARA** — Format de règles pour identifier des fichiers/malwares. (10, 11)
- **Zeek** — Analyseur de trafic produisant des logs structurés. (11)
- **Zero-day (0-day)** — Vulnérabilité inconnue de l'éditeur, sans correctif. (01)
- **Zero Trust** — « Ne jamais faire confiance, toujours vérifier ». (01)

---

**← [Sommaire](../README.md)** · [Cheatsheet](cheatsheet-commandes.md) · [Ressources](ressources.md)
