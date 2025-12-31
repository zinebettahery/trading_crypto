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


## 📸 Vues et vues matérialisées

### Vues simples
- Simplification des requêtes métier
- Centralisation de la logique SQL

### Vues matérialisées
- Pré-calcul des indicateurs (VWAP, RSI, volatilité)
- Réduction drastique du temps de réponse

Stratégie :
- Refresh périodique
- Rafraîchissement incrémental lorsque possible

---

## 🧠 Extended Statistics

Mise en place de statistiques multicolonnes sur :
- (paire_id, date_creation)
- (utilisateur_id, statut)

Objectif :
- Améliorer les estimations du planner
- Réduire les mauvais plans d’exécution

---

## 🔒 Gestion de la concurrence

### Advisory Locks
Utilisés pour :
- Sécuriser les mises à jour de portefeuilles
- Éviter les deadlocks lors d’ordres simultanés

---

### Isolation SERIALIZABLE
Utilisée pour :
- Garantir la cohérence des soldes
- Simuler un comportement transactionnel strict

---

## 🧠 Mémoire et stockage

### work_mem
- Augmenté pour les sessions analytiques
- Réduction des temp file spills

---

### Fillfactor
- Ajusté sur les tables fortement mises à jour (ORDRE)
- Amélioration des HOT updates

---

## 🧪 Validation des optimisations

- Comparaison des temps d’exécution avant / après
- Analyse via EXPLAIN ANALYZE
- Tests de charge avec insertions massives
- Mesure de la latence et du TPS

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
