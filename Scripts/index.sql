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