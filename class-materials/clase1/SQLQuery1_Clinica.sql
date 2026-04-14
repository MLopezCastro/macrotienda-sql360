CREATE DATABASE Clinica; --creo la db Clínica de SQL 360 Clase 1 -sin acento-

--Orden sugerido:

--1-Pacientes
--2-Consultorios
--3-Medicos
--4-Especialidades
--5-Intermedia (relación M:N entre Médicos y Especialidades)
--6-Turnos (FK a Pacientes, Médicos, Consultorios)

USE Clinica;

--Tabla Pacientes:

CREATE TABLE dbo.Pacientes (
    ID_Paciente INT IDENTITY(1,1) NOT NULL,
    Nombre NVARCHAR(100) NOT NULL,    
    DNI VARCHAR(20) NOT NULL,    
    Telefono VARCHAR(30) NULL,    
    CONSTRAINT PK_Pacientes PRIMARY KEY (ID_Paciente),    
    CONSTRAINT UQ_Pacientes_DNI UNIQUE (DNI)
);



SELECT * FROM dbo.Pacientes;

--Tabla Consultorios:

CREATE TABLE dbo.Consultorios (
	ID_Consultorio INT IDENTITY(1,1) NOT NULL,
	Telefono_Interno VARCHAR(10) NULL,
	CONSTRAINT PK_Consultorios PRIMARY KEY (ID_Consultorio),
	CONSTRAINT UQ_Consultorios_Telefono_Interno UNIQUE (Telefono_Interno)
);

--Tabla Especialidades:


CREATE TABLE dbo.Especialidades (
	ID_Especialidad INT IDENTITY(1,1) NOT NULL,
	Nombre NVARCHAR(50) NOT NULL,
	CONSTRAINT PK_Especialidades PRIMARY KEY (ID_Especialidad),
	CONSTRAINT UQ_Especialidades_Nombre UNIQUE (Nombre)
);


--Tabla Médicos:

CREATE TABLE dbo.Medicos (
	ID_Medico INT IDENTITY(1,1) NOT NULL,
	Nombre NVARCHAR(100) NOT NULL,
	Matricula VARCHAR(50) NOT NULL,
	Fecha_Ingreso DATE NOT NULL,
	CONSTRAINT PK_Medicos PRIMARY KEY (ID_Medico),
	CONSTRAINT UQ_Medicos_Matricula UNIQUE (Matricula) --clave natural alternativa (Matricula) como UNIQUE
);

--Chequeo previo de tablas creadas:

SELECT name FROM sys.tables;


--Tabla intermedia, porque hay relación M:N entre Medicos y Especialidades

CREATE TABLE dbo.Medicos_Especialidades (
	ID_Medico INT NOT NULL, ---PRIMARY KEY (ID_Medico, ID_Especialidad) puede ser también
	ID_Especialidad INT NOT NULL,
	CONSTRAINT PK_Medicos_Especialidades PRIMARY KEY (ID_Medico, ID_Especialidad),
	CONSTRAINT FK_ME_Medicos FOREIGN KEY (ID_Medico) REFERENCES dbo.Medicos(ID_Medico),
	CONSTRAINT FK_ME_Especialidades FOREIGN KEY (ID_Especialidad) REFERENCES dbo.Especialidades(ID_Especialidad)
);


--Tabla Turnos:

CREATE TABLE dbo.Turnos (
	ID_Turno INT IDENTITY(1,1) NOT NULL,
	Fecha DATE NOT NULL,
	Hora TIME NOT NULL,
	Observaciones NVARCHAR(255) NULL,
	ID_Paciente INT NOT NULL,
	ID_Medico INT NOT NULL,
	ID_Consultorio INT NOT NULL,
	CONSTRAINT PK_Turnos PRIMARY KEY (ID_Turno),
	CONSTRAINT FK_Turnos_Pacientes FOREIGN KEY (ID_Paciente) REFERENCES dbo.Pacientes(ID_Paciente),
	CONSTRAINT FK_Turnos_Medicos FOREIGN KEY (ID_Medico) REFERENCES dbo.Medicos (ID_Medico),
	CONSTRAINT FK_Turnos_Consultorio FOREIGN KEY (ID_Consultorio) REFERENCES dbo.Consultorios (ID_Consultorio),
	CONSTRAINT UQ_Turnos_Medico_Fecha_Hora UNIQUE (ID_Medico, Fecha, Hora)
);

---Voy a crear una restricción para que un paciente no pueda tomar dos turnos a la misma fecha y hora con ALTER TABLE:

ALTER TABLE dbo.Turnos
ADD CONSTRAINT UQ_Turnos_Pacientes_Fecha_Hora UNIQUE (ID_Paciente, Fecha, Hora);

--La base garantiza que:
--Un médico no puede estar en dos lugares al mismo tiempo.
--Un paciente no puede tener dos turnos simultáneos.

-----Voy a crear una restricción para que dos médicos no pueda tomar el mismo consultorio a la misma fecha y hora con ALTER TABLE:

ALTER TABLE dbo.Turnos
ADD CONSTRAINT UQ_Turnos_Consultorios_Fecha_Hora UNIQUE (ID_Consultorio, Fecha, Hora);

--
EXEC SP_HELP; --objetos creados en la db


