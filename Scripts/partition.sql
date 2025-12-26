
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
    CONSTRAINT pk_audit_trail PRIMARY KEY (id_audit, action)
) PARTITION BY LIST (action);


------------------------------------------------------------
-- 3. CRÉATION DES PARTITIONS
------------------------------------------------------------

-- Partition INSERT
CREATE TABLE audit_trail_insert
PARTITION OF audit_trail
FOR VALUES IN ('INSERT');

-- Partition UPDATE
CREATE TABLE audit_trail_update
PARTITION OF audit_trail
FOR VALUES IN ('UPDATE');

-- Partition DELETE
CREATE TABLE audit_trail_delete
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
CREATE INDEX idx_audit_order
ON audit_trail(id_order);

CREATE INDEX idx_audit_trade
ON audit_trail(id_trade);

-- 3. Recherche par date
CREATE INDEX idx_audit_date
ON audit_trail(date_action DESC)
INCLUDE (table_cible, action, id_utilisateur);

-- 2. Recherche par utilisateur
CREATE INDEX idx_audit_utilisateur
ON audit_trail(id_utilisateur, date_action DESC)
INCLUDE (table_cible, action, id_order, id_trade);


-- Index GIN sur details : Pour les recherches texte dans la colonne details.
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX idx_audit_details_gin
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