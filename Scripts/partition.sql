
CREATE TABLE audit_trail_parent (
    id_audit        integer NOT NULL,
    table_cible     varchar(50),
    action          varchar(50) NOT NULL,
    date_action     date,
    details         text,
    id_utilisateur  integer,
    id_order        integer,
    id_trade        integer,
    CONSTRAINT pk_audit_trail_parent PRIMARY KEY (id_audit, action)
) PARTITION BY LIST (action);


-- INSERT
CREATE TABLE audit_trail_insert
PARTITION OF audit_trail_parent FOR VALUES IN ('INSERT');

-- UPDATE
CREATE TABLE audit_trail_update
PARTITION OF audit_trail_parent FOR VALUES IN ('UPDATE');

-- DELETE
CREATE TABLE audit_trail_delete
PARTITION OF audit_trail_parent FOR VALUES IN ('DELETE');


CREATE TABLE trades_parent (
    id_trade        integer NOT NULL,
    prix            decimal,
    quantite        decimal,
    date_execution  date NOT NULL,
    id_order        integer,
    id_paire        integer,
    CONSTRAINT pk_trades_parent PRIMARY KEY (id_trade, date_execution)
) PARTITION BY RANGE (date_execution);

-- Décembre 2025
CREATE TABLE trades_2025_12
PARTITION OF trades_parent
FOR VALUES FROM ('2025-12-01') TO ('2026-01-01');

-- Janvier 2026
CREATE TABLE trades_2026_01
PARTITION OF trades_parent
FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
