/*=====================================================================
  TSQLV4 — Exercises 1–22
  Questions 1–20 run against the TSQLV4 sample database.
  Questions 21–22 create their own tables (DDL included).
=====================================================================*/

USE TSQLV4;
GO

---------------------------------------------------------------------
-- 1
-- Return orders placed in June 2015
---------------------------------------------------------------------
SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
WHERE orderdate >= '20150601'
  AND orderdate <  '20150701'
ORDER BY orderid;

---------------------------------------------------------------------
-- 2
-- Return orders placed on the last day of the month
---------------------------------------------------------------------
SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
WHERE orderdate = EOMONTH(orderdate)
ORDER BY orderid;

---------------------------------------------------------------------
-- 3
-- Employees with a last name containing the letter 'e' twice or more
---------------------------------------------------------------------
SELECT empid, firstname, lastname
FROM HR.Employees
WHERE lastname LIKE '%e%e%';

---------------------------------------------------------------------
-- 4
-- Orders with total value (qty*unitprice) greater than 10000,
-- sorted by total value
---------------------------------------------------------------------
SELECT orderid, SUM(qty * unitprice) AS totalvalue
FROM Sales.OrderDetails
GROUP BY orderid
HAVING SUM(qty * unitprice) > 10000
ORDER BY totalvalue DESC;

---------------------------------------------------------------------
-- 5
-- Employees whose last name starts with a lower-case letter.
-- The database collation is case-insensitive, so force a
-- case-sensitive collation for the comparison.
---------------------------------------------------------------------
SELECT empid, lastname
FROM HR.Employees
WHERE lastname LIKE '[a-z]%' COLLATE Latin1_General_CS_AS;

---------------------------------------------------------------------
-- 6
-- Explain the difference between the following two queries
/*
  Query 1 filters rows BEFORE grouping: it keeps only orders whose
  orderdate is earlier than 2016-05-01 and then counts, per employee,
  how many of THOSE orders exist.

  Query 2 groups ALL of each employee's orders first, then the HAVING
  keeps only employees whose most recent order (MAX(orderdate)) is
  before 2016-05-01 — and for those employees it counts ALL their
  orders, not just the ones before that date.

  So Query 1 = "orders before the date, per employee"; Query 2 =
  "all orders of employees who placed nothing on/after that date".
*/

-- Query 1
SELECT empid, COUNT(*) AS numorders
FROM Sales.Orders
WHERE orderdate < '20160501'
GROUP BY empid;

-- Query 2
SELECT empid, COUNT(*) AS numorders
FROM Sales.Orders
GROUP BY empid
HAVING MAX(orderdate) < '20160501';

---------------------------------------------------------------------
-- 7
-- Three ship countries with the highest average freight
-- for orders placed in 2015
---------------------------------------------------------------------
SELECT TOP (3) shipcountry, AVG(freight) AS avgfreight
FROM Sales.Orders
WHERE orderdate >= '20150101'
  AND orderdate <  '20160101'
GROUP BY shipcountry
ORDER BY avgfreight DESC;

---------------------------------------------------------------------
-- 8
-- Row numbers for orders per customer,
-- ordered by orderdate (orderid as tiebreaker)
---------------------------------------------------------------------
SELECT custid, orderdate, orderid,
       ROW_NUMBER() OVER (PARTITION BY custid
                          ORDER BY orderdate, orderid) AS rownum
FROM Sales.Orders
ORDER BY custid, rownum;

---------------------------------------------------------------------
-- 9
-- Gender from the title of courtesy
---------------------------------------------------------------------
SELECT empid, firstname, lastname, titleofcourtesy,
       CASE
           WHEN titleofcourtesy IN ('Ms.', 'Mrs.') THEN 'Female'
           WHEN titleofcourtesy = 'Mr.'            THEN 'Male'
           ELSE 'Unknown'
       END AS gender
FROM HR.Employees;

---------------------------------------------------------------------
-- 10
-- Customer ID and region, sorted by region with NULLs last
---------------------------------------------------------------------
SELECT custid, region
FROM Sales.Customers
ORDER BY CASE WHEN region IS NULL THEN 1 ELSE 0 END,
         region;

---------------------------------------------------------------------
-- 11
-- All orders placed on the last day of activity in the Orders table
---------------------------------------------------------------------
SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
WHERE orderdate = (SELECT MAX(orderdate) FROM Sales.Orders)
ORDER BY orderid DESC;

---------------------------------------------------------------------
-- 12
-- All orders placed by the customer(s) with the highest number of orders
-- (TOP ... WITH TIES handles the "more than one customer" case)
---------------------------------------------------------------------
SELECT custid, orderid, orderdate, empid
FROM Sales.Orders
WHERE custid IN (
        SELECT TOP (1) WITH TIES custid
        FROM Sales.Orders
        GROUP BY custid
        ORDER BY COUNT(*) DESC
      )
ORDER BY custid, orderid;

---------------------------------------------------------------------
-- 13
-- Employees who did not place orders on or after May 1st, 2016
---------------------------------------------------------------------
SELECT e.empid, e.firstname AS FirstName, e.lastname
FROM HR.Employees AS e
WHERE NOT EXISTS (
        SELECT *
        FROM Sales.Orders AS o
        WHERE o.empid = e.empid
          AND o.orderdate >= '20160501'
      );

---------------------------------------------------------------------
-- 14
-- Countries where there are customers but not employees
---------------------------------------------------------------------
SELECT DISTINCT c.country
FROM Sales.Customers AS c
WHERE c.country NOT IN (SELECT e.country FROM HR.Employees AS e)
ORDER BY c.country;

---------------------------------------------------------------------
-- 15
-- For each customer, all orders placed on that customer's last day of activity
---------------------------------------------------------------------
SELECT custid, orderid, orderdate, empid
FROM Sales.Orders AS o1
WHERE orderdate = (
        SELECT MAX(o2.orderdate)
        FROM Sales.Orders AS o2
        WHERE o2.custid = o1.custid
      )
ORDER BY custid;

---------------------------------------------------------------------
-- 16
-- Customers who placed orders in 2015 but not in 2016
---------------------------------------------------------------------
SELECT c.custid, c.companyname
FROM Sales.Customers AS c
WHERE EXISTS (
        SELECT * FROM Sales.Orders AS o
        WHERE o.custid = c.custid
          AND o.orderdate >= '20150101' AND o.orderdate < '20160101'
      )
  AND NOT EXISTS (
        SELECT * FROM Sales.Orders AS o
        WHERE o.custid = c.custid
          AND o.orderdate >= '20160101' AND o.orderdate < '20170101'
      )
ORDER BY c.custid;

---------------------------------------------------------------------
-- 17
-- Customers who ordered product 12
---------------------------------------------------------------------
SELECT DISTINCT c.custid, c.companyname
FROM Sales.Customers AS c
WHERE EXISTS (
        SELECT *
        FROM Sales.Orders AS o
        JOIN Sales.OrderDetails AS od ON od.orderid = o.orderid
        WHERE o.custid = c.custid
          AND od.productid = 12
      )
ORDER BY c.companyname;

---------------------------------------------------------------------
-- 18
-- Running total qty for each customer and month, using a subquery
---------------------------------------------------------------------
SELECT o1.custid, o1.ordermonth, o1.qty,
       (SELECT SUM(o2.qty)
        FROM Sales.CustOrders AS o2
        WHERE o2.custid = o1.custid
          AND o2.ordermonth <= o1.ordermonth) AS runqty
FROM Sales.CustOrders AS o1
ORDER BY o1.custid, o1.ordermonth;

---------------------------------------------------------------------
-- 19
-- Explain the difference between IN and EXISTS
/*
  IN compares a value against the set of values returned by a subquery
  (or list) and is true when a match is found. EXISTS takes a correlated
  subquery and is true as soon as that subquery returns at least one row,
  so it returns no actual data, just a yes/no.

  The main practical difference is NULL handling: NOT IN against a
  subquery that returns any NULL yields UNKNOWN for every row, so the
  outer query returns nothing — a classic bug. NOT EXISTS is immune to
  that. Performance is usually comparable, as the optimizer often turns
  both into the same semi-/anti-join.
*/

---------------------------------------------------------------------
-- 20
-- Days since the same customer's previous order
-- (orderdate primary sort, orderid as tiebreaker)
---------------------------------------------------------------------
SELECT custid, orderdate, orderid,
       DATEDIFF(day,
                LAG(orderdate) OVER (PARTITION BY custid
                                     ORDER BY orderdate, orderid),
                orderdate) AS diff
FROM Sales.Orders
ORDER BY custid, orderdate, orderid;
GO

/*=====================================================================
  Questions 21–22 — self-contained (do not use TSQLV4 tables).
=====================================================================*/

---------------------------------------------------------------------
-- 21
-- Find the 3 lowest-paid employees who have finished at least 3 projects.
---------------------------------------------------------------------
DROP TABLE IF EXISTS dbo.Projects;
DROP TABLE IF EXISTS dbo.Employee;
GO

CREATE TABLE dbo.Employee (
    ID     INT          NULL,
    Name   NVARCHAR(50) NULL,
    Salary INT          NULL
);
CREATE TABLE dbo.Projects (
    Project_ID  INT NULL,
    Employee_ID INT NULL
);
GO

INSERT INTO dbo.Employee (ID, Name, Salary) VALUES
    (1, N'A', 100), (2, N'B', 50),  (3, N'C', 200), (4, N'D', 150),
    (5, N'E', 30),  (6, N'F', 10),  (7, N'G', 90),  (8, N'H', 180);

INSERT INTO dbo.Projects (Project_ID, Employee_ID) VALUES
    (1,1),(2,3),(3,4),(4,5),(5,6),(6,2),(7,8),(8,7),(9,7),(10,8),(11,4),
    (12,3),(13,1),(14,1),(15,3),(16,4),(17,5),(18,6),(19,7),(20,8),(21,2),(22,5);
GO

-- Answer 21
SELECT TOP (3) e.ID, e.Name, e.Salary
FROM dbo.Employee AS e
JOIN dbo.Projects AS p ON p.Employee_ID = e.ID
GROUP BY e.ID, e.Name, e.Salary
HAVING COUNT(p.Project_ID) >= 3
ORDER BY e.Salary ASC;

---------------------------------------------------------------------
-- 22
-- Find the parents who have both male and female children.
---------------------------------------------------------------------
DROP TABLE IF EXISTS dbo.tblPerson;
GO

SELECT 'A' AS Parent, 'Male'   AS ChildGender INTO dbo.tblPerson
UNION ALL SELECT 'A', 'Male'
UNION ALL SELECT 'A', 'Female'
UNION ALL SELECT 'A', 'Male'
UNION ALL SELECT 'A', 'Female'
UNION ALL SELECT 'B', 'Male'
UNION ALL SELECT 'B', 'Male'
UNION ALL SELECT 'B', 'Male'
UNION ALL SELECT 'C', 'Female'
UNION ALL SELECT 'C', 'Male'
UNION ALL SELECT 'D', 'Male';
GO

-- Answer 22
SELECT Parent
FROM dbo.tblPerson
GROUP BY Parent
HAVING COUNT(DISTINCT ChildGender) = 2
ORDER BY Parent;
GO
