-- table orderes
ALTER TABLE ordres
ADD CONSTRAINT chk_ordres_type
    CHECK (type_ordre IN ('BUY', 'SELL')),
ADD CONSTRAINT chk_ordres_mode
    CHECK ("mode" IN ('MARKET', 'LIMIT')),
ADD CONSTRAINT chk_ordres_quantite
    CHECK (quantite > 0),
ADD CONSTRAINT chk_ordres_prix
    CHECK (prix IS NULL OR prix > 0),
ADD CONSTRAINT chk_ordres_statut
    CHECK (statut IN ('OPEN', 'EXECUTED', 'CANCELLED'));

