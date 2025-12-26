# 🚀 CryptoTrade – Optimisation et Analyse Avancée PostgreSQL

## 📌 Présentation du projet

**CryptoTrade** est un projet visant à concevoir, modéliser et optimiser une base de données **PostgreSQL** pour une plateforme de trading de cryptomonnaies en temps réel.

La plateforme doit gérer :
- des **millions d’ordres par jour**
- des **transactions en temps réel**
- des **analyses avancées de marché**
- une **forte concurrence d’accès**
- des exigences élevées en **performance, fiabilité et audit**

Ce projet met l’accent sur **l’optimisation PostgreSQL** plutôt que sur la taille du schéma.


## 🎯 Objectifs du projet

- Concevoir une base PostgreSQL performante avec **10 tables maximum**
- Réduire la latence des requêtes critiques
- Optimiser les requêtes analytiques complexes
- Gérer la concurrence (ordres simultanés, portefeuilles)
- Calculer des indicateurs financiers (VWAP, RSI, Volatilité)
- Détecter des comportements suspects (wash trading, spoofing)
- Mettre en place un **monitoring avancé**
- Tester et valider les performances


## 🧱 Modélisation de la base

### MCD – Modèle Conceptuel de Données

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

<img width="1533" height="481" alt="mcd_crypto" src="https://github.com/user-attachments/assets/7377dcab-9494-4d74-85b2-276d07c89aae" />

### MRD/MLD – Modèle relationnel de Données

Nous avons travaillé avec DBSchema afin d’obtenir le MPD et de générer les scripts SQL de création des tables ainsi que les relations via les clés étrangères:

<img width="1500" height="522" alt="mld" src="https://github.com/user-attachments/assets/87d4f5d9-fa56-4985-8a91-d60cb8ec2148" />


## 🛠️ Technologies utilisées

- **PL/pgSQL**
- **pgAdmin**
- **DbSchema** (modélisation)
- **Git / GitHub**
- **Trello** (suivi des tâches)

## ⚙️ Fonctionnalités techniques implémentées

### Contraintes métier (PK, FK, CHECK, UNIQUE)
Afin de garantir la cohérence, la fiabilité et la sécurité des données, plusieurs contraintes ont été mises en place au niveau de la base de données.

**Table ordres**
* Contraintes CHECK pour contrôler les valeurs possibles (BUY / SELL, MARKET / LIMIT, statuts).
* Validation des règles métier :
    * La quantité doit être strictement positive.
    * Un ordre LIMIT doit obligatoirement avoir un prix positif.
    * Un ordre MARKET ne doit pas avoir de prix.
* Vérification de la cohérence entre le statut, le prix et la date d’exécution.

**Table paire_trading**
* Champs obligatoires (NOT NULL) pour garantir l’existence des informations essentielles.
* Interdiction d’une paire composée de la même cryptomonnaie (BTC/BTC).
* Contrôle des statuts possibles (ACTIVE, INACTIVE, SUSPENDUE).
* Interdiction des dates d’ouverture futures.


**Table detection_anomalie**
* Champs critiques obligatoires (type, utilisateur, date).
* Types d’anomalies strictement définis (wash trading, spoofing, etc.).
* Interdiction des dates futures.
* Contrainte UNIQUE : un même utilisateur ne peut avoir qu’une seule anomalie du même type par jour.
* Trigger de cohérence : vérifie que l’ordre associé appartient bien à l’utilisateur.

**Table detection_anomalie**
* Champs critiques obligatoires (type, utilisateur, date).
* Types d’anomalies strictement définis (wash trading, spoofing, etc.).
* Interdiction des dates futures.
* Contrainte UNIQUE : un même utilisateur ne peut avoir qu’une seule anomalie du même type par jour.
* Trigger de cohérence : vérifie que l’ordre associé appartient bien à l’utilisateur.

**Table utilisateurs**
* Adresse email unique et format valide.
* Longueur maximale des champs texte.
* Statut contrôlé (ACTIF, INACTIF).
* Date d’inscription valide (pas dans le futur).

**Table statistique_marche**
* Indicateurs autorisés (VWAP, RSI, VOLATILITE).
* Contraintes spécifiques par indicateur :
    * RSI entre 0 et 100
    * VWAP strictement positif
    * Date de mise à jour valide.
* Unicité par paire, indicateur et période.

**Table prix_marche**
* Prix strictement positif.
* Volume non négatif.
* Date valide.
* Un seul prix par paire et par date.

**Table trades**
* Prix et quantité strictement positifs.
* Date d’exécution non future.

**Table audit_trail**
* Actions limitées à INSERT, UPDATE, DELETE.
* Date d’audit valide.

**Table portefeuilles**
* Soldes toujours positifs.
* Solde bloqué ≤ solde total.
* Valeurs par défaut cohérentes.
* Un seul portefeuille par utilisateur et cryptomonnaie.

**Table cryptomonnaies**
* Nom et symbole obligatoires.
* Symbole unique.
* Statut contrôlé.
* Date de création valide.

### Insertion automatique des données

Un script d’insertion automatique a été mis en place pour peupler la base de données avec des données de test réalistes.
Il permet de simuler le fonctionnement d’une plateforme de trading crypto tout en respectant l’ensemble des contraintes d’intégrité, des clés étrangères et des règles métier.

