# TSQLV4 Exercises (1–22)

Answers to the 22 T-SQL exercises in `exercises.sql`.

- **Q1–20** run against the **TSQLV4** sample database.
- **Q21–22** are self-contained — the required tables (DDL + data) are created inside the script.
- **Q6** and **Q19** are explanation questions, answered as inline comments.

## Run

Open `exercises.sql` in SSMS / Azure Data Studio against a server that has the
TSQLV4 database, and execute. Q21–22 drop and recreate their own tables, so the
script is safe to re-run.

## Highlights
- Q2/Q11/Q15 use `EOMONTH` / correlated `MAX(orderdate)` for "last day" logic.
- Q5 forces `COLLATE Latin1_General_CS_AS` for the case-sensitive match.
- Q12 uses `TOP (1) WITH TIES` so ties on order count are all returned.
- Q20 uses `LAG(...)` for the gap to the customer's previous order.
