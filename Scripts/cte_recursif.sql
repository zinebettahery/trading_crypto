-- Création de la séquence si elle n'existe pas
CREATE SEQUENCE IF NOT EXISTS seq_detection_anomalie START 1;

-- WASH TRADING : Un utilisateur fait un BUY puis un SELL avec même paire, même prix, même quantité et très proche dans le temps
WITH RECURSIVE wash_chain AS (

    -- Point de départ (s’exécute une seule fois): un BUY
    -- PostgreSQL crée un ensemble initial de lignes, appelé seed set (ou “ensemble de départ”).
    -- Chaque ligne du seed set reçoit profondeur = 1.
    SELECT
        o.id_order,
        o.id_utilisateur,
        o.id_paire,
        o.type_ordre,
        o.prix,
        o.quantite,
        o.date_creation,
        1 AS profondeur
    FROM ordres o
    WHERE o.type_ordre = 'BUY'

    UNION ALL

    -- Étape récursive : SELL juste après
    -- PostgreSQL prend toutes les lignes de wash_chain déjà calculées
    -- Pour chaque ligne de wash_chain (wc), il cherche les ordres suivants dans ordres (o2) qui respectent les conditions
    -- Chaque ligne trouvée devient une nouvelle ligne wash_chain avec profondeur = wc.profondeur + 1
    SELECT
        o2.id_order,
        o2.id_utilisateur,
        o2.id_paire,
        o2.type_ordre,
        o2.prix,
        o2.quantite,
        o2.date_creation,
        wc.profondeur + 1
    FROM ordres o2
    JOIN wash_chain wc
        ON o2.id_utilisateur = wc.id_utilisateur
       AND o2.id_paire = wc.id_paire
       AND o2.prix = wc.prix
       AND o2.quantite = wc.quantite
       AND o2.date_creation > wc.date_creation
       AND o2.date_creation <= wc.date_creation + INTERVAL '2 minutes'
       AND o2.type_ordre <> wc.type_ordre
)
-- Insérer les anomalies détectées dans la table detection_anomalie
INSERT INTO detection_anomalie (id_detection, type, date_detection, commentaire, id_order, id_utilisateur)
SELECT
    nextval('seq_detection_anomalie'),
    'WASH_TRADING',
    CURRENT_DATE,
    'Suspicion wash trading entre ordres BUY et SELL rapides',
    wc.id_order,
    wc.id_utilisateur
FROM wash_chain wc
-- Si un utilisateur fait 5 ordres successifs BUY/SELL → profondeur = 5 → suspicion plus forte
WHERE wc.profondeur >= 2;



--SPOOFING : Gros ordre LIMIT, Pas exécuté, Annulé rapidement, Répété plusieurs fois
WITH RECURSIVE spoof_chain AS (

    -- Gros ordre
    SELECT
        id_order,
        id_utilisateur,
        id_paire,
        quantite,
        statut,
        date_creation,
        1 AS niveau
    FROM ordres
    WHERE quantite > 1000
      AND statut = 'OPEN'

    UNION ALL

    -- Ordre annulé rapidement
    SELECT
        o.id_order,
        o.id_utilisateur,
        o.id_paire,
        o.quantite,
        o.statut,
        o.date_creation,
        sc.niveau + 1
    FROM ordres o
    JOIN spoof_chain sc
        ON o.id_utilisateur = sc.id_utilisateur
       AND o.id_paire = sc.id_paire
       AND o.date_creation > sc.date_creation
       AND o.date_creation <= sc.date_creation + INTERVAL '1 minute'
       AND o.statut = 'CANCELLED'
)
INSERT INTO detection_anomalie (id_detection, type, date_detection, commentaire, id_order, id_utilisateur)
SELECT
    nextval('seq_detection_anomalie'),
    'SPOOFING',
    CURRENT_DATE,
    'Ordres volumineux ouverts puis annulés rapidement',
    sc.id_order,
    sc.id_utilisateur
FROM spoof_chain sc
WHERE sc.niveau >= 2;


-- PUMP AND DUMP : Série d’achats, Prix monte vite, Série de ventes juste après
WITH RECURSIVE pump_chain AS (

    -- Début du pump
    SELECT
        t.id_trade,
        t.id_paire,
        t.prix,
        t.quantite,
        t.date_execution,
        1 AS step
    FROM trades t

    UNION ALL

    -- Trades successifs avec prix croissant
    SELECT
        t2.id_trade,
        t2.id_paire,
        t2.prix,
        t2.quantite,
        t2.date_execution,
        pc.step + 1
    FROM trades t2
    JOIN pump_chain pc
        ON t2.id_paire = pc.id_paire
       AND t2.date_execution > pc.date_execution
       AND t2.date_execution <= pc.date_execution + INTERVAL '5 minutes'
       AND t2.prix > pc.prix
)
INSERT INTO detection_anomalie (id_detection, type, date_detection, commentaire, id_order, id_utilisateur)
SELECT
    nextval('seq_detection_anomalie'),
    'PUMP_AND_DUMP',
    CURRENT_DATE,
    'Série d’achats suivi d’une hausse rapide et ventes',
    pc.id_order,
    pc.id_utilisateur
FROM pump_chain pc
WHERE pc.step >= 5;


-- FRONT RUNNING : Un utilisateur place un ordre juste avant un gros ordre qui impacte le prix
WITH RECURSIVE front_run_chain AS (

    -- Petit ordre
    SELECT
        o.id_order,
        o.id_utilisateur,
        o.id_paire,
        o.quantite,
        o.date_creation,
        1 AS niveau
    FROM ordres o
    WHERE o.quantite < 10

    UNION ALL

    -- Gros ordre juste après
    SELECT
        o2.id_order,
        o2.id_utilisateur,
        o2.id_paire,
        o2.quantite,
        o2.date_creation,
        frc.niveau + 1
    FROM ordres o2
    JOIN front_run_chain frc
        ON o2.id_paire = frc.id_paire
       AND o2.date_creation > frc.date_creation
       AND o2.date_creation <= frc.date_creation + INTERVAL '30 seconds'
       AND o2.quantite > 1000
)
INSERT INTO detection_anomalie (id_detection, type, date_detection, commentaire, id_order, id_utilisateur)
SELECT
    nextval('seq_detection_anomalie'),
    'FRONT_RUNNING',
    CURRENT_DATE,
    'Petit ordre suivi rapidement par un gros ordre',
    frc.id_order,
    frc.id_utilisateur
FROM front_run_chain frc
WHERE frc.niveau >= 2;