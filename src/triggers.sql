CREATE DATABASE triggers_bank;

USE triggers_bank;

CREATE TABLE clientes(
    cliente_id INT NOT NULL IDENTITY (1,1),
    cliente_nombre VARCHAR(50) NOT NULL,
    cliente_apellido VARCHAR(50) NOT NULL,
    cliente_dui VARCHAR(11) UNIQUE NOT NULL,
    cliente_nit VARCHAR(20) UNIQUE NOT NULL,
    cliente_email VARCHAR(50) UNIQUE  NOT NULL,
    cliente_direccion VARCHAR(100) NOT NULL,
    PRIMARY KEY (cliente_id)
);

SELECT * FROM clientes;

INSERT INTO clientes(cliente_nombre, cliente_apellido, cliente_dui, cliente_nit, cliente_email, cliente_direccion)
VALUES
('Lázaro', 'del Albero', '07867588-0', '1217-280298-106-3','fovid23193@ecofreon.com', 'Col Sta Marta No 1 San Martín, San Martín'),
('Roque', 'Noguera Abril', '08945678-4', '1219-231155-112-2', 'pinegog181@ingfix.com', 'Bo San Juan 2 Cl Ote No 7, Cuscatlán'),
('Victorino', 'Pérez', '00340956-9', '1217-201290-106-4', 'poyip47959@ecofreon.com', 'Col Flor Blanca 45 Av Sur Estadio Flor Blanca'),
('Gregorio', 'Peral', '03423679-8', '1120-201099-104-2', 'sigesi9381@niekie.com', 'Col Padre Pío Cl Al Zamorán Lt1'),
('Tristán', 'Carbajo Rozas', '03423467-9', '1217-010289-105-6', 'paxab49489@epeva.com' ,'Col Layco 25 Cl Pte No 1354');

CREATE TABLE cuenta(
  cuenta_id VARCHAR(10) NOT NULL UNIQUE,
  cuenta_saldo DECIMAL(10,2) CHECK(cuenta_saldo >= 0.00) NOT NULL,
  cliente_id INT NOT NULL,
  PRIMARY KEY(cliente_id),
  CONSTRAINT FK_CLIEN_ID FOREIGN KEY (cliente_id) REFERENCES clientes(cliente_id) ON UPDATE CASCADE ON DELETE CASCADE
);

SELECT * FROM cuenta;

INSERT INTO cuenta(cuenta_id, cuenta_saldo, cliente_id)
VALUES
('7896578054', 1200.67, 1),
('8245678523', 17000.45, 2),
('0978965643', 19234.90, 3),
('5090876789', 1000.00, 4),
('6745098967', 2800.65, 5);

CREATE TABLE lineaCredito(
  lineaCredito_id INT UNIQUE NOT NULL IDENTITY(1000,3),
  lineaCredito_saldo DECIMAL(10,2) CHECK(lineaCredito_saldo >= 0.00) NOT NULL,
  cuenta_id VARCHAR(10) NOT NULL,
  PRIMARY KEY(lineaCredito_id),
  CONSTRAINT FK_CUEN_ID FOREIGN KEY(cuenta_id) REFERENCES cuenta(cuenta_id) ON UPDATE CASCADE ON DELETE CASCADE
);

SELECT * FROM lineaCredito;

INSERT INTO lineaCredito(lineaCredito_saldo, cuenta_id)
VALUES
(1000.00, '7896578054'),
(1500.00, '8245678523'),
(2000.00, '0978965643'),
(750.00,  '5090876789'),
(500.00,  '6745098967');

CREATE TABLE giro(
  giro_id INT UNIQUE NOT NULL IDENTITY (1,1),
  giro_fecha DATETIME NOT NULL,
  giro_monto DECIMAL(10,2) CHECK(giro_monto >= 0.00) NOT NULL,
  cuenta_id VARCHAR(10) NOT NULL,
  PRIMARY KEY (giro_id),
  CONSTRAINT FK_CUENTA_ID FOREIGN KEY (cuenta_id) REFERENCES cuenta(cuenta_id) ON UPDATE CASCADE ON DELETE CASCADE
);

SELECT * FROM giro;

CREATE TABLE usolineaCredito(
    usolineaCredito_id INT UNIQUE NOT NULL IDENTITY(1,1),
    usolineaCredito_fecha DATETIME NOT NULL,
    usolineaCredito_monto DECIMAL(10,2) CHECK(usolineaCredito_monto >= 0.00) NOT NULL,
    lineaCredito_id INT NOT NULL,
    PRIMARY KEY(usolineaCredito_id),
    CONSTRAINT FK_LIN_CRED_ID FOREIGN KEY(lineaCredito_id) REFERENCES lineaCredito(lineaCredito_id) ON UPDATE CASCADE ON DELETE CASCADE
);

SELECT * FROM usolineaCredito;

/** CREAREMOS UN VIEW PARA VER LA INFO DE LA CUENTA PRINCIPAL*/
CREATE VIEW view_info_account
AS
  SELECT cuenta.cuenta_id, cliente_nombre,cliente_apellido,cliente_nit,cuenta_saldo
  FROM clientes ,cuenta

  WHERE clientes.cliente_id = cuenta.cliente_id

SELECT * FROM view_info_account

CREATE TRIGGER delete_on_cascade
ON clientes
FOR DELETE
AS
Begin
DELETE cuenta from cuenta, deleted
WHERE
deleted.cliente_id=cuenta.cliente_id
End

/**
  TAREA
 */

CREATE OR ALTER TRIGGER triggers_transaction_giro
ON giro AFTER INSERT, UPDATE
AS
DECLARE @giro_monto DECIMAL(10,2)
DECLARE @cuenta_saldo DECIMAL(10,2)
DECLARE @cuenta_id VARCHAR(10)

SET @giro_monto = (SELECT giro_monto FROM inserted);
SET @cuenta_id = (SELECT cuenta_id FROM inserted);
SET @cuenta_saldo = (SELECT cuenta_saldo FROM cuenta WHERE cuenta_id = @cuenta_id);
IF @giro_monto <= @cuenta_saldo
BEGIN
    UPDATE cuenta SET cuenta_saldo = cuenta_saldo - @giro_monto
    WHERE cuenta_id = @cuenta_id
END
ELSE
BEGIN
    RAISERROR('El saldo disponible es insuficienta para completar la transaccion', 16, 10)
    ROLLBACK;
END

/**TEST TRIGGERS */
INSERT INTO giro(giro_fecha, giro_monto, cuenta_id)
VALUES
(GETDATE(), 105.40, '5090876789');

INSERT INTO usolineaCredito(usolineaCredito_fecha, usolineaCredito_monto, lineaCredito_id)
VALUES
(GETDATE(),50.00, 1000);

CREATE OR ALTER TRIGGER triggers_transaction_credito
ON usolineaCredito AFTER INSERT, UPDATE
AS
DECLARE @usolineaCredito_monto DECIMAL(10,2)
DECLARE @lineaCredito_saldo DECIMAL(10,2)
DECLARE @lineaCredito_id VARCHAR(10)

SET @usolineaCredito_monto = (SELECT usolineaCredito_monto FROM inserted);
SET @lineaCredito_id = (SELECT lineaCredito_id FROM inserted);
SET @lineaCredito_saldo = (SELECT lineaCredito_saldo FROM lineaCredito WHERE lineaCredito.lineaCredito_id = @lineaCredito_id);
IF @usolineaCredito_monto <= @lineaCredito_saldo
BEGIN
    UPDATE lineaCredito SET lineaCredito_saldo = lineaCredito_saldo - @usolineaCredito_monto
    WHERE lineaCredito_id = @lineaCredito_id
END
ELSE
BEGIN
    RAISERROR('El credito disponible es insuficienta para completar la transaccion', 16, 10)
    ROLLBACK;
END



