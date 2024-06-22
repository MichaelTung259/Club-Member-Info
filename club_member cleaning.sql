select *
from club_member_info;

/* Create temp table and begin cleaning process */

select * into #supertemp
from club_member_info;

DROP TABLE IF EXISTS [dbo].[club_member_info_clean]
CREATE TABLE [dbo].[club_member_info_clean]
( 
	[member_id] [int] IDENTITY(1,1) NOT NULL,
	[full_name] [nvarchar](50) NULL,
	[age] [int] NULL,
	[martial_status] [nvarchar](50) NULL,
	[email] [nvarchar](50) NULL,
	[phone] [nvarchar](50) NULL,
	[full_address] [nvarchar](100) NULL,
	[job_title] [nvarchar](50) NULL,
	[membership_date] [datetime2](7) NULL,
) 
ON [PRIMARY];

insert into club_member_info_clean
select * 
from #supertemp;

select * 
from club_member_info_clean; 


-- Check and delete any duplicates.
select full_name, COUNT(full_name)
from club_member_info_clean
group by full_name
having COUNT(full_name) >1;

select *
from club_member_info_clean
where full_name = 'ERWIN HUXTER' or 
      full_name = 'Garrick Reglar' or
      full_name = 'georges prewett' or
      full_name = 'Haskell Braden' or
      full_name = 'Maddie Morrallee' or
      full_name = 'Nicki Filliskirk' or
      full_name = 'Obed MacCaughen' or
      full_name = 'Seymour Lamble' or
      full_name = 'Tamqrah Dunkersley'
order by full_name;


delete from club_member_info_clean
where member_id not in 
(
      select MIN(member_id)
      from club_member_info_clean
      group by full_name
);


-- Check and remove any special characters or whitespaces then change name cased.
select full_name	
from club_member_info_clean
where full_name like '[^A-Za-z0-9]%' 
   or full_name like '%[^A-Za-z0-9]';

UPDATE club_member_info_clean
set full_name = LOWER(TRIM
(
  case 
      when full_name like '[^A-Za-z0-9]%'
          then REPLACE(full_name, SUBSTRING(full_name, 1, 
			                                PATINDEX('[^A-Za-z0-9]%', full_name)),'')
      when full_name like '%[^A-Za-z0-9]'
          then REPLACE(full_name, REVERSE(SUBSTRING(REVERSE(full_name), 1, 
			                                PATINDEX('[^A-Za-z0-9]%', REVERSE(full_name)))),'')
      else full_name
  end
));


-- Check and correct the appropriate age.
select * from club_member_info_clean
where LEN(age)>2;

UPDATE club_member_info_clean
set age =
      STUFF(age,3,1,'')
where LEN(age)>2;


-- Check whitespace and errors of martial_status.
UPDATE club_member_info_clean
set martial_status = TRIM(martial_status);

select martial_status, COUNT(*)
from club_member_info_clean
group by martial_status;

UPDATE club_member_info_clean
set martial_status = 'divorced'
where martial_status = 'divored';


-- Check whitespace and duplicate of email.
UPDATE club_member_info_clean
set email = TRIM(email);

select email, COUNT(email)
from club_member_info_clean
group by email
having COUNT(email) > 1;


-- Correct incomplete phone number, phone number must be 12 digits.
UPDATE club_member_info_clean
set phone = null 
where LEN(phone) < 12;


-- Check and correct any misspelling of city and state.
select distinct
(
  SUBSTRING(full_address,
           CHARINDEX(',', full_address) + 1,
		            CHARINDEX(',', full_address, CHARINDEX(',', full_address) + 1) - 
					          CHARINDEX(',', full_address) - 1
)) as city
from club_member_info_clean;

select distinct
(
  SUBSTRING(full_address, 
           CHARINDEX(',', full_address, 
					CHARINDEX(',', full_address) + 1) + 1, LEN(full_address)
)) as state
from club_member_info_clean;

UPDATE club_member_info_clean
set full_address = TRIM
(
  case 
      when full_address like '% Puerto Rico' then REPLACE(full_address, ' Puerto Rico', 'Puerto Rico')
      when full_address like '%Districts of Columbia' then REPLACE(full_address, 'Districts of Columbia', 'District of Columbia')
      when full_address like '%NewYork' then REPLACE(full_address, 'NewYork', 'New York')
      when full_address like '%NorthCarolina' then REPLACE(full_address, 'NorthCarolina', 'North Carolina')
      when full_address like '%South Dakotaaa' then REPLACE(full_address, 'South Dakotaaa', 'South Dakota')
      when full_address like '%Tej+F823as' then REPLACE(full_address, 'Tej+F823as', 'Texas')
      when full_address like '%Tejas' then REPLACE(full_address, 'Tejas', 'Texas')
      when full_address like '%Tennesseeee' then REPLACE(full_address, 'Tennesseeee', 'Tennesse')
      when full_address like '%Kalifornia' then REPLACE(full_address, 'Kalifornia', 'California')
      when full_address like '%Kansus' then REPLACE(full_address, 'Kansus', 'Kansas')
      else full_address
  end
);


-- Add 2 new columns as City and State.
alter table club_member_info_clean
add [city] [nvarchar](50) null,
	[state] [nvarchar](50) null;

update club_member_info_clean
set  
     city =
     PARSENAME(REPLACE(full_address, ',', '.'), 2),
	 state =
     PARSENAME(REPLACE(full_address, ',', '.'), 1)
;


-- Convert roman numerals(I, II, III, IV) to numbers level in job_title.
UPDATE club_member_info_clean
set job_title = TRIM
(   
    case	
	    when right(job_title COLLATE Latin1_General_CS_AS, 2)  = 'IV'
		      then REPLACE(job_title, right(job_title COLLATE Latin1_General_CS_AS, 2), 'Level 4')
		when right(job_title COLLATE Latin1_General_CS_AS, 3)  = 'III'
		      then REPLACE(job_title, right(job_title COLLATE Latin1_General_CS_AS, 3), 'Level 3')
		when right(job_title COLLATE Latin1_General_CS_AS, 2) = 'II'
		      then REPLACE(job_title, right(job_title COLLATE Latin1_General_CS_AS, 2), 'Level 2')
		when right(job_title COLLATE Latin1_General_CS_AS, 1) = 'I'
		      then REPLACE(job_title, right(job_title COLLATE Latin1_General_CS_AS, 1), 'Level 1')
		else job_title
	end
);
	

-- Correct membership date, must be 2000s go on.
UPDATE club_member_info_clean
set membership_date =
    case
         when membership_date like '19%' 
		      then STUFF(membership_date, 1, 2, '20')
    else membership_date
end;


/* The table is cleaned. Continue to analyze the data */

-- How many members are there in the club?
select COUNT(*) as total_member
from club_member_info_clean;

-- What is the age range of members?
select 
      COUNT(case when age < 20 then 1 end) as [Under 20],
	  COUNT(case when age >= 20 and age <40 then 1 end) as [20 to 39],
	  COUNT(case when age >= 40 and age < 60 then 1 end) as [40 to 59],
	  COUNT(case when age >= 60 then 1 end) as [60 and over]
from club_member_info_clean;

-- How many members are married or single?
select martial_status, 
       COUNT(*) as member_count
from club_member_info_clean
group by martial_status;

-- The total members registered based on years.
select YEAR(membership_date) as Year, 
       COUNT(*) as total_member 
from club_member_info_clean
group by YEAR(membership_date)
order by Year asc;

-- The total members registered based on states.
select state, 
       COUNT(*) as member_count
from club_member_info_clean
group by state
order by member_count desc;

-- The average number of members registered based on months through out the years.
with CTE as
(
    select MONTH(membership_date) as MONTH,
	       YEAR(membership_date) as YEAR,
		   COUNT(*) as month_count
    from club_member_info_clean
    group by MONTH(membership_date), 
	         YEAR(membership_date)
)
select [month],
       AVG(month_count) as Avgmem_month
from CTE
group by [month]
order by [month];

/* The end of cleaning and analyzing */


































