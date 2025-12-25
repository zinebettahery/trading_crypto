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

-- Index sur les prix récents uniquement
CREATE INDEX idx_prix_marche_recent ON prix_marche (id_paire, date_maj DESC)
WHERE
    date_maj >= CURRENT_DATE - INTERVAL '7 days';

= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =