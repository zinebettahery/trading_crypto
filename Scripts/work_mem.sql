--- Identifier si tu as des spills (diagnostic)
SELECT
    datname,
    temp_files,
    pg_size_pretty(temp_bytes) AS temp_size
FROM pg_stat_database
WHERE datname = current_database();


-- Appliquer work_mem (Par requête)
BEGIN;
SET LOCAL work_mem = '128MB';

-- requête analytique lourde 
SELECT
    o.id_utilisateur,
    SUM(t.prix * t.quantite) AS volume_total
FROM trades t
JOIN ordres o ON o.id_order = t.id_order
WHERE t.date_execution >= now() - interval '24 hours'
GROUP BY o.id_utilisateur
ORDER BY volume_total DESC;

COMMIT;

rollback;

-- Appliquer work_mem (Globalement pour la session)
SET work_mem = '128MB';

-- Vérifier le paramètre work_mem appliqué
SHOW work_mem;