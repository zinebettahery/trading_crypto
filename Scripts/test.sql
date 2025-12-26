--test du calcule des indicateurs
--- ==================================
-- Test des fonctions de calcul des indicateurs pour la table prix_marche
-- ==================================
SELECT
    COUNT(*) AS nb_trades
FROM
    trades;

SELECT
    id_paire
FROM
    paire_trading
LIMIT
    5;

-- Test VWAP sur une paire (ex : id_paire = 1)
SELECT
    calcul_vwap (
        1,
        CURRENT_DATE - INTERVAL '30 days',
        CURRENT_DATE
    ) AS vwap_30j;

SELECT
    SUM(prix * quantite) / SUM(quantite) AS vwap_verification
FROM
    trades
WHERE
    id_paire = 1
    AND date_execution BETWEEN CURRENT_DATE - INTERVAL '30 days' AND CURRENT_DATE;

SELECT
    SUM(prix * quantite) / SUM(quantite) AS vwap_verification
FROM
    trades
WHERE
    id_paire = 1
    AND date_execution BETWEEN CURRENT_DATE - INTERVAL '30 days' AND CURRENT_DATE;

-- Test volatilité sur 7 jours
SELECT
    calcul_volatilite (1, CURRENT_DATE - INTERVAL '7 days', CURRENT_DATE) AS volatilite_7j;

SELECT
    STDDEV (prix) AS volatilite_verification
FROM
    trades
WHERE
    id_paire = 1
    AND date_execution BETWEEN CURRENT_DATE - INTERVAL '7 days' AND CURRENT_DATE;

-- Test RSI (14 derniers trades)
SELECT
    calcul_rsi (1) AS rsi_14;