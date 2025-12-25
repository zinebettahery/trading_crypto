CREATE SCHEMA IF NOT EXISTS "public";

CREATE  TABLE "public".cryptomonnaies ( 
	id_crypto            integer  NOT NULL  ,
	nom                  varchar(255)    ,
	date_creation        date    ,
	statut               varchar(255)    ,
	symbole              varchar    ,
	CONSTRAINT pk_cryptomonnaies PRIMARY KEY ( id_crypto )
 );

CREATE  TABLE "public".paire_trading ( 
	id_paire             integer  NOT NULL  ,
	statut               varchar(255)    ,
	date_ouverture       date    ,
	crypto_base          integer    ,
	crypto_contre        integer    ,
	CONSTRAINT pk_paire_trading PRIMARY KEY ( id_paire )
 );

CREATE  TABLE "public".prix_marche ( 
	id_prix              integer  NOT NULL  ,
	prix                 decimal    ,
	volume               decimal    ,
	date_maj             date    ,
	id_paire             integer    ,
	CONSTRAINT pk_prix_marche PRIMARY KEY ( id_prix )
 );

CREATE  TABLE "public".statistique_marche ( 
	id_statistique       integer  NOT NULL  ,
	indicateur           varchar(50)    ,
	valeur               decimal    ,
	periode              varchar(255)    ,
	date_maj             date    ,
	id_paire             integer    ,
	CONSTRAINT pk_statistique_marche PRIMARY KEY ( id_statistique )
 );

CREATE  TABLE "public".utilisateurs ( 
	id_utilisateur       integer  NOT NULL  ,
	nom                  varchar    ,
	prenom               varchar    ,
	email                varchar    ,
	date_inscription     date    ,
	statut               varchar    ,
	CONSTRAINT pk_utilisateurs PRIMARY KEY ( id_utilisateur )
 );

CREATE  TABLE "public".ordres ( 
	id_order             integer  NOT NULL  ,
	type_ordre           varchar(50)    ,
	"mode"               varchar(100)    ,
	quantite             decimal    ,
	prix                 decimal    ,
	statut               varchar(50)    ,
	date_creation        date    ,
	id_utilisateur       integer    ,
	id_paire             integer    ,
	CONSTRAINT pk_ordres PRIMARY KEY ( id_order )
 );

CREATE  TABLE "public".portefeuilles ( 
	id_portefeuille      integer  NOT NULL  ,
	solde_total          decimal  NOT NULL  ,
	solde_bloque         decimal    ,
	date_maj             date    ,
	id_utilisateur       integer    ,
	id_crypto            integer    ,
	CONSTRAINT pk_portefeuilles PRIMARY KEY ( id_portefeuille )
 );

CREATE  TABLE "public".trades ( 
	id_trade             integer  NOT NULL  ,
	prix                 decimal    ,
	quantite             decimal    ,
	date_execution       date    ,
	id_order             integer    ,
	id_paire             integer    ,
	CONSTRAINT pk_trades PRIMARY KEY ( id_trade )
 );

CREATE  TABLE "public".audit_trail ( 
	id_audit             integer  NOT NULL  ,
	table_cible          varchar(50)    ,
	"action"             varchar(50)    ,
	date_action          date    ,
	details              text    ,
	id_utilisateur       integer    ,
	id_order             integer    ,
	id_trade             integer    ,
	CONSTRAINT pk_audit_trail PRIMARY KEY ( id_audit )
 );

CREATE  TABLE "public".detection_anomalie ( 
	id_detection         integer  NOT NULL  ,
	"type"               varchar(50)    ,
	date_detection       date    ,
	commentaire          text    ,
	id_order             integer    ,
	id_utilisateur       integer    ,
	CONSTRAINT pk_detection_anomalie PRIMARY KEY ( id_detection )
 );

ALTER TABLE "public".audit_trail ADD CONSTRAINT fk_audit_trail_utilisateurs FOREIGN KEY ( id_utilisateur ) REFERENCES "public".utilisateurs( id_utilisateur );

ALTER TABLE "public".audit_trail ADD CONSTRAINT fk_audit_trail_ordres FOREIGN KEY ( id_order ) REFERENCES "public".ordres( id_order );

ALTER TABLE "public".audit_trail ADD CONSTRAINT fk_audit_trail_trades FOREIGN KEY ( id_trade ) REFERENCES "public".trades( id_trade );

ALTER TABLE "public".detection_anomalie ADD CONSTRAINT fk_detection_anomalie_ordres FOREIGN KEY ( id_order ) REFERENCES "public".ordres( id_order );

ALTER TABLE "public".detection_anomalie ADD CONSTRAINT fk_detection_anomalie_utilisateurs FOREIGN KEY ( id_utilisateur ) REFERENCES "public".utilisateurs( id_utilisateur );

ALTER TABLE "public".ordres ADD CONSTRAINT fk_ordres_utilisateurs FOREIGN KEY ( id_utilisateur ) REFERENCES "public".utilisateurs( id_utilisateur );

ALTER TABLE "public".ordres ADD CONSTRAINT fk_ordres_paire_trading FOREIGN KEY ( id_paire ) REFERENCES "public".paire_trading( id_paire );

ALTER TABLE "public".paire_trading ADD CONSTRAINT fk_paire_trading_cryptomonnaies FOREIGN KEY ( crypto_base ) REFERENCES "public".cryptomonnaies( id_crypto );

ALTER TABLE "public".paire_trading ADD CONSTRAINT fk_paire_trading_cryptomonnaies_0 FOREIGN KEY ( crypto_contre ) REFERENCES "public".cryptomonnaies( id_crypto );

ALTER TABLE "public".portefeuilles ADD CONSTRAINT fk_portefeuilles_utilisateurs FOREIGN KEY ( id_utilisateur ) REFERENCES "public".utilisateurs( id_utilisateur );

ALTER TABLE "public".portefeuilles ADD CONSTRAINT fk_portefeuilles_cryptomonnaies FOREIGN KEY ( id_crypto ) REFERENCES "public".cryptomonnaies( id_crypto );

ALTER TABLE "public".prix_marche ADD CONSTRAINT fk_prix_marche_paire_trading FOREIGN KEY ( id_paire ) REFERENCES "public".paire_trading( id_paire );

ALTER TABLE "public".statistique_marche ADD CONSTRAINT fk_statistique_marche_paire_trading FOREIGN KEY ( id_paire ) REFERENCES "public".paire_trading( id_paire );

ALTER TABLE "public".trades ADD CONSTRAINT fk_trades_ordres FOREIGN KEY ( id_order ) REFERENCES "public".ordres( id_order );

ALTER TABLE "public".trades ADD CONSTRAINT fk_trades_paire_trading FOREIGN KEY ( id_paire ) REFERENCES "public".paire_trading( id_paire );

