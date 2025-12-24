-- table orderes: 
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
ADD CONSTRAINT chk_ordres_execute_prix
    CHECK (
        statut <> 'EXECUTED'
        OR prix IS NOT NULL
    );
ADD CONSTRAINT chk_ordres_execute_date
    CHECK (
        statut <> 'EXECUTED'
        OR date_creation <= CURRENT_DATE
    );

-- table utilisateurs:
ALTER TABLE utilisateurs
ADD CONSTRAINT uq_utilisateurs_email
    UNIQUE (email),

ADD CONSTRAINT chk_utilisateurs_nom_len
    CHECK (length(nom) <= 50),

ADD CONSTRAINT chk_utilisateurs_nom_len
    CHECK (length(prenom) <= 50),

ADD CONSTRAINT chk_utilisateurs_email_len
    CHECK (length(email) <= 100),

ADD CONSTRAINT chk_utilisateurs_email_format
    CHECK (email LIKE '%_@_%._%'),

ADD CONSTRAINT chk_utilisateurs_statut
    CHECK (statut IN ('ACTIF', 'INACTIF')),

ADD CONSTRAINT chk_utilisateurs_date
    CHECK (date_inscription <= CURRENT_DATE),

ADD CONSTRAINT chk_utilisateurs_portefeuille_actif
    CHECK (
        statut <> 'ACTIF'
        OR portefeuille_id IS NOT NULL
    );

-- table statistique_marche:
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
    UNIQUE (paire_id, indicateur, periode);

-- table prix_marche:
ALTER TABLE prix_marche
ADD CONSTRAINT chk_prix_marche_prix
    CHECK (prix > 0),

ADD CONSTRAINT chk_prix_marche_volume
    CHECK (volume >= 0),

ADD CONSTRAINT chk_prix_marche_date
    CHECK (date_maj <= now()),

ADD CONSTRAINT uq_prix_marche_unique
    UNIQUE (paire_id, date_maj);
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
