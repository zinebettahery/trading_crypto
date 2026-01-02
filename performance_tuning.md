# ⚙️ PERFORMANCE_TUNING – CryptoTrade

## 🎯 Objectif

Ce document décrit les actions de **tuning et d’optimisation PostgreSQL** mises en place pour améliorer :
- la latence des requêtes critiques
- les performances analytiques
- la gestion de la concurrence
- la scalabilité de la base de données CryptoTrade


## 🧱 Problèmes de performance identifiés

- Latence élevée sur l’affichage du carnet d’ordres
- Requêtes analytiques lentes (> 10 secondes)
- Temp file spills lors d’agrégations
- Deadlocks sur mises à jour concurrentes
- Mauvaises estimations du planner
- Vacuum lag sur tables fortement écrites
- HOT updates peu efficaces


## 📌 Indexation

### 📌 `detection_anomalie`
- Index sur `id_utilisateur`, `id_order` et `date_detection`
- Index covering pour récupérer les anomalies d’un utilisateur sans accès à la table

**Bénéfice :** accélération des analyses de fraude et du monitoring


### 📌 `paire_trading`
- Index sur `statut`, `crypto_base`, `crypto_contre` et `date_ouverture`
- Index partiel limité aux paires actives (`statut = 'ACTIVE'`)
- Index covering pour les consultations fréquentes par cryptomonnaie

**Bénéfice :** affichage rapide des paires disponibles et réduction de la charge mémoire


### 📌 `statistique_marche`
- Index sur `id_paire`, `indicateur` et `periode`
- Index covering pour récupérer directement `valeur` et `date_maj`
- Index partiel ciblé sur les indicateurs clés (VWAP, RSI, VOLATILITE)

**Bénéfice :** meilleures performances pour les dashboards et analyses techniques


### 📌 `cryptomonnaies`
- Index **UNIQUE** sur `symbole`
- Index sur `statut` et `date_creation`

**Bénéfice :** intégrité des données et accès rapide aux cryptomonnaies actives


### 📌 `portefeuilles`
- Index unique composite `(id_utilisateur, id_crypto)`
- Index partiel sur les soldes positifs uniquement
- Index covering pour consultation rapide des soldes

**Bénéfice :** cohérence financière et requêtes rapides


### 📌 `prix_marche`
- Index composite `(id_paire, date_maj DESC)`
- Index sur la date de mise à jour

**Bénéfice :** récupération instantanée des prix récents


### 📌 `ordres` — Optimisation critique

#### Carnet d’ordres temps réel
- Index partiels distincts pour les ordres **BUY** et **SELL**
- Tri optimisé par prix (DESC pour BUY, ASC pour SELL)

**Bénéfice :** affichage instantané du carnet d’ordres


#### Ordres par utilisateur
- Index dédiés à la consultation des ordres d’un utilisateur
- Index covering pour l’historique complet

**Bénéfice :** navigation fluide et rapide


#### Moteur de matching
- Index ciblé sur les ordres **LIMIT** ouverts

**Bénéfice :** matching plus rapide et réduction de la latence

#### Analyses & monitoring
- Index par paire et par statut
- Index dédié à la détection de **wash trading**
- Index pour l’archivage des ordres exécutés

**Bénéfice :** analyses performantes et surveillance efficace

#### Extended statistics
- Statistiques multi-colonnes pour améliorer les estimations du planner PostgreSQL

**Bénéfice :** plans d’exécution plus efficaces pour les requêtes complexes



### 📌 Utilisateurs (`utilisateurs`)
- Index **UNIQUE** fonctionnel sur email (insensible à la casse)
- Index partiel sur les utilisateurs actifs
- Index **GIN full-text** pour la recherche par nom, prénom et email
- Index covering pour le profil utilisateur

**Bénéfice :** authentification rapide et recherche performante



### 📌 Trades (`trades`)
- Index sur `id_paire`, `date_execution` et `id_order`
- Index covering pour les analyses de volume et de prix

**Bénéfice :** statistiques de trading optimisées


### 📌 Audit (`audit_trail`)
- Index sur utilisateur, date, ordre et trade
- Index **GIN (pg_trgm)** pour la recherche textuelle dans les logs

**Bénéfice :** traçabilité rapide et audit efficace


## 🧩 Partitionnement

### Tables partitionnées
- ORDRE
- TRADE
- AUDIT_TRAIL

### Stratégies utilisées
- Partitionnement par date (RANGE)
- Partitionnement par paire (LIST)

Bénéfices :
- Requêtes plus rapides
- Maintenance facilitée
- Autovacuum plus efficace

### Choix d’architecture pour les tests de performance

Les insertions massives de données sont volontairement réalisées sans triggers afin d’éviter toute surcharge supplémentaire et de garantir des mesures de performance fiables.

---

## 🧮 Optimisation des requêtes analytiques

### Window Functions

Les window functions permettent de faire des calculs analytiques avancés (moyennes mobiles, VWAP, volatilité, variations de prix, classements) directement sur les données de trading, sans perdre le détail ligne par ligne, ce qui est essentiel pour une plateforme de trading en temps réel.
👉 Contrairement à GROUP BY,

✔️ on garde toutes les lignes

✔️ on ajoute des valeurs calculées par-dessus


Utilisées pour le calcul de:
- Une moyenne mobile afin de suivre l’évolution du prix et d’identifier les tendances du marché sans regrouper les données.
- Le VWAP afin de fournir un indicateur de prix pondéré par le volume, mis à jour trade par trade en quasi temps réel.
- Variation de prix entre deux trades successifs qui sera utile pour : détection de volatilité, alertes, anomalies de marché.
- Volatilité sur les dernières 24 heures afin de mesurer dynamiquement le risque associé à chaque paire de trading (plus elle est élevée → marché instable).
- Les prix minimum et maximum afin de suivre l’amplitude des variations sur une période glissante de 24 heures.
- Classement des paires (ranking) pour identifier les paires les plus actives, les paires les plus performantes et leur position par rapport aux autres.

---

### LATERAL JOIN
Utilisé pour :
- Calculs statistiques par utilisateur
- Agrégations par paire de trading

#### Différence entre JOIN classique et JOIN LATERAL
**JOIN classique (sans LATERAL)**
* Sert à relier deux tables indépendantes
* La condition de liaison est définie dans ON
* La sous-requête est exécutée **UNE SEULE FOIS** et son résultat (1 ligne) est ensuite attaché à tous les lignes de la table principale
```sql
SELECT
    u.id_utilisateur,
    o.id_order,
    o.date_creation
FROM utilisateurs u
LEFT JOIN (
    SELECT id_order, date_creation
    FROM ordres
    ORDER BY date_creation DESC
    LIMIT 1
) o ON true;
```
* Ne permet pas à une sous-requête d’utiliser les colonnes de la table principale
* Adapté aux relations simples (clé étrangère, égalité)

👉 Exemple d’usage : relier utilisateurs et ordres

**JOIN LATERAL**
* Permet de joindre une sous-requête dépendante de la ligne courante
* La sous-requête est réexécutée pour chaque ligne
* La logique de filtrage est dans la sous-requête
* ON true signifie que le résultat de la sous-requête est simplement rattaché
* Idéal pour statistiques personnalisées et données temps réel

👉 Exemple d’usage : dernier ordre par utilisateur, dernier prix par paire

---
### DISTINCT ON
#### ➡️ Problème à résoudre :
Imaginons que tu veux construire un dashboard ou faire des calculs analytiques :
* Chaque ordre peut avoir plusieurs trades → plusieurs prix et statuts successifs.
* Sans optimisation, il faudrait parcourir toute la table trades ou prix_marche pour trouver le plus récent par ordre ou par paire.
* Les requêtes deviennent lentes si le volume est important.


#### ➡️ Solution : DISTINCT ON
DISTINCT ON est une fonctionnalité PostgreSQL qui permet de :
* Grouper les données par une clé (id_order ou id_paire)
* Choisir la première ligne selon un ordre défini (ORDER BY date DESC)

**Pourquoi avoir choisi MATERIALIZED VIEW au lieu de VIEW:**

1. Performance élevée

* Une VIEW recalculerait le DISTINCT ON à chaque requête
* Une MATERIALIZED VIEW pré-calcule et stocke le dernier état/prix

2. Réduction de la charge sur la table ordres

* Moins de scans
* Moins de tri (ORDER BY)
* Moins de contention en environnement multi-utilisateurs

3. Indexation possible

Contrairement à une VIEW, une MATERIALIZED VIEW peut être indexée

Et pour garder les données à jour sans bloquer les lectures :

```sql
-- Rafraîchissement du dernier état des ordres
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_last_order_state;

-- Rafraîchissement du dernier prix par paire
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_last_price_pair;
```

CONCURRENTLY permet aux requêtes de continuer à lire la vue pendant le rafraîchissement.

---

### Recursive CTE

Un CTE récursif permet de suivre une chaîne d’actions liées entre elles, afin de détecter des comportements répétés ou suspects.
Dans un CTE récursif, nous avons 2 parties :

1️⃣ Cas de base : la première ligne ou les premiers événements
2️⃣ Partie récursive : les lignes “suivantes” reliées à la première

```sql
WITH RECURSIVE wash_chain AS (
    SELECT ... -- point de départ
    UNION ALL
    SELECT ... -- étape récursive
)
SELECT * FROM wash_chain;
```
**UNION ALL** = mets tout ensemble, ne supprime rien, il est utile dans les CTE récursifs pour suivre toutes les suites d’événements sans en perdre une seule.

Pour remplir la table `detection_anomalie`, on peut détecter:

* WASH TRADING : Même utilisateur qui achète et vend la même crypto, même prix, même quantité, très rapidement.
* SPOOFING : Créer de gros ordres pour tromper le marché puis les annuler.
* PUMP AND DUMP : Hausse artificielle rapide puis vente massive.
* FRONT RUNNING : Un utilisateur trade juste avant un gros ordre.

## 🧠 Mémoire et stockage

### work_mem

C'est la mémoire utilisée par requête pour :
* ORDER BY
* GROUP BY
* JOIN
* DISTINCT

**Problème : temp file spill**

Quand work_mem est trop petit :
* PostgreSQL manque de mémoire
* Il écrit les données intermédiaires sur le disque
* ça crée des fichiers temporaires (**temp file**)

👉 requêtes beaucoup plus lentes

**Pourquoi c’est mauvais ?**
* le disque est beaucoup plus lent que la RAM
* surtout critique pour : calculs de prix - volumes - indicateurs financiers

**Solution : augmenter work_mem**
```sql
SET work_mem = '64MB';
```
ou globalement dans "postgresql.conf".

---

### Fillfactor

Une **page disque**, c’est :
un petit bloc de données que PostgreSQL utilise pour lire et écrire.

PostgreSQL utilise des pages parce que :
* lire 1 ligne à la fois serait trop lent.
* le disque travaille mieux par blocs.

Quand **work_mem** est trop petit :
* PostgreSQL ne peut pas garder les pages en RAM.
* il écrit des pages temporaires sur le disque.

Contrairement à ce qu’on croit, PostgreSQL ne modifie pas la ligne directement:
* Ancienne ligne → marquée comme obsolète
* Nouvelle ligne → écrite ailleurs
👉 pour permettre à d’autres transactions de continuer à lire l’ancienne version (MVCC).

PostgreSQL écrit la nouvelle ligne dans la même page disque et HOT UPDATE (Mise à jour faite sans toucher aux index) sera possible, **SI il reste de la place**.

**fillfactor = 100 %** veut dire :

PostgreSQL remplit la page disque au maximum lors des INSERT.

Le problème quand la page est à 100% pleine, quand tu fais un UPDATE il n’y a PLUS DE PLACE pour la nouvelle version.

PostgreSQL est obligé de :
* créer une nouvelle page disque
* écrire la nouvelle ligne dedans

Les index doivent être mis à jour :

Avant :
* L’index pointait vers page A
Après :
* La ligne est maintenant dans page B

👉 PostgreSQL doit modifier tous les index

Plus de travail pour VACUUM :
* Anciennes lignes mortes partout
* VACUUM doit nettoyer plus de pages
* VACUUM en retard = bloat

```sql
ALTER TABLE ordres SET (fillfactor = 70);
```

---

## 🔍 Monitoring

### pg_stat_statements

pg_stat_statements est une **extension PostgreSQL** qui permet de savoir:
* quelles requêtes sont les plus lentes
* lesquelles s’exécutent le plus souvent
* lesquelles consomment le plus de CPU

```sql
SELECT query, calls, total_exec_time
FROM pg_stat_statements
ORDER BY total_exec_time DESC;
```
👉 Tu sais quoi optimiser en priorité
#### Comment l’activer (pas à pas)
**1 Trouver le fichier postgresql.conf**

```sql
SHOW config_file;
```
**2 Modifier postgresql.conf**
Ajouter ou modifier cette ligne : 

shared_preload_libraries = 'pg_stat_statements'

**3 Redémarrer PostgreSQL**

**4 Créer l’extension dans la base**
```sql
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
```
### pg_stat_io

pg_stat_io est une **vue système PostgreSQL** qui sert à voir les accès disque :
* lectures
* écritures
* cache vs disque
```sql
SELECT 
    backend_type,
    object,
    context,
    reads,
    writes
FROM pg_stat_io
ORDER BY reads DESC
LIMIT 10;
```
`backend_type` → **QUI fait l’I/O ?**
Exemples :
* client backend → une requête SQL utilisateur
* autovacuum worker → nettoyage automatique
* checkpointer → checkpoint
* bgwriter → writer arrière-plan

`object` → **SUR QUOI ?**
Exemples :
* table → lecture table (ordres, trades)
* index → lecture index
* toast → données volumineuses
* temp → fichiers temporaires ⚠️
* wal → journal de transactions

👉 beaucoup de table reads = index manquants

👉 beaucoup de temp = requêtes mal optimisées ou work_mem trop bas

`context` → **POURQUOI ?**
Exemples :
* normal → requêtes normales
* vacuum → nettoyage
* checkpoint → flush disque
* bgwriter → écriture automatique

👉 vacuum très actif = fillfactor ou partitionnement à revoir

`reads` → **COMBIEN DE LECTURES DISQUE ?**

`writes` → **COMBIEN D’ÉCRITURES DISQUE ?**

### auto_explain

auto_explain est une **extension PostgreSQL** qui sert à enregistrer automatiquement le plan d’exécution des requêtes lentes, sans que tu écrives **EXPLAIN ANALYZE** toi-même.

**EXPLAIN :** PostgreSQL te dit ce qu’il prévoit de faire avant d’exécuter la requête.
```sql
EXPLAIN SELECT * FROM ordres WHERE statut = 'OPEN';
```
👉 Plan théorique, pas réel.

**EXPLAIN ANALYZE :** PostgreSQL exécute réellement la requête, puis montre ce qu’il a vraiment fait
```sql
EXPLAIN ANALYZE SELECT * FROM ordres WHERE statut = 'OPEN';
```
Il permet de :
* comprendre pourquoi une requête est lente
* voir si PostgreSQL utilise :
    * Seq Scan (PostgreSQL lit toute la table ligne par ligne)
    * Index Scan (PostgreSQL passe par un index pour aller directement aux lignes utiles)
    * des Hash Join (PostgreSQL crée une table de hachage en mémoire pour joindre deux tables → Génère des temp files)
* détecter :
    * index manquants
    * mauvaises estimations du planner
    * problèmes de work_mem
👉 Les résultats sont écrits dans les logs PostgreSQL.

#### Comment l’activer (pas à pas)

**1 Modifier postgresql.conf**

shared_preload_libraries = 'pg_stat_statements,auto_explain'

**2 Redémarrer PostgreSQL**

**3 Créer l’extension dans la base**
```sql
CREATE EXTENSION auto_explain;
```
**4 Configurer les paramètres clés**
(ou dans `postgresql.conf`)
```sql
-- Log uniquement les requêtes lentes
SET auto_explain.log_min_duration = '500ms';

-- Activer l'analyse réelle (EXPLAIN ANALYZE)
SET auto_explain.log_analyze = on;
```
**5 Exécuter normalement les requêtes**
```sql
SELECT * FROM ordres WHERE statut = 'OPEN';
```



---

## 🧪 Tests et validation des optimisations

- **Latence :** Le temps que met une requête pour répondre.
- **TPS (Transactions Per Second)** : Combien de transactions (INSERT, UPDATE, DELETE…) la base peut gérer par seconde.
- **Deadlocks :** Situation où deux transactions accumulent des verrous dans un ordre différent. **N.B:** Dans PostgreSQL, les verrous de lignes sont conservés jusqu’à la fin de la transaction à COMMIT ou ROLLBACK pour garantir l’isolation.
Imagine ceci si A ne garde pas le verrou sur la ligne modifié:
    * A met id=1 à 110
    * PostgreSQL libère le verrou
    * B lit 110
    * A échoue ensuite et fait ROLLBACK
👉 B a vu une donnée qui n’existera jamais (incohérence totale) 
- **Advisory Locks :** verrous manuels, optionnels, contrôlés par l’application, et pas automatiquement imposés par PostgreSQL
    * Verrou classique: “PostgreSQL bloque techniquement l’accès à la donnée”
    * Advisory lock : “On s’est mis d’accord qu’un seul processus peut exécuter cette opération à la fois.”
  
    exemple: Un seul job peut analyser cette paire de trading à la fois, les autres attendent
- **SERIALIZABLE :** PostgreSQL fait comme si les transactions s’exécutaient une par une, même si en réalité elles s’exécutent en parallèle.
```sql
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
```

---

## ✅ Résultats obtenus

- Réduction significative des temps de réponse
- Diminution des temp file spills
- Amélioration de la stabilité en concurrence
- Meilleure prédictibilité du planner PostgreSQL

---

## 🏁 Conclusion

Les optimisations mises en place permettent à la base PostgreSQL CryptoTrade de :
- supporter une charge élevée
- fournir des analyses avancées en temps réel
- garantir cohérence, performance et fiabilité
