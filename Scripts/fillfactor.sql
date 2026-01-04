-- -- Analyse des statistiques de mise à jour et d'insertion des tables utilisateur pour évaluer l'efficacité des mises à jour "HOT" (Heap-Only Tuple)
-- SELECT
--     relname AS table,
--     n_tup_ins AS inserts,
--     n_tup_upd AS updates,
--     n_tup_del AS deletes,
--     n_live_tup AS lignes_actives
-- FROM pg_stat_user_tables
-- ORDER BY n_tup_upd DESC;

-- -- Calcul du pourcentage de mises à jour "HOT" pour les tables
-- SELECT
--     relname AS table,
--     n_tup_upd,
--     n_tup_hot_upd,
--     ROUND(100.0 * n_tup_hot_upd / NULLIF(n_tup_upd,0), 2) AS hot_ratio_percent
-- FROM pg_stat_user_tables
-- WHERE relname IN ('ordres', 'portefeuilles');

-- Table				Type d’opérations
-- ORDRES 70			INSERT massif + UPDATE fréquent (statut)
-- TRADES 90			INSERT massif
-- AUDIT_TRAIL 90		INSERT massif
-- PORTEFEUILLES 70 	UPDATE très fréquent (solde)

-- Appliquer le Fillfactor:
ALTER TABLE ordres SET (fillfactor = 70);
ALTER TABLE portefeuilles SET (fillfactor = 70);
ALTER TABLE trades SET (fillfactor = 90);
ALTER TABLE audit_trail SET (fillfactor = 90);


-- Rebuild obligatoire (très important ⚠)
-- note: Pour que le fillfactor ait un impact réel, il faut réécrire la table entière avec une de ces méthodes(VACUUM FULL, CLUSTER, pg_repack). Sinon, seules les nouvelles lignes créées après l’alter bénéficieront de l’espace libre.
-- Appliquer le fillfactor avec CLUSTER

CLUSTER ordres USING pk_ordres;
CLUSTER portefeuilles USING pk_portefeuilles;
CLUSTER trades USING pk_trades;
CLUSTER audit_trail USING pk_audit_trail;
