#				                 E-Commerce Customer Churn Analysis   
 
 USE ecomm;
 
 select * from customer_churn 

 ---- Data Cleaning ------ Handling Missing Values and Outliers-----

select round(avg(WarehouseToHome)) from customer_churn;
select round(avg(HourSpendOnApp)) from customer_churn;
select round(avg(OrderAmountHikeFromlastYear)) from customer_churn;
select round(avg(DaySinceLastOrder)) from customer_churn;

 ------- Impute mode for the following columns -----------

set @Tenure_mode=(select Tenure from customer_churn group by Tenure order by count(*) desc limit 1);
select @Tenure_mode; 

set sql_safe_updates=0;
update  customer_churn 
set Tenure=@Tenure_mode
where Tenure is null;

select * from customer_churn;

 set @CouponUsed_mode=(select CouponUsed from customer_churn group by  CouponUsed  order by count(*) desc limit 1);
 select @CouponUsed_mode; 

set sql_safe_updates=0;
update  customer_churn 
set CouponUsed = @CouponUsed_mode
where CouponUsed is null;

select * from customer_churn;

 set @OrderCount=(select OrderCount from customer_churn group by OrderCount order by count(*) desc limit 1);
 select @OrderCount; 

set sql_safe_updates=0;
update  customer_churn 
set OrderCount = @OrderCount
where OrderCount is null;

select * from customer_churn;

------------Handle outliers-----------
delete from customer_churn
where WarehouseToHome >100;

-------------Dealing with Inconsistencies ----------------
update customer_churn
set PreferredLoginDevice = if(PreferredLoginDevice = 'phone','mobile phone',PreferredLoginDevice);

update customer_churn
set PreferedOrderCat = if(PreferedOrderCat = 'mobile','mobile phone',PreferedOrderCat);

------------Standardize payment mode values--------------

update customer_churn
set PreferredPaymentMode = case 
                        when PreferredPaymentMode='COD' then 'Cash On Delivery'
					    when PreferredPaymentMode='CC' then 'Credit Card'
                        else PreferredPaymentMode
                        end ;


---------------Data Transformation----------------
alter table customer_churn
rename column PreferedOrderCat to PreferredOrderCat,
rename column HourSpendOnApp to HoursSpentOnApp; 

---------------Creating New Columns--------------
alter table customer_churn
add column ComplaintReceived enum('yes','no'),
add  column ChurnStatus enum('Active','Inactive');

update customer_churn
set ComplaintReceived=if( Complain=1,'yes','no'),
     ChurnStatus=if(Churn=1,'Active','Inactive');

------------Column Dropping-------------
Alter table customer_churn
drop column Churn,
drop column Complain; 

---------Data Exploration and Analysis----------
-----the count of churned and active customers----
select ChurnStatus ,count(*) as churn_count from customer_churn group by ChurnStatus;

--------average tenure of customers who churned---------
select (avg(Tenure)) as avg_tenure from customer_churn where churn='yes';

----------the total cashback amount earned by customers who churned---
select sum(CashbackAmount) as total_cashback from customer_churn where churn='yes';

---------percentage of churned customers who complained---------
select Churn,concat(round(count(*) / (select count(*) from customer_churn) * 100, 2), '%') as percentage_churn from customer_churn group by churn;

---------the gender distribution of customers who complained-------
select gender, count(*) as gender_complain from customer_churn group by gender;

select CityTier,count(*) / (select count(*) from customer_churn where PreferedOrderCat='Laptop & Accessory')*100 as highestnumber_churnedcustomer 
from customer_churn 
where PreferedOrderCat='Laptop & Accessory'
group by CityTier;

---------Identify the most preferred payment mode among active customers-------
select PreferredPaymentMode, count(*) / (select count(*) from customer_churn where PreferredPaymentMode='Debit Card')*100 as active_customer 
from  customer_churn
where churn=1
group by PreferredPaymentMode;

-----List the preferred login device(s) among customers who took more than 10 days since their last order---------
select PreferredLoginDevice,count(*) as preferredlogin_customer from customer_churn where DaySinceLastOrder>10 group by PreferredLoginDevice;

-------List the number of active customers who spent more than 3 hours on the app-----
select churn ,count(*) as active_customeronapp from customer_churn where churn=1 and HourSpendOnApp>3;

-----------Find the average cashback amount received by customers who spent at least 2 hours on the app----
select HourSpendOnApp, round(avg(CashbackAmount)) as avgcashback_customer from customer_churn where HourSpendOnApp=2;

-----------Display the maximum hours spent on the app by customers in each preferred order category----------

select PreferedOrderCat,(max(HourSpendOnApp)) as maxhoursspent_customer from customer_churn group by PreferedOrderCat;

----------Find the average order amount hike from last year for customers in each marital status category------

select MaritalStatus,round(avg(OrderAmountHikeFromlastYear)) as avg_orderamountcustomer from customer_churn group by  MaritalStatus;
 
-------------Calculate the total order amount hike from last year for customers who are single and prefer mobile phones for ordering---------
select sum(OrderAmountHikeFromlastYear) as total_order_amount_customer from customer_churn 
where MaritalStatus='single' and PreferedOrderCat='mobile';

-------Find the average number of devices registered among customers who used UPI as their preferred payment mode----
select PreferredPaymentMode,(avg(NumberOfDeviceRegistered)) as Avg_UPI_User from customer_churn where PreferredPaymentMode='UPI';

---------Determine the city tier with the highest number of customers---------
select CityTier,count(CustomerID) as highest_numberof_customerid from customer_churn group by CityTier;

----------Find the marital status of customers with the highest number of addresses---------
select count(*) as married_address from customer_churn 
where MaritalStatus='married' and  NumberOfAddress >7;

--------Identify the gender that utilized the highest number of coupons-----------
select Gender ,count(*) as highest_coupen_user from customer_churn where CouponUsed > 8 group by Gender;

--------List the average satisfaction score in each of the preferred order categories--------
select PreferedOrderCat,round(avg(SatisfactionScore)) as avg_satisfaction from customer_churn group by PreferedOrderCat;

---------Calculate the total order count for customers who prefer using credit cards and have the maximum satisfaction score---------
select sum(OrderCount) as ordercountfor_creditcard_user from customer_churn
where PreferredPaymentMode='credit card' and (select max(SatisfactionScore) from customer_churn );

---------How many customers are there who spent only one hour on the app and days since their last order was more than 5?-------
select CustomerID,count(*) as customer_onehoursspent_app from customer_churn 
where HourSpendOnApp= 1 and DaySinceLastOrder >5 group by CustomerID;

---------What is the average satisfaction score of customers who have complained?--------
select round(avg(SatisfactionScore)) as avg_satification_score from customer_churn where Complain='yes'; 

---------How many customers are there in each preferred order category?--------
select PreferedOrderCat,count(*) as customers_PreferedOrderCat from customer_churn group by PreferedOrderCat;

---------What is the average cashback amount received by married customers?---------
select round(avg(CashbackAmount)) as cashback_recevied_marriedcustomers from customer_churn where MaritalStatus='married';

--------What is the average number of devices registered by customers who are not using Mobile Phone as their preferred login device?-------
select round(avg(NumberOfDeviceRegistered)) as avglogin_devices_registerd from customer_churn where PreferredLoginDevice='mobile phone';

----------List the preferred order category among customers who used more than 5 coupons---------
select PreferedOrderCat,count(*) as coupons_used_customer from customer_churn where CouponUsed > 5 group by PreferedOrderCat;

---------List the top 3 preferred order categories with the highest average cashback amount------
select PreferedOrderCat, avg(CashbackAmount) as avgcashback_preferredordercategories from customer_churn group by PreferedOrderCat order by PreferedOrderCat  desc limit 3;

-----------Find the preferred payment modes of customers whose average tenure is 10 months and have placed more than 500 orders-----
select PreferredPaymentMode,count(*) as tenure_placedorder from customer_churn where Tenure=10 and OrderCount > 500 group by PreferredPaymentMode;

----------Categorize customers based on their distance from the warehouse to home such as 'Very Close Distance' for distances <=5km, 'Close Distance' for <=10km,
'Moderate Distance' for <=15km, and 'Far Distance' for >15km. Then, display the churn status breakdown for each distance category---------

 select 
	case
      when WarehouseToHome <=5 then 'Very Close Distance'
      when WarehouseToHome <=10 then 'Close Distance'
      when WarehouseToHome <=10 then 'Moderate Distance' 
      else'Far Distance'
	end as customersbased_distance,
    count(*) as churnstatus_distancecategory
    from customer_churn
    where Churn='yes'
    group by customersbased_distance 
    order by customersbased_distance;


-----------List the customer’s order details who are married, live in City Tier-1, and their
order counts are more than the average number of orders placed by all customers----------

----CTE---Comman Table Expression WITH 
WITH CTE_customer_orders as(
select  MaritalStatus,CityTier, avg(OrderCount) as  avg_customerorders
from customer_churn
where MaritalStatus='married' and CityTier=1
group by MaritalStatus, CityTier)

select MaritalStatus,CityTier,avg_customerorders,
    case 
       when avg_customerorders = (select avg(avg_customerorders) from CTE_customer_orders) then 'Above Average'
       else 'below average or equal average'
    end as avg_customer_oeders
from CTE_customer_orders
order by MaritalStatus,CityTier;

----------a) Create a ‘customer_returns’ table in the ‘ecomm’ database and insert the following data---------
----create table------
create table customer_returns (
ReturnID int primary key,
CustomerID int,
ReturnDate date,
RefundAmount decimal(10,2)
);

insert into customer_returns(ReturnID,CustomerID,ReturnDate,RefundAmount)values
(1001, 50022, '2023-01-01',2130),
(1002 ,50316 ,'2023-01-23', 2000),
(1003 ,51099, '2023-02-14', 2290),
(1004, 52321, '2023-03-08' ,2510),
(1005, 52928 ,'2023-03-20' ,3000),
(1006 ,53749, '2023-04-17', 1740),
(1007, 54206, '2023-04-21' ,3250),
(1008, 54838 ,'2023-04-30', 1990);


---------Display the return details along with the customer details of those who have churned and have made complaints------------
select r.CustomerID,c.Churn,c.Complain from ecomm as e
inner join CustomerID as c
on c.CustomerID=r.CustomerID;

select*from customer_returns;

select * from customer_churn;







