-- table paire_trading
ALTER TABLE paire_trading
ALTER COLUMN crypto_base SET NOT NULL,
ALTER COLUMN crypto_contre SET NOT NULL,
ALTER COLUMN statut SET NOT NULL,
ALTER COLUMN date_ouverture SET NOT NULL;

-- Interdire une paire crypto identique
ALTER TABLE paire_trading
ADD CONSTRAINT chk_crypto_diff
CHECK (crypto_base <> crypto_contre);

-- les valeurs possibles du statut
ALTER TABLE paire_trading
ADD CONSTRAINT chk_statut_paire
CHECK (statut IN ('ACTIVE', 'INACTIVE', 'SUSPENDUE'));


-- Empêcher une date d’ouverture dans le futur
ALTER TABLE paire_trading
ADD CONSTRAINT chk_date_ouverture
CHECK (date_ouverture <= CURRENT_DATE);


-- table detection_anomalie
ALTER TABLE detection_anomalie
ALTER COLUMN "type" SET NOT NULL,
ALTER COLUMN date_detection SET NOT NULL,
ALTER COLUMN id_utilisateur SET NOT NULL;

ALTER TABLE detection_anomalie
ADD CONSTRAINT chk_type_anomalie
CHECK (
    "type" IN (
        'WASH_TRADING',
        'SPOOFING',
        'PUMP_AND_DUMP',
        'FRONT_RUNNING'
    )
);

ALTER TABLE detection_anomalie
ADD CONSTRAINT chk_date_detection
CHECK (date_detection <= CURRENT_DATE);

--Même utilisateur + même type + même jour → une seule anomalie
ALTER TABLE detection_anomalie
ADD CONSTRAINT uq_anomalie_unique
UNIQUE ("type", id_utilisateur, date_detection);

--Vérifier la cohérence ordre / utilisateur
CREATE OR REPLACE FUNCTION trg_check_order_user()
RETURNS trigger AS $$
BEGIN
    IF NEW.id_order IS NOT NULL THEN
        IF NOT EXISTS (
            SELECT 1
            FROM ordres
            WHERE id_order = NEW.id_order
              AND id_utilisateur = NEW.id_utilisateur
        ) THEN
            RAISE EXCEPTION
            'L''ordre % n''appartient pas à l''utilisateur %',
            NEW.id_order, NEW.id_utilisateur;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_order_user
BEFORE INSERT OR UPDATE ON detection_anomalie
FOR EACH ROW
EXECUTE FUNCTION trg_check_order_user();

