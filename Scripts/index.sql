-- table detection_anomalie
-- ==================================
-- Index B-tree classique pour les recherches fréquentes sur id_order ou id_utilisateur ou date_detection
CREATE INDEX idx_detection_anomalie_utilisateur ON detection_anomalie(id_utilisateur);
CREATE INDEX idx_detection_anomalie_order ON detection_anomalie(id_order);
CREATE INDEX idx_detection_anomalie_date ON detection_anomalie(date_detection);


-- Index covering si tu as des requêtes qui récupèrent plusieurs colonnes fréquemment
-- Exemple : récupérer date_detection et commentaire pour un id_utilisateur
CREATE INDEX idx_detection_anomalie_utilisateur_covering 
ON detection_anomalie(id_utilisateur) INCLUDE(date_detection, commentaire);

-- table paire_trading
-- ==================================
-- B-tree pour les recherches par statut, date_ouverture ou crypto
CREATE INDEX idx_paire_trading_statut ON paire_trading(statut);
CREATE INDEX idx_paire_trading_date ON paire_trading(date_ouverture);
CREATE INDEX idx_paire_trading_crypto_base ON paire_trading(crypto_base);
CREATE INDEX idx_paire_trading_crypto_contre ON paire_trading(crypto_contre);

-- Covering index si tu sélectionnes souvent statut et crypto_contre pour une crypto_base
CREATE INDEX idx_paire_trading_base_covering 
ON paire_trading(crypto_base) INCLUDE(statut,crypto_contre);

-- Partial index pour les paires actives
CREATE INDEX idx_paire_trading_ouvertes 
ON paire_trading(date_ouverture) 
WHERE statut = 'ACTIVE';

--Optimise les requêtes pour obtenir le dernier prix par paire
CREATE INDEX idx_prix_marche_last_price
ON prix_marche(id_paire, date_maj DESC);


-- B-tree recherches par paire,indicateur,période
CREATE INDEX idx_stat_marche_paire ON statistique_marche(id_paire);
CREATE INDEX idx_stat_marche_indicateur ON statistique_marche(indicateur);
CREATE INDEX idx_stat_marche_periode ON statistique_marche(periode);

-- Covering Index si tu récupères souvent valeur et date_maj pour une paire
CREATE INDEX idx_stat_marche_indicateur_covering 
ON statistique_marche(indicateur) INCLUDE(valeur, date_maj, id_paire);


-- Index partiel pour les indicateurs spécifiques
CREATE INDEX idx_stat_marche_indicateurs
ON statistique_marche(valeur)
WHERE indicateur IN ('VWAP', 'RSI', 'VOLATILITE');
= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
-- table cryptomonnaies
-- ==================================
-- indexes unique sur le symbole (BTC, ETH…)
CREATE UNIQUE INDEX idx_cryptomonnaies_symbole ON cryptomonnaies (symbole);

-- index sur le statut (ACTIVE / INACTIVE)
CREATE INDEX idx_cryptomonnaies_statut ON cryptomonnaies (statut);

-- index sur la date de création
CREATE INDEX idx_cryptomonnaies_date_creation ON cryptomonnaies (date_creation);

= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
-- table portefeuilles
-- ================================== 
-- index unique composite 
CREATE UNIQUE INDEX idx_portefeuilles_utilisateur_crypto ON portefeuilles (id_utilisateur, id_crypto);

-- index pour rechercher par utilisateur
CREATE INDEX idx_portefeuilles_utilisateur ON portefeuilles (id_utilisateur);

-- index pour analyse par crypto
CREATE INDEX idx_portefeuilles_crypto ON portefeuilles (id_crypto);

-- index sur le solde total
CREATE INDEX idx_portefeuilles_solde_positif ON portefeuilles (id_crypto)
WHERE
    solde_total > 0;

-- index coverging 
CREATE INDEX idx_portefeuilles_covering ON portefeuilles (id_utilisateur) INCLUDE (solde_total, solde_bloque);

= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
-- table prix_marché
--==================================
-- index composite paire + date
CREATE INDEX idx_prix_marche_paire_date ON prix_marche (id_paire, date_maj DESC);

-- index sur la date 
CREATE INDEX idx_prix_marche_date ON prix_marche (date_maj);

= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
-- table statistique_marche
-- ==================================
-- index sur la paire 
CREATE INDEX idx_statistique_marche_paire ON statistique_marche (id_paire);

-- index sur l'indicateur
CREATE INDEX idx_statistique_marche_indicateur ON statistique_marche (indicateur);

-- index sur la période
CREATE INDEX idx_statistique_marche_periode ON statistique_marche (periode);

-- index sur la date de mise à jour
CREATE INDEX idx_statistique_marche_date_maj ON statistique_marche (date_maj);

-- index composite paire + indicateur + période
CREATE INDEX idx_statistique_marche_composite ON statistique_marche (id_paire, indicateur, periode);

-- index coverging pour requêtes fréquentes
CREATE INDEX idx_statistique_marche_covering ON statistique_marche (id_paire, indicateur) INCLUDE (valeur, date_maj);

-- ==================================
= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
-- ============================================================================
-- Table orders
-- ============================================================================

-- ============================================================================
-- 1. CARNET D’ORDRES TEMPS RÉEL (CRITIQUE)
-- ============================================================================

-- BUY : ordres d’achat actifs, triés par prix décroissant
-- utilite: Affichage du carnet d’ordres – côté ACHAT (BUY)
CREATE INDEX idx_ordres_carnet_buy
ON ordres (id_paire, prix DESC, date_creation)
INCLUDE (quantite, id_utilisateur)
WHERE statut = 'OPEN' AND type_ordre = 'BUY';

COMMENT ON INDEX idx_ordres_carnet_buy IS
'Carnet d’ordres BUY actifs - affichage temps réel';

-- SELL : ordres de vente actifs, triés par prix croissant
-- utilite: Affichage du carnet d’ordres – côté VENTE (SELL)
CREATE INDEX idx_ordres_carnet_sell
ON ordres (id_paire, prix ASC, date_creation)
INCLUDE (quantite, id_utilisateur)
WHERE statut = 'OPEN' AND type_ordre = 'SELL';

COMMENT ON INDEX idx_ordres_carnet_sell IS
'Carnet d’ordres SELL actifs - affichage temps réel';

--Optimise le ORDER BY utilisé par DISTINCT ON
CREATE INDEX idx_ordres_last_state
ON ordres(id_order, date_creation DESC);

COMMENT ON INDEX idx_ordres_last_state IS
'Optimise le ORDER BY pour obtenir le dernier état d’un ordre';

-- ============================================================================
-- 2. ORDRES PAR UTILISATEUR
-- ============================================================================

-- Liste rapide des ordres d’un utilisateur (page "Mes ordres")
CREATE INDEX idx_ordres_utilisateur
ON ordres (id_utilisateur, date_creation DESC);

COMMENT ON INDEX idx_ordres_utilisateur IS
'Accès rapide aux ordres par utilisateur';

-- Historique complet utilisateur (index covering)
CREATE INDEX idx_ordres_user_history
ON ordres (id_utilisateur, date_creation DESC)
INCLUDE (type_ordre, mode, quantite, prix, statut, id_paire);

COMMENT ON INDEX idx_ordres_user_history IS
'Historique utilisateur en index-only scan';

-- ============================================================================
-- 3. MATCHING (LIMIT ORDERS)
-- ============================================================================

-- Ordres LIMIT ouverts pour le moteur de matching
CREATE INDEX idx_ordres_limit_open
ON ordres (id_paire, prix, date_creation)
WHERE statut = 'OPEN' AND mode = 'LIMIT';

COMMENT ON INDEX idx_ordres_limit_open IS
'Matching rapide des ordres LIMIT ouverts';

-- ============================================================================
-- 4. ANALYSES & MONITORING
-- ============================================================================

-- Analyses par paire (volume, prix, activité)
CREATE INDEX idx_ordres_paire
ON ordres (id_paire, date_creation DESC)
INCLUDE (quantite, prix);

COMMENT ON INDEX idx_ordres_paire IS
'Analyses et statistiques par paire';

-- Analyse par statut (EXECUTED, CANCELLED)
CREATE INDEX idx_ordres_statut
ON ordres (statut, date_creation DESC)
WHERE statut IN ('EXECUTED', 'CANCELLED');

COMMENT ON INDEX idx_ordres_statut IS
'Monitoring et statistiques par statut';

-- Archivage / purge des ordres exécutés anciens
CREATE INDEX idx_ordres_archive
ON ordres (date_creation)
WHERE statut = 'EXECUTED';

COMMENT ON INDEX idx_ordres_archive IS
'Archivage rapide des ordres exécutés';

-- ============================================================================
-- 5. DÉTECTION D’ANOMALIES (WASH TRADING)
-- ============================================================================

CREATE INDEX idx_ordres_wash_trading
ON ordres (id_utilisateur, id_paire, type_ordre, date_creation)
WHERE statut = 'EXECUTED';

COMMENT ON INDEX idx_ordres_wash_trading IS
'Détection rapide des patterns de wash trading';

-- ============================================================================
-- 6. EXTENDED STATISTICS (PLANNER)
-- ============================================================================

CREATE STATISTICS stats_ordres_paire_type_statut
ON id_paire, type_ordre, statut
FROM ordres;

COMMENT ON STATISTICS stats_ordres_paire_type_statut IS
'Améliore les estimations du planner sur les ordres';


-- ============================================================================ 
-- 2. TABLE UTILISATEURS - Index pour authentification et recherche (OPTIMISÉ)
-- ============================================================================

-- 2.1 Index UNIQUE B-TREE sur email (lowercase) + COVERING pour login rapide
-- Utilisation : Authentification, éviter doublons, récupération rapide du statut et id_utilisateur
CREATE UNIQUE INDEX idx_utilisateurs_email_lower_covering 
ON utilisateurs(LOWER(email))
INCLUDE(id_utilisateur, statut);

COMMENT ON INDEX idx_utilisateurs_email_lower_covering IS 
'Login rapide + évite doublons email (case-insensitive) + récupération rapide des infos pour login';

-- 2.2 Index PARTIAL pour utilisateurs actifs (optimisé)
-- Liste seulement les utilisateurs actifs pour les recherches fréquentes
CREATE INDEX idx_utilisateurs_actifs ON utilisateurs(statut, date_inscription DESC)
WHERE statut = 'ACTIF';

COMMENT ON INDEX idx_utilisateurs_actifs IS 
'Index 20x plus petit - Seulement utilisateurs actifs';

-- 2.3 Index GIN pour recherche full-text (nom/prenom/email)
CREATE INDEX idx_utilisateurs_fulltext ON utilisateurs 
USING GIN (to_tsvector('french', COALESCE(nom, '') || ' ' || COALESCE(prenom, '') || ' ' || COALESCE(email, '')));

COMMENT ON INDEX idx_utilisateurs_fulltext IS 
'Recherche full-text rapide sur nom/prénom/email';

-- 2.4 Index B-TREE sur date inscription (analytics)
-- Utile pour rapports mensuels sur nouveaux utilisateurs
CREATE INDEX idx_utilisateurs_inscription ON utilisateurs(date_inscription DESC)
WHERE statut = 'ACTIF';

COMMENT ON INDEX idx_utilisateurs_inscription IS 
'Analytics - Nouveaux utilisateurs actifs par période';

-- 2.5 Index COVERING pour profil complet
-- Optimisé : récupération complète du profil en 1 scan, évite lecture table principale
CREATE INDEX idx_utilisateurs_profil ON utilisateurs(id_utilisateur)
INCLUDE (nom, prenom, email, statut, date_inscription);

COMMENT ON INDEX idx_utilisateurs_profil IS 
'Index-only scan pour profil utilisateur complet';
-------------------
--TABLE TRADES
-------------------

--Index B-tree sur id_paire
CREATE INDEX idx_trades_paire
ON trades(id_paire);

--Index B-tree sur  date_execution
CREATE INDEX idx_trades_date
ON trades(date_execution);


-- Covering index sur (id_paire, date_execution) incluant prix et quantite
CREATE INDEX idx_trades_covering
ON trades(id_paire, date_execution DESC)
INCLUDE (prix, quantite, id_order);

-- Index pour recherches par ordre spécifique
CREATE INDEX idx_trades_order
ON trades(id_order);

--------------------
-- TABLE AUDIT_TRAIL
--------------------

-- Index B-tree sur id_order et id_trade
CREATE INDEX idx_audit_order
ON audit_trail(id_order);

CREATE INDEX idx_audit_trade
ON audit_trail(id_trade);

-- 3. Recherche par date
CREATE INDEX idx_audit_date
ON audit_trail(date_action DESC)
INCLUDE (table_cible, action, id_utilisateur);

-- 2. Recherche par utilisateur
CREATE INDEX idx_audit_utilisateur
ON audit_trail(id_utilisateur, date_action DESC)
INCLUDE (table_cible, action, id_order, id_trade);


-- Index GIN sur details : Pour les recherches texte dans la colonne details.
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX idx_audit_details_gin
ON audit_trail
USING GIN (details gin_trgm_ops);


