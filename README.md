# crypto

# 🚀 CryptoTrade – Optimisation et Analyse Avancée PostgreSQL

## 📌 Présentation du projet

**CryptoTrade** est un projet académique visant à concevoir, modéliser et optimiser une base de données **PostgreSQL** pour une plateforme de trading de cryptomonnaies en temps réel.

La plateforme doit gérer :
- des **millions d’ordres par jour**
- des **transactions en temps réel**
- des **analyses avancées de marché**
- une **forte concurrence d’accès**
- des exigences élevées en **performance, fiabilité et audit**

Ce projet met l’accent sur **l’optimisation PostgreSQL** plutôt que sur la taille du schéma.

---

## 🎯 Objectifs du projet

- Concevoir une base PostgreSQL performante avec **10 tables maximum**
- Réduire la latence des requêtes critiques
- Optimiser les requêtes analytiques complexes
- Gérer la concurrence (ordres simultanés, portefeuilles)
- Calculer des indicateurs financiers (VWAP, RSI, Volatilité)
- Détecter des comportements suspects (wash trading, spoofing)
- Mettre en place un **monitoring avancé**
- Tester et valider les performances

---

## 🧱 Modélisation de la base

### 📐 MCD – Modèle Conceptuel de Données

Le MCD comprend les entités principales suivantes :

- UTILISATEUR  
- PORTEFEUILLE  
- CRYPTOMONNAIE  
- PAIRE_TRADING  
- ORDRE  
- TRADE  
- PRIX_MARCHE  
- STATISTIQUE_MARCHE  
- DETECTION_ANOMALIE  
- AUDIT_TRAIL  

Les relations couvrent :
- la gestion des ordres et trades
- les portefeuilles utilisateurs
- les paires de trading (crypto base / contre)
- l’historisation et l’audit
- la détection d’anomalies

📁 Les diagrammes MCD / MLD / MRD sont disponibles dans le dossier `docs/`.

---

## 🛠️ Technologies utilisées

- **PostgreSQL**
- **PL/pgSQL**
- **pgAdmin**
- **DbSchema** (modélisation)
- **Git / GitHub**
- **Trello** (suivi des tâches)

---

## ⚙️ Fonctionnalités techniques implémentées

### 🔹 Base de données
- Contraintes métier (PK, FK, CHECK, UNIQUE)
- Normalisation stricte (1FN → 3FN)
- Types PostgreSQL adaptés

### Données de test

Les données de test sont générées automatiquement à l’aide de scripts SQL (`generate_series`, `random()`) afin de simuler des volumes réalistes et permettre l’analyse des performances PostgreSQL.


### 🔹 Optimisation
- Index B-tree, partial index, covering index
- Partitionnement des tables volumineuses
- Extended statistics (colonnes corrélées)
- Optimisation du `fillfactor`
- Réglage du `work_mem`

### 🔹 Analyse avancée
- Window Functions (AVG, SUM, STDDEV, RANK…)
- LATERAL JOIN
- DISTINCT ON
- CTE récursives
- Fonctions métier en PL/pgSQL

### 🔹 Performance
- Vues et vues matérialisées
- Pré-calcul des indicateurs de marché
- Gestion de la concurrence avec Advisory Locks
- Transactions isolées en SERIALIZABLE

---

## 📊 Monitoring et diagnostic

- `pg_stat_statements`
- `pg_stat_io`
- `auto_explain`
- Analyse des plans `EXPLAIN ANALYZE`
- Suivi des temp file spills
- Surveillance de l’autovacuum

📄 Les détails sont disponibles dans :
- `MONITORING.md`
- `PERFORMANCE_TUNING.md`

---

## 🧪 Tests et validation

### ✔ Tests fonctionnels
- Création et exécution des ordres
- Mise à jour des portefeuilles
- Calcul des indicateurs de marché
- Détection d’anomalies

### ✔ Tests de performance
- Temps de réponse
- TPS (Transactions Per Second)
- Comparaison avant / après optimisation

### ✔ Tests de concurrence
- Ordres simultanés
- Deadlocks
- Advisory Locks
- Isolation SERIALIZABLE

---