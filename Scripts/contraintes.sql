-- table portefeuilles
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

-- table cryptomonnaie'
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