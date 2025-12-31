-- =====================================================
-- 1. UTILISATEURS (1000)
-- =====================================================
INSERT INTO utilisateurs (id_utilisateur, nom, prenom, email, statut, date_inscription)
SELECT
    i,
    'Nom_' || i,
    'Prenom_' || i,
    'user_' || i || '@mail.com',
    CASE WHEN random() < 0.85 THEN 'ACTIF' ELSE 'INACTIF' END,
    CURRENT_DATE - (random() * 365)::int
FROM generate_series(1,1000) i;



-- =====================================================
-- 2. CRYPTOMONNAIES (10+)
-- =====================================================
INSERT INTO cryptomonnaies (id_crypto, nom, symbole, statut, date_creation)
SELECT
    row_number() OVER (),
    nom,
    symbole,
    'ACTIVE',
    CURRENT_DATE - (random()*3000)::int
FROM (
    VALUES
    ('Bitcoin','BTC'),
    ('Ethereum','ETH'),
    ('Binance Coin','BNB'),
    ('Solana','SOL'),
    ('Ripple','XRP'),
    ('Cardano','ADA'),
    ('Polkadot','DOT'),
    ('Avalanche','AVAX'),
    ('Polygon','MATIC'),
    ('Litecoin','LTC')
) c(nom, symbole);

-- =====================================================
-- 3. PAIRES DE TRADING
-- =====================================================
INSERT INTO paire_trading (
    id_paire,
    crypto_base,
    crypto_contre,
    statut,
    date_ouverture
)
SELECT
    row_number() OVER (),
    c1.id_crypto,
    c2.id_crypto,
    'ACTIVE',
    CURRENT_DATE - (random() * 3000)::int
FROM cryptomonnaies c1
JOIN cryptomonnaies c2
  ON c1.id_crypto < c2.id_crypto
CROSS JOIN generate_series(1,5);




-- =====================================================
-- 4. PORTEFEUILLES
-- =====================================================
INSERT INTO portefeuilles (id_portefeuille, id_utilisateur, id_crypto, solde_total, solde_bloque, date_maj)
SELECT
    row_number() OVER (),
    u.id_utilisateur,
    c.id_crypto,
    solde_total,
    round((random() * solde_total)::numeric, 2) AS solde_bloque,
    CURRENT_DATE
FROM utilisateurs u
CROSS JOIN cryptomonnaies c
CROSS JOIN LATERAL (
    SELECT round((random() * 10000)::numeric, 2) AS solde_total
) s
WHERE random() < 0.5;



-- =====================================================
-- 5. ORDRES
-- =====================================================
INSERT INTO ordres (
    id_order,
    type_ordre,
    mode,
    quantite,
    prix,
    statut,
    date_creation,
    id_utilisateur,
    id_paire
)
SELECT
    gs AS id_order,

    -- BUY / SELL 50 / 50
    CASE 
        WHEN gs % 2 = 0 THEN 'BUY'
        ELSE 'SELL'
    END AS type_ordre,

    -- MODE : 60% LIMIT / 40% MARKET
    CASE
        WHEN gs <= 15000 THEN 'LIMIT'
        ELSE 'MARKET'
    END AS mode,

    -- Quantité > 0
    round((random() * 100 + 1)::numeric, 2) AS quantite,

    -- Prix : LIMIT obligatoire, MARKET NULL
    CASE
        WHEN gs <= 15000 THEN round((random() * 1000 + 10)::numeric, 2)
        ELSE NULL
    END AS prix,

    -- STATUT par MODE
    CASE
        -- ===== LIMIT =====
        WHEN gs <= 7500  THEN 'EXECUTED'
        WHEN gs <= 12000 THEN 'OPEN'
        WHEN gs <= 15000 THEN 'CANCELLED'

        -- ===== MARKET =====
        WHEN gs <= 20000 THEN 'EXECUTED'
        WHEN gs <= 23000 THEN 'OPEN'
        ELSE 'CANCELLED'
    END AS statut,

    -- 📅 DISTRIBUTION MENSUELLE ÉQUILIBRÉE SUR 2 ANS
    (
        DATE '2024-01-01'
        + INTERVAL '1 month' * ((gs - 1) % 24)
        + INTERVAL '1 day' * floor(random() * 28)
    )::date AS date_creation,

    -- FK simulées
    (gs % 1000) + 1 AS id_utilisateur,
    (gs % 45) + 1   AS id_paire
FROM generate_series(1, 25000) AS gs;

-- select * from ordres;


-- =====================================================
-- 6. TRADES (ordres de mode EXECUTED uniquement)
-- =====================================================
INSERT INTO trades (
    id_trade,
    prix,
    quantite,
    date_execution,
    id_order,
    id_paire
)
SELECT
    row_number() OVER ()                        AS id_trade,

    -- PRIX DU TRADE
    CASE
        -- LIMIT → prix de l’ordre
        WHEN o.mode = 'LIMIT' THEN o.prix

        -- MARKET → prix du marché simulé
        ELSE round((random() * 1000 + 10)::numeric, 2)
    END                                         AS prix,

    -- Quantité échangée (<= quantité de l’ordre)
    round((random() * o.quantite + 0.01)::numeric, 2)
                                                AS quantite,

    -- Date d’exécution (jamais dans le futur)
    o.date_creation
        + (random() * INTERVAL '1 day')         AS date_execution,

    o.id_order,
    o.id_paire
FROM ordres o
WHERE o.statut = 'EXECUTED';

-- select * from trades

-- =====================================================
-- 7. PRIX_MARCHE
-- =====================================================
INSERT INTO prix_marche (id_prix, id_paire, prix, volume, date_maj)
SELECT
    row_number() OVER (),
    p.id_paire,
    round((random()*50000 + 100)::numeric, 2),
    round((random()*100000)::numeric, 2),
    now()
FROM paire_trading p;



-- =====================================================
-- 8. STATISTIQUE_MARCHE
-- =====================================================
INSERT INTO statistique_marche (id_statistique, id_paire, indicateur, valeur, periode, date_maj)
SELECT
    row_number() OVER (),
    p.id_paire,
    i.indicateur,
    CASE
        WHEN i.indicateur = 'RSI' THEN round((random()*100)::numeric, 2)
        ELSE round((random()*5000 + 1)::numeric, 2)
    END,
    '1D',
    now()
FROM paire_trading p
CROSS JOIN (VALUES ('VWAP'),('RSI'),('VOLATILITE')) i(indicateur);



-- =====================================================
-- 9. DETECTION_ANOMALIE
-- =====================================================
INSERT INTO detection_anomalie (id_detection, type, date_detection, id_utilisateur, id_order, commentaire)
SELECT
    row_number() OVER (),
    type,
    CURRENT_DATE,
    id_utilisateur,
    id_order,
    'Anomalie détectée automatiquement'
FROM (
    SELECT DISTINCT ON (o.id_utilisateur, a.type)
        o.id_utilisateur,
        o.id_order,
        a.type
    FROM ordres o
    CROSS JOIN (
        VALUES
        ('WASH_TRADING'),
        ('SPOOFING'),
        ('PUMP_AND_DUMP'),
        ('FRONT_RUNNING')
    ) a(type)
    WHERE random() < 0.02
    ORDER BY o.id_utilisateur, a.type, random()
) t;




-- =====================================================
-- 10. AUDIT_TRAIL
-- =====================================================
INSERT INTO audit_trail (id_audit, table_cible, action, date_action, details, id_utilisateur, id_order, id_trade)
SELECT
    row_number() OVER (),
    CASE WHEN random() < 0.5 THEN 'ORDRES' ELSE 'TRADES' END,
    CASE WHEN random() < 0.5 THEN 'INSERT' ELSE 'UPDATE' END,
    now(),
    'Audit automatique cohérent',
    u.id_utilisateur,
    o.id_order,
    t.id_trade
FROM utilisateurs u
JOIN ordres o ON o.id_utilisateur = u.id_utilisateur
JOIN trades t ON t.id_order = o.id_order
WHERE random() < 0.3;

select * from audit_trail

-- Vider toutes les tables
-- TRUNCATE TABLE audit_trail, detection_anomalie, statistique_marche,
-- 			 prix_marche, trades, ordres, portefeuilles,
-- 			 paire_trading, cryptomonnaies, utilisateurs CASCADE;