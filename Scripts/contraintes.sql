   -- ================================
   -- LA TABLE trades
   -- ================================

-- Le prix d’un trade doit être strictement positif
ADD CONSTRAINT chk_trades_prix
CHECK (prix > 0);

-- La quantité échangée doit être strictement positive
ADD CONSTRAINT chk_trades_quantite
CHECK (quantite > 0);

-- La date d’exécution du trade ne doit pas être dans le futur
ADD CONSTRAINT chk_trades_date
CHECK (date_execution <= CURRENT_TIMESTAMP);


   -- ==================================
   -- LA TABLE audit_trail
   -- ==================================

-- L’action auditée doit être INSERT, UPDATE ou DELETE
ALTER TABLE audit_trail
ADD CONSTRAINT chk_audit_action
CHECK (action IN ('INSERT', 'UPDATE', 'DELETE'));

-- La date de l’action auditée ne doit pas être dans le futur
ADD CONSTRAINT chk_audit_date
CHECK (date_action <= CURRENT_TIMESTAMP);
