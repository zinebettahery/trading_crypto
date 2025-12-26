# ⚙️ PERFORMANCE_TUNING – CryptoTrade

## 🎯 Objectif

Ce document décrit les actions de **tuning et d’optimisation PostgreSQL** mises en place pour améliorer :
- la latence des requêtes critiques
- les performances analytiques
- la gestion de la concurrence
- la scalabilité de la base de données CryptoTrade

---

## 🧱 Problèmes de performance identifiés

- Latence élevée sur l’affichage du carnet d’ordres
- Requêtes analytiques lentes (> 10 secondes)
- Temp file spills lors d’agrégations
- Deadlocks sur mises à jour concurrentes
- Mauvaises estimations du planner
- Vacuum lag sur tables fortement écrites
- HOT updates peu efficaces

---

## 📌 Indexation

### Index B-tree
Utilisés pour les recherches fréquentes par identifiant et filtres simples.

Exemples :
- `utilisateur_id` dans ORDRE
- `paire_id` dans ORDRE, PRIX_MARCHE, STATISTIQUE_MARCHE

---

### Partial Index
Index créés uniquement sur les lignes utiles.

Exemples :
- Ordres avec statut = 'EN_ATTENTE'
- Trades récents

Objectif :
- Réduire la taille des index
- Améliorer la vitesse de lecture

---

### Covering Index (Index-only scan)
Ajout de colonnes incluses pour éviter la lecture de la table.

Objectif :
- Réduire les accès disque
- Accélérer les requêtes analytiques

---

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
Utilisées pour :
- Moyennes mobiles
- Volatilité
- Classements

Avantage :
- Calculs puissants sans sous-requêtes complexes

---

### LATERAL JOIN
Utilisé pour :
- Calculs statistiques par utilisateur
- Agrégations par paire de trading

---

### DISTINCT ON
Utilisé pour :
- Récupérer le dernier prix
- Obtenir le dernier état d’un ordre

---

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