CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'2017-09-22'),
(3,'2017-04-21');

---------------------------------------------------------------------------------------------

CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'2014-09-02'),
(2,'2015-01-15'),
(3,'2014-04-11');

-------------------------------------------------------------------------------------------------------
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'2017-04-19',2),
(3,'2019-12-18',1),
(2,'2020-07-20',3),
(1,'2019-10-23',2),
(1,'2018-03-19',3),
(3,'2016-12-20',2),
(1,'2016-11-09',1),
(1,'2016-05-20',3),
(2,'2017-09-24',1),
(1,'2017-03-11',2),
(1,'2016-03-11',1),
(3,'2016-11-10',1),
(3,'2017-12-07',2),
(3,'2016-12-15',2),
(2,'2017-11-08',2),
(2,'2018-09-10',3);

---------------------------------------------------------------------------------------------------------
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);

-------------------------------------------------------------------------------------------------------------------
select * from sales; 
select * from product;
select * from goldusers_signup;
select * from users;

----------------------------------------------------------------------------------------------------------------------

---- QUS1.) WHAT IS THE TOTAL AMOUNT EACH CUSTOMER SPENT ON ZOMATO
select userid, sum(price) as total_amount from sales as s 
join product as p
on s.product_id = p.product_id
group by userid
order by userid


---- QUS2.) HOW MANY DAYS HAS EACH CUSTOMER VISITED ZOMATO
select userid, count(created_date) as total_cust_visited  from sales
group by userid

---- QUS3.) WHAT WAS THE FIRST PRODUCT PURCHASED BY EACH CUSTOMER
select * from (
	select *, rank() over(partition by userid order by created_date) as rnk
	from sales) a
where rnk = 1 

---- QUS4.) WHAT IS THE MOST PURCHASED ITEM ON THE MENU AND HOW MANY TIMES WAS IT PURCHASED BY ALL CUSTOMERS
select userid, count(product_id) count from sales 
where product_id = 
	(select product_id from sales
	group by product_id
	order by count(*) desc
	limit 1
	)
group by userid ;


---- QUS5.) WHICH ITEM WAS THE MOST POPULAR FOR EACH CUSTOMER
select * from 
(select *, 
		rank() over(partition by userid order by count desc) as rank from 
			(select userid,  product_id, count(product_id) as count from sales
			group by userid,  product_ids) as a ) as b 
where rank = 1


---- QUS.) WHICH ITEM WAS PURCHASED FIRST BY THE CUSTOMER AFTER THEY BECAME A MEMBER
select * from 	
	(select a.*, rank() over(partition by userid order by created_date) rank from 		
			(select s.userid, created_date, product_id, gold_signup_date from sales s
			join goldusers_signup gs
			on s.userid = gs.userid and created_date >= gold_signup_date
			) a 
	) b 
where rank = 1


---- QUS7.) WHICH ITEM WAS PURCHASED JUST BEFORE THE CUSTOMER BECOME A MEMBER
select * from 
(select *, rank() over(partition by userid order by created_date desc) as rank from 
(select s.userid, created_date, product_id, gold_signup_date from sales s join goldusers_signup gs 
 on s.userid = gs.userid and s.created_date <= gs.gold_signup_date
) a ) b
where rank = 1 ;


---- QUS8.) WHAT IS THE TOTAL ORDERS AND AMOUNT SPENT FOR EACH NUMBER BEFORE THEY BECAME A MEMBER

select s.userid, count(s.created_date) as total_orders, sum(price) as spent_amount from product p
join sales s on p.product_id = s.product_id
join users u on u.userid = s.userid
join goldusers_signup gs on s.userid = gs.userid
where s.created_date <= gs.gold_signup_date
group by s.userid 

---- QUS9.) IF BUYING EACH PRODUCT GENERATES POINTS FOR eg 5RS=2 AND EACH PRODUCT HAS DIFFERENT PURCHASING POINTS FOR eg 
---- FOR P1 5RS=1 ZOMATO POINT, FOR P2 10RS=5 ZOMATO POINT AND P3 5RS=1 ZOMATO POINT. 
---- CALCULATE POINTS COLLECTED BY EACH CUSTOMERS AND FOR WHICH PRODUCT MOST POINTS HAVE BEEN GIVEN TILLL NOW. 
--- Part 1.
select userid, sum(total_points)*2.5 as total_cashback from
		(select c.*, total_price/points as total_points from
			(select b.*, case
			when product_id = 1 then 5
			when product_id = 2 then 2
			when product_id = 3 then 5
			else 0 end as points from
				(select userid, product_id, sum(price) as total_price from
					(select s.*, p.price from product p join sales s on p.product_id = s.product_id) a
				group by userid, product_id
				order by userid, product_id
				) b) c) d
group by userid

--- Part 2.FOR WHICH PRODUCT MOST POINTS HAVE BEEN GIVEN TILLL NOW.
select * from 
	(select *, rank() over(order by total_points_earned desc) rank	from
		(select product_id, sum(total_points) as total_points_earned from
				(select c.*, total_price/points as total_points from
					(select b.*, case
					when product_id = 1 then 5
					when product_id = 2 then 2
					when product_id = 3 then 5
					else 0 end as points from
						(select userid, product_id, sum(price) as total_price from
							(select s.*, p.price from product p join sales s on p.product_id = s.product_id) a
						group by userid, product_id
						order by userid, product_id
						) b) c) d
		group by product_id
		order by product_id)e)f
where rank = 1


---- QUS10.) IN THE FIRST ONE YEAR AFTER A CUSTOMER JOINS THE GOLD PROGRAM (INCLUDING THEIR JOIN DATE) IRRESPECTIVE OF WHAT THE 
---- CUSTOMER HAS PURCHASED THEY EARN 5 ZOMATO POINTS FOR EVERY 10RS SPENT WHO EARNED MORE 1 OR 3 AND WHAT WAS THEIR POINTS 
---- EARNING IN THEIR FIRST YEAR
select a.*, p.price * 0.5 total_points_earned from	
	(select s.userid, created_date, product_id, gold_signup_date from sales s 
	join goldusers_signup gs on s.userid = gs.userid 
	and created_date >= gold_signup_date and created_date <= gold_signup_date + INTERVAL '1 year')a
join product p on a.product_id = p.product_id


---- QUS11.) RANK ALL THE TRANSACTION OF THE CUSTOMERS
select *, 
rank() over(partition by userid order by created_date) rank
from sales

--- QUS12.) RANK ALL THE TRANSACTION FOR EACH MEMBER WHENEVER THEY ARE A ZOMATO GOLD MEMBER FOR EVERY NON GOLD MEMBER TRANSACTION MARK AS NA 
select a.*,
case
when gold_signup_date is null then 'na' 
else	
cast(rank() over(partition by userid order by created_date) as varchar) end rank from
		(select s.userid, created_date, product_id, gold_signup_date from sales s 
		left join goldusers_signup gs on s.userid = gs.userid 
		and created_date >= gold_signup_date
		) a





