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
