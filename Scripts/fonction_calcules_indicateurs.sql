-- Script SQL pour le calcul des indicateurs techniques 
-- =====================================================
-- VWAP : Volume Weighted Average Price
-- Calcul basé sur les trades exécutés
-- =====================================================
CREATE OR REPLACE FUNCTION calcul_vwap(
    p_id_paire INT,
    p_date_debut TIMESTAMP,
    p_date_fin   TIMESTAMP
)
RETURNS NUMERIC AS $$
DECLARE
    v_vwap NUMERIC;
BEGIN
    SELECT
        SUM(prix * quantite) / NULLIF(SUM(quantite), 0)
    INTO v_vwap
    FROM trades
    WHERE id_paire = p_id_paire
      AND date_execution BETWEEN p_date_debut AND p_date_fin;

    RETURN v_vwap;
END;
$$ LANGUAGE plpgsql;
-- =====================================================
-- Volatilité : écart-type des prix exécutés
-- =====================================================
CREATE OR REPLACE FUNCTION calcul_volatilite(
    p_id_paire INT,
    p_date_debut TIMESTAMP,
    p_date_fin   TIMESTAMP
)
RETURNS NUMERIC AS $$
DECLARE
    v_volatilite NUMERIC;
BEGIN
    SELECT
        STDDEV(prix)
    INTO v_volatilite
    FROM trades
    WHERE id_paire = p_id_paire
      AND date_execution BETWEEN p_date_debut AND p_date_fin;

    RETURN v_volatilite;
END;
$$ LANGUAGE plpgsql;
-- =====================================================
-- RSI : Relative Strength Index (version simplifiée)
-- =====================================================
CREATE OR REPLACE FUNCTION calcul_rsi(
    p_id_paire INT,
    p_nb_points INT DEFAULT 14
)
RETURNS NUMERIC AS $$
DECLARE
    v_rsi NUMERIC;
BEGIN
    WITH derniers_trades AS (
        SELECT prix, date_execution
        FROM trades
        WHERE id_paire = p_id_paire
        ORDER BY date_execution DESC
        LIMIT p_nb_points + 1
    ),
    variations AS (
        SELECT
            prix - LAG(prix) OVER (ORDER BY date_execution) AS variation
        FROM derniers_trades
    )
    SELECT
        100 - (100 / (1 +
            AVG(GREATEST(variation, 0)) /
            NULLIF(AVG(ABS(LEAST(variation, 0))), 0)
        ))
    INTO v_rsi
    FROM variations;

    RETURN v_rsi;
END;
$$ LANGUAGE plpgsql;
-- =====================================================