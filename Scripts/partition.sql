-- Script SQL pour partitionner la table audit_trail par type d'action
------------------------------------------------------------
-- 1. RENOMMER LA TABLE EXISTANTE
------------------------------------------------------------
ALTER TABLE audit_trail
RENAME TO audit_trail_old;


------------------------------------------------------------
-- 2. CRÉATION DE LA TABLE PARENT PARTITIONNÉE
------------------------------------------------------------
CREATE TABLE audit_trail (
    id_audit        integer NOT NULL,
    table_cible     varchar(50),
    action          varchar(50) NOT NULL,
    date_action     date,
    details         text,
    id_utilisateur  integer,
    id_order        integer,
    id_trade        integer,
    CONSTRAINT audit_trail_pk PRIMARY KEY (id_audit, action)
) PARTITION BY LIST (action);


------------------------------------------------------------
-- 3. CRÉATION DES PARTITIONS
------------------------------------------------------------

-- Partition INSERT
CREATE TABLE insert_audit_trail
PARTITION OF audit_trail
FOR VALUES IN ('INSERT');

-- Partition UPDATE
CREATE TABLE update_audit_trail
PARTITION OF audit_trail
FOR VALUES IN ('UPDATE');

-- Partition DELETE
CREATE TABLE delete_audit_trail
PARTITION OF audit_trail
FOR VALUES IN ('DELETE');


------------------------------------------------------------
-- 4. CLÉS ÉTRANGÈRES
------------------------------------------------------------
ALTER TABLE audit_trail
ADD CONSTRAINT fk_audit_trail_utilisateurs
FOREIGN KEY (id_utilisateur)
REFERENCES utilisateurs(id_utilisateur);

ALTER TABLE audit_trail
ADD CONSTRAINT fk_audit_trail_ordres
FOREIGN KEY (id_order)
REFERENCES ordres(id_order);

ALTER TABLE audit_trail
ADD CONSTRAINT fk_audit_trail_trades
FOREIGN KEY (id_trade)
REFERENCES trades(id_trade);


------------------------------------------------------------
-- 5. INDEX
------------------------------------------------------------
-- Index B-tree sur id_order et id_trade
CREATE INDEX audit_order_idx
ON audit_trail(id_order);

CREATE INDEX audit_trade_idx
ON audit_trail(id_trade);

-- 3. Recherche par date
CREATE INDEX audit_date_idx
ON audit_trail(date_action DESC)
INCLUDE (table_cible, action, id_utilisateur);

-- 2. Recherche par utilisateur
CREATE INDEX audit_utilisateur_idx
ON audit_trail(id_utilisateur, date_action DESC)
INCLUDE (table_cible, action, id_order, id_trade);


-- Index GIN sur details : Pour les recherches texte dans la colonne details.
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX audit_details_gin_idx
ON audit_trail
USING GIN (details gin_trgm_ops);


------------------------------------------------------------
-- 6. MIGRATION DES DONNÉES
------------------------------------------------------------
INSERT INTO audit_trail (
    id_audit,
    table_cible,
    action,
    date_action,
    details,
    id_utilisateur,
    id_order,
    id_trade
)
SELECT
    id_audit,
    table_cible,
    action,
    date_action,
    details,
    id_utilisateur,
    id_order,
    id_trade
FROM audit_trail_old;


------------------------------------------------------------
-- 7. CONTRAINTES
------------------------------------------------------------
-- L’action auditée doit être INSERT, UPDATE ou DELETE
ALTER TABLE audit_trail
ADD CONSTRAINT chk_audit_action
CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),

-- La date de l’action auditée ne doit pas être dans le futur
ADD CONSTRAINT chk_audit_date
CHECK (date_action <= CURRENT_TIMESTAMP);


------------------------------------------------------------
-- 8. SUPPRESSION DE L’ANCIENNE TABLE
------------------------------------------------------------
DROP TABLE audit_trail_old;

------------------------------------------------------------
-- 9. VÉRIFICATION DES PARTITIONS
------------------------------------------------------------
SELECT 'INSERT' AS partition, COUNT(*) FROM audit_trail_insert
UNION ALL
SELECT 'UPDATE', COUNT(*) FROM audit_trail_update
UNION ALL
SELECT 'DELETE', COUNT(*) FROM audit_trail_delete;

-- -- Script SQL pour partitionner la table ordres par date de creaction et trades par date d'execution
--=============================================================================================================
-----------------------------------------------Table ordres----------------------------------------------------
--=============================================================================================================

-- ÉTAPE 1 — Créer la table partitionnée ordres_partition :
CREATE TABLE ordres_partition (
    id_order        integer NOT NULL,
    type_ordre      varchar(50),
    mode            varchar(100),
    quantite        decimal,
    prix            decimal,
    statut          varchar(50),
    date_creation   date NOT NULL,
    id_utilisateur  integer,
    id_paire        integer,

	-- contraintes
    CONSTRAINT pk_ordres_partition
        PRIMARY KEY (id_order, date_creation),

    CONSTRAINT chk_ordres_p_type
        CHECK (type_ordre IN ('BUY', 'SELL')),

    CONSTRAINT chk_ordres_p_mode
        CHECK (mode IN ('MARKET', 'LIMIT')),

    CONSTRAINT chk_ordres_p_quantite
        CHECK (quantite > 0),

    CONSTRAINT chk_ordres_p_prix_mode
        CHECK (
            (mode = 'LIMIT' AND prix IS NOT NULL AND prix > 0)
         OR (mode = 'MARKET' AND prix IS NULL)
        ),

    CONSTRAINT chk_ordres_p_statut
        CHECK (statut IN ('OPEN', 'EXECUTED', 'CANCELLED'))
)
PARTITION BY RANGE (date_creation);

-- index:
CREATE INDEX idx_ordres_carnet_buy_partition
ON ordres_partition (id_paire, prix DESC, date_creation)
INCLUDE (quantite, id_utilisateur)
WHERE statut = 'OPEN' AND type_ordre = 'BUY';

CREATE INDEX idx_ordres_carnet_sell_partition
ON ordres_partition (id_paire, prix ASC, date_creation)
INCLUDE (quantite, id_utilisateur)
WHERE statut = 'OPEN' AND type_ordre = 'SELL';

CREATE INDEX idx_ordres_utilisateur_partition
ON ordres_partition (id_utilisateur, date_creation DESC);

CREATE INDEX idx_ordres_user_history_partition
ON ordres_partition (id_utilisateur, date_creation DESC)
INCLUDE (type_ordre, mode, quantite, prix, statut, id_paire);

CREATE INDEX idx_ordres_limit_open_partition
ON ordres_partition (id_paire, prix, date_creation)
WHERE statut = 'OPEN' AND mode = 'LIMIT';

CREATE INDEX idx_ordres_paire_partition
ON ordres_partition (id_paire, date_creation DESC)
INCLUDE (quantite, prix);

CREATE INDEX idx_ordres_statut_partition
ON ordres_partition (statut, date_creation DESC)
WHERE statut IN ('EXECUTED', 'CANCELLED');

CREATE INDEX idx_ordres_archive_partition
ON ordres_partition (date_creation)
WHERE statut = 'EXECUTED';

CREATE INDEX idx_ordres_wash_trading_partition
ON ordres_partition (id_utilisateur, id_paire, type_ordre, date_creation)
WHERE statut = 'EXECUTED';

CREATE STATISTICS stats_ordres_paire_type_statut_partition
ON id_paire, type_ordre, statut
FROM ordres_partition;


-- ÉTAPE 2 — Créer les partitions mensuelles

------ fonction de creation automatique des partitions
CREATE OR REPLACE FUNCTION create_ordres_monthly_partitions(
    start_date DATE,
    end_date   DATE
)
RETURNS void AS
$$
DECLARE
    d DATE := date_trunc('month', start_date);
    partition_name TEXT;
BEGIN
    WHILE d < end_date LOOP
        partition_name := format('ordres_%s', to_char(d, 'YYYY_MM'));

        EXECUTE format(
            'CREATE TABLE IF NOT EXISTS %I
             PARTITION OF ordres_partition
             FOR VALUES FROM (%L) TO (%L)',
            partition_name,
            d,
            (d + INTERVAL '1 month')::DATE
        );

        d := d + INTERVAL '1 month';
    END LOOP;
END;
$$ LANGUAGE plpgsql;


-- Ajouter une partition par défaut pour sécurité
CREATE TABLE ordres_default
PARTITION OF ordres DEFAULT;

-- fonction pour creation initiale (passe + futur)
SELECT create_ordres_monthly_partitions(
    (SELECT date_trunc('month', MIN(date_creation))::DATE FROM ordres),
    (date_trunc('month', current_date) + INTERVAL '12 months')::DATE
);

-- fonction d’assurance (a executer chaque mois)
CREATE OR REPLACE FUNCTION ensure_future_ordres_partitions()
RETURNS void AS
$$
BEGIN
    PERFORM create_ordres_monthly_partitions(
        date_trunc('month', current_date)::DATE,
        (date_trunc('month', current_date) + INTERVAL '6 months')::DATE
    );
END;
$$ LANGUAGE plpgsql;

-- Panification automatique // remarque: il faut installer l'extension pg_crone
-- SELECT cron.schedule(
--     'ordres_monthly_partitions',
--     '0 1 1 * *',
--     $$SELECT ensure_future_ordres_partitions();$$
-- );

-- ÉTAPE 3 — Créer la fonction de redirection (TRIGGER)
CREATE OR REPLACE FUNCTION redirect_ordres_to_partition()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO ordres_partition VALUES (NEW.*);
    RETURN NULL; -- empêche l'insertion dans ordres
END;
$$ LANGUAGE plpgsql;

-- ÉTAPE 4 — Créer le trigger sur ordres
CREATE TRIGGER trg_redirect_ordres
BEFORE INSERT ON ordres
FOR EACH ROW
EXECUTE FUNCTION redirect_ordres_to_partition();


-- ÉTAPE 5 — Migrer les données EXISTANTES
INSERT INTO ordres_partition
SELECT * FROM ordres;


-- test
---------- Lister les partitions et leur table parente
SELECT
    inhrelid::regclass AS partition_name,
    inhparent::regclass AS parent_table
FROM pg_inherits
WHERE inhparent = 'ordres_partition'::regclass;

---------- Afficher le détail des plages de partition (RANGE)
SELECT
    relname AS partition_name,
    pg_get_expr(pg_class.relpartbound, pg_class.oid) AS partition_range
FROM pg_class
JOIN pg_inherits ON pg_class.oid = inhrelid
WHERE inhparent = 'ordres_partition'::regclass;

--------- Voir dans quelle partition se trouve chaque ligne
SELECT *, tableoid::regclass AS partition_name
FROM ordres_partition;


--=============================================================================================================
-----------------------------------------------Table trades----------------------------------------------------
--=============================================================================================================


-- ÉTAPE 1 — Créer la table partitionnée ordres_partition :
CREATE TABLE trades_partition (
    id_trade        integer NOT NULL,
    prix            decimal,
    quantite        decimal,
    date_execution  date NOT NULL,
    id_order        integer,
    id_paire        integer,

    CONSTRAINT pk_trades_partition
        PRIMARY KEY (id_trade, date_execution),

    CONSTRAINT chk_trades_quantite
        CHECK (quantite > 0),

    CONSTRAINT chk_trades_prix
        CHECK (prix > 0)
)
PARTITION BY RANGE (date_execution);


-- index:

--Index B-tree sur id_paire
CREATE INDEX idx_trades_paire_partition
ON trades_partition(id_paire);

--Index B-tree sur  date_execution
CREATE INDEX idx_trades_date_partition
ON trades_partition(date_execution);


-- Covering index sur (id_paire, date_execution) incluant prix et quantite
CREATE INDEX idx_trades_covering_partition
ON trades_partition(id_paire, date_execution DESC)
INCLUDE (prix, quantite, id_order);

-- Index pour recherches par ordre spécifique
CREATE INDEX idx_trades_order_partition
ON trades_partition(id_order);


-- ÉTAPE 2 — Créer les partitions mensuelles

------ fonction de creation automatique des partitions
CREATE OR REPLACE FUNCTION create_trades_monthly_partitions(
    start_date DATE,
    end_date   DATE
)
RETURNS void AS
$$
DECLARE
    d DATE := date_trunc('month', start_date);
    partition_name TEXT;
BEGIN
    WHILE d < end_date LOOP
        partition_name := format('trades_%s', to_char(d, 'YYYY_MM'));

        EXECUTE format(
            'CREATE TABLE IF NOT EXISTS %I
             PARTITION OF trades_partition
             FOR VALUES FROM (%L) TO (%L)',
            partition_name,
            d,
            (d + INTERVAL '1 month')::DATE
        );

        d := d + INTERVAL '1 month';
    END LOOP;
END;
$$ LANGUAGE plpgsql;


-- Ajouter une partition par défaut pour sécurité
CREATE TABLE trades_default
PARTITION OF trades_partition DEFAULT;

-- fonction pour creation initiale (passe + futur)
SELECT create_trades_monthly_partitions(
    (SELECT date_trunc('month', MIN(date_execution))::DATE FROM trades),
    (date_trunc('month', current_date) + INTERVAL '12 months')::DATE
);


-- fonction d’assurance (a executer chaque mois)
CREATE OR REPLACE FUNCTION ensure_future_trades_partitions()
RETURNS void AS
$$
BEGIN
    PERFORM create_trades_monthly_partitions(
        date_trunc('month', current_date)::DATE,
        (date_trunc('month', current_date) + INTERVAL '6 months')::DATE
    );
END;
$$ LANGUAGE plpgsql;


-- Panification automatique // remarque: il faut installer l'extension pg_crone
-- SELECT cron.schedule(
--     'trades_monthly_partitions',
--     '0 1 1 * *',
--     $$SELECT ensure_future_trades_partitions();$$
-- );

-- ÉTAPE 3 — Créer la fonction de redirection (TRIGGER)
CREATE OR REPLACE FUNCTION redirect_trades_to_partition()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO trades_partition VALUES (NEW.*);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


-- ÉTAPE 4 — Créer le trigger sur ordres
CREATE TRIGGER trg_redirect_trades
BEFORE INSERT ON trades
FOR EACH ROW
EXECUTE FUNCTION redirect_trades_to_partition();



-- ÉTAPE 5 — Migrer les données EXISTANTES
INSERT INTO trades_partition
SELECT * FROM trades;


-- test
---------- Lister les partitions et leur table parente
SELECT
    inhrelid::regclass AS partition_name,
    inhparent::regclass AS parent_table
FROM pg_inherits
WHERE inhparent = 'trades_partition'::regclass;

---------- Afficher le détail des plages de partition (RANGE)
SELECT
    relname AS partition_name,
    pg_get_expr(pg_class.relpartbound, pg_class.oid) AS partition_range
FROM pg_class
JOIN pg_inherits ON pg_class.oid = inhrelid
WHERE inhparent = 'trades_partition'::regclass;

--------- Voir dans quelle partition se trouve chaque ligne
SELECT *, tableoid::regclass AS partition_name
FROM trades_partition;
