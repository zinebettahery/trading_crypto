-- utilisateurs (1000 déjà ok)
INSERT INTO utilisateurs (
    id_utilisateur, nom, prenom, email, date_inscription, statut
)
SELECT
    g,
    'Nom_' || g,
    'Prenom_' || g,
    'user' || g || '@gmail.com',
    CURRENT_DATE - (random() * 730)::int,
    CASE WHEN random() < 0.85 THEN 'ACTIF' ELSE 'INACTIF' END
FROM generate_series(1, 1000) g;


-- cryptomonnaies (7 ok)
INSERT INTO cryptomonnaies (id_crypto, nom, symbole, date_creation, statut)
SELECT
    g,
    c.nom,
    c.symbole,
    c.date_creation::date,
    'ACTIVE'
FROM generate_series(1, 7) g
JOIN (
    VALUES
    (1,'Bitcoin','BTC','2009-01-03'),
    (2,'Ethereum','ETH','2015-07-30'),
    (3,'Tether','USDT','2014-10-06'),
    (4,'BNB','BNB','2017-07-25'),
    (5,'Solana','SOL','2020-03-16'),
    (6,'Cardano','ADA','2017-09-29'),
    (7,'XRP','XRP','2012-06-02')
) c(id, nom, symbole, date_creation) ON g = c.id;

-- portefeuille (beaucoup plus de combinaisons)
INSERT INTO portefeuilles (
    id_portefeuille,
    solde_total,
    solde_bloque,
    date_maj,
    id_utilisateur,
    id_crypto
)
SELECT
    row_number() OVER (),
    round((random() * 20000)::numeric, 2),
    round((random() * 3000)::numeric, 2),
    CURRENT_DATE,
    u.id_utilisateur,
    c.id_crypto
FROM utilisateurs u
CROSS JOIN cryptomonnaies c; -- toutes combinaisons

-- paire_trading (plus de paires avec USDT)
INSERT INTO paire_trading (
    id_paire, statut, date_ouverture, crypto_base, crypto_contre
)
SELECT
    row_number() OVER (),
    'ACTIVE',
    CURRENT_DATE - (random() * 365)::int,
    base.id_crypto,
    contre.id_crypto
FROM cryptomonnaies base
JOIN cryptomonnaies contre
    ON base.id_crypto <> contre.id_crypto
WHERE contre.symbole = 'USDT'
  AND base.symbole IN ('BTC','ETH','SOL','ADA','XRP','BNB');

-- prix_marche
INSERT INTO prix_marche (
    id_prix, prix, volume, date_maj, id_paire
)
SELECT
    row_number() OVER (),
    round((random() * 60000 + 10)::numeric, 2),
    round((random() * 200000)::numeric, 2),
    CURRENT_DATE - (random() * 5)::int,
    p.id_paire
FROM paire_trading p
CROSS JOIN generate_series(1, 50) g; -- plus de prix pour simuler historique

-- ORDRES : ~100 000
INSERT INTO ordres (
    id_order, type_ordre, "mode", quantite, prix,
    statut, date_creation, id_utilisateur, id_paire
)
SELECT
    gs.id_order,
    CASE WHEN random() < 0.5 THEN 'BUY' ELSE 'SELL' END,
    CASE WHEN random() < 0.6 THEN 'MARKET' ELSE 'LIMIT' END,
    (random() * 10 + 1)::int,
    round((random() * 60000 + 10)::numeric, 2),
    CASE
        WHEN random() < 0.55 THEN 'EN_ATTENTE'
        WHEN random() < 0.85 THEN 'EXECUTE'
        ELSE 'ANNULE'
    END,
    CURRENT_DATE - (random() * 60)::int,
    (1 + floor(random() * 1000))::int, -- utilisateur aléatoire
    (1 + floor(random() * (SELECT COUNT(*) FROM paire_trading)))::int -- paire aléatoire
FROM generate_series(1, 100000) AS gs(id_order);

-- TRADES : générer plus de trades pour chaque ordre exécuté
INSERT INTO trades (
    id_trade, prix, quantite, date_execution, id_order, id_paire
)
SELECT
    row_number() OVER (),
    o.prix + (random() * 20 - 10),
    (random() * 5 + 1)::int,
    o.date_creation + (random() * 2)::int,
    o.id_order,
    o.id_paire
FROM ordres o
WHERE o.statut = 'EXECUTE';


-- statistique_marche
INSERT INTO statistique_marche (
    id_statistique, indicateur, valeur, periode, date_maj, id_paire
)
SELECT
    row_number() OVER (),
    ind.indicateur,
    round((random() * 100)::numeric, 2),
    ind.periode,
    CURRENT_DATE,
    p.id_paire
FROM paire_trading p
CROSS JOIN (
    VALUES
    ('RSI','24h'),
    ('VWAP','24h'),
    ('VOLATILITE','7j')
) ind(indicateur, periode);


-- detection_anomalie
INSERT INTO detection_anomalie (
    id_detection, "type", date_detection,
    commentaire, id_order, id_utilisateur
)
SELECT
    row_number() OVER (),
    CASE WHEN random() < 0.5 THEN 'WASH_TRADING' ELSE 'SPOOFING' END,
    CURRENT_DATE,
    'Anomalie détectée automatiquement',
    o.id_order,
    o.id_utilisateur
FROM ordres o
WHERE random() < 0.08;


-- audit_trail
INSERT INTO audit_trail (
    id_audit,
    table_cible,
    "action",
    date_action,
    details,
    id_utilisateur,
    id_order,
    id_trade
)
SELECT
    row_number() OVER () AS id_audit,
    CASE WHEN random() < 0.5 THEN 'ORDRES'
         ELSE 'TRADES' END AS table_cible,
    CASE WHEN random() < 0.5 THEN 'INSERT' ELSE 'UPDATE' END AS action,
    CURRENT_DATE - (random() * 30)::int AS date_action,
    'Action système automatique avec toutes les FK' AS details,
    u.id_utilisateur,
    o.id_order,
    t.id_trade
FROM utilisateurs u
JOIN ordres o ON o.id_utilisateur = u.id_utilisateur
JOIN trades t ON t.id_order = o.id_order
WHERE random() < 0.3;


select count(*) from ordres;