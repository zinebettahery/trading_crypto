-- Indicateurs avancés par paire (VWAP, volatilité, RSI)
SELECT
    p.id_paire,
    s.vwap_30j,
    s.volatilite_30j,
    s.rsi
FROM paire_trading p
JOIN LATERAL (
    SELECT
        calcul_vwap(p.id_paire, CURRENT_DATE - INTERVAL '30 days', CURRENT_DATE) AS vwap_30j,
        calcul_volatilite(p.id_paire, CURRENT_DATE - INTERVAL '30 days', CURRENT_DATE) AS volatilite_30j,
        calcul_rsi(p.id_paire) AS rsi
) s ON true;

-- Statistiques par utilisateur (nombre d’ordres, volume échangé)
SELECT
    u.id_utilisateur,
    u.nom,
    stats.nb_ordres,
    stats.volume_trade
FROM utilisateurs u
JOIN LATERAL (
    SELECT
        COUNT(o.id_order) AS nb_ordres,
        COALESCE(SUM(t.quantite), 0) AS volume_trade
    FROM ordres o
    LEFT JOIN trades t ON t.id_order = o.id_order
    WHERE o.id_utilisateur = u.id_utilisateur
) stats ON true;



-- 
SELECT
    p.id_paire,
    last_stat.indicateur,
    last_stat.valeur,
    last_stat.date_maj
FROM paire_trading p
JOIN LATERAL (
    SELECT indicateur, valeur, date_maj
    FROM statistique_marche sm
    WHERE sm.id_paire = p.id_paire
    ORDER BY date_maj DESC
    LIMIT 1
) last_stat ON true;




