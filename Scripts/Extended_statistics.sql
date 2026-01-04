----------------------------------------------------------ordres
-- Corrélation paire_id et date_creation
CREATE STATISTICS ordres_paire_date_stat (dependencies)
ON id_paire, date_creation
FROM ordres;

-- Corrélation utilisateur_id et statut
CREATE STATISTICS ordres_user_statut_stat (dependencies)
ON id_utilisateur, statut
FROM ordres;

-- Mise à jour des stats
ANALYZE ordres;


----------------------------------------------------------trades
CREATE STATISTICS trades_paire_date_stat (dependencies)
ON id_paire, date_execution
FROM trades;

ANALYZE trades;

----------------------------------------------------------portefeuille
CREATE STATISTICS portefeuilles_user_crypto_stat (dependencies)
ON id_utilisateur, id_crypto
FROM portefeuilles;

ANALYZE portefeuilles;


----------------------------------------------------------statistique_marche
CREATE STATISTICS statistique_marche_paire_periode_stat (dependencies)
ON id_paire, periode
FROM statistique_marche;

ANALYZE statistique_marche;


----------------------------------------------------------detection_anomalie
CREATE STATISTICS detection_anomalie_user_type_stat (dependencies)
ON id_utilisateur, type
FROM detection_anomalie;

ANALYZE detection_anomalie;


----------------------------------------------------------prix_marche
CREATE STATISTICS prix_marche_paire_date_stat (dependencies)
ON id_paire, date_maj
FROM prix_marche;

ANALYZE prix_marche;
