CREATE TABLE departments (
    id SERIAL PRIMARY KEY NOT NULL,
    building int NOT NULL CHECK (building > 0 AND building < 6),
    financing money NOT NULL DEFAULT 0 CHECK (financing >= 0),
    name nvarchar(100) NOT NULL UNIQUE
);

CREATE TABLE diseases (
    id SERIAL PRIMARY KEY NOT NULL,
    name nvarchar(100) NOT NULL UNIQUE
);

CREATE TABLE doctors (
    id SERIAL PRIMARY KEY NOT NULL,
    name nvarchar(max) NOT NULL,
    salary money NOT NULL CHECK (salary > 0),
    surname nvarchar(max) NOT NULL
);

CREATE TABLE doctors_examinations (
    id SERIAL PRIMARY KEY NOT NULL,
    date date NOT NULL DEFAULT CURRENT_DATE,
    disease_id int NOT NULL,
    doctor_id int NOT NULL,
    examination_id int NOT NULL,
    ward_id int NOT NULL,
    FOREIGN KEY (disease_id) REFERENCES diseases(id),
    FOREIGN KEY (doctor_id) REFERENCES doctors(id),
    FOREIGN KEY (examination_id) REFERENCES examinations(id),
    FOREIGN KEY (ward_id) REFERENCES wards(id)
);

CREATE TABLE examinations (
    id SERIAL PRIMARY KEY NOT NULL,
    name nvarchar(100) NOT NULL UNIQUE
);

CREATE TABLE interns (
    id SERIAL PRIMARY KEY NOT NULL,
    doctor_id int NOT NULL,
    FOREIGN KEY (doctor_id) REFERENCES doctors(id)
);

CREATE TABLE professors (
    id SERIAL PRIMARY KEY NOT NULL,
    doctor_id int NOT NULL,
    FOREIGN KEY (doctor_id) REFERENCES doctors(id)
);

CREATE TABLE wards (
    id SERIAL PRIMARY KEY NOT NULL,
    name nvarchar(20) NOT NULL UNIQUE,
    places int NOT NULL CHECK (places >= 1),
    department_id int NOT NULL,
    FOREIGN KEY (department_id) REFERENCES departments(id)
);


INSERT INTO departments (building, financing, name) VALUES
(1, 0, 'emergency'),
(2, 0, 'cardiology'),
(3, 0, 'pediatric'),
(4, 0, 'neurology'),
(5, 0, 'radiology');

INSERT INTO diseases (name) VALUES
('Disease1'),
('Disease2'),
('Disease3');

INSERT INTO doctors (name, salary, surname) VALUES
('Greg', 200000, 'House'),
('Eric', 110000, 'Foreman'),
('Robert', 100000, 'Chase'),
('Allison', 120000, 'Cameron'),
('Lisa', 170000, 'Caddy'),
('James', 80000, 'Willson');

INSERT INTO examinations (name) VALUES
('General Checkup'),
('MRI Scan'),
('Echocardiogram');

INSERT INTO interns (doctor_id) VALUES
(1),
(2),
(3);

INSERT INTO professors (doctor_id) VALUES
(4),
(5),
(6);

INSERT INTO wards (name, places, department_id) VALUES
('ward1', 1, 1),
('ward2', 2, 2),
('ward3', 3, 1),
('ward4', 2, 2),
('ward5', 4, 3),
('ward6', 3, 3),
('ward7', 2, 1),
('ward8', 1, 4),
('ward9', 4, 4),
('ward10', 3, 4),
('ward11', 2, 4),
('ward12', 1, 5),
('ward13', 2, 5),
('ward14', 3, 5);

INSERT INTO doctors_examinations (date, disease_id, doctor_id, examination_id, ward_id) VALUES
('2024-05-08', 1, 1, 1, 1),
('2024-05-08', 2, 2, 2, 2),
('2024-05-08', 3, 3, 3, 3),
('2024-05-08', 1, 4, 1, 4),
('2024-05-08', 2, 5, 2, 5),
('2024-05-08', 3, 6, 3, 6);


--1. Вивести назви та місткості палат, розташованих у 1-му
--корпусі, місткістю 5 і більше місць, якщо в цьому корпусі
--є хоча б одна палата місткістю понад 1 місць.


SELECT name, places
FROM wards
WHERE department_id IN (SELECT id FROM departments WHERE building = 1)
AND places >= 5
AND (SELECT MAX(places) FROM wards WHERE department_id IN (SELECT id FROM departments WHERE building = 1)) > 1;


--2. Вивести назви відділень, у яких проводилося хоча б одне
--обстеження за останній тиждень.

FROM departments d
INNER JOIN wards w ON d.id = w.department_id
INNER JOIN doctors_examinations de ON w.id = de.ward_id
WHERE de.date >= GETDATE() - 7;

--3. Вивести назви захворювань, для яких не проводяться обстеження.


SELECT name
FROM diseases
WHERE id NOT IN (SELECT DISTINCT disease_id FROM doctors_examinations);


--4. Вивести повніі мена лікарів,які не проводять обстеження.

SELECT CONCAT(name, ' ', surname) AS full_name
FROM doctors
WHERE id NOT IN (SELECT DISTINCT doctor_id FROM doctors_examinations);

--5. Вивестиназвивідділень,уяких не проводяться обстеження.


SELECT d.name
FROM departments d
LEFT JOIN wards w ON d.id = w.department_id
LEFT JOIN doctors_examinations de ON w.id = de.ward_id
WHERE de.id IS NULL;

--6. Вивести прізвища лікарів, які є інтернами.

SELECT d.name, d.surname
FROM doctors d
INNER JOIN interns i ON d.id = i.doctor_id;

--7. Вивести прізвища інтернів, ставки яких більші, ніж ставка хоча б одного з лікарів.

SELECT intern.name, intern.surname
FROM doctors intern
INNER JOIN interns i ON intern.id = i.doctor_id
WHERE intern.salary > ANY (SELECT salary FROM doctors WHERE id NOT IN (SELECT doctor_id FROM interns));


--8. Вивести назви палат, чия місткість більша, ніж місткість кожної палати, що знаходиться в 3-му корпусі.


SELECT w.name
FROM wards w
WHERE w.places > ALL (
    SELECT w2.places
    FROM wards w2
    INNER JOIN departments d ON w2.department_id = d.id
    WHERE d.building = 3
);


--9. Вивести прізвища лікарів, які проводять обстеження у відділеннях “pediatric” та “radiology”.

SELECT DISTINCT d.name, d.surname
FROM doctors d
JOIN doctors_examinations de ON d.id = de.doctor_id
JOIN wards w ON de.ward_id = w.id
JOIN departments dep ON w.department_id = dep.id
WHERE dep.name IN ('pediatric', 'radiology');


--10. Вивести назви відділень, у яких працюють інтерни та професори.

SELECT DISTINCT d.name
FROM departments d
JOIN wards w ON d.id = w.department_id
JOIN doctors d1 ON d1.id IN (SELECT doctor_id FROM interns)
JOIN doctors d2 ON d2.id IN (SELECT doctor_id FROM professors)
WHERE w.department_id = d.id;


--11. Вивести повні імена лікарів та відділення у яких вони
--проводять обстеження, якщо відділення має фонд фінансування понад 20000.


SELECT CONCAT(d.name, ' ', d.surname) AS full_name, dep.name AS department
FROM doctors d
JOIN doctors_examinations de ON d.id = de.doctor_id
JOIN wards w ON de.ward_id = w.id
JOIN departments dep ON w.department_id = dep.id
WHERE dep.financing > 20000;


--12. Вивести назву відділення, в якому проводить обстеження лікар із найбільшою ставкою.

SELECT dep.name
FROM departments dep
JOIN wards w ON dep.id = w.department_id
JOIN doctors_examinations de ON w.id = de.ward_id
JOIN doctors d ON de.doctor_id = d.id
WHERE d.salary = (
    SELECT MAX(salary) FROM doctors
);


