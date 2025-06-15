# selects data_scientist_project database to use
use data_scientist_project;

# shows tables present in selected database
show tables;

#                                                  Data Preparation with SQL – Creating a View
# I. Calculating a Subscription’s End Date

# displays data present in student_purchases table
select * from student_purchases;
# creates column date_end by adding 1,3,12 months based on plan_id where  0 = monthly, 1 = Quarterly, 2 = Annual, 3 = Life-time (value should be null). 
select purchase_id,student_id,plan_id, date_purchased as date_start,case when plan_id=0 then date_add(date_purchased, interval 1 month) when plan_id=1 then date_add(date_purchased, interval 1 quarter) when plan_id=2 then date_add(date_purchased, interval 12 month) when plan_id=3 then null end as date_end from student_purchases;

# II. Re-Calculating a Subscription’s End Date

# Recalculating date_end column using date_refunded field if an order was refunded the date-end should be same as refund date.
select purchase_id,student_id,plan_id,date_refunded,date_start,if (date_refunded is null, date_end,date_refunded) as date_end from (select purchase_id,student_id,plan_id, date_purchased as date_start,case when plan_id=0 then date_add(date_purchased, interval 1 month) when plan_id=1 then date_add(date_purchased, interval 1 quarter) when plan_id=2 then date_add(date_purchased, interval 12 month) when plan_id=3 then null end as date_end,date_refunded from student_purchases)a;

# III. Creating Two ‘paid’ Columns and a MySQL View

# drops the view purchase_info if it exists in database
drop view if exists purchase_info;
# creates view and two new columns (paid_q2_2021,paid_q2_2021) based on condition where year should be 2021 & 2022 of quarter 2 which is indicated by 1 else 0
create view purchase_info as select purchase_id,student_id,plan_id,date_start,date_end,case when ( date_start >= '2021-04-01' and (date_end <= '2021-06-30' or (date_end is null and date_start between '2021-04-01' and '2021-06-30'))) then 1 else 0 end as paid_q2_2021,case when (date_start >= '2022-04-01' and  (date_end <= '2022-06-30.' or (date_end is null and date_start between '2022-04-01' and '2022-06-30' ))) then 1 else 0 end as paid_q2_2022 from (select purchase_id,student_id,plan_id, date_purchased as date_start,case when plan_id=0 then date_add(date_purchased, interval 1 month) when plan_id=1 then date_add(date_purchased, interval 1 quarter) when plan_id=2 then date_add(date_purchased, interval 12 month) when plan_id=3 then null end as date_end from student_purchases)a;
# shows data in purchase_info view
select * from purchase_info;


#                                               Data Preparation with SQL – Splitting Into Periods
# I. Calculating Total Minutes Watched in Q2 2021 and Q2 2022
# creating new column minutes_watched by converting seconds_watched from student_video_watched table
select student_id,year(date_watched) as years, round(sum(seconds_watched)/60,2) as minutes_watched from student_video_watched where(year (date_watched) in (2021,2022) and month(date_watched) between 4 and 6) group by student_id,year(date_watched);

# II. Creating a ‘paid’ Column
# drops view master_data if it exists in the database
drop view if exists master_data;
# creates view and new column paid_in_q2 which contains quarter 2 payment indicating 1 for paid 0 not paid by joining student_video_watched and purchase_info; 
create view master_data as  select a.student_id,a.minutes_watched,a.years,if(b.student_id is not null,1,0) as paid_in_q2 from(select student_id, year(date_watched) as Years, round(sum(seconds_watched)/60,2) as minutes_watched from student_video_watched  where year(date_watched) in (2021,2022) group by student_id,years)a left join purchase_info b on a.student_id=b.student_id group by student_id,a.years;
# shows the data in master_data view
select * from master_data;

# Dropping view before creating which contains free_students from 2021 which is indicated by 0 from master_data view
drop view if exists minutes_watched_2021_paid_0;
create view minutes_watched_2021_paid_0 as select * from master_data where (years=2021 and paid_in_q2=0) group by student_id;
select * from minutes_watched_2021_paid_0;

# Dropping view before creating which contains free_students from 2022 which is indicated by 0 from master_data view
drop view if exists minutes_watched_2022_paid_0;
create view minutes_watched_2022_paid_0 as select * from master_data where (years=2022 and paid_in_q2=0) group by student_id;
select * from minutes_watched_2022_paid_0;
 
 # Dropping view before creating which contains Paid_students from 2021 which is indicated by 1 from master_data view
drop view if exists minutes_watched_2021_paid_1;
create view minutes_watched_2021_paid_1 as select * from master_data where (years=2021 and paid_in_q2=1) group by student_id;
select * from minutes_watched_2021_paid_1;

# Dropping view before creating which contains Paid_students from 2022 which is indicated by 1 from master_data view
drop view if exists minutes_watched_2022_paid_1;
create view minutes_watched_2022_paid_1 as select * from master_data where (years=2022 and paid_in_q2=1) group by student_id;
select * from minutes_watched_2022_paid_1;

#														Data Preparation with SQL – Certificates Issued
# I. Studying Minutes Watched and Certificates Issued
# caculating total certificates of students by using student_certificates,student_video_watched tables and replacing null vals in minutes_watched by zero
select a.student_id, certificates_issued,coalesce(sum(b.seconds_watched)/60,0) as minutes_watched from(select student_id,count(certificate_id) as certificates_issued from student_certificates group by student_id)a left join student_video_watched b on a.student_id=b.student_id group by student_id;

#																Dependencies and Probabilities
# I. Assessing Event Dependencies
# Dropping view before creating which contains only qurater 2 data of 2021 from student_video_watched table 
drop view if exists Q2_2021;
create view Q2_2021 as (select * from student_video_watched where year(date_watched)=2021 and month(date_watched) between 4 and 6);
select * from Q2_2021;

# Dropping view before creating which contains only qurater 2 data of 2022 from student_video_watched table
drop view if exists Q2_2022;
create view Q2_2022 as (select * from student_video_watched where year(date_watched)=2022 and month(date_watched) between 4 and 6);
select * from Q2_2022;

# II. Calculating Probabilities
# P(A) : The probability that a student watched a lecture in Q2 2021 , Formula: student watched in year 2021 quarter 2/ total students who watched video
select (select count(distinct student_id) from Q2_2021)/(select count(distinct student_id) from student_video_watched) as 'P(A)';

# P(B) : The probability that a student watched a lecture in Q2 2022 , Formula: student watched in year 2022 quarter 2/ total students who watched the video
select (select count(distinct student_id) from Q2_2022)/(select count(distinct student_id) from student_video_watched) as 'P(B)';

# P(A∩B): The probability that a student watched a lecture in Q2 2021 & Q2 2022 used join, Formula: student watched in both year quarter 2 / total students watched video
select(select count(distinct student_id) from (select distinct student_id from student_video_watched where year(date_watched)=2021)a join (select distinct student_id from student_video_watched where year(date_watched)=2022)b using(student_id))/(select count(distinct student_id)from student_video_watched) as 'P(AB)'; 
#Test for independence: P(A∩B) is not equal to P(A)×P(B) thus both are thus both events are dependent

# P(B|A): Probability that a student watched a lecture in Q2 2022 , given that they watched one in Q2 2021.
select(select count(distinct student_id) from (select distinct student_id from student_video_watched where year(date_watched)=2021)a join (select distinct student_id from student_video_watched where year(date_watched)=2022)b using(student_id))/ (select count(distinct student_id) from Q2_2021) as 'P(B|A)';
# P(A|B): Probability that a student watched a lecture in Q2 2021 , given that they watched one in Q2 2022.
select(select count(distinct student_id) from (select distinct student_id from student_video_watched where year(date_watched)=2021)a join (select distinct student_id from student_video_watched where year(date_watched)=2022)b using(student_id))/ (select count(distinct student_id) from Q2_2022) as 'P(A|B)';
