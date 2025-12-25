-------------------
--TABLE TRADES
-------------------

--Index B-tree sur id_paire
CREATE INDEX idx_trades_paire
ON trades(id_paire);

--Index B-tree sur  date_execution
CREATE INDEX idx_trades_date
ON trades(date_execution);


-- Covering index sur (id_paire, date_execution) incluant prix et quantite
CREATE INDEX idx_trades_covering
ON trades(id_paire, date_execution DESC)
INCLUDE (prix, quantite, id_order);

-- Index pour recherches par ordre spécifique
CREATE INDEX idx_trades_order
ON trades(id_order);

--------------------
-- TABLE AUDIT_TRAIL
--------------------

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


