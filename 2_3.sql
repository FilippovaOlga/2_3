DROP TABLE IF EXISTS WorkPlans;
DROP TABLE IF EXISTS Employees;
DROP TABLE IF EXISTS Divisions;
DROP TYPE IF EXISTS grade_type;
DROP TYPE IF EXISTS score_type;

CREATE TYPE  grade_type AS ENUM ('junior','middle','senior','lead');
CREATE TYPE  score_type AS ENUM ('A','B','C','D','E');

CREATE TABLE employees
(
	Id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	FirstName VARCHAR(30) NOT NULL,
	LastName VARCHAR(30) NOT NULL,
	LastName2 VARCHAR(30),
	BirthDate DATE,
	DateIn DATE,
	JobTitle VARCHAR(30),
	JobLevel grade_type NOT NULL,
	Salary INT,
	Division_Id INT,
	bRules BOOLEAN,
	CHECK (Salary > 0 AND Division_Id > 0)
);



CREATE TABLE divisions
(
	Id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	DivisionName VARCHAR(50) NOT NULL,
	FirstName VARCHAR(30) NOT NULL,
	LastName VARCHAR(30) NOT NULL,
	LastName2 VARCHAR(30),
	num_Employees INTEGER
);

ALTER TABLE employees ADD CONSTRAINT division_fk 
	FOREIGN KEY (Division_Id) 
	REFERENCES Divisions(Id) 
	ON DELETE CASCADE;



CREATE TABLE workplans
(
	Id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	Emp_id INT NOT NULL,
	Mark1 score_type,
	Mark2 score_type,
	Mark3 score_type,
	Mark4 score_type,
	CONSTRAINT employee_score_fk 
	FOREIGN KEY (Emp_Id) 
	REFERENCES Employees(Id) 
	ON DELETE CASCADE
);


INSERT INTO Divisions (FirstName,LastName,DivisionName,num_Employees) 
VALUES 
('Jon1','Smith1','Div1',5),
('Jon2','Smith2','Div2',3),
('Jon3','Smith3','Div3',2);

INSERT INTO Employees (FirstName,LastName,JobLevel,Division_Id,Salary,DateIn,JobTitle) 
VALUES 
('John1','Smith1','junior',1,50000,NULL,NULL),
('John2','Smith2','junior',2,60000,'2021-08-09','Driver'),
('John3','Smith3','middle',1,150000,'2020-09-02',NULL),
('John4','Smith4','middle',2,150000,NULL,'Driver'),
('John5','Smith5','senior',1,250000,'2020-01-12',NULL),
('John6','Smith6','senior',3,350000,'2019-05-16',NULL);


INSERT INTO Divisions (FirstName,LastName,DivisionName,num_Employees) 
VALUES 
('Jon4','Smith4','Интеллектуальный анализ данных',2);
INSERT INTO Employees (FirstName,LastName,JobLevel,Division_Id,Salary) 
VALUES 
('John6','Smith6','middle',4,150000),
('John7','Smith7','senior',4,250000);



INSERT INTO WorkPlans (Emp_Id,Mark1,Mark2,Mark3,Mark4) 
VALUES 
(1,'E','A','B','C'),
(2,'A','B','D','C'),
(3,'B','A','B','C'),
(4,'B','D','D','C'),
(5,'C','A','B','B'),
(6,'C','A','B','C'),
(7,'C','A','B','D');

-- Уникальный номер сотрудника, ФИО и стаж работы – для всех сотрудников компании
SELECT DISTINCT id, FirstName, LastName, COALESCE(current_date-DateIn,0) as StageInCompany FROM Employees ORDER BY StageInCompany DESC;
-- Уникальный номер сотрудника, ФИО и стаж работы – только первая 3 сотрудников
SELECT DISTINCT id, FirstName, LastName, COALESCE(current_date-DateIn,0) as StageInCompany FROM Employees ORDER BY StageInCompany DESC LIMIT 3; 

-- Уникальный номер сотрудников - Водителей
SELECT DISTINCT id AS Driver_IDs
FROM Employees 
WHERE JobTitle = 'Driver'; 

-- Выведите номера сотрудников, которые хотя бы за 1 квартал получили оценку D или E
SELECT DISTINCT id AS BadWorkers_IDs
FROM Employees 
WHERE id IN (SELECT DISTINCT Emp_Id FROM WorkPlans WHERE Mark1 >= 'D' OR Mark2 >= 'D' OR Mark3 >= 'D' OR Mark4 >= 'D');

-- Выведите самую высокую зарплату в компании.
SELECT MAX(Salary)
FROM Employees;

-- Выведите название самого крупного отдела
SELECT DivisionName
FROM Divisions
WHERE num_employees = (SELECT MAX(num_employees) FROM Divisions);

-- Выведите номера сотрудников от самых опытных до вновь прибывших
SELECT id as Empl_IDs FROM Employees ORDER BY COALESCE(current_date-DateIn,0) DESC;

-- Рассчитайте среднюю зарплату для каждого уровня сотрудников
SELECT JobLevel, ROUND(AVG(Salary),-2) FROM Employees GROUP BY JobLevel;

-- Добавьте столбец с информацией о коэффициенте годовой премии к основной таблице. 
-- Коэффициент рассчитывается по такой схеме: базовое значение коэффициента – 1, каждая оценка действует на коэффициент так:
-- Е – минус 20%
-- D – минус 10%
-- С – без изменений
-- B – плюс 10%
-- A – плюс 20%

WITH Bonuses AS 
(SELECT Emp_id, 
ROUND((CASE WHEN Mark1 = 'A' THEN 20 WHEN Mark1='B' THEN 10 WHEN Mark1='C' THEN 0 WHEN Mark1='D' THEN -10 WHEN Mark1='E' THEN -20 END + 
CASE WHEN Mark2 = 'A' THEN 20 WHEN Mark2='B' THEN 10 WHEN Mark2='C' THEN 0 WHEN Mark2='D' THEN -10 WHEN Mark2='E' THEN -20 END + 
CASE WHEN Mark3 = 'A' THEN 20 WHEN Mark3='B' THEN 10 WHEN Mark3='C' THEN 0 WHEN Mark3='D' THEN -10 WHEN Mark3='E' THEN -20 END + 
CASE WHEN Mark4 = 'A' THEN 20 WHEN Mark4='B' THEN 10 WHEN Mark4='C' THEN 0 WHEN Mark4='D' THEN -10 WHEN Mark4='E' THEN -20 END)/4.0,2) AS Bonus
FROM WorkPlans)

SELECT e.id,FirstName, LastName, Division_ID, Salary, COALESCE(Bonus,0), Salary*COALESCE(Bonus/100.0,0) 
FROM Employees as e
left join Bonuses as b
ON e.id = b.Emp_id
ORDER BY e.id;
