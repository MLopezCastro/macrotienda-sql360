-----SUBCONSULTAS







SELECT * FROM Dbo.Departamentos;
SELECT * FROM Dbo.Empleados;

---------------INNER JOIN---------------

SELECT * 
FROM Empleados
INNER JOIN Departamentos ON Departamentos.ID = Empleados.DepartamentoId;

--------

--mejor:

SELECT E.Nombre, D.Nombre 
FROM Empleados E
INNER JOIN Departamentos AS D ON D.ID = E.DepartamentoId;

----------LEFT JOIN--------------------------

SELECT *
FROM Empleados AS E
LEFT JOIN Departamentos AS D ON D.ID = E.DepartamentoId;

--------RIGHT JOIN-----------------------

SELECT *
FROM Empleados AS E
RIGHT JOIN Departamentos AS D ON D.ID = E.DepartamentoId;

-----------FULL JOIN--------------------

SELECT *
FROM Empleados AS E
FULL JOIN Departamentos AS D ON D.ID = E.DepartamentoId;