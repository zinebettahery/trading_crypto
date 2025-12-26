
--1- Moyenne mobile sur 7 jours
SELECT
    date_execution,
    id_paire,
    prix AS prix_actuel,
    -- Calcule la moyenne des 7 derniers trades (6 précédents + actuel)
    AVG(prix) OVER (
        PARTITION BY id_paire              -- Par paire de trading (ex: BTC/EUR)
        ORDER BY date_execution            -- Dans l'ordre chronologique
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW  -- 7 lignes: 6 avant + maintenant
    ) AS moyenne_mobile_7jours
FROM trades
WHERE id_paire = 1  -- Exemple: BTC/EUR
ORDER BY date_execution DESC
LIMIT 30;

--2- VWAP : Le prix moyen pondéré par le volume
SELECT
    date_execution,
    prix,
    quantite,
    -- VWAP qui se calcule trade par trade
    SUM(prix * quantite) OVER w / SUM(quantite) OVER w AS vwap_cumule
FROM trades
WHERE id_paire = 1
  AND DATE(date_execution) = CURRENT_DATE
WINDOW w AS (
    PARTITION BY id_paire, DATE(date_execution)
    ORDER BY date_execution
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
)
ORDER BY date_execution DESC;

--3- Variation de prix entre chaque trade
SELECT
    date_execution,
    prix AS prix_actuel,
    -- LAG récupère la valeur de la ligne précédente
    LAG(prix) OVER (
        PARTITION BY id_paire
        ORDER BY date_execution
    ) AS prix_precedent,
    -- Calcul de la variation
    prix - LAG(prix) OVER (
        PARTITION BY id_paire
        ORDER BY date_execution
    ) AS variation_absolue,
    -- Variation en pourcentage
    ((prix - LAG(prix) OVER (
        PARTITION BY id_paire
        ORDER BY date_execution
    )) / LAG(prix) OVER (
        PARTITION BY id_paire
        ORDER BY date_execution
    )) * 100 AS variation_pct
FROM trades
WHERE id_paire = 1
ORDER BY date_execution DESC
LIMIT 10;


--4- Volatilité sur les dernières 24 heures
SELECT
    id_paire,
    date_execution,
    prix,
    -- Écart-type sur 24h
    STDDEV(prix) OVER (
        PARTITION BY id_paire
        ORDER BY date_execution
        RANGE BETWEEN INTERVAL '24 hours' PRECEDING AND CURRENT ROW
    ) AS volatilite_24h,
    -- Coefficient de variation (volatilité en %)
    (STDDEV(prix) OVER (
        PARTITION BY id_paire
        ORDER BY date_execution
        RANGE BETWEEN INTERVAL '24 hours' PRECEDING AND CURRENT ROW
    ) / AVG(prix) OVER (
        PARTITION BY id_paire
        ORDER BY date_execution
        RANGE BETWEEN INTERVAL '24 hours' PRECEDING AND CURRENT ROW
    )) * 100 AS volatilite_pct
FROM trades
WHERE id_paire = 1
ORDER BY date_execution DESC
LIMIT 20;



--5- Min/Max sur les dernières 24 heures
SELECT
    date_execution,
    prix AS prix_actuel,
    -- Prix maximum sur 24h
    MAX(prix) OVER (
        PARTITION BY id_paire
        ORDER BY date_execution
        RANGE BETWEEN INTERVAL '24 hours' PRECEDING AND CURRENT ROW
    ) AS prix_max_24h,
    -- Prix minimum sur 24h
    MIN(prix) OVER (
        PARTITION BY id_paire
        ORDER BY date_execution
        RANGE BETWEEN INTERVAL '24 hours' PRECEDING AND CURRENT ROW
    ) AS prix_min_24h,
    -- Range (amplitude)
    MAX(prix) OVER (
        PARTITION BY id_paire
        ORDER BY date_execution
        RANGE BETWEEN INTERVAL '24 hours' PRECEDING AND CURRENT ROW
    ) - MIN(prix) OVER (
        PARTITION BY id_paire
        ORDER BY date_execution
        RANGE BETWEEN INTERVAL '24 hours' PRECEDING AND CURRENT ROW
    ) AS range_24h
FROM trades
WHERE id_paire = 1
ORDER BY date_execution DESC
LIMIT 10;


--6- Classement: Top des paires par volume journalier
WITH stats_journalieres AS (
    SELECT
        t.id_paire,
        c1.symbole || '/' || c2.symbole AS paire,
        DATE(t.date_execution) AS jour,
        SUM(t.quantite) AS volume_total,
        ((MAX(t.prix) - MIN(t.prix)) / MIN(t.prix)) * 100 AS variation_pct
    FROM trades t
    JOIN paire_trading pt ON t.id_paire = pt.id_paire
    JOIN cryptomonnaies c1 ON pt.crypto_base = c1.id_crypto
    JOIN cryptomonnaies c2 ON pt.crypto_contre = c2.id_crypto
    WHERE DATE(t.date_execution) = CURRENT_DATE
    GROUP BY t.id_paire, paire, DATE(t.date_execution)
)
SELECT
    paire,
    volume_total,
    variation_pct,
    -- Classement par volume (1 = plus gros volume)
    RANK() OVER (ORDER BY volume_total DESC) AS rang_volume,
    -- Classement par performance
    RANK() OVER (ORDER BY variation_pct DESC) AS rang_performance,
    -- Dans quel percentile se trouve cette paire ?
    PERCENT_RANK() OVER (ORDER BY volume_total) * 100 AS percentile_volume
FROM stats_journalieres
ORDER BY volume_total DESC;
