-- -------create temporary_table------------
/*#drop table temporary_table;
create table  if not exists temporary_table 
as
select 
Position_1.Security_ID,Position_1.Security_Name,
Pecent_of_Total_Market_Value,ISSUER_,
SECURITY_TYP,INDUSTRY_SECTOR, Marketinfo_1.MARKET_SECTOR_DES,
RTG_FITCH,RTG_SP,RTG_MOODY,
DUR_ADJ_MID
from Position_1 inner join Marketinfo_1 
on Position_1.Security_ID = Marketinfo_1.Security_ID;


#alter table temporary_table add ALERT varchar(30);

-- -------ALERT INFO------------
SET SQL_SAFE_UPDATES = 0;
#TOTAL_MARKET_VALUE
UPDATE temporary_table 
SET ALERT = 'PORTFOLIO CONCENTRATION' 
WHERE 
ISSUER_ in
(select ISSUER_
from (SELECT * FROM temporary_table)
as sum_value
group by ISSUER_
having sum(Pecent_of_Total_Market_Value)>5);

#unqualified 
UPDATE temporary_table 
SET ALERT = 'UNQUALIFIED' 
WHERE 
(ISSUER_ in
(select ISSUER_
from (SELECT * FROM temporary_table) as a
where ISSUER_ NOT REGEXP 'FHLMC|FRESB|Fannie|Freddie|US TREASURY'))
and 
(INDUSTRY_SECTOR in
(select INDUSTRY_SECTOR
from (SELECT * FROM temporary_table) as b
where INDUSTRY_SECTOR NOT REGEXP 'Mortgage|Asset Backed|Government'))
AND
(RTG_SP in
(select RTG_SP
from (SELECT * FROM temporary_table) as c
where RTG_SP NOT REGEXP 'A|BBB')
AND (MARKET_SECTOR_DES = 'Corp'))
AND
(RTG_MOODY in
(select RTG_MOODY
from (SELECT * FROM temporary_table) as d
where RTG_MOODY NOT REGEXP 'A|Baa')
AND (MARKET_SECTOR_DES = 'Corp'));

#DURATION
UPDATE temporary_table 
SET ALERT = 'DURATION' 
WHERE 
DUR_ADJ_MID >10;*/

-- -----OUTPUT------ --


#TOTAL_MARKET_VALUE
create table if not exists Violation_Alert
as
select * from
((select
ALERT, 
CONCAT('The concentration of ', ISSUER_,' is ',sum(Pecent_of_Total_Market_Value),'%.') as ALERT_INFO,
GROUP_CONCAT(Security_ID) as Security_ID
from temporary_table 
where ALERT = 'PORTFOLIO CONCENTRATION' 
Group by ISSUER_,ALERT
order by sum(Pecent_of_Total_Market_Value) Desc)

union all

(select 
ALERT, 
CONCAT(SECURITY_TYP,' ',MARKET_SECTOR_DES,'   ',RTG_SP,'(SP) ',RTG_MOODY,'(MOODY) ')as ALERT_INFO,
Security_ID
from temporary_table 
where ALERT = 'UNQUALIFIED')

union all

(select 
ALERT, 
CONCAT('The Modified Duration is ', DUR_ADJ_MID) as ALERT_INFO,
Security_ID
from temporary_table 
where ALERT = 'DURATION'
order by DUR_ADJ_MID Desc)) w
;













