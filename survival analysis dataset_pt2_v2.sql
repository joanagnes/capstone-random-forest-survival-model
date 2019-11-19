/*******************************************************
*** TREATING DIAGNOSIS CODES ISSUE-- USING CCS LEVEL 1 INSTEAD: TRAINING DATA
*********************************************************/

/* Creating ICD 9 and 10 data tables for joins */
/*
drop table icd9;
create table icd9 
(icd9 CHARACTER VARYING (7)
,CCS_LVL CHARACTER VARYING (4)
,CCS_CAT_DESC CHARACTER VARYING (45)
,icd9_2 character varying (5)
)

select * from icd9 limit 3;

drop table icd10;
create table icd10 
(icd10 CHARACTER VARYING (7)
,CCS_LVL CHARACTER VARYING (4)
,CCS_CAT_DESC CHARACTER VARYING (114)
)

select * from icd10 limit 3;

drop table icd_x;
create table icd_x
(icd_x character varying (7)
)

select * from icd_x;
*/

-- TREATING TRAINING DATA WITH ICD TABLE JOINS
--DROP TABLE COPY_TRAINING;
create temporary table copy_training
as select * from final_merged_training;

select * from copy_training limit 10;
-- REMOVE THE DECIMAL IN THE DX CODES FROM UCHICAGO DATA (THE ICD FILES DID NOT HAVE DECIMALS)
update copy_training
set top_dx_1 = regexp_replace(top_dx_1, '[^\w]+','')
,top_dx_2 = regexp_replace(top_dx_2, '[^\w]+','')
,top_dx_3 = regexp_replace(top_dx_3, '[^\w]+','')
;

select distinct(top_dx_1), top_dx_2 from copy_training 
order by top_dx_1 asc;

--CHECKING THE ICD TABLES
/*
select * from icd9 limit 10;
select * from icd10 limit 10;
*/
-- TRIED CREATING A MASTER ICD 9 AND 10 TABLE, BUT IT WAS A BAS IDEA BECAUSE IT'S JUST BETTER TO KEEP THEM SEPARATE
/*
create temporary table icd_tab
as
select * from icd9
union
select * from icd10
;

select * from icd_tab limit 50;
*/

-- NOW HAVE TO FIGURE OUT WHICH ICD CODES ARE IN UCHICAGO DATA, BUT CODED DIFFERENTLY IN ICD TABLES
--DROP TABLE FIND_MISSING
create temporary table FIND_MISSING
as
select a.*
,coalesce(b.ccs_cat_desc, c.ccs_cat_desc) as ccs_cat_desc
from copy_training a
left join icd9 b 
on trim(a.top_dx_1)=trim(b.icd9_2)
left join icd10 c
on trim(leading '0' from cast (a.top_dx_1 as text))=trim(c.icd10)
;

select * from FIND_MISSING
where ccs_cat_desc is null limit 100;

-- SELECT THE MISSING CASES, PUT INTO EXCEL TO FORMAT FOR THE FOLLOWING SELECT STATEMENT

-- IMPUTE THE MISSING VALUES-- SEEMS MOSTLY TO BE CAUSED BY INCORRECT ENTRY VIS A VIS WHAT IS AVAILABLE IN ICD 10 CATALOGUE
--drop table missing_ccs;
create temporary table missing_ccs
as
select * from icd10 
where icd10 similar to 
'
|M1A372%|M84422%|M84452%|M84452%|O36592%|R40214%|S01111%|S01111%|S01111%|S01111%|S01111%|S01112%|S01119%|S01311%|S01411%|S01412%|S01511%|S01511%|S01511%|S01511%|S02401%|S02401%|S02401%|S02401%|S02401%|S02401%|S02401%|S02401%|S02411%|S02411%|S02600%|S02609%|S02609%|S02609%|S02609%|S02609%|S060X0%|S060X0%|S060X0%|S060X0%|S060X0%|S060X1%|S060X1%|S060X1%|S060X3%|S060X9%|S060X9%|S062X0%|S062X0%|S062X0%|S06360%|S065X0%|S065X0%|S065X0%|S066X1%|S066X9%|S066X9%|S06899%|S069X0%|S069X1%|S069X9%|S069X9%|S069X9%|S069X9%|S069X9%|S069X9%|S069X9%|S069X9%|S069X9%|S069X9%|S08112%|S12030%|S12130%|S12490%|S14156%|S20211%|S20211%|S20211%|S20212%|S20212%|S20212%|S20212%|S20212%|S20212%|S20219%|S20221%|S20412%|S21102%|S21111%|S21112%|S21212%|S22079%|S29011%|S29012%|S29092%|S31104%|S31821%|S31829%|S32000%|S32009%|S32009%|S32038%|S32511%|S32591%|S32592%|S36113%|S39011%|S39012%|S39012%|S40012%|S40021%|S40811%|S41001%|S41012%|S41041%|S41112%|S42001%|S42001%|S42021%|S42022%|S42031%|S42142%|S42201%|S42202%|S42211%|S42251%|S42291%|S42292%|S42301%|S42322%|S42322%|S43004%|S43004%|S43005%|S43014%|S43402%|S43402%|S43491%|S43492%|S46012%|S51012%|S52001%|S52272%|S52501%|S52501%|S52501%|S52501%|S52501%|S52501%|S52501%|S52501%|S52501%|S52501%|S52502%|S52502%|S52502%|S52502%|S52502%|S52502%|S52502%|S52522%|S52561%|S52571%|S52571%|S52571%|S52571%|S52572%|S52602%|S52611%|S53104%|S60211%|S60222%|S60511%|S60811%|S61213%|S61215%|S61401%|S61411%|S61412%|S62001%|S62002%|S62002%|S62002%|S62101%|S62141%|S62316%|S62337%|S62339%|S62390%|S62515%|S62521%|S62521%|S62609%|S62609%|S62619%|S62624%|S62645%|S63094%|S63094%|S63261%|S70312%|S71101%|S72001%|S72001%|S72002%|S72002%|S72141%|S72302%|S72401%|S72451%|S73102%|S79911%|S80211%|S80212%|S80212%|S80212%|S80219%|S80821%|S81002%|S81811%|S82141%|S82142%|S82142%|S82142%|S82291%|S82392%|S82401%|S82431%|S82832%|S82872%|S82891%|S82891%|S82891%|S82892%|S82892%|S82892%|S82892%|S82892%|S83241%|S86011%|S91002%|S92001%|S92001%|S92002%|S92002%|S92041%|S92042%|S92101%|S92251%|S92301%|S92301%|S92351%|S92351%|S92901%|S92901%|S99912%|T17208%|T17900%|T18198%|T22211%|T24391%|T24392%|T25222%|T368X5%|T380X5%|T380X5%|T380X5%|T382X5%|T39016%|T391X1%|T39395%|T394X5%|T401X1%|T401X1%|T401X1%|T401X4%|T402X5%|T40605%|T420X5%|T424X1%|T424X1%|T43012%|T43621%|T451X5%|T451X5%|T451X5%|T45515%|T45515%|T458X5%|T464X5%|T465X6%|T502X5%|T502X6%|T508X5%|T508X5%|T50905%|T50995%|T510X1%|T510X1%|T80211%|T80211%|T80818%|T82110%|T82119%|T82120%|T82330%|T82538%|T82818%|T82838%|T82838%|T82857%|T82867%|T82867%|T82868%|T82897%|T82897%|T82898%|T82898%|T84021%|T84021%|T84042%|T84098%|T84098%|T85192%|T85614%|W01198%|W01198%
'
order by icd10 asc;
select * from missing_ccs limit 10;

-- CREATE TABLE ICD_X, LOAD INTO PGADMIN-- THIS IS A CSV OF THE MISSING DIAGNOSIS CODES THAT WE COULDN'T INTIALLY MATCH WITH THE ICD TABLES

select * from missing_ccs limit 10;
select * from icd_x limit 10;

-- CREATE TABLE TO IMPUTE THE MOST LIKELY CCS LEVEL TO THE DX CODE WHICH WE INITIALLY COULD NOT MATCH AGAINST THE ICD TABLES
--drop table other_ccs;
create temporary table other_ccs
as
select a.*, b.icd_x
from missing_ccs a
left join icd_x b
on a.icd10 similar to '%' || b.icd_x||'%';

select * from other_ccs;

-- IF THERE ARE MULTIPLE POSSIBLE CCS LEVELS, WE WANT TO REDUCE TO JUST ONE, SO WE WILL TAKE THE FIRST ROW ONLY
--drop table final_ccs;
create temporary table final_ccs
as select * from
(
select
distinct icd_x, ccs_cat_desc, row_number() over (partition by icd_x) as rownumber
from other_ccs
) as foo
where rownumber=1
;

select * from final_ccs;

-- STEP 1: CREATING FINAL TRAINING SET
--drop table final_training;

create temporary table final_training
as
select a.*
,coalesce(b.ccs_cat_desc, c.ccs_cat_desc, d.ccs_cat_desc) as ccs_cat_desc
from copy_training a
left join icd9 b 
on trim(a.top_dx_1)=trim(b.icd9_2)
left join icd10 c
on trim(leading '0' from cast (a.top_dx_1 as text))=trim(c.icd10)
left join final_ccs d 
on trim(leading '0' from cast (a.top_dx_1 as text)) =d.icd_x 
;

select * from final_training
where ccs_cat_desc is null limit 100;

-- STEP 2: IMPUTING NO DIAGNOSIS VALUES FOR ROWS THAT DID NOT HAVE A DIAGNOSIS CODE
--drop table final_training_2;
create temporary table final_training_2
as 
select *
, case when ccs_cat_desc is not null then ccs_cat_desc else 'No diagnosis' end as ccs_desc
, CASE WHEN TOBACCO_PAK_PER_DY = '0' THEN '1'
WHEN TOBACCO_PAK_PER_DY IS NOT NULL AND TOBACCO_PAK_PER_DY <> '0' THEN '2'
WHEN TOBACCO_PAK_PER_DY IS NULL THEN '3'
END AS TOBACCO_PAK_PER_DY_2

, CASE WHEN TOBACCO_USED_YEARS = '0' THEN '1'
WHEN TOBACCO_USED_YEARS IS NOT NULL AND TOBACCO_USED_YEARS <> '0' THEN '2'
WHEN TOBACCO_USED_YEARS IS NULL THEN '3'
END AS TOBACCO_USED_YEARS_2

, CASE WHEN CIGARETTES_YN = 'Y' THEN '1'
WHEN CIGARETTES_YN = 'N' THEN '2'
WHEN CIGARETTES_YN IS NULL THEN '3'
END AS CIGARETTES_YN_2

, CASE WHEN PIPES_YN = 'Y' THEN '1'
WHEN PIPES_YN = 'N' THEN '2'
WHEN PIPES_YN IS NULL THEN '3'
END AS PIPES_YN_2

, CASE WHEN CIGARS_YN = 'Y' THEN '1'
WHEN CIGARS_YN = 'N' THEN '2'
WHEN CIGARS_YN IS NULL THEN '3'
END AS CIGARS_YN_2

, CASE WHEN SNUFF_YN = 'Y' THEN '1'
WHEN SNUFF_YN = 'N' THEN '2'
WHEN SNUFF_YN IS NULL THEN '3'
END AS SNUFF_YN_2

, CASE WHEN ALCOHOL_OZ_PER_WK = '0' THEN '1'
WHEN ALCOHOL_OZ_PER_WK IS NOT NULL AND ALCOHOL_OZ_PER_WK <> '0' THEN '2'
WHEN ALCOHOL_OZ_PER_WK IS NULL THEN '3'
END AS ALCOHOL_OZ_PER_WK_2

, CASE WHEN IV_DRUG_USER_YN = 'Y' THEN '1'
WHEN IV_DRUG_USER_YN = 'N' THEN '2'
WHEN IV_DRUG_USER_YN IS NULL THEN '3'
END AS IV_DRUG_USER_YN_2

, CASE WHEN TOBACCO_USER = 'Yes' THEN '1'
WHEN TOBACCO_USER = 'Never' THEN '2'
WHEN TOBACCO_USER IS NULL THEN '3'
WHEN TOBACCO_USER = 'Quit' THEN '4'
WHEN TOBACCO_USER = 'Passive' THEN '5'
WHEN TOBACCO_USER = 'Not Asked' THEN '6'
END AS TOBACCO_USER_2

, CASE WHEN SMOKING_TOB_USE = 'Unknown If Ever Smoked' THEN '1'
WHEN SMOKING_TOB_USE ='Smoker, Current Status Unknown' THEN '2'
WHEN SMOKING_TOB_USE IS NULL THEN '3'
WHEN SMOKING_TOB_USE = 'Passive Smoke Exposure - Never Smoker' THEN '4'
WHEN SMOKING_TOB_USE = 'Never Smoker' THEN '5'
WHEN SMOKING_TOB_USE = 'Never Assessed' THEN '6'
WHEN SMOKING_TOB_USE = 'Light Tobacco Smoker' THEN '7'
WHEN SMOKING_TOB_USE = 'Heavy Tobacco Smoker' THEN '8'
WHEN SMOKING_TOB_USE = 'Former Smoker' THEN '9'
WHEN SMOKING_TOB_USE = 'Current Some Day Smoker' THEN '10'
WHEN SMOKING_TOB_USE = 'Current Every Day Smoker' THEN '11'
END AS SMOKING_TOB_USE_2

, CASE WHEN FIRST_TO_DIAGNOSED_DAYS = 0 THEN '1'
WHEN FIRST_TO_DIAGNOSED_DAYS >0 AND FIRST_TO_DIAGNOSED_DAYS<101 THEN '2'
WHEN FIRST_TO_DIAGNOSED_DAYS > 100 AND FIRST_TO_DIAGNOSED_DAYS<201 THEN '3'
WHEN FIRST_TO_DIAGNOSED_DAYS >200 AND FIRST_TO_DIAGNOSED_DAYS <301 THEN '4'
WHEN FIRST_TO_DIAGNOSED_DAYS >300 AND FIRST_TO_DIAGNOSED_DAYS < 401 THEN '5'
WHEN FIRST_TO_DIAGNOSED_DAYS >400 AND FIRST_TO_DIAGNOSED_DAYS < 501 THEN '6'
WHEN FIRST_TO_DIAGNOSED_DAYS >500 AND FIRST_TO_DIAGNOSED_DAYS < 601 THEN '7'
WHEN FIRST_TO_DIAGNOSED_DAYS >600 AND FIRST_TO_DIAGNOSED_DAYS < 701 THEN '8'
WHEN FIRST_TO_DIAGNOSED_DAYS >700 AND FIRST_TO_DIAGNOSED_DAYS < 801 THEN '9'
WHEN FIRST_TO_DIAGNOSED_DAYS >800 AND FIRST_TO_DIAGNOSED_DAYS < 901THEN '10'
WHEN FIRST_TO_DIAGNOSED_DAYS >900 THEN '11'
WHEN FIRST_TO_DIAGNOSED_DAYS IS NULL THEN '12'
END AS FIRST_TO_DIAGNOSED_DAYS_2

from final_training
;

select * from final_training_2 limit 10;

-- CREATE FINAL FINAL FINAL TABLE- TRAINING
drop table final_training_3;
CREATE TABLE FINAL_TRAINING_3
AS SELECT
PATIENT_ID
, ILD_STATUS
, GENDER
, RACE
, ETHNICITY
, AGE_AT_LAST_VISIT
, length_of_first_visit
, LENGTH_OF_LAST_VISIT
, avg_length_of_all_visits
, total_nbr_visits
, total_nbr_procs
, avg_nbr_procs_per_encounter
, total_xr
, total_ct
, total_other
, censored
, t
, ccs_desc
, tobacco_pak_per_dy_2
, tobacco_used_years_2
, cigarettes_yn_2
, pipes_yn_2
, cigars_yn_2
, snuff_yn_2 
, alcohol_oz_per_wk_2
, iv_drug_user_yn_2
, tobacco_user_2
, smoking_tob_use_2
, first_to_diagnosed_days_2
from final_training_2;

select * from final_training_3 limit 25;

-- CHECKS TO MAKE SURE DATA LOOKS OK
select count(*) from final_training_2;--100,405
select count(*) from final_merged_training;--100,405

select * from final_training_2 limit 10;

select distinct patient_id, count(patient_id) as freq
from final_training_2
group by 1 order by 2 desc
;


select * from final_training_2
where patient_id=1004192;
;


/*******************************************************
*** TREATING DIAGNOSIS CODES ISSUE-- USING CCS LEVEL 1 INSTEAD: TEST DATA
*********************************************************/

-- TREATING TEST DATA WITH ICD TABLE JOINS

create temporary table copy_test
as select * from final_merged_test;

-- REMOVE THE DECIMAL IN THE DX CODES FROM UCHICAGO DATA (THE ICD FILES DID NOT HAVE DECIMALS)
update copy_test
set top_dx_1 = regexp_replace(top_dx_1, '[^\w]+','');

select distinct(top_dx_1) from copy_test 
order by top_dx_1 asc;

-- NOW HAVE TO FIGURE OUT WHICH ICD CODES ARE IN UCHICAGO DATA, BUT CODED DIFFERENTLY IN ICD TABLES
drop table find_missing;
create temporary table FIND_MISSING
as
select a.*
,coalesce(b.ccs_cat_desc, c.ccs_cat_desc) as ccs_cat_desc
from copy_test a
left join icd9 b 
on trim(a.top_dx_1)=trim(b.icd9_2)
left join icd10 c
on trim(leading '0' from cast (a.top_dx_1 as text))=trim(c.icd10)
;

select * from FIND_MISSING
where ccs_cat_desc is null limit 100;

select distinct(top_dx_1) from FIND_MISSING
where ccs_cat_desc is null limit 100;

-- SELECT THE MISSING CASES, PUT INTO EXCEL TO FORMAT FOR THE FOLLOWING SELECT STATEMENT
--drop table icd_x2;
/*create table icd_x2
(icd_x CHARACTER VARYING (6)
);*/

select * from icd_x2 limit 10;
-- create this table using the csv of missing dx's from step above

-- IMPUTE THE MISSING VALUES-- SEEMS MOSTLY TO BE CAUSED BY INCORRECT ENTRY VIS A VIS WHAT IS AVAILABLE IN ICD 10 CATALOGUE
drop table missing_ccs;
create temporary table missing_ccs
as
select * from icd10 
where icd10 similar to 
'
|M84622%|S01111%|S01112%|S060X0%|S060X9%|S066X0%|S069X1%|S069X9%|S20211%|S27329%|S31030%|S32009%|S32591%|S36116%
|S37021%|S39012%|S40011%|S40812%|S42212%|S42442%|S43421%|S52124%|S52592%|S52602%|S61401%|S61412%|S62014%|S62021%|S62613%
|S63094%|S72352%|S80211%|S82201%|T402X5%|T451X5%|T82330%|W01198%
'
order by icd10 asc;
select * from missing_ccs limit 10;

-- CREATE TABLE ICD_X, LOAD INTO PGADMIN-- THIS IS A CSV OF THE MISSING DIAGNOSIS CODES THAT WE COULDN'T INTIALLY MATCH WITH THE ICD TABLES

select * from missing_ccs limit 10;
select * from icd_x2 limit 10;

-- CREATE TABLE TO IMPUTE THE MOST LIKELY CCS LEVEL TO THE DX CODE WHICH WE INITIALLY COULD NOT MATCH AGAINST THE ICD TABLES
drop table other_ccs;
create temporary table other_ccs
as
select a.*, b.icd_x
from missing_ccs a
left join icd_x2 b
on a.icd10 similar to '%' || b.icd_x||'%';

select * from other_ccs;

-- IF THERE ARE MULTIPLE POSSIBLE CCS LEVELS, WE WANT TO REDUCE TO JUST ONE, SO WE WILL TAKE THE FIRST ROW ONLY
drop table final_ccs;
create temporary table final_ccs
as select * from
(
select
distinct icd_x, ccs_cat_desc, row_number() over (partition by icd_x) as rownumber
from other_ccs
) as foo
where rownumber=1
;

select * from final_ccs;

-- STEP 1: CREATING FINAL test SET
--drop table final_test;

create temporary table final_test
as
select a.*
,coalesce(b.ccs_cat_desc, c.ccs_cat_desc, d.ccs_cat_desc) as ccs_cat_desc
from copy_test a
left join icd9 b 
on trim(a.top_dx_1)=trim(b.icd9_2)
left join icd10 c
on trim(leading '0' from cast (a.top_dx_1 as text))=trim(c.icd10)
left join final_ccs d 
on trim(leading '0' from cast (a.top_dx_1 as text)) =d.icd_x 
;

select * from final_test
where ccs_cat_desc is null limit 100;

-- STEP 2: IMPUTING NO DIAGNOSIS VALUES FOR ROWS THAT DID NOT HAVE A DIAGNOSIS CODE
--drop table final_test_2;
create temporary table final_test_2
as 
select *
, case when ccs_cat_desc is not null then ccs_cat_desc else 'No diagnosis' end as ccs_desc
, CASE WHEN TOBACCO_PAK_PER_DY = '0' THEN '1'
WHEN TOBACCO_PAK_PER_DY IS NOT NULL AND TOBACCO_PAK_PER_DY <> '0' THEN '2'
WHEN TOBACCO_PAK_PER_DY IS NULL THEN '3'
END AS TOBACCO_PAK_PER_DY_2

, CASE WHEN TOBACCO_USED_YEARS = '0' THEN '1'
WHEN TOBACCO_USED_YEARS IS NOT NULL AND TOBACCO_USED_YEARS <> '0' THEN '2'
WHEN TOBACCO_USED_YEARS IS NULL THEN '3'
END AS TOBACCO_USED_YEARS_2

, CASE WHEN CIGARETTES_YN = 'Y' THEN '1'
WHEN CIGARETTES_YN = 'N' THEN '2'
WHEN CIGARETTES_YN IS NULL THEN '3'
END AS CIGARETTES_YN_2

, CASE WHEN PIPES_YN = 'Y' THEN '1'
WHEN PIPES_YN = 'N' THEN '2'
WHEN PIPES_YN IS NULL THEN '3'
END AS PIPES_YN_2

, CASE WHEN CIGARS_YN = 'Y' THEN '1'
WHEN CIGARS_YN = 'N' THEN '2'
WHEN CIGARS_YN IS NULL THEN '3'
END AS CIGARS_YN_2

, CASE WHEN SNUFF_YN = 'Y' THEN '1'
WHEN SNUFF_YN = 'N' THEN '2'
WHEN SNUFF_YN IS NULL THEN '3'
END AS SNUFF_YN_2

, CASE WHEN ALCOHOL_OZ_PER_WK = '0' THEN '1'
WHEN ALCOHOL_OZ_PER_WK IS NOT NULL AND ALCOHOL_OZ_PER_WK <> '0' THEN '2'
WHEN ALCOHOL_OZ_PER_WK IS NULL THEN '3'
END AS ALCOHOL_OZ_PER_WK_2

, CASE WHEN IV_DRUG_USER_YN = 'Y' THEN '1'
WHEN IV_DRUG_USER_YN = 'N' THEN '2'
WHEN IV_DRUG_USER_YN IS NULL THEN '3'
END AS IV_DRUG_USER_YN_2

, CASE WHEN TOBACCO_USER = 'Yes' THEN '1'
WHEN TOBACCO_USER = 'Never' THEN '2'
WHEN TOBACCO_USER IS NULL THEN '3'
WHEN TOBACCO_USER = 'Quit' THEN '4'
WHEN TOBACCO_USER = 'Passive' THEN '5'
WHEN TOBACCO_USER = 'Not Asked' THEN '6'
END AS TOBACCO_USER_2

, CASE WHEN SMOKING_TOB_USE = 'Unknown If Ever Smoked' THEN '1'
WHEN SMOKING_TOB_USE ='Smoker, Current Status Unknown' THEN '2'
WHEN SMOKING_TOB_USE IS NULL THEN '3'
WHEN SMOKING_TOB_USE = 'Passive Smoke Exposure - Never Smoker' THEN '4'
WHEN SMOKING_TOB_USE = 'Never Smoker' THEN '5'
WHEN SMOKING_TOB_USE = 'Never Assessed' THEN '6'
WHEN SMOKING_TOB_USE = 'Light Tobacco Smoker' THEN '7'
WHEN SMOKING_TOB_USE = 'Heavy Tobacco Smoker' THEN '8'
WHEN SMOKING_TOB_USE = 'Former Smoker' THEN '9'
WHEN SMOKING_TOB_USE = 'Current Some Day Smoker' THEN '10'
WHEN SMOKING_TOB_USE = 'Current Every Day Smoker' THEN '11'
END AS SMOKING_TOB_USE_2

, CASE WHEN FIRST_TO_DIAGNOSED_DAYS = 0 THEN '1'
WHEN FIRST_TO_DIAGNOSED_DAYS >0 AND FIRST_TO_DIAGNOSED_DAYS<101 THEN '2'
WHEN FIRST_TO_DIAGNOSED_DAYS > 100 AND FIRST_TO_DIAGNOSED_DAYS<201 THEN '3'
WHEN FIRST_TO_DIAGNOSED_DAYS >200 AND FIRST_TO_DIAGNOSED_DAYS <301 THEN '4'
WHEN FIRST_TO_DIAGNOSED_DAYS >300 AND FIRST_TO_DIAGNOSED_DAYS < 401 THEN '5'
WHEN FIRST_TO_DIAGNOSED_DAYS >400 AND FIRST_TO_DIAGNOSED_DAYS < 501 THEN '6'
WHEN FIRST_TO_DIAGNOSED_DAYS >500 AND FIRST_TO_DIAGNOSED_DAYS < 601 THEN '7'
WHEN FIRST_TO_DIAGNOSED_DAYS >600 AND FIRST_TO_DIAGNOSED_DAYS < 701 THEN '8'
WHEN FIRST_TO_DIAGNOSED_DAYS >700 AND FIRST_TO_DIAGNOSED_DAYS < 801 THEN '9'
WHEN FIRST_TO_DIAGNOSED_DAYS >800 AND FIRST_TO_DIAGNOSED_DAYS < 901THEN '10'
WHEN FIRST_TO_DIAGNOSED_DAYS >900 THEN '11'
WHEN FIRST_TO_DIAGNOSED_DAYS IS NULL THEN '12'
END AS FIRST_TO_DIAGNOSED_DAYS_2

from final_test
;

select * from final_test_2 limit 10;

-- CREATE FINAL FINAL FINAL TABLE- Test
drop table final_test_3;
CREATE TABLE FINAL_test_3
AS SELECT
PATIENT_ID
, ILD_STATUS
, GENDER
, RACE
, ETHNICITY
, AGE_AT_LAST_VISIT
, length_of_first_visit
, LENGTH_OF_LAST_VISIT
, avg_length_of_all_visits
, total_nbr_visits
, total_nbr_procs
, avg_nbr_procs_per_encounter
, total_xr
, total_ct
, total_other
, censored
, t
, ccs_desc
, tobacco_pak_per_dy_2
, tobacco_used_years_2
, cigarettes_yn_2
, pipes_yn_2
, cigars_yn_2
, snuff_yn_2 
, alcohol_oz_per_wk_2
, iv_drug_user_yn_2
, tobacco_user_2
, smoking_tob_use_2
, first_to_diagnosed_days_2
from final_test_2;

select * from final_test_3 limit 25;


select distinct ccs_desc from final_training_3;
select distinct ccs_desc from final_test_3;
select count(patient_id) from final_training_3;--100,405
select count(patient_id) from final_test_3;--35050


/*********************************************************
Add ILD probability from Chantel's analysis to datasets
**********************************************************/
/*drop table ild_probs;
Create table ild_probs
(patient_id int not null
, ild_status character varying (1)
, ild_prob character varying (19)
)
;

select * from ild_probs
limit 10;
*/
-- join the ild probs onto final trianing and test files

-- train data file
drop table final_training_4;
create table final_training_4 as
select a.*
, b.ild_prob
from final_training_3 a
left join ild_probs b
on a.patient_id=b.patient_id
;

select count(patient_id) from final_training_3;--100405
select count(patient_id) from final_training_4;--100405

-- test file
drop table final_test_4;
create table final_test_4 as
select a.*
, b.ild_prob
from final_test_3 a
left join ild_probs b
on a.patient_id=b.patient_id
;

select count(patient_id) from final_test_3;--35050
select count(patient_id) from final_test_4;--35050

select * from final_test_4 limit 25;


/* APPENDIX 

select distinct top_dx_1
from final_merged_training
order by top_dx_1 asc;

create temporary table missing_ccs as
select top_dx_1, ccs_cat_desc, ild_status from final_training
where ccs_cat_desc is   null
;
select * from missing_ccs limit 10;

select count(ccs_cat_desc) from final_training
where ccs_cat_desc is null;

select * from icd10 limit 10;

select * from missing_ccs a
left JOIN icd10 b
ON a.top_dx_1 LIKE b.ccs_cat_desc;



select * from icd10 where icd10 like'M1A372%';

select distinct(top_dx_1) from final_merged_training;

select * from icd10 
where icd10='V725';

select * from icd9 
where icd9 like '20%';

SELECT
 TRIM (
 LEADING '0'
 FROM
 CAST (top_dx_1 AS TEXT)
 ) from final_training; -- 9100

select count(*) from icd10;
*/