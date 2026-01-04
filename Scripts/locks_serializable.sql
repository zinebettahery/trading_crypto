------------------------------------------------------potefeuille
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- Lock sur UN seul portefeuille
SELECT pg_advisory_xact_lock(1);

UPDATE portefeuilles
SET solde_total = solde_total - 500,
    solde_bloque = solde_bloque + 500,
    date_maj = NOW()
WHERE id_portefeuille = 1;

COMMIT;


ROLLBACK;
------------------------------------------------------ordres
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

SELECT pg_advisory_xact_lock(204);

INSERT INTO ordres (
	id_order,
    id_utilisateur, id_paire, type_ordre, mode,
    quantite, prix, statut, date_creation
)
VALUES (20,204, 3, 'BUY', 'LIMIT', 1.5, 35000, 'OPEN', NOW());

COMMIT;


ROLLBACK;
------------------------------------------------------trades
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

SELECT pg_advisory_xact_lock(60);

INSERT INTO trades (
	id_trade, id_order, id_paire, prix, quantite, date_execution
)
VALUES (1000, 9001, 3, 34980, 0.5, NOW());

COMMIT;

ROLLBACK;

------------------------------------------------------prix_marche
BEGIN;

SELECT pg_advisory_xact_lock(35);

UPDATE prix_marche
SET prix = 35020,
    volume = volume + 12.5,
    date_maj = NOW()
WHERE id_paire = 35;

COMMIT;

ROLLBACK;