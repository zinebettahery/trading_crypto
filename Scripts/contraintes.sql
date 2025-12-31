-- ==================================
-- table orderes:
-- ==================================

ALTER TABLE ordres
ADD CONSTRAINT chk_ordres_type
    CHECK (type_ordre IN ('BUY', 'SELL')), 
ADD CONSTRAINT chk_ordres_mode
    CHECK (mode IN ('MARKET', 'LIMIT')),
ADD CONSTRAINT chk_ordres_quantite
    CHECK (quantite > 0),
ADD CONSTRAINT chk_ordres_prix_mode
    CHECK (
        (mode = 'LIMIT' AND prix IS NOT NULL AND prix > 0)
     OR (mode = 'MARKET' AND prix IS NULL)
    ),
ADD CONSTRAINT chk_ordres_statut
    CHECK (statut IN ('OPEN', 'EXECUTED', 'CANCELLED')),
ADD CONSTRAINT chk_ordres_execute_date
    CHECK (
        statut <> 'EXECUTED'
        OR date_creation <= CURRENT_DATE
    );
-- ==================================
-- table paire_trading
-- ==================================

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

-- ==================================
-- table detection_anomalie
-- ==================================

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

-- ==================================
-- table utilisateurs:
-- ==================================

ALTER TABLE utilisateurs
ADD CONSTRAINT uq_utilisateurs_email
    UNIQUE (email),

ADD CONSTRAINT chk_utilisateurs_nom_len
    CHECK (length(nom) <= 50),

ADD CONSTRAINT chk_utilisateurs_prenom_len
    CHECK (length(prenom) <= 50),

ADD CONSTRAINT chk_utilisateurs_email_len
    CHECK (length(email) <= 100),

ADD CONSTRAINT chk_utilisateurs_email_format
    CHECK (email LIKE '%_@_%._%'),

ADD CONSTRAINT chk_utilisateurs_statut
    CHECK (statut IN ('ACTIF', 'INACTIF')),

ADD CONSTRAINT chk_utilisateurs_date
    CHECK (date_inscription <= CURRENT_DATE);


-- ==================================
-- table statistique_marche:
-- ==================================

ALTER TABLE statistique_marche
ADD CONSTRAINT chk_stat_marche_indicateur
    CHECK (indicateur IN ('VWAP', 'RSI', 'VOLATILITE')),

ADD CONSTRAINT chk_stat_marche_valeur_positive
    CHECK (valeur >= 0),

ADD CONSTRAINT chk_stat_marche_rsi_range
    CHECK (
        indicateur <> 'RSI'
        OR (valeur BETWEEN 0 AND 100)
    ),

ADD CONSTRAINT chk_stat_marche_volatilite
    CHECK (
        indicateur <> 'VOLATILITE'
        OR valeur >= 0
    ),

ADD CONSTRAINT chk_stat_marche_vwap
    CHECK (
        indicateur <> 'VWAP'
        OR valeur > 0
    ),

ADD CONSTRAINT chk_stat_marche_date
    CHECK (date_maj <= now()),

ADD CONSTRAINT uq_stat_marche_unique
    UNIQUE (id_paire, indicateur, periode);

-- ==================================
-- table prix_marche:
-- ==================================

ALTER TABLE prix_marche
ADD CONSTRAINT chk_prix_marche_prix
    CHECK (prix > 0),

ADD CONSTRAINT chk_prix_marche_volume
    CHECK (volume >= 0),

ADD CONSTRAINT chk_prix_marche_date
    CHECK (date_maj <= now()),

ADD CONSTRAINT uq_prix_marche_unique
    UNIQUE (id_paire, date_maj);

-- ================================
-- LA TABLE trades
-- ================================

-- Le prix d’un trade doit être strictement positif
Alter Table trades
ADD CONSTRAINT chk_trades_prix
CHECK (prix > 0),

-- La quantité échangée doit être strictement positive
ADD CONSTRAINT chk_trades_quantite
CHECK (quantite > 0),

-- La date d’exécution du trade ne doit pas être dans le futur
ADD CONSTRAINT chk_trades_date
CHECK (date_execution <= CURRENT_TIMESTAMP);


-- ==================================
-- LA TABLE audit_trail
-- ==================================

-- L’action auditée doit être INSERT, UPDATE ou DELETE
ALTER TABLE audit_trail
ADD CONSTRAINT chk_audit_action
CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),

-- La date de l’action auditée ne doit pas être dans le futur
ADD CONSTRAINT chk_audit_date
CHECK (date_action <= CURRENT_TIMESTAMP);

-- ==================================
-- table portefeuilles
-- ==================================

-- Contraintes NOT NULL
ALTER TABLE public.portefeuilles
ALTER COLUMN solde_total
SET
    NOT NULL;

ALTER TABLE public.portefeuilles
ALTER COLUMN id_utilisateur
SET
    NOT NULL;

ALTER TABLE public.portefeuilles
ALTER COLUMN id_crypto
SET
    NOT NULL;

--Contraintes CHECK
--Solde total ≥ 0
ALTER TABLE public.portefeuilles ADD CONSTRAINT chk_solde_total_positive CHECK (solde_total >= 0);

--Solde bloqué ≥ 0
ALTER TABLE public.portefeuilles ADD CONSTRAINT chk_solde_bloque_positive CHECK (
    solde_bloque IS NULL
    OR solde_bloque >= 0
);

--Solde bloqué ≤ solde total
ALTER TABLE public.portefeuilles ADD CONSTRAINT chk_solde_bloque_inferieur_total CHECK (
    solde_bloque IS NULL
    OR solde_bloque <= solde_total
);

--Valeur par défaut
-- Solde bloqué = 0 par défaut
ALTER TABLE public.portefeuilles
ALTER COLUMN solde_bloque
SET DEFAULT 0;

-- Date de mise à jour = date actuelle par défaut
ALTER TABLE public.portefeuilles
ALTER COLUMN date_maj
SET DEFAULT CURRENT_DATE;

--Contrainte UNIQUE
ALTER TABLE public.portefeuilles ADD CONSTRAINT uq_utilisateur_crypto UNIQUE (id_utilisateur, id_crypto);

-- ==================================
-- table cryptomonnaie'
-- ==================================

-- nom obligatoire
ALTER TABLE public.cryptomonnaies
ALTER COLUMN nom
SET
    NOT NULL;

-- symbole obligatoire
ALTER TABLE public.cryptomonnaies
ALTER COLUMN symbole
SET
    NOT NULL;

-- symbole unique (BTC, ETH...)
ALTER TABLE public.cryptomonnaies ADD CONSTRAINT uq_symbole_crypto UNIQUE (symbole);

-- statut contrôlé
ALTER TABLE public.cryptomonnaies ADD CONSTRAINT chk_statut_crypto CHECK (statut IN ('ACTIVE', 'DESACTIVE'));

-- date de création valide
ALTER TABLE public.cryptomonnaies ADD CONSTRAINT chk_date_creation_crypto CHECK (date_creation <= CURRENT_DATE);