# Module 02 — Cryptographie appliquée

> **Objectif :** comprendre les primitives cryptographiques, savoir les combiner correctement,
> et surtout **reconnaître les usages erronés** — car c'est là que se trouvent les failles.
>
> **Durée :** 2 à 3 semaines · **Prérequis :** modules 00, 01

> **Cadre d'esprit :** vous n'aurez presque jamais à *inventer* de la crypto (et vous ne
> devez jamais le faire). Vous devrez l'*utiliser correctement* et *repérer les mauvais
> usages*. 95 % des failles crypto réelles ne sont pas des cassages d'algorithmes, mais des
> erreurs d'implémentation : mauvais mode, IV réutilisé, clé en dur, comparaison non
> constante, absence d'authentification.

---

## 2.1 — Les trois familles

| Famille | Ce qu'elle garantit | Clé | Analogie |
|---|---|---|---|
| **Hachage** | Intégrité | Aucune | Empreinte digitale |
| **Chiffrement symétrique** | Confidentialité | Une clé partagée | Un cadenas à code unique |
| **Chiffrement asymétrique** | Confidentialité + authenticité | Paire publique/privée | Une boîte aux lettres (tous déposent, un seul relève) |

La cryptographie moderne **combine** ces trois familles. TLS, la signature, le chiffrement
de bout en bout : tout est assemblage.

---

## 2.2 — Les fonctions de hachage

Une fonction de hachage transforme une entrée de taille quelconque en une empreinte de
taille fixe. Propriétés attendues d'un hash **cryptographique** :

1. **Déterministe** — même entrée → même sortie
2. **Rapide à calculer**
3. **Résistance à la préimage** — impossible de retrouver l'entrée depuis la sortie
4. **Résistance à la seconde préimage** — impossible de trouver une autre entrée donnant le même hash
5. **Résistance aux collisions** — impossible de trouver deux entrées différentes de même hash
6. **Effet avalanche** — 1 bit changé → ~50 % de la sortie change

### Panorama

| Algorithme | Taille | Statut | Usage |
|---|---|---|---|
| **MD5** | 128 bits | ☠️ Cassé (collisions triviales) | Checksums non sécurité uniquement |
| **SHA-1** | 160 bits | ☠️ Cassé (SHAttered, 2017) | À éliminer |
| **SHA-256 / SHA-512** | 256/512 | ✅ Sûr | Usage général, signatures, blockchain |
| **SHA-3 (Keccak)** | variable | ✅ Sûr | Alternative structurelle à SHA-2 |
| **BLAKE2 / BLAKE3** | variable | ✅ Sûr, très rapide | Alternative moderne performante |

```bash
echo -n "hello" | sha256sum
sha256sum fichier.iso        # vérifier l'intégrité d'un téléchargement
```

### ⚠️ Le hachage de mots de passe : un cas totalement à part

**Un mot de passe ne se hache JAMAIS avec SHA-256 simple.** SHA-256 est conçu pour être
*rapide* — exactement ce qu'on ne veut pas ici, car cela permet de tester des milliards de
candidats par seconde sur GPU.

Il faut des fonctions **lentes, salées et paramétrables** :

| Fonction | Recommandation | Pourquoi |
|---|---|---|
| **Argon2id** | ✅ **Le choix actuel** (gagnant du Password Hashing Competition) | Résiste au GPU **et** à l'ASIC (memory-hard) |
| **scrypt** | ✅ Bon | Memory-hard |
| **bcrypt** | ✅ Acceptable | Éprouvé, mais limité à 72 octets |
| **PBKDF2** | ⚠️ Si contrainte de conformité | Pas memory-hard, exiger beaucoup d'itérations |
| SHA-256/MD5 nu | ❌ **Faute grave** | Cassé en masse par rainbow tables et GPU |

**Deux notions indispensables :**

- **Le sel (salt)** — une valeur aléatoire **unique par utilisateur**, stockée à côté du hash.
  Il empêche les *rainbow tables* et fait que deux utilisateurs avec le même mot de passe
  ont des hash différents. Le sel n'est pas secret.
- **Le poivre (pepper)** — un secret **global**, stocké séparément (HSM, variable
  d'environnement), ajouté avant le hachage. Défense supplémentaire si la base fuit mais pas le pepper.

```python
# Exemple correct avec argon2-cffi
from argon2 import PasswordHasher
ph = PasswordHasher()                      # paramètres sûrs par défaut
hash = ph.hash("motdepasse_utilisateur")   # sel géré automatiquement, intégré au hash
ph.verify(hash, "motdepasse_utilisateur")  # lève une exception si faux
```

### HMAC — hachage avec clé

Un hash simple prouve l'intégrité mais **pas l'authenticité** (n'importe qui peut recalculer
un hash). Le **HMAC** combine un hash avec une clé secrète : seul celui qui détient la clé
peut produire ou vérifier le code. Usage : API, webhooks, tokens, cookies signés.

```python
import hmac, hashlib
sig = hmac.new(cle_secrete, message, hashlib.sha256).hexdigest()
# Vérification : TOUJOURS avec comparaison à temps constant
hmac.compare_digest(sig_recue, sig_calculee)   # ← jamais ==
```

> **Piège du timing attack :** comparer deux signatures avec `==` s'arrête au premier octet
> différent. Le temps de réponse révèle combien d'octets sont corrects, ce qui permet de
> reconstruire la signature octet par octet. Toujours `hmac.compare_digest` /
> `crypto.timingSafeEqual`.

---

## 2.3 — Le chiffrement symétrique

Une seule clé pour chiffrer et déchiffrer. Rapide, adapté aux gros volumes.

### AES — le standard

**AES** (Advanced Encryption Standard) opère sur des blocs de 128 bits, avec des clés de
128, 192 ou 256 bits. C'est un **chiffrement par bloc** — et c'est le **mode d'opération**
qui fait toute la différence de sécurité.

### Les modes d'opération — LE point critique

| Mode | Type | Statut | Note |
|---|---|---|---|
| **ECB** | Bloc | ☠️ **À bannir** | Chaque bloc chiffré indépendamment → les motifs restent visibles |
| **CBC** | Bloc | ⚠️ Correct si bien fait | Nécessite un IV aléatoire ; vulnérable au padding oracle sans authentification |
| **CTR** | Flux | ⚠️ | Ne jamais réutiliser le couple (clé, nonce) |
| **GCM** | AEAD | ✅ **Recommandé** | Chiffre **et** authentifie (intégrité intégrée) |
| **ChaCha20-Poly1305** | AEAD | ✅ **Recommandé** | Excellent sans accélération matérielle AES (mobile) |

**La démonstration ECB (le « pingouin ECB ») :** si vous chiffrez une image en mode ECB,
on reconnaît encore l'image, car les zones de même couleur produisent les mêmes blocs
chiffrés. **Faites ce lab, il est marquant.**

### AEAD — chiffrement authentifié : la seule bonne pratique moderne

Un chiffrement sans authentification garantit la confidentialité mais **pas l'intégrité** :
un attaquant peut modifier le texte chiffré sans être détecté (bit-flipping, padding oracle).

L'**AEAD** (Authenticated Encryption with Associated Data) — AES-GCM, ChaCha20-Poly1305 —
produit un **tag d'authentification** : si un seul bit est modifié, le déchiffrement échoue.

> **Règle simple à retenir toute votre carrière :** *chiffrer ce n'est pas authentifier.*
> Utilisez toujours un mode AEAD, ou combinez « Encrypt-then-MAC ». Ne combinez jamais vous-même
> un chiffrement et un MAC à la main sans savoir exactement ce que vous faites.

### Les erreurs classiques à repérer en audit

- Mode **ECB** (motifs visibles)
- **IV/nonce réutilisé** ou constant (`IV = 0000...`) — casse CTR et GCM
- **IV prévisible** en CBC (permet certaines attaques)
- Clé **codée en dur** dans le source (`grep -r "key ="`)
- Absence d'authentification (pas de tag, pas de MAC)
- Clé dérivée d'un mot de passe **sans KDF** (utiliser Argon2/PBKDF2/HKDF)

---

## 2.4 — Le chiffrement asymétrique

Deux clés mathématiquement liées : la **publique** (partageable) et la **privée** (secrète).

### Les deux usages, symétriques l'un de l'autre

```
CONFIDENTIALITÉ :  chiffrer avec la clé PUBLIQUE du destinataire
                   → seul lui, avec sa clé PRIVÉE, peut déchiffrer

SIGNATURE :        signer avec sa PROPRE clé PRIVÉE
                   → tous, avec la clé PUBLIQUE, vérifient l'authenticité et l'intégrité
```

### Les algorithmes

| Algorithme | Fondé sur | Note |
|---|---|---|
| **RSA** | Factorisation de grands nombres | Historique, robuste. Clés ≥ 2048 bits (3072+ conseillé) |
| **ECC (ECDSA, EdDSA)** | Courbes elliptiques | Clés bien plus courtes à sécurité égale (256 bits ECC ≈ 3072 bits RSA) |
| **Diffie-Hellman (DH/ECDH)** | Logarithme discret | **Échange de clé**, pas chiffrement. Base du secret partagé |

### Le chiffrement hybride — comment ça marche vraiment

L'asymétrique est lent : on ne l'utilise pas pour chiffrer les données. On l'utilise pour
**échanger une clé de session symétrique**, puis on chiffre les données avec le symétrique
(rapide). **C'est ce que fait TLS, PGP, Signal, chaque connexion HTTPS.**

```
1. Alice génère une clé de session AES aléatoire
2. Alice chiffre cette clé avec la clé PUBLIQUE de Bob (ou l'échange par ECDH)
3. Alice chiffre le message avec AES-GCM (rapide)
4. Bob déchiffre la clé de session avec sa clé PRIVÉE, puis le message avec AES
```

### Forward secrecy (PFS)

Avec un échange **éphémère** (ECDHE), une nouvelle clé de session est générée à chaque
connexion. Conséquence majeure : même si la clé privée long-terme du serveur est volée
**plus tard**, les communications passées **capturées** restent indéchiffrables.
C'est pourquoi TLS moderne impose ECDHE. Exigez-le.

---

## 2.5 — PKI, certificats et TLS

### Le problème de la confiance

Le chiffrement asymétrique règle la confidentialité, mais pose une question : *comment
savoir que cette clé publique appartient bien à `banque.fr` et non à un attaquant ?*
Réponse : la **PKI** (Public Key Infrastructure) et les **certificats**.

### La chaîne de confiance

```
Autorité racine (CA Root)  — auto-signée, sa clé privée est le trésor absolu, hors ligne
        │  signe
   CA intermédiaire         — signe les certificats du quotidien
        │  signe
   Certificat serveur       — « je certifie que cette clé publique est celle de banque.fr »
```

Votre navigateur/OS embarque une liste de **CA racines de confiance**. Un certificat est
validé s'il **remonte** à une racine de confiance, qu'il n'est **pas expiré**, **pas révoqué**
(CRL/OCSP), et que le **nom (CN/SAN)** correspond au domaine visité.

### Un certificat X.509 contient

- La clé publique du serveur
- Le nom (Subject : CN, SAN — les domaines couverts)
- L'émetteur (Issuer : la CA)
- La période de validité
- La signature de la CA
- Les usages autorisés

```bash
# Inspecter le certificat d'un site
openssl s_client -connect exemple.fr:443 -servername exemple.fr </dev/null 2>/dev/null \
  | openssl x509 -noout -text
# Vérifier la date d'expiration
echo | openssl s_client -connect exemple.fr:443 2>/dev/null | openssl x509 -noout -dates
```

### Le déroulé d'un handshake TLS 1.3 (simplifié)

```
1. ClientHello  → versions, suites cryptographiques, part ECDHE du client
2. ServerHello  → suite choisie, part ECDHE du serveur, certificat
3. Les deux dérivent le même secret partagé (ECDHE) → forward secrecy
4. Le client valide le certificat (chaîne, date, nom, révocation)
5. Communication chiffrée en AEAD
```

TLS 1.3 (2018) a supprimé les options dangereuses (RC4, CBC sans AEAD, RSA static,
renégociation), réduit le handshake à un aller-retour, et rendu la PFS obligatoire.
**TLS 1.0/1.1 sont morts. TLS 1.2 minimum, 1.3 recommandé.**

### Attaques et défenses autour de TLS

| Attaque | Principe | Défense |
|---|---|---|
| **MITM avec faux certificat** | L'attaquant présente son propre certificat | Validation stricte, HSTS, certificate pinning |
| **Downgrade** | Forcer une version faible | TLS 1.2+ imposé, `TLS_FALLBACK_SCSV` |
| **Certificat volé/mal émis** | CA compromise | Certificate Transparency (logs publics), CAA DNS |
| **HTTP en clair initial** | 1ʳᵉ requête interceptable | **HSTS** (préchargé) force HTTPS d'emblée |

**Outil incontournable :** [SSL Labs](https://www.ssllabs.com/ssltest/) — audite gratuitement
la config TLS d'un site public et attribue une note. Apprenez à interpréter son rapport.

---

## 2.6 — Applications concrètes de la crypto

| Besoin | Solution |
|---|---|
| Stocker des mots de passe | Argon2id + sel (jamais réversible) |
| Chiffrer une base de données au repos | AES-256-GCM, clé dans un HSM/KMS |
| Chiffrer un disque | LUKS (Linux), BitLocker (Windows), FileVault (macOS) |
| Sécuriser une API | HTTPS + tokens signés (JWT HMAC/RS256) |
| Authentifier un webhook | HMAC-SHA256 sur le corps + comparaison constante |
| Chiffrement de bout en bout (messagerie) | Protocole Signal (Double Ratchet, X3DH) |
| Signer un logiciel/commit | GPG, Sigstore, signature de code |
| Prouver une possession sans la révéler | Zero-knowledge proofs (avancé) |

### JWT — un cas d'école des erreurs crypto

Le JSON Web Token est omniprésent et truffé de pièges classiques d'audit :

- **`alg: none`** — certaines implémentations acceptent un token « non signé ». Faille critique.
- **Confusion RS256 → HS256** — l'attaquant change l'algo pour HMAC et utilise la clé **publique** (connue) comme secret HMAC. Toujours **fixer** l'algorithme côté serveur.
- **Secret HMAC faible** — brute-forçable hors ligne (`hashcat -m 16500`).
- **Absence de vérification d'expiration / d'audience** — token rejouable.
- **Données sensibles dans le payload** — un JWT est **encodé (base64), pas chiffré**. Tout le monde lit son contenu.

---

## 2.7 — Ce qui vient : cryptographie post-quantique

Un ordinateur quantique suffisamment puissant casserait RSA et ECC (algorithme de Shor).
Ce n'est pas encore le cas, mais la menace **« harvest now, decrypt later »** est réelle :
des adversaires **capturent aujourd'hui** du trafic chiffré pour le déchiffrer demain.

Le NIST a standardisé (2024) les premiers algorithmes résistants :
- **ML-KEM (Kyber)** — échange de clé
- **ML-DSA (Dilithium)** / **SLH-DSA (SPHINCS+)** — signatures

La transition est en cours (hybridation classique+PQC dans TLS). À connaître de nom ;
vous n'aurez pas à l'implémenter, mais on vous posera la question.

---

## ✅ Labs du module 02

- [ ] **Lab 2.1 — Le pingouin ECB.** Chiffrez une image bitmap simple en AES-ECB puis en AES-CBC/GCM. Comparez visuellement. Comprenez *pourquoi* ECB laisse voir les motifs.
- [ ] **Lab 2.2 — Cassage de mots de passe.** Créez des hash MD5, SHA-256 nu, et bcrypt de mots de passe faibles. Attaquez-les avec `hashcat` ou `john`. Mesurez la différence de vitesse (des milliards/s vs des dizaines/s). **La leçon est viscérale.**
- [ ] **Lab 2.3 — Votre propre HMAC de webhook.** Écrivez en Python un émetteur qui signe un message et un récepteur qui vérifie, avec `compare_digest`. Puis démontrez pourquoi `==` est vulnérable au timing.
- [ ] **Lab 2.4 — PKI maison.** Avec `openssl`, créez une CA racine, une CA intermédiaire, et un certificat serveur signé. Faites confiance à votre CA et servez un site HTTPS local. **Vous ne verrez plus jamais un cadenas de la même façon.**
- [ ] **Lab 2.5 — Audit TLS.** Passez 3 sites au SSL Labs, lisez et expliquez chaque point du rapport (versions, suites, PFS, HSTS, chaîne).
- [ ] **Lab 2.6 — Cryptopals.** Commencez le [Set 1 des Cryptopals](https://cryptopals.com). Les 8 premiers challenges sont accessibles et formateurs (XOR, détection ECB…).
- [ ] **Lab 2.7 — JWT.** Sur un JWT de test, démontrez l'attaque `alg:none` et le brute force d'un secret HMAC faible avec hashcat (`-m 16500`).

---

## 🎯 Auto-évaluation

1. Pourquoi ne hache-t-on pas un mot de passe avec SHA-256 ? Quoi à la place ?
2. À quoi sert le sel ? Doit-il être secret ? Et le pepper ?
3. « Chiffrer, c'est authentifier. » Vrai ou faux ? Conséquence pratique ?
4. Expliquez le chiffrement hybride en 4 étapes.
5. Qu'est-ce que la forward secrecy et pourquoi est-ce important ?
6. Dans une signature, quelle clé signe, quelle clé vérifie ?
7. Citez trois erreurs classiques de manipulation de JWT.
8. Pourquoi comparer deux signatures avec `==` est-il dangereux ?
9. Que signifie « harvest now, decrypt later » ?

---

**Suivant → [Module 03 : Réseaux](03-reseaux.md)**
