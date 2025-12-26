-- Vues matérialisées pour optimiser les performances des requêtes fréquentes
CREATE MATERIALIZED VIEW mv_last_order_state AS
SELECT DISTINCT ON (id_order)
       id_order,
       statut,
       date_creation,
       id_utilisateur,
       id_paire
FROM ordres
ORDER BY id_order, date_creation DESC;


COMMENT ON MATERIALIZED VIEW mv_last_order_state IS
'Vue matérialisée pour obtenir le dernier état de chaque ordre';

-- Index pour accélérer le DISTINCT ON
CREATE INDEX idx_ordres_last_state
ON ordres(id_order, date_creation DESC);

-- Index unique sur la vue pour REFRESH CONCURRENTLY
CREATE UNIQUE INDEX idx_mv_last_order_state
ON mv_last_order_state(id_order);


CREATE MATERIALIZED VIEW mv_last_price_pair AS
SELECT DISTINCT ON (id_paire)
       id_paire,
       prix,
       date_maj
FROM prix_marche
ORDER BY id_paire, date_maj DESC;

COMMENT ON MATERIALIZED VIEW mv_last_price_pair IS
'Vue matérialisée pour obtenir le dernier prix de chaque paire de trading';

-- Index pour accélérer le DISTINCT ON
CREATE INDEX idx_prix_marche_last_price
ON prix_marche(id_paire, date_maj DESC);

-- Index unique sur la vue pour REFRESH CONCURRENTLY
CREATE UNIQUE INDEX idx_mv_last_price_pair
ON mv_last_price_pair(id_paire);

-- ============================================================================
-- Rafraîchissement des vues matérialisées
-- ============================================================================

-- Rafraîchir la vue matérialisée des derniers états des ordres
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_last_order_state;
-- Rafraîchir la vue matérialisée des derniers prix par paire
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_last_price_pair;