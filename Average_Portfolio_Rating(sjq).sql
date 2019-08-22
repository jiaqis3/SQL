#drop table Portofolio_Rating_Calculation;

create table if not exists Portofolio_Rating_Calculation
as select * from temporary_table;

-- -----------Cleaning Data------------ --
update Portofolio_Rating_Calculation
set RTG_SP = replace(RTG_SP,'*+',''),
RTG_SP = replace(RTG_SP,'*-',''),
RTG_SP= replace(RTG_SP,'u',''),
RTG_MOODY = replace(RTG_MOODY,'*+',''),
RTG_MOODY = replace(RTG_MOODY,'*-',''),
RTG_MOODY = replace(RTG_MOODY,'u',''),
RTG_FITCH = replace(RTG_FITCH,'*+',''),
RTG_FITCH = replace(RTG_FITCH,'*-',''),
RTG_FITCH = replace(RTG_FITCH,'u','');
update Portofolio_Rating_Calculation
set RTG_SP=null 
where RTG_SP NOT REGEXP 'A|B|C|D';
update Portofolio_Rating_Calculation
set RTG_MOODY=null 
where RTG_MOODY NOT REGEXP 'A|B|C|D';
update Portofolio_Rating_Calculation
set RTG_FITCH=null 
where RTG_FITCH NOT REGEXP 'A|B|C|D'
or RTG_FITCH REGEXP 'W';

#Government bond rate AAA
update Portofolio_Rating_Calculation
SET RTG_SP = 'AAA' 
WHERE 
(ISSUER_ in
(select ISSUER_
from (SELECT * FROM Portofolio_Rating_Calculation) as a1
where ISSUER_ REGEXP 'FHLMC|FRESB|Fannie|Freddie|US TREASURY'))
or 
(INDUSTRY_SECTOR in
(select INDUSTRY_SECTOR
from (SELECT * FROM Portofolio_Rating_Calculation) as b1
where INDUSTRY_SECTOR  REGEXP 'Government'));

-- -----------Combine Value Table------------ --
create table if not exists Portofolio_Rating_Calculation_2 
select * from Portofolio_Rating_Calculation
left join (select SP_Rating,SP_Value from Rating) as f
on Portofolio_Rating_Calculation.RTG_SP = f.SP_Rating
left join (select Moody_Rating,Moody_Value from Rating) as g
on Portofolio_Rating_Calculation.RTG_MOODY = g.Moody_Rating
left join (select Fitch_Rating ,Fitch_Value from Rating) as h
on Portofolio_Rating_Calculation.RTG_FITCH = h.Fitch_Rating ;

alter table Portofolio_Rating_Calculation_2 
add rate_number FLOAT,
add Rating_Score FLOAT;

update Portofolio_Rating_Calculation_2 P
inner join 
(select Security_ID,(if(SP_Value is null,0,1)+
if(Moody_Value is null,0,1)+
if(Fitch_Value is null,0,1)) as sum_of_nnull
from (select * from Portofolio_Rating_Calculation_2) W) Q
on P.Security_ID=Q.Security_ID
set P.rate_number=Q.sum_of_nnull;

-- -----------Update Rating_Score----------- --

update Portofolio_Rating_Calculation_2 P
inner join
(select 
Security_ID,
(SP_Value+Moody_Value+Fitch_Value)*Pecent_of_Total_Market_Value/300 as score
from  
(select * from Portofolio_Rating_Calculation_2 ) Q
) W
on P.Security_ID=W.Security_ID
set P.Rating_Score =W.score
where P.rate_number=3;

update Portofolio_Rating_Calculation_2 P
inner join
(select 
Security_ID,
if(SP_Value is null,if(Moody_Value<Fitch_Value,Moody_Value,Fitch_Value),
(if(Moody_Value is null,if(SP_Value<Fitch_Value,SP_Value,Fitch_Value),
if(SP_Value<Moody_Value,SP_Value,Moody_Value))))
*Pecent_of_Total_Market_Value/100 as score
from  
(select * from Portofolio_Rating_Calculation_2 ) Q
) W
on P.Security_ID=W.Security_ID
set P.Rating_Score =W.score
where P.rate_number=2;

update Portofolio_Rating_Calculation_2 P
inner join
(select 
Security_ID,
if(SP_Value is not null,SP_Value,
(if(Moody_Value is not null,Moody_Value,Fitch_Value)))
*Pecent_of_Total_Market_Value/100 as score
from  
(select * from Portofolio_Rating_Calculation_2 ) Q
) W
on P.Security_ID=W.Security_ID
set P.Rating_Score =W.score
where P.rate_number=1;


-- -----------Creat Result Table------------ --

create table if not exists Average_Portofolio_Rating (
Portfolio_ Float,
Benchmark_ Float,
Result_ TEXT);

Insert into Average_Portofolio_Rating 
(Portfolio_,Benchmark_)
Values
((select sum(Rating_Score) from Portofolio_Rating_Calculation_2),
(select SP_Value from Rating
where SP_Rating='A'));

update Average_Portofolio_Rating
set Result_=(
if(Portfolio_ >= Benchmark_,'The average credit quality is consistent with the benchmark index',
'The average credit quality is not consistent with the benchmark index'));

select * from Average_Portofolio_Rating ;
#drop table Average_Portofolio_Rating;











