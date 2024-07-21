-- Loan History
-- Select all records from the table 'financial4_55.loan'
select * from financial4_55.loan;
-- Select and aggregate data from the table 'financial4_55.loan'
select
    extract(year from date) as loan_year,   -- Extract the year from the 'date' column and alias it as 'loan_year'
    extract(quarter from date) as loan_quarter, -- Extract the quarter from the 'date' column and alias it as 'loan_quarter'
    extract(month from date) as loan_month, -- Extract the month from the 'date' column and alias it as 'loan_month'
    sum(amount) as loans_total,   -- Calculate the sum of the 'amount' column and alias it as 'loans_total'
    avg(amount) as loans_avg,     -- Calculate the average of the 'amount' column and alias it as 'loans_avg'
    count(amount) as loans_count  -- Count the number of records in the 'amount' column and alias it as 'loans_count'
from financial4_55.loan
group by 1, 2, 3 with rollup  -- Group by year, quarter, and month and use ROLLUP to include subtotals and grand total
order by 1, 2, 3;  -- Order the results by year, quarter, and month

--Loan Status
-- Query to count the number of loans for each status and order them by status
select
    status,                           -- Select the status column
    count(status) as amount           -- Count the number of occurrences of each status and alias it as 'amount'
from financial4_55.loan
group by 1                            -- Group by the status column (referenced by its position in the SELECT list)
order by 1;                           -- Order the results by the status column

-- Account Analysis
with cte as (
    select
        account_id,                        -- Select the account_id column
        count(amount) as number_of_loans,  -- Count the number of loans for each account_id and alias it as 'number_of_loans'
        sum(amount) as amount_of_loans,    -- Sum the amount of loans for each account_id and alias it as 'amount_of_loans'
        avg(amount) as average_amount      -- Calculate the average amount of loans for each account_id and alias it as 'average_amount'
    from financial4_55.loan
    where status = 'A' or status = 'C'     -- Filter the rows where the status is 'A' or 'C'
    group by 1                             -- Group by the account_id column (referenced by its position in the SELECT list)
)
select
    *,                                    -- Select all columns from the CTE
    row_number() over (order by amount_of_loans desc) as rank_loans_amount,  -- Add a row number column ordered by amount_of_loans in descending order and alias it as 'rank_loans_amount'
    row_number() over (order by number_of_loans desc) as rank_loans_count    -- Add a row number column ordered by number_of_loans in descending order and alias it as 'rank_loans_count'
from cte;                                 -- Select from the common table expression (CTE)

-- Query to get the total amount of repaid loans grouped by gender
select
    c.gender as gender,          -- Select the gender column from the client table and alias it as 'gender'
    sum(l.amount) as amount      -- Sum the amount column from the loan table and alias it as 'amount'
from financial4_55.loan as l
    -- Inner join the loan table with the account table on the account_id column
    inner join financial4_55.account as a
        on l.account_id = a.account_id
    -- Inner join the account table with the disp (disposition) table on the account_id column
    inner join financial4_55.disp as d
        on a.account_id = d.account_id
    -- Inner join the disp table with the client table on the client_id column
    inner join financial4_55.client as c
        on d.client_id = c.client_id
where l.status in ('A', 'C')  -- Filter the loans to include only those with status 'A' or 'C' (repaid loans)
group by 1;  -- Group the results by gender (referenced by its position in the SELECT list)

-- Select all records from the table 'financial4_55.disp'
select * from financial4_55.disp;

-- Drop the temporary table 'tmp_results' if it exists
drop table if exists tmp_results;

-- Create a temporary table 'tmp_results' with the aggregated results
create temporary table tmp_results as
    select
        c.gender as gender,          -- Select the gender column from the client table and alias it as 'gender'
        sum(l.amount) as amount      -- Sum the amount column from the loan table and alias it as 'amount'
    from financial4_55.loan as l
        -- Inner join the loan table with the account table on the account_id column
        inner join financial4_55.account as a
            on l.account_id = a.account_id
        -- Inner join the account table with the disp (disposition) table on the account_id column
        inner join financial4_55.disp as d
            on a.account_id = d.account_id
        -- Inner join the disp table with the client table on the client_id column
        inner join financial4_55.client as c
            on d.client_id = c.client_id
    where True  -- Always true, used to simplify adding multiple conditions
    and status in ('A', 'C')  -- Filter the loans to include only those with status 'A' or 'C' (repaid loans)
    and d.type = 'OWNER'  -- Filter to include only records where the disposition type is 'OWNER'
    group by 1;  -- Group the results by gender (referenced by its position in the SELECT list)


with cte as (
    select sum(amount) as amount   -- Calculate the sum of the amount column and alias it as 'amount'
    from financial4_55.loan as l
    where l.status in ('A','C')    -- Filter the loans to include only those with status 'A' or 'C' (repaid loans)
)
select (select sum(amount) from tmp_results) - (select amount from cte);  -- Subtract the sum from the CTE from the sum in tmp_results

-- Customer Analysis
select
    c.gender as gender,                            -- Select the gender column from the client table and alias it as 'gender'
    2021 - extract(year from c.birth_date) as age, -- Calculate the age by subtracting the year of birth from 2021 and alias it as 'age'
    sum(l.amount) as amount,                       -- Sum the amount column from the loan table and alias it as 'amount'
    count(l.amount) as loans_count                 -- Count the number of occurrences of the amount column and alias it as 'loans_count'
from financial4_55.loan as l
    -- Inner join the loan table with the account table on the account_id column
    inner join financial4_55.account as a
        on l.account_id = a.account_id
    -- Inner join the account table with the disp (disposition) table on the account_id column
    inner join financial4_55.disp as d
        on a.account_id = d.account_id
    -- Inner join the disp table with the client table on the client_id column
    inner join financial4_55.client as c
        on d.client_id = c.client_id
where True  -- Always true, used to simplify adding multiple conditions
    and l.status in ('A', 'C')  -- Filter the loans to include only those with status 'A' or 'C' (repaid loans)
    and d.type = 'OWNER'  -- Filter to include only records where the disposition type is 'OWNER'
group by 1, 2;  -- Group the results by gender and age (referenced by their positions in the SELECT list)

-- Drop the temporary table 'tmp_analysis' if it exists
drop table if exists tmp_analysis;

-- Create a temporary table 'tmp_analysis' with the aggregated results
create temporary table tmp_analysis as
select
    c.gender as gender,                            -- Select the gender column from the client table and alias it as 'gender'
    2021 - extract(year from c.birth_date) as age, -- Calculate the age by subtracting the year of birth from 2021 and alias it as 'age'
    sum(l.amount) as amount,                       -- Sum the amount column from the loan table and alias it as 'amount'
    count(l.amount) as loans_count                 -- Count the number of occurrences of the amount column and alias it as 'loans_count'
from financial4_55.loan as l
    -- Inner join the loan table with the account table on the account_id column
    inner join financial4_55.account as a
        on l.account_id = a.account_id
    -- Inner join the account table with the disp (disposition) table on the account_id column
    inner join financial4_55.disp as d
        on a.account_id = d.account_id
    -- Inner join the disp table with the client table on the client_id column
    inner join financial4_55.client as c
        on d.client_id = c.client_id
where True  -- Always true, used to simplify adding multiple conditions
    and l.status in ('A', 'C')  -- Filter the loans to include only those with status 'A' or 'C' (repaid loans)
    and d.type = 'OWNER'  -- Filter to include only records where the disposition type is 'OWNER'
group by 1, 2;  -- Group the results by gender and age (referenced by their positions in the SELECT list)

-- Query to get the total number of loans from the temporary table
select sum(loans_count) from tmp_analysis;

select
    gender,                               -- Select the gender column
    sum(loans_count) as loans_count       -- Calculate the sum of the 'loans_count' column and alias it as 'loans_count'
from tmp_analysis                        -- Use the temporary table 'tmp_analysis'
group by 1;                             -- Group the results by gender (referenced by its position in the SELECT list)

select
    gender,                               -- Select the gender column
    avg(age) as age                       -- Calculate the average age and alias it as 'age'
from tmp_analysis                        -- Use the temporary table 'tmp_analysis'
group by 1;                             -- Group the results by gender (referenced by its position in the SELECT list)

select
    d2.district_id,                      -- Select the district_id from the district table
    count(distinct c.client_id) as customer_amount,  -- Count the number of distinct clients and alias it as 'customer_amount'
    sum(l.amount) as loans_given_amount,  -- Sum the amount of loans given and alias it as 'loans_given_amount'
    count(l.amount) as loans_given_count  -- Count the number of loans and alias it as 'loans_given_count'
from financial4_55.loan as l
    -- Inner join the loan table with the account table on the account_id column
    inner join financial4_55.account as a
        on l.account_id = a.account_id
    -- Inner join the account table with the disp (disposition) table on the account_id column
    inner join financial4_55.disp as d
        on a.account_id = d.account_id
    -- Inner join the disp table with the client table on the client_id column
    inner join financial4_55.client as c
        on d.client_id = c.client_id
    -- Inner join the account table with the district table on the district_id column
    inner join financial4_55.district as d2
        on a.district_id = d2.district_id
where True
    and l.status in ('A', 'C')  -- Filter the loans to include only those with status 'A' or 'C' (repaid loans)
    and d.type = 'OWNER'        -- Filter to include only records where the disposition type is 'OWNER'
group by 1;                     -- Group the results by district_id (referenced by its position in the SELECT list)

-- Drop the temporary table 'tmp_district_analytics' if it exists
drop table if exists tmp_district_analytics;

-- Create a temporary table 'tmp_district_analytics' with aggregated district-level data
create temporary table tmp_district_analytics as
    select
        d2.district_id,                           -- Select the district_id from the district table
        count(distinct c.client_id) as customer_amount,  -- Count the number of distinct clients and alias it as 'customer_amount'
        sum(l.amount) as loans_given_amount,      -- Sum the amount of loans given and alias it as 'loans_given_amount'
        count(l.amount) as loans_given_count      -- Count the number of loans and alias it as 'loans_given_count'
    from financial4_55.loan as l
        -- Inner join the loan table with the account table on the account_id column
        inner join financial4_55.account as a
            on l.account_id = a.account_id
        -- Inner join the account table with the disp (disposition) table on the account_id column
        inner join financial4_55.disp as d
            on a.account_id = d.account_id
        -- Inner join the disp table with the client table on the client_id column
        inner join financial4_55.client as c
            on d.client_id = c.client_id
        -- Inner join the account table with the district table on the district_id column
        inner join financial4_55.district as d2
            on a.district_id = d2.district_id
    where True
        and l.status in ('A', 'C')  -- Filter the loans to include only those with status 'A' or 'C' (repaid loans)
        and d.type = 'OWNER'  -- Filter to include only records where the disposition type is 'OWNER'
    group by 1;  -- Group the results by district_id (referenced by its position in the SELECT list)

-- Select all columns from 'tmp_district_analytics' and order by the number of customers in descending order
select
    *
from tmp_district_analytics
order by customer_amount desc  -- Sort by 'customer_amount' in descending order
limit 1;  -- Limit the result to the top 1 row


-- Select all columns from 'tmp_district_analytics' and order by the number of loans given in descending order
select
    *
from tmp_district_analytics
order by loans_given_count desc  -- Sort by 'loans_given_count' in descending order
limit 1;  -- Limit the result to the top 1 row

-- Select all columns from 'tmp_district_analytics' and order by the total amount of loans given in descending order
select
    *
from tmp_district_analytics
order by loans_given_amount desc  -- Sort by 'loans_given_amount' in descending order
limit 1;  -- Limit the result to the top 1 row

-- Common Table Expression (CTE) to calculate the total number of clients, total amount of loans, and count of loans for each district
with cte as (
    select
        d2.district_id,                          -- Select the district_id from the district table
        count(distinct c.client_id) as customer_amount,  -- Count the number of distinct clients and alias it as 'customer_amount'
        sum(l.amount) as loans_given_amount,     -- Sum the amount of loans given and alias it as 'loans_given_amount'
        count(l.amount) as loans_given_count     -- Count the number of loans and alias it as 'loans_given_count'
    from financial4_55.loan as l
        -- Inner join the loan table with the account table on the account_id column
        inner join financial4_55.account as a
            on l.account_id = a.account_id
        -- Inner join the account table with the disp (disposition) table on the account_id column
        inner join financial4_55.disp as d
            on a.account_id = d.account_id
        -- Inner join the disp table with the client table on the client_id column
        inner join financial4_55.client as c
            on d.client_id = c.client_id
        -- Inner join the account table with the district table on the district_id column
        inner join financial4_55.district as d2
            on a.district_id = d2.district_id
    where True
        and l.status in ('A', 'C')   -- Filter to include only records with status 'A' or 'C' (repaid loans)
        and d.type = 'OWNER'        -- Filter to include only records where the disposition type is 'OWNER'
    group by 1                     -- Group by district_id (referenced by its position in the SELECT list)
)
-- Select all columns from the CTE and calculate the percentage share of each district's loan amount in the total amount of loans
select *,
       (loans_given_amount / sum(loans_given_amount) over ()) * 100 as percentage_share  -- Calculate the percentage share of each district's loan amount
from cte
order by percentage_share desc;  -- Order the results by the percentage share in descending order


-- Select client information and filter based on balance and number of loans
select
    c.client_id,                              -- Select the client_id
    sum(amount - payments) as client_balance, -- Calculate the client's balance (total amount minus payments) and alias it as 'client_balance'
    count(loan_id) as loans_amount            -- Count the number of loans associated with the client and alias it as 'loans_amount'
from financial4_55.loan as l
    -- Inner join the loan table with the account table on the account_id column
    inner join financial4_55.account as a
        on l.account_id = a.account_id
    -- Inner join the account table with the disp (disposition) table on the account_id column
    inner join financial4_55.disp as d
        on a.account_id = d.account_id
    -- Inner join the disp table with the client table on the client_id column
    inner join financial4_55.client as c
        on d.client_id = c.client_id
    -- Inner join the account table with the district table on the district_id column
    inner join financial4_55.district as d2
        on a.district_id = d2.district_id
where True
    and l.status in ('A', 'C')  -- Filter to include only records with status 'A' or 'C' (repaid loans)
    and d.type = 'OWNER'       -- Filter to include only records where the disposition type is 'OWNER'
    -- and extract(year from c.birth_date) > 1990  -- Optional filter: include only clients born after 1990
group by 1
having
    sum(amount - payments) > 1000  -- Filter to include only clients with a balance greater than 1000
    -- and count(loan_id) > 5       -- Optional filter: include only clients with more than 5 loans
order by loans_amount desc;      -- Order the results by the number of loans in descending order

create table financial4_55.cards_at_expiration
(
    client_id       int                      not null,                -- Unique identifier for the client
    card_id         int default 0            not null,                -- Unique identifier for the card
    expiration_date date                     null,                    -- Expiration date of the card
    A3              varchar(15) charset utf8 not null,                -- Address field (assuming this is a specific field for address in UTF-8 encoding)
    generated_for_date date                     null                  -- Date when the report was generated
);

delimiter $$
drop procedure if exists financial4_55.generate_cards_at_expiration_report;
create procedure financial4_55.generate_cards_at_expiration_report (p_date DATE)
begin
    -- Clear the table before inserting new data
    truncate table financial4_55.cards_at_expiration;

    -- Insert new data into the cards_at_expiration table
    insert into financial4_55.cards_at_expiration
    with cte as (
        -- Common Table Expression (CTE) to compute card expiration dates
        select
            c2.client_id as client_id,                     -- Client ID
            c.card_id as card_id,                         -- Card ID
            date_add(c.issued, interval 3 year) as expiration_date,  -- Compute expiration date as 3 years after card issuance
            d2.A3 as customer_address                     -- Address from the district table
        from financial4_55.card as c
            inner join financial4_55.disp d on c.disp_id = d.disp_id  -- Join with disposition table
            inner join financial4_55.client c2 on d.client_id = c2.client_id  -- Join with client table
            inner join financial4_55.district d2 on c2.district_id = d2.district_id  -- Join with district table
    )
    -- Select data from the CTE and insert into the target table
    select
        *,
        p_date
    from cte
    where p_date between date_add(expiration_date, interval -7 day) and expiration_date;
end $$

-- Call the procedure with a specific date
call financial4_55.generate_cards_at_expiration_report('2001-01-01');

-- Select all records from the cards_at_expiration table to view the results
select * from financial4_55.cards_at_expiration;
