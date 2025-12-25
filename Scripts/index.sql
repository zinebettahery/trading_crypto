-- Index B-tree classique pour les recherches fréquentes sur id_order ou id_utilisateur ou date_detection
CREATE INDEX idx_detection_anomalie_utilisateur ON detection_anomalie(id_utilisateur);
CREATE INDEX idx_detection_anomalie_order ON detection_anomalie(id_order);
CREATE INDEX idx_detection_anomalie_date ON detection_anomalie(date_detection);


-- Index covering si tu as des requêtes qui récupèrent plusieurs colonnes fréquemment
-- Exemple : récupérer date_detection et commentaire pour un id_utilisateur
CREATE INDEX idx_detection_anomalie_utilisateur_covering 
ON detection_anomalie(id_utilisateur) INCLUDE(date_detection, commentaire);

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
