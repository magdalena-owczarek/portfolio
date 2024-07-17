#Loan History
select * from financial4_55.loan;
select
    extract(year from date) as loan_year,
    extract(quarter from date) as loan_quarter,
    extract(month from date) as loan_month,
    sum(amount) as loans_total,
    avg(amount) as loans_avg,
    count(amount) as loans_count
from financial4_55.loan
group by 1,2,3 with rollup
order by 1,2,3;

#Loan Status
select
    status,
    count(status) as amount
from financial4_55.loan
group by 1
order by 1;

#Account Analysis
with cte as (
select
    account_id,
    count(amount) as number_of_loans,
    sum(amount) as amount_of_loans,
    avg(amount) as average_amount
    from financial4_55.loan
where status = "A" or status = "C"
group by 1
)
select
    *,
    row_number() over (order by amount_of_loans desc) as rank_loans_amount,
    row_number() over (order by number_of_loans desc) as rank_loans_count
from cte;

#Repaid Loans
select
    c.gender as gender,
    sum(l.amount) as amount
from financial4_55.loan as l
    inner join financial4_55.account a
        on l.account_id = a.account_id
    inner join financial4_55.disp d
        on a.account_id = d.account_id
    inner join financial4_55.client c
        on d.client_id = c.client_id
where status in ('A', 'C')
group by 1;

select * from financial4_55.disp;

drop table if exists tmp_results;

create temporary table tmp_results as
    select
        c.gender as gender,
        sum(l.amount) as amount
    from financial4_55.loan as l
        inner join financial4_55.account a
            on l.account_id = a.account_id
    inner join financial4_55.disp d
            on a.account_id = d.account_id
    inner join financial4_55.client c
            on d.client_id = c.client_id
    where True
    and status in ('A', 'C')
    and d.type = 'OWNER'
    group by 1;

with cte as (
    select sum(amount) as amount
    from financial4_55.loan as l
    where l.status in ('A','C')
)
select (select sum(amount) from tmp_results) - (select amount from cte);

# Customer Analysis
select
    c.gender as gender,
    2021 - extract(year from c.birth_date) as age,
    sum(l.amount) as amount,
    count(l.amount) as loans_count
from financial4_55.loan as l
    inner join financial4_55.account a
        on l.account_id = a.account_id
    inner join financial4_55.disp d
        on a.account_id = d.account_id
    inner join financial4_55.client c
        on d.client_id = c.client_id
where True
    and status in ('A', 'C')
    and d.type = 'OWNER'
group by 1,2;

drop table if exists tmp_analysis;

create temporary table tmp_analysis as
select
     c.gender as gender,
    2021 - extract(year from c.birth_date) as age,
    sum(l.amount) as amount,
    count(l.amount) as loans_count
from financial4_55.loan as l
    inner join financial4_55.account a
        on l.account_id = a.account_id
    inner join financial4_55.disp d
        on a.account_id = d.account_id
    inner join financial4_55.client c
        on d.client_id = c.client_id
where True
    and status in ('A', 'C')
    and d.type = 'OWNER'
group by 1,2;

select sum(loans_count) from tmp_analysis;

select
    gender,
    sum(loans_count) as loans_count
from tmp_analysis
group by 1;

select
    gender,
    avg(age) as age
from tmp_analysis
group by 1

select
    d2.district_id,
    count(distinct c.client_id) as customer_amount,
    sum(l.amount) as loans_given_amount,
    count(l.amount) as loans_given_count
from financial4_55.loan as l
    inner join financial4_55.account a
        on l.account_id = a.account_id
    inner join financial4_55.disp d
        on a.account_id = d.account_id
    inner join financial4_55.client c
        on d.client_id = c.client_id
    inner join financial4_55.district d2
        on a.district_id = d2.district_id
where True
    and status in ('A', 'C')
    and d.type = 'OWNER'
group by 1;

drop table if exists tmp_district_analytics;
create temporary table tmp_district_analytics as
    select
    d2.district_id,
    count(distinct c.client_id) as customer_amount,
    sum(l.amount) as loans_given_amount,
    count(l.amount) as loans_given_count
from financial4_55.loan as l
    inner join financial4_55.account a
        on l.account_id = a.account_id
    inner join financial4_55.disp d
        on a.account_id = d.account_id
    inner join financial4_55.client c
        on d.client_id = c.client_id
    inner join financial4_55.district d2
        on a.district_id = d2.district_id
where True
    and status in ('A', 'C')
    and d.type = 'OWNER'
group by 1;

#Region with the most customers
select
    *
from tmp_district_analytics
order by customer_amount desc
limit 1;

#Region where the highest number of loans has been repaid quantitatively.
select
    *
from tmp_district_analytics
order by loans_given_count desc
limit 1;

#Region with the most loans repaid by amount
select
    *
from tmp_district_analytics
order by loans_given_amount desc
limit 1;

#Percentage share of each region in the total amount of loans granted
with cte as(
 select
    d2.district_id,
    count(distinct c.client_id) as customer_amount,
    sum(l.amount) as loans_given_amount,
    count(l.amount) as loans_given_count
from financial4_55.loan as l
    inner join financial4_55.account a
        on l.account_id = a.account_id
    inner join financial4_55.disp d
        on a.account_id = d.account_id
    inner join financial4_55.client c
        on d.client_id = c.client_id
    inner join financial4_55.district d2
        on a.district_id = d2.district_id
where True
    and status in ('A', 'C')
    and d.type = 'OWNER'
group by 1)
select *,
       (loans_given_amount / sum(loans_given_amount) over ())*100 as percentage_share
from cte
order by percentage_share desc;

#Customer Selection
select
    c.client_id,
    sum(amount - payments) as client_balance,
    count(loan_id) as loans_amount
from financial4_55.loan as l
    inner join financial4_55.account a
        on l.account_id = a.account_id
    inner join financial4_55.disp d
        on a.account_id = d.account_id
    inner join financial4_55.client c
        on d.client_id = c.client_id
    inner join financial4_55.district d2
        on a.district_id = d2.district_id
where True
    and status in ('A', 'C')
    and d.type = 'OWNER'
    #and extract(year from c.birth_date) > 1990
group by 1
having
     sum(amount - payments) > 1000
     #and count(loan_id) > 5
order by loans_amount desc;

# Procedure - expiring cards
create table financial4_55.cards_at_expiration
(
    client_id       int                      not null,
    card_id         int default 0            not null,
    expiration_date date                     null,
    A3              varchar(15) charset utf8 not null,
    generated_for_date date                     null
);

delimiter $$
drop procedure if exists financial4_55.generate_cards_at_expiration_report;
create procedure financial4_55.generate_cards_at_expiration_report (p_date DATE)
begin
    truncate table financial4_55.cards_at_expiration;
    insert into financial4_55.cards_at_expiration
    with cte as (
        select c2.client_id as client_id,
                c.card_id as card_id,
                date_add(c.issued, interval 3 year) as expiration_date,
                d2.A3 as customer_address
        from financial4_55.card as c
                inner join
        financial4_55.disp d on c.disp_id = d.disp_id
                inner join
        financial4_55.client c2 on d.client_id = c2.client_id
                inner join
        financial4_55.district d2 on c2.district_id = d2.district_id
    )
    select
        *,
        p_date
    from cte
    where p_date between date_add(expiration_date, interval -7 day) and expiration_date;
    end $$;

call financial4_55.generate_cards_at_expiration_report('2001-01-01');
select * from financial4_55.cards_at_expiration
