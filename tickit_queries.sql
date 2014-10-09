

different join syntaxes
case statements
regexp
self referencing query
exploding joins
coalesce
nvl

---------------------------
-- NAVIGATING POSTGRESQL --
---------------------------

-- list databases
\l 

-- create database
create database tickit;

-- connect to database
\c tickit


----------------------
-- SET UP TEST DATA -- 
----------------------

-- create tables
create table users(
  userid integer not null,
  username char(8),
  firstname varchar(30),
  lastname varchar(30),
  city varchar(30),
  state char(2),
  email varchar(100),
  phone char(14),
  likesports varchar(1),
  liketheatre varchar(1),
  likeconcerts varchar(1),
  likejazz varchar(1),
  likeclassical varchar(1),
  likeopera varchar(1),
  likerock varchar(1),
  likevegas varchar(1),
  likebroadway varchar(1),
  likemusicals varchar(1));

create table venue(
  venueid smallint not null,
  venuename varchar(100),
  venuecity varchar(30),
  venuestate char(2),
  venueseats integer);

create table category(
  catid smallint not null,
  catgroup varchar(10),
  catname varchar(10),
  catdesc varchar(50));

create table date(
  dateid smallint not null,
  caldate date not null,
  day character(3) not null,
  week smallint not null,
  month character(5) not null,
  qtr character(5) not null,
  year smallint not null,
  holiday boolean default('N'));

create table event(
  eventid integer not null,
  venueid smallint not null,
  catid smallint not null,
  dateid smallint not null,
  eventname varchar(200),
  starttime timestamp);

create table listing(
  listid integer not null,
  sellerid integer not null,
  eventid integer not null,
  dateid smallint not null,
  numtickets smallint not null,
  priceperticket decimal(8,2),
  totalprice decimal(8,2),
  listtime timestamp);

create table sales(
  salesid integer not null,
  listid integer not null,
  sellerid integer not null,
  buyerid integer not null,
  eventid integer not null,
  dateid smallint not null,
  qtysold smallint not null,
  pricepaid decimal(8,2),
  commission decimal(8,2),
  saletime timestamp);


-- load data from file into database using the 'copy' command
copy users from '<file directory>/users.txt' delimiter '|';
copy venue from '<file directory>/venue.txt' delimiter '|';
copy category from '<file directory>/category.txt' delimiter '|';
copy date from '<file directory>/date.txt' delimiter '|';
copy event from '<file directory>/event.txt' delimiter '|';
copy listing from '<file directory>/listing.txt' delimiter '|';
copy sales from '<file directory>/sales.txt' delimiter '|';


-- show all tables in database
\dt

-- describe table
\d+ sales



--------------------
-- SELECTING DATA --
--------------------

-- SELECT
-- basic select
select * from category;

-- use control-c to stop the scrolling
select * from users;

-- limit number of rows
select * from users 
limit 10;

-- limit number of columns and rows
select userid, username, firstname, lastname, city, state, email, phone
from users
limit 10;

-- select with conditions
select * 
from sales
where qtysold = 1
limit 10;

select userid, username, firstname, lastname, city, state, email, phone
from users
where state = 'NY';

select userid, username, firstname, lastname, city, state, email, phone
from users
where state in ('NY', 'CA', 'OR');



-- REGEXP
-- use regexp to parse out area codes

select userid, username, firstname, lastname, city, state, email, phone
from users
where phone like '(809)%';


select userid, username, firstname, lastname, city, state, email, phone,
  substring(phone from '\((.*)\)') as areacode
from users
limit 10;


-- DATE_PART
-- use case
-- create charts by different date dimensions
-- dow is useful for segmenting time series data by day of week to account for fluctuations through the week 
select s.*, 
  date_part('year', s.saletime) as sale_year, 
  date_part('quarter', s.saletime) as sale_quarter, 
  date_part('month', s.saletime) as sale_month, 
  date_part('week', s.saletime) as sale_week, 
  date_part('dow', s.saletime) as sale_dow 
from sales s
limit 10;

-- aggregation functions (count, sum, max, min)
select count(*) from users;

select count(*) from sales;

select count(distinct state) from users;

select sum(qtysold) from sales;

select sum(qtysold) as total_sold, sum(pricepaid) as total_sales_amount, sum(commission) as total_commission
from sales;

-- GROUP BY SALES BY MONTH

select state, count(userid) as users
from users
group by state
order by state asc;

select state, count(userid) as users
from users
group by state
order by 2 desc;

select date_part('year', saletime) as year, 
      date_part('month', saletime) as month,
      sum(pricepaid) as total_sales_amount
from sales
group by 1,2;

select date_part('year', saletime) as year, 
      date_part('month', saletime) as month,
      count(salesid) as total_sales
from sales
group by 1,2;

-- GROUP BY HAVING

select buyerid, count(salesid) as purchases
from sales
group by 1
having count(salesid) = 1;


-- INNER JOIN SYNTAX
select s.*, e.*
from sales s, event e
where s.eventid = e.eventid;

select s.*, e.*
from sales s inner join event e
on s.eventid = e.eventid
limit 10;;

select *
from sales s, listing l
where s.listid = l.listid
  and s.listid = 8942;


-- OUTER JOIN
select u.userid, count(s.salesid) as num_sales
from users u 
  left join sales s on u.userid = s.sellerid
group by 1
having count(s.salesid) < 1;


select u.userid, count(s.salesid) as num_sales
from users u 
  inner join sales s on u.userid = s.sellerid
group by 1
having count(s.salesid) < 1;


-- INSERT
insert into venue (venueid, venuename, venuecity, venuestate, venueseats) 
  VALUES (1001, 'Podunk Stadium', 'Podunk', 'CA', 100);

insert into venue (venueid, venuename, venuecity, venuestate, venueseats) 
  VALUES (1001, 'Weedly Backyard', 'Weedly', 'NY', 10);



-- SUBQUERY
select count(tmp.*)
from (select buyerid, count(salesid) as purchases
      from sales
      group by 1
      having count(salesid) = 1) as tmp;

-- WINDOW FUNCTION
select s.*, rank() over (partition by s.buyerid order by s.saletime asc) as user_order_num
from sales s;

select tmp.*
from (select s.*, rank() over (partition by s.buyerid order by s.saletime asc) as user_order_num
      from sales s) as tmp
where tmp.user_order_num = 1;

-- OVERCOUNTING ORDERS
-- attribution pitfall. multiple channels associated with one order



-- CASE statements
select 