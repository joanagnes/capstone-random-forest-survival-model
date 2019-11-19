/* THIS SCRIPT IS DIFFERENT FROM V7 AS IT ONLY INCLUDES HOSPITAL ADMITS BEFORE AND UP TO ILD DIAGNOSIS.
IN THIS VERSION, THE DATA ARE PREPARED DIFFERENTLY IN THE FIRST CHUNK TO ACCOUNT FOR THIS CHANGE.*/

/* FIXING NULL ADM AND DISC DATES */
--training
create temporary table cohorts_merged_training0
as select *
, case when adm_date_d is null then start_date_d else adm_date_d end as adm_date_d1
, case when disc_date_d is null then end_date_d else disc_date_d end as disc_date_d1
from cohorts_merged_training
;

--test
create temporary table cohorts_merged_test0
as select *
, case when adm_date_d is null then start_date_d else adm_date_d end as adm_date_d1
, case when disc_date_d is null then end_date_d else disc_date_d end as disc_date_d1
from cohorts_merged_test
;

/*Creating tables for survival analysis-- for ILD patients, remove all observations after ILD diagnosis*/

--training
create temporary table training_ild
as select * from cohorts_merged_training0
where ild_status=1;

create temporary table training_ild2
as
select * from training_ild where adm_date_d1 <= date_diagnosed;

create temporary table training_no_ild
as
select * from cohorts_merged_training0
where ild_status=0;

create temporary table cohorts_merged_training1
as 
select * from training_ild2
union
select * from training_no_ild;

DROP TABLE COHORTS_MERGED_TRAINING0;

--test
create temporary table test_ild
as select * from cohorts_merged_test0
where ild_status=1;

create temporary table test_ild2
as
select * from test_ild where adm_date_d1 <= date_diagnosed;

create temporary table test_no_ild
as
select * from cohorts_merged_test0
where ild_status=0;

create temporary table cohorts_merged_test1
as 
select * from test_ild2
union
select * from test_no_ild;

DROP TABLE COHORTS_MERGED_TEST0;

--FIRST VISIT TABLE
create temporary table first_visit_tab as select patient_id
,encounter_id as first_encounter_id
,gender
,race
,ethnicity
,adm_date_d1 as first_admit_date
,first_disc_date_d
,length_of_first_visit
,age_at_last_encounter as age_at_first_visit
, first_enc_eio
, first_visit_status_1
, first_visit_status_2
, first_visit_status_3
, first_visit_status_4
--, first_start_date_d
--, first_end_date_d
, first_admit_source_1
, first_admit_source_2
, first_admit_source_3
, first_disch_disp_1
, first_disch_disp_2
, first_disch_disp_3
, first_zip_d
, first_contact_date_off
, avg_length_of_all_visits
,rownumber
from(
select patient_id
,encounter_id
,gender
,race
,ethnicity
,age_at_last_encounter
,adm_date_d1
, enc_eio as first_enc_eio
, visit_status_1 as first_visit_status_1
, visit_status_2 as first_visit_status_2
, visit_status_3 as first_visit_status_3
, visit_status_4 as first_visit_status_4
, disc_date_d1 as first_disc_date_d
--, start_date_d as first_start_date_d
--, end_date_d as first_end_date_d
,(disc_date_d1-adm_date_d1) as length_of_first_visit
, admit_source_1 as first_admit_source_1
, admit_source_2 as first_admit_source_2
, admit_source_3 as first_admit_source_3
, disch_disp_1 as first_disch_disp_1
, disch_disp_2 as first_disch_disp_2
, disch_disp_3 as first_disch_disp_3
, zip_d as first_zip_d
, contact_date_off as first_contact_date_off
, round(avg(length_of_visit) over (partition by patient_id order by patient_id),2) as avg_length_of_all_visits
,ROW_NUMBER() 
over (partition by patient_id order by patient_id, adm_date_d1 asc) as rownumber 
from 
(
select distinct on (patient_id, encounter_id) 
patient_id
, encounter_id
, gender
,race
, ethnicity
, age_at_last_encounter
, adm_date_d1
, enc_eio
, visit_status_1
, visit_status_2
, visit_status_3
, visit_status_4
, disc_date_d1
--, start_date_d
--, end_date_d
, admit_source_1
, admit_source_2
, admit_source_3
, disch_disp_1
, disch_disp_2
, disch_disp_3
, zip_d
, contact_date_off
, (disc_date_d1-adm_date_d1) as length_of_visit
from cohorts_merged_training1
) as a
) as b where rownumber=1;
--) as c;

select * from first_visit_tab where avg_length_of_all_visits<0;--0 rows
select count(*) from first_visit_tab;--100,405

select min(avg_length_of_all_visits) from first_visit_tab;-- 0.0 days

--Last visit table
create temporary table last_visit_tab as 
select 
distinct c.patient_id
,c.last_encounter_id
,c.last_admit_date
,c.last_enc_eio
,c.last_visit_status_1
,c.last_visit_status_2
,c.last_visit_status_3
,c.last_visit_status_4
,c.last_disc_date_d
,c.length_of_last_visit
--,c.last_start_date_d
--,c.last_end_date_d
,c.last_admit_source_1
,c.last_admit_source_2
,c.last_admit_source_3
,c.last_disch_disp_1
,c.last_disch_disp_2
,c.last_disch_disp_3
,c.last_zip_d
,c.last_contact_date_off
,c.age_at_last_visit
,c.rownumber 
,c.max_rownumber
from(
select patient_id
,encounter_id as last_encounter_id
,adm_date_d1 as last_admit_date
,age_at_last_encounter as age_at_last_visit
, disc_date_d1 as last_disc_date_d
,length_of_last_visit
, enc_eio as last_enc_eio
, visit_status_1 as last_visit_status_1
, visit_status_2 as last_visit_status_2
, visit_status_3 as last_visit_status_3
, visit_status_4 as last_visit_status_4
--, start_date_d as last_start_date_d
--, end_date_d as last_end_date_d
, admit_source_1 as last_admit_source_1
, admit_source_2 as last_admit_source_2
, admit_source_3 as last_admit_source_3
, disch_disp_1 as last_disch_disp_1
, disch_disp_2 as last_disch_disp_2
, disch_disp_3 as last_disch_disp_3
, zip_d as last_zip_d
, contact_date_off as last_contact_date_off
,rownumber
,max(rownumber) over (partition by patient_id ) as max_rownumber
from(
select patient_id
,encounter_id
,age_at_last_encounter
,adm_date_d1
, enc_eio
, visit_status_1
, visit_status_2
, visit_status_3
, visit_status_4
, disc_date_d1
,(disc_date_d1-adm_date_d1) as length_of_last_visit
--, start_date_d
--, end_date_d
, admit_source_1
, admit_source_2
, admit_source_3
, disch_disp_1
, disch_disp_2
, disch_disp_3
, zip_d
, contact_date_off
,ROW_NUMBER() 
over (partition by patient_id order by patient_id, adm_date_d1 asc) as rownumber
from
(
select distinct on (patient_id, encounter_id) patient_id, encounter_id, age_at_last_encounter
, adm_date_d1
, enc_eio
, visit_status_1
, visit_status_2
, visit_status_3
, visit_status_4
, disc_date_d1
--, start_date_d
--, end_date_d
, admit_source_1
, admit_source_2
, admit_source_3
, disch_disp_1
, disch_disp_2
, disch_disp_3
, zip_d
, contact_date_off
from cohorts_merged_training1
where adm_date_d1 is not null
) as a order by 1,2
) as b group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20
) as c where rownumber=max_rownumber;

select * from last_visit_tab limit 100;
select count(*) from last_visit_tab;--100,405, w/o admit_date_d null filter, with filter 95,258

/*VISITS TABLE-- brining it all together + survey information*/
--drop visits_tab
create temporary table visits_tab as select *
,(date_diagnosed-first_admit_date) as first_to_diagnosed_days
from 
(SELECT
a.patient_id
,c.ild_status
,a.gender
,a.race
,a.ethnicity
,a.first_encounter_id
,a.first_admit_date
, a.first_enc_eio
, a.first_visit_status_1
, a.first_visit_status_2
, a.first_visit_status_3
, a.first_visit_status_4
, a.first_disc_date_d
, a.length_of_first_visit
--, a.first_start_date_d
--, a.first_end_date_d
, a.first_admit_source_1
, a.first_admit_source_2
, a.first_admit_source_3
, a.first_disch_disp_1
, a.first_disch_disp_2
, a.first_disch_disp_3
, a.first_zip_d
, a.first_contact_date_off
,b.last_encounter_id
,b.last_admit_date
,b.age_at_last_visit
,b.last_enc_eio
,b.last_visit_status_1
,b.last_visit_status_2
,b.last_visit_status_3
,b.last_visit_status_4
,b.last_disc_date_d
,b.length_of_last_visit
--,b.last_start_date_d
--,b.last_end_date_d
,b.last_admit_source_1
,b.last_admit_source_2
,b.last_admit_source_3
,b.last_disch_disp_1
,b.last_disch_disp_2
,b.last_disch_disp_3
,b.last_zip_d
,b.last_contact_date_off
,a.avg_length_of_all_visits
,c.encounter_id_diagnosed
,c.date_diagnosed
,c.date_of_death
,c.is_tobacco_user
,c.tobacco_pak_per_dy
,c.tobacco_used_years
,c.smoking_quit_date_off
,c.cigarettes_yn
,c.pipes_yn
,c.cigars_yn
,c.snuff_yn
,c.chew_yn
,c.is_alcohol_user
,c.alcohol_oz_per_wk
,c.is_ill_drug_user
,c.iv_drug_user_yn
,c.illicit_drug_freq
,c.is_sexually_actv
,c.female_partner_yn
,c.male_partner_yn
,c.condom_yn
,c.pill_yn
,c.diaphragm_yn
,c.iud_yn
,c.surgical_yn
,c.spermicide_yn
,c.implant_yn
,c.rhythm_yn
,c.injection_yn
,c.sponge_yn
,c.inserts_yn
,c.abstinence_yn
,c.years_education
,c.tob_src_c
,c.alcohol_src_c
,c.sex_src_c
,c.alcohol_use_c
,c.ill_drug_user_c
,c.sexually_active_c
,c.tobacco_user
,c.smokeless_tob_use_c
,c.smokeless_quit_date_off
,c.smoking_tob_use
,c.unknown_fam_hx_yn
,c.smoking_start_date_off 
from first_visit_tab a
inner join last_visit_tab b
on a.patient_id=b.patient_id
inner join (select distinct on (patient_id) patient_id, encounter_id_diagnosed, date_diagnosed, date_of_death, is_tobacco_user,tobacco_pak_per_dy, tobacco_used_years,smoking_quit_date_off,
cigarettes_yn,pipes_yn,cigars_yn,snuff_yn,chew_yn,is_alcohol_user,alcohol_oz_per_wk,is_ill_drug_user,iv_drug_user_yn,
illicit_drug_freq,is_sexually_actv,female_partner_yn,male_partner_yn,condom_yn,pill_yn,diaphragm_yn,iud_yn,surgical_yn,
spermicide_yn,implant_yn,rhythm_yn,injection_yn,sponge_yn,inserts_yn,abstinence_yn,years_education,tob_src_c,alcohol_src_c,
sex_src_c,alcohol_use_c,ill_drug_user_c,sexually_active_c,tobacco_user,smokeless_tob_use_c,smokeless_quit_date_off,
smoking_tob_use,unknown_fam_hx_yn,smoking_start_date_off,ild_status from cohorts_merged_training1) c
on a.patient_id=c.patient_id
) as d;

select * from visits_tab limit 100;
--select * from visits_tab where patient_id=49;
select count(patient_id) from visits_tab;-- w/admit date filter: 100,405
select count(patient_id) from visits_tab where ild_status=1;--6679

/*AVERAGE NUMBER OF VISITS TABLE*/
create temporary table tab1 as select distinct patient_id, total_nbr_visits
,sum(nbr_procs_per_encount) over (partition by patient_id) as total_nbr_procs
,round(avg(nbr_procs_per_encount) over (partition by patient_id),2) as avg_nbr_procs_per_encounter
from
(
select distinct on (patient_id, encounter_id)
patient_id
,count(encounter_id) over (partition by patient_id) as total_nbr_visits
,count(encounter_id) as nbr_procs_per_encount
from cohorts_merged_training1
where adm_date_d is not null
group by patient_id, encounter_id
) as a;

select * from tab1;
select count(patient_id) from tab1;--95,258

/*NUMBER of visits between first and diagnosis visits and avg length of stays*/
create temporary table tab2 as select distinct patient_id
,encounter_id
,rownumber
,(rownumber -1) as nbr_visits_before_ild_diag 
,avg_length_of_visit_days
from
(
select 
patient_id
,encounter_id
,encounter_id_diagnosed
,round(avg(length_of_visit) over (partition by patient_id order by patient_id)) as avg_length_of_visit_days
,date_diagnosed
--,ild_diag_prior_to_visit
,ild_status
,ROW_NUMBER() 
over (partition by patient_id order by patient_id, adm_date_d asc) as rownumber 
from 
(
select distinct on (patient_id, encounter_id) 
patient_id
,encounter_id
,adm_date_d
,disc_date_d
,(disc_date_d-adm_date_d) as length_of_visit
,encounter_id_diagnosed
,date_diagnosed
--,ild_diag_prior_to_visit
,ild_status
from cohorts_merged_training1
where adm_date_d is not null
) as a
)as b
where encounter_id=encounter_id_diagnosed;

select * from tab2;
select count(patient_id) from tab2;--6271

/*DIAGNOSIS table*/
-- drop table diags;
create temporary table diags as select 
patient_id
,dx_1
,dx_desc_1
,freq
,rank
,row_number() over (partition by patient_id order by patient_id, rank desc) as rownumber
from
(
select 
patient_id, dx_1,dx_desc_1,count(dx_1) as freq ,row_number() over (partition by patient_id order by patient_id,count(dx_1) ) as rank
from(
select distinct encounter_id, patient_id, dx_1, dx_desc_1 from cohorts_merged_training1 where dx_1 is not null
union select distinct encounter_id, patient_id, dx_2, dx_desc_2 from cohorts_merged_training1 where dx_2 is not null
union select distinct encounter_id, patient_id, dx_3, dx_desc_3 from cohorts_merged_training1 where dx_3 is not null
union select distinct encounter_id, patient_id, dx_4, dx_desc_4 from cohorts_merged_training1 where dx_4 is not null
union select distinct encounter_id, patient_id, dx_5, dx_desc_5 from cohorts_merged_training1 where dx_5 is not null
union select distinct encounter_id, patient_id, dx_6, dx_desc_6 from cohorts_merged_training1 where dx_6 is not null
union select distinct encounter_id, patient_id, dx_7, dx_desc_7 from cohorts_merged_training1 where dx_7 is not null
union select distinct encounter_id, patient_id, dx_8, dx_desc_8 from cohorts_merged_training1 where dx_8 is not null
union select distinct encounter_id, patient_id, dx_9, dx_desc_9 from cohorts_merged_training1 where dx_9 is not null
union select distinct encounter_id, patient_id, dx_10, dx_desc_10 from cohorts_merged_training1 where dx_10 is not null
union select distinct encounter_id, patient_id, dx_11, dx_desc_11 from cohorts_merged_training1 where dx_11 is not null
union select distinct encounter_id, patient_id, dx_12, dx_desc_12 from cohorts_merged_training1 where dx_12 is not null
union select distinct encounter_id, patient_id, dx_13, dx_desc_13 from cohorts_merged_training1 where dx_13 is not null
union select distinct encounter_id, patient_id, dx_14, dx_desc_14 from cohorts_merged_training1 where dx_14 is not null
union select distinct encounter_id, patient_id, dx_15, dx_desc_15 from cohorts_merged_training1 where dx_15 is not null
union select distinct encounter_id, patient_id, dx_16, dx_desc_16 from cohorts_merged_training1 where dx_16 is not null
union select distinct encounter_id, patient_id, dx_17, dx_desc_17 from cohorts_merged_training1 where dx_17 is not null
union select distinct encounter_id, patient_id, dx_18, dx_desc_18 from cohorts_merged_training1 where dx_18 is not null
union select distinct encounter_id, patient_id, dx_19, dx_desc_19 from cohorts_merged_training1 where dx_19 is not null
union select distinct encounter_id, patient_id, dx_20, dx_desc_20 from cohorts_merged_training1 where dx_20 is not null
union select distinct encounter_id, patient_id, dx_21, dx_desc_21 from cohorts_merged_training1 where dx_21 is not null
union select distinct encounter_id, patient_id, dx_22, dx_desc_22 from cohorts_merged_training1 where dx_22 is not null
union select distinct encounter_id, patient_id, dx_23, dx_desc_23 from cohorts_merged_training1 where dx_23 is not null
union select distinct encounter_id, patient_id, dx_24, dx_desc_24 from cohorts_merged_training1 where dx_24 is not null
union select distinct encounter_id, patient_id, dx_25, dx_desc_25 from cohorts_merged_training1 where dx_25 is not null
union select distinct encounter_id, patient_id, dx_26, dx_desc_26 from cohorts_merged_training1 where dx_26 is not null
union select distinct encounter_id, patient_id, dx_27, dx_desc_27 from cohorts_merged_training1 where dx_27 is not null
union select distinct encounter_id, patient_id, dx_28, dx_desc_28 from cohorts_merged_training1 where dx_28 is not null
union select distinct encounter_id, patient_id, dx_29, dx_desc_29 from cohorts_merged_training1 where dx_29 is not null
union select distinct encounter_id, patient_id, dx_30, dx_desc_30 from cohorts_merged_training1 where dx_30 is not null
union select distinct encounter_id, patient_id, dx_31, dx_desc_31 from cohorts_merged_training1 where dx_31 is not null
union select distinct encounter_id, patient_id, dx_32, dx_desc_32 from cohorts_merged_training1 where dx_32 is not null
union select distinct encounter_id, patient_id, dx_33, dx_desc_33 from cohorts_merged_training1 where dx_33 is not null
union select distinct encounter_id, patient_id, dx_34, dx_desc_34 from cohorts_merged_training1 where dx_34 is not null
union select distinct encounter_id, patient_id, dx_35, dx_desc_35 from cohorts_merged_training1 where dx_35 is not null
union select distinct encounter_id, patient_id, dx_36, dx_desc_36 from cohorts_merged_training1 where dx_36 is not null
union select distinct encounter_id, patient_id, dx_37, dx_desc_37 from cohorts_merged_training1 where dx_37 is not null
union select distinct encounter_id, patient_id, dx_38, dx_desc_38 from cohorts_merged_training1 where dx_38 is not null
union select distinct encounter_id, patient_id, dx_39, dx_desc_39 from cohorts_merged_training1 where dx_39 is not null
union select distinct encounter_id, patient_id, dx_40, dx_desc_40 from cohorts_merged_training1 where dx_40 is not null
union select distinct encounter_id, patient_id, dx_41, dx_desc_41 from cohorts_merged_training1 where dx_41 is not null
union select distinct encounter_id, patient_id, dx_42, dx_desc_42 from cohorts_merged_training1 where dx_42 is not null
union select distinct encounter_id, patient_id, dx_43, dx_desc_43 from cohorts_merged_training1 where dx_43 is not null
union select distinct encounter_id, patient_id, dx_44, dx_desc_44 from cohorts_merged_training1 where dx_44 is not null
union select distinct encounter_id, patient_id, dx_45, dx_desc_45 from cohorts_merged_training1 where dx_45 is not null
union select distinct encounter_id, patient_id, dx_46, dx_desc_46 from cohorts_merged_training1 where dx_46 is not null
union select distinct encounter_id, patient_id, dx_47, dx_desc_47 from cohorts_merged_training1 where dx_47 is not null
union select distinct encounter_id, patient_id, dx_48, dx_desc_48 from cohorts_merged_training1 where dx_48 is not null
union select distinct encounter_id, patient_id, dx_49, dx_desc_49 from cohorts_merged_training1 where dx_49 is not null
union select distinct encounter_id, patient_id, dx_50, dx_desc_50 from cohorts_merged_training1 where dx_50 is not null
union select distinct encounter_id, patient_id, dx_51, dx_desc_51 from cohorts_merged_training1 where dx_51 is not null
union select distinct encounter_id, patient_id, dx_52, dx_desc_52 from cohorts_merged_training1 where dx_52 is not null
union select distinct encounter_id, patient_id, dx_53, dx_desc_53 from cohorts_merged_training1 where dx_53 is not null
union select distinct encounter_id, patient_id, dx_54, dx_desc_54 from cohorts_merged_training1 where dx_54 is not null
union select distinct encounter_id, patient_id, dx_55, dx_desc_55 from cohorts_merged_training1 where dx_55 is not null
union select distinct encounter_id, patient_id, dx_56, dx_desc_56 from cohorts_merged_training1 where dx_56 is not null
union select distinct encounter_id, patient_id, dx_57, dx_desc_57 from cohorts_merged_training1 where dx_57 is not null
union select distinct encounter_id, patient_id, dx_58, dx_desc_58 from cohorts_merged_training1 where dx_58 is not null
union select distinct encounter_id, patient_id, dx_59, dx_desc_59 from cohorts_merged_training1 where dx_59 is not null
union select distinct encounter_id, patient_id, dx_60, dx_desc_60 from cohorts_merged_training1 where dx_60 is not null
union select distinct encounter_id, patient_id, dx_61, dx_desc_61 from cohorts_merged_training1 where dx_61 is not null
union select distinct encounter_id, patient_id, dx_62, dx_desc_62 from cohorts_merged_training1 where dx_62 is not null
union select distinct encounter_id, patient_id, dx_63, dx_desc_63 from cohorts_merged_training1 where dx_63 is not null
union select distinct encounter_id, patient_id, dx_64, dx_desc_64 from cohorts_merged_training1 where dx_64 is not null
union select distinct encounter_id, patient_id, dx_65, dx_desc_65 from cohorts_merged_training1 where dx_65 is not null
union select distinct encounter_id, patient_id, dx_66, dx_desc_66 from cohorts_merged_training1 where dx_66 is not null
union select distinct encounter_id, patient_id, dx_67, dx_desc_67 from cohorts_merged_training1 where dx_67 is not null
union select distinct encounter_id, patient_id, dx_68, dx_desc_68 from cohorts_merged_training1 where dx_68 is not null
union select distinct encounter_id, patient_id, dx_69, dx_desc_69 from cohorts_merged_training1 where dx_69 is not null
union select distinct encounter_id, patient_id, dx_70, dx_desc_70 from cohorts_merged_training1 where dx_70 is not null
union select distinct encounter_id, patient_id, dx_71, dx_desc_71 from cohorts_merged_training1 where dx_71 is not null
union select distinct encounter_id, patient_id, dx_72, dx_desc_72 from cohorts_merged_training1 where dx_72 is not null
union select distinct encounter_id, patient_id, dx_73, dx_desc_73 from cohorts_merged_training1 where dx_73 is not null
union select distinct encounter_id, patient_id, dx_74, dx_desc_74 from cohorts_merged_training1 where dx_74 is not null
union select distinct encounter_id, patient_id, dx_75, dx_desc_75 from cohorts_merged_training1 where dx_75 is not null
union select distinct encounter_id, patient_id, dx_76, dx_desc_76 from cohorts_merged_training1 where dx_76 is not null
union select distinct encounter_id, patient_id, dx_77, dx_desc_77 from cohorts_merged_training1 where dx_77 is not null
union select distinct encounter_id, patient_id, dx_78, dx_desc_78 from cohorts_merged_training1 where dx_78 is not null
union select distinct encounter_id, patient_id, dx_79, dx_desc_79 from cohorts_merged_training1 where dx_79 is not null
union select distinct encounter_id, patient_id, dx_80, dx_desc_80 from cohorts_merged_training1 where dx_80 is not null
union select distinct encounter_id, patient_id, dx_81, dx_desc_81 from cohorts_merged_training1 where dx_81 is not null
union select distinct encounter_id, patient_id, dx_82, dx_desc_82 from cohorts_merged_training1 where dx_82 is not null
union select distinct encounter_id, patient_id, dx_83, dx_desc_83 from cohorts_merged_training1 where dx_83 is not null
union select distinct encounter_id, patient_id, dx_84, dx_desc_84 from cohorts_merged_training1 where dx_84 is not null
union select distinct encounter_id, patient_id, dx_85, dx_desc_85 from cohorts_merged_training1 where dx_85 is not null
union select distinct encounter_id, patient_id, dx_86, dx_desc_86 from cohorts_merged_training1 where dx_86 is not null
)as foo 
group by patient_id, dx_1, dx_desc_1
order by patient_id, rank desc
) as foo2
group by 1,2,3,4,5;

select * from diags limit 100;
select count(distinct patient_id) from diags;--100,361

-- drop table top_diags;
create temporary table top_diags as select 
patient_id
,max(case rownumber when 1 then dx_1 end) as top_dx_1
,max(case rownumber when 2 then dx_1 end) as top_dx_2
,max(case rownumber when 3 then dx_1 end) as top_dx_3
,max(case rownumber when 4 then dx_1 end) as top_dx_4
,max(case rownumber when 5 then dx_1 end) as top_dx_5
,max(case rownumber when 6 then dx_1 end) as top_dx_6
,max(case rownumber when 7 then dx_1 end) as top_dx_7
,max(case rownumber when 8 then dx_1 end) as top_dx_8
,max(case rownumber when 9 then dx_1 end) as top_dx_9
,max(case rownumber when 10 then dx_1 end) as top_dx_10
from diags
group by 1
;

select * from top_diags;

/* X-RAY TABLE */
-- drop table xray;
create temporary table xray as select distinct(b.patient_id)
,max(case b.exam_type when 'XR' then b.freq else 0 end) as total_XR
,max(case b.exam_type when 'CT' then b.freq else 0 end) as total_CT
,max(case b.exam_type when 'Other' then b.freq else 0 end) as total_Other
from
(
select patient_id, exam_type, count(exam_type) as freq, ROW_NUMBER() over (
partition by patient_id order by patient_id, count(exam_type)desc) as rownumber
from (
select patient_id
, case 
when exam_type='XR' then 'XR' 
when exam_type='CT' then 'CT' 
else 'Other' 
end as exam_type
from
(
select patient_id, trim(left(exam_type, 3)) as exam_type from cohorts_merged_training1
) as foo
) as a
group by patient_id, exam_type
) as b
group by b.patient_id;

select * from xray limit 50;

/*FINAL DATASET */
drop table final_merged_training;
create table final_merged_training as select 
*
,case when ild_status=1 then 0 else 1 end as censored
,case when ild_status=1 then date_diagnosed-first_admit_date
when ild_status=0 and date_of_death is not null then date_of_death-first_admit_date
when ild_status=0 and date_of_death is null then last_disc_date_d-first_admit_date
end as t
from
(
select
a.*
,b.total_nbr_visits
,b.total_nbr_procs
,b.avg_nbr_procs_per_encounter
--,c.nbr_visits_before_ild_diag
,d.top_dx_1
,d.top_dx_2
,d.top_dx_3
,d.top_dx_4
,d.top_dx_5
,d.top_dx_6
,d.top_dx_7
,d.top_dx_8
,d.top_dx_9
,d.top_dx_10
,e.total_XR
,e.total_CT
,total_Other
from visits_tab a
left join tab1 b on a.patient_id=b.patient_id
left join tab2 c on a.patient_id=c.patient_id
left join top_diags d on a.patient_id=d.patient_id
left join xray e on a.patient_id=e.patient_id
) as foo
;

select * from final_merged_training limit 100;
select count(patient_id) from final_merged_training;--100,405

select * from final_merged_training where top_dx_1 is null;--44 rows

select * from final_merged_training where first_disc_date_d is null;--0
select count(patient_id) from final_merged_training where t<0;

/**********************************************************************************/
/***** TREATMENT FOR TEST DATA ***************************************************/
/********************************************************************************/

--FIRST VISIT TABLE
--just checking counts
drop table first_visit_tab;
--select count(patient_id) from --100405 rows
--(
create temporary table first_visit_tab as select patient_id
,encounter_id as first_encounter_id
,gender
,race
,ethnicity
,adm_date_d1 as first_admit_date
,first_disc_date_d
,length_of_first_visit
,age_at_last_encounter as age_at_first_visit
, first_enc_eio
, first_visit_status_1
, first_visit_status_2
, first_visit_status_3
, first_visit_status_4
--, first_start_date_d
--, first_end_date_d
, first_admit_source_1
, first_admit_source_2
, first_admit_source_3
, first_disch_disp_1
, first_disch_disp_2
, first_disch_disp_3
, first_zip_d
, first_contact_date_off
, avg_length_of_all_visits
,rownumber
from(
select patient_id
,encounter_id
,gender
,race
,ethnicity
,age_at_last_encounter
,adm_date_d1
, enc_eio as first_enc_eio
, visit_status_1 as first_visit_status_1
, visit_status_2 as first_visit_status_2
, visit_status_3 as first_visit_status_3
, visit_status_4 as first_visit_status_4
, disc_date_d1 as first_disc_date_d
--, start_date_d as first_start_date_d
--, end_date_d as first_end_date_d
,(disc_date_d1-adm_date_d1) as length_of_first_visit
, admit_source_1 as first_admit_source_1
, admit_source_2 as first_admit_source_2
, admit_source_3 as first_admit_source_3
, disch_disp_1 as first_disch_disp_1
, disch_disp_2 as first_disch_disp_2
, disch_disp_3 as first_disch_disp_3
, zip_d as first_zip_d
, contact_date_off as first_contact_date_off
, round(avg(length_of_visit) over (partition by patient_id order by patient_id),2) as avg_length_of_all_visits
,ROW_NUMBER() 
over (partition by patient_id order by patient_id, adm_date_d1 asc) as rownumber 
from 
(
select distinct on (patient_id, encounter_id) 
patient_id
, encounter_id
, gender
,race
, ethnicity
, age_at_last_encounter
, adm_date_d1
, enc_eio
, visit_status_1
, visit_status_2
, visit_status_3
, visit_status_4
, disc_date_d1
--, start_date_d
--, end_date_d
, admit_source_1
, admit_source_2
, admit_source_3
, disch_disp_1
, disch_disp_2
, disch_disp_3
, zip_d
, contact_date_off
, (disc_date_d1-adm_date_d1) as length_of_visit
from cohorts_merged_test1
) as a
) as b where rownumber=1;
--) as c;

select * from first_visit_tab where avg_length_of_all_visits<0;--0 rows
select count(*) from first_visit_tab;--100,405

select min(avg_length_of_all_visits) from first_visit_tab;-- 0.0 days

--PATIENT AGE AT LAST ENCOUNTER
 drop table last_visit_tab;
create temporary table last_visit_tab as 
select 
distinct c.patient_id
,c.last_encounter_id
,c.last_admit_date
,c.last_enc_eio
,c.last_visit_status_1
,c.last_visit_status_2
,c.last_visit_status_3
,c.last_visit_status_4
,c.last_disc_date_d
,c.length_of_last_visit
--,c.last_start_date_d
--,c.last_end_date_d
,c.last_admit_source_1
,c.last_admit_source_2
,c.last_admit_source_3
,c.last_disch_disp_1
,c.last_disch_disp_2
,c.last_disch_disp_3
,c.last_zip_d
,c.last_contact_date_off
,c.age_at_last_visit
,c.rownumber 
,c.max_rownumber
from(
select patient_id
,encounter_id as last_encounter_id
,adm_date_d1 as last_admit_date
,age_at_last_encounter as age_at_last_visit
, disc_date_d1 as last_disc_date_d
,length_of_last_visit
, enc_eio as last_enc_eio
, visit_status_1 as last_visit_status_1
, visit_status_2 as last_visit_status_2
, visit_status_3 as last_visit_status_3
, visit_status_4 as last_visit_status_4
--, start_date_d as last_start_date_d
--, end_date_d as last_end_date_d
, admit_source_1 as last_admit_source_1
, admit_source_2 as last_admit_source_2
, admit_source_3 as last_admit_source_3
, disch_disp_1 as last_disch_disp_1
, disch_disp_2 as last_disch_disp_2
, disch_disp_3 as last_disch_disp_3
, zip_d as last_zip_d
, contact_date_off as last_contact_date_off
,rownumber
,max(rownumber) over (partition by patient_id ) as max_rownumber
from(
select patient_id
,encounter_id
,age_at_last_encounter
,adm_date_d1
, enc_eio
, visit_status_1
, visit_status_2
, visit_status_3
, visit_status_4
, disc_date_d1
,(disc_date_d1-adm_date_d1) as length_of_last_visit
--, start_date_d
--, end_date_d
, admit_source_1
, admit_source_2
, admit_source_3
, disch_disp_1
, disch_disp_2
, disch_disp_3
, zip_d
, contact_date_off
,ROW_NUMBER() 
over (partition by patient_id order by patient_id, adm_date_d1 asc) as rownumber
from
(
select distinct on (patient_id, encounter_id) patient_id, encounter_id, age_at_last_encounter
, adm_date_d1
, enc_eio
, visit_status_1
, visit_status_2
, visit_status_3
, visit_status_4
, disc_date_d1
--, start_date_d
--, end_date_d
, admit_source_1
, admit_source_2
, admit_source_3
, disch_disp_1
, disch_disp_2
, disch_disp_3
, zip_d
, contact_date_off
from cohorts_merged_test1
where adm_date_d1 is not null
) as a order by 1,2
) as b group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20
) as c where rownumber=max_rownumber;

select * from last_visit_tab limit 100;
select count(*) from last_visit_tab;--100,405, w/o admit_date_d null filter, with filter 95,258

/*VISITS TABLE-- brining it all together + survey information*/
-- drop table visits_tab;
drop table visits_tab;

create temporary table visits_tab as select *
,(date_diagnosed-first_admit_date) as first_to_diagnosed_days
from 
(SELECT
a.patient_id
,c.ild_status
,a.gender
,a.race
,a.ethnicity
,a.first_encounter_id
,a.first_admit_date
, a.first_enc_eio
, a.first_visit_status_1
, a.first_visit_status_2
, a.first_visit_status_3
, a.first_visit_status_4
, a.first_disc_date_d
, a.length_of_first_visit
--, a.first_start_date_d
--, a.first_end_date_d
, a.first_admit_source_1
, a.first_admit_source_2
, a.first_admit_source_3
, a.first_disch_disp_1
, a.first_disch_disp_2
, a.first_disch_disp_3
, a.first_zip_d
, a.first_contact_date_off
,b.last_encounter_id
,b.last_admit_date
,b.age_at_last_visit
,b.last_enc_eio
,b.last_visit_status_1
,b.last_visit_status_2
,b.last_visit_status_3
,b.last_visit_status_4
,b.last_disc_date_d
,b.length_of_last_visit
--,b.last_start_date_d
--,b.last_end_date_d
,b.last_admit_source_1
,b.last_admit_source_2
,b.last_admit_source_3
,b.last_disch_disp_1
,b.last_disch_disp_2
,b.last_disch_disp_3
,b.last_zip_d
,b.last_contact_date_off
,a.avg_length_of_all_visits
,c.encounter_id_diagnosed
,c.date_diagnosed
,c.date_of_death
,c.is_tobacco_user
,c.tobacco_pak_per_dy
,c.tobacco_used_years
,c.smoking_quit_date_off
,c.cigarettes_yn
,c.pipes_yn
,c.cigars_yn
,c.snuff_yn
,c.chew_yn
,c.is_alcohol_user
,c.alcohol_oz_per_wk
,c.is_ill_drug_user
,c.iv_drug_user_yn
,c.illicit_drug_freq
,c.is_sexually_actv
,c.female_partner_yn
,c.male_partner_yn
,c.condom_yn
,c.pill_yn
,c.diaphragm_yn
,c.iud_yn
,c.surgical_yn
,c.spermicide_yn
,c.implant_yn
,c.rhythm_yn
,c.injection_yn
,c.sponge_yn
,c.inserts_yn
,c.abstinence_yn
,c.years_education
,c.tob_src_c
,c.alcohol_src_c
,c.sex_src_c
,c.alcohol_use_c
,c.ill_drug_user_c
,c.sexually_active_c
,c.tobacco_user
,c.smokeless_tob_use_c
,c.smokeless_quit_date_off
,c.smoking_tob_use
,c.unknown_fam_hx_yn
,c.smoking_start_date_off 
from first_visit_tab a
inner join last_visit_tab b
on a.patient_id=b.patient_id
inner join (select distinct on (patient_id) patient_id, encounter_id_diagnosed, date_diagnosed, date_of_death, is_tobacco_user
,tobacco_pak_per_dy, tobacco_used_years,smoking_quit_date_off,
cigarettes_yn,pipes_yn,cigars_yn,snuff_yn,chew_yn,is_alcohol_user,alcohol_oz_per_wk,is_ill_drug_user,iv_drug_user_yn,
illicit_drug_freq,is_sexually_actv,female_partner_yn,male_partner_yn,condom_yn,pill_yn,diaphragm_yn,iud_yn,surgical_yn,
spermicide_yn,implant_yn,rhythm_yn,injection_yn,sponge_yn,inserts_yn,abstinence_yn,years_education,tob_src_c,alcohol_src_c,
sex_src_c,alcohol_use_c,ill_drug_user_c,sexually_active_c,tobacco_user,smokeless_tob_use_c,smokeless_quit_date_off,
smoking_tob_use,unknown_fam_hx_yn,smoking_start_date_off,ild_status from cohorts_merged_test1) c
on a.patient_id=c.patient_id
) as d;

select * from visits_tab limit 100;
--select * from visits_tab where patient_id=49;
select count(patient_id) from visits_tab;-- w/admit date filter: 100,405
select count(patient_id) from visits_tab where ild_status=1;--6679

/*AVERAGE NUMBER OF VISITS TABLE*/
drop table tab1;
create temporary table tab1 as select distinct patient_id, total_nbr_visits
,sum(nbr_procs_per_encount) over (partition by patient_id) as total_nbr_procs
,round(avg(nbr_procs_per_encount) over (partition by patient_id),2) as avg_nbr_procs_per_encounter
from
(
select distinct on (patient_id, encounter_id)
patient_id
,count(encounter_id) over (partition by patient_id) as total_nbr_visits
,count(encounter_id) as nbr_procs_per_encount
from cohorts_merged_test1
where adm_date_d is not null
group by patient_id, encounter_id
) as a;

select * from tab1;
select count(patient_id) from tab1;--95,258

/*NUMBER of visits between first and diagnosis visits and avg length of stays*/
drop table tab2;

create temporary table tab2 as select distinct patient_id
,encounter_id
,rownumber
,(rownumber -1) as nbr_visits_before_ild_diag 
,avg_length_of_visit_days
from
(
select 
patient_id
,encounter_id
,encounter_id_diagnosed
,round(avg(length_of_visit) over (partition by patient_id order by patient_id)) as avg_length_of_visit_days
,date_diagnosed
--,ild_diag_prior_to_visit
,ild_status
,ROW_NUMBER() 
over (partition by patient_id order by patient_id, adm_date_d asc) as rownumber 
from 
(
select distinct on (patient_id, encounter_id) 
patient_id
,encounter_id
,adm_date_d
,disc_date_d
,(disc_date_d-adm_date_d) as length_of_visit
,encounter_id_diagnosed
,date_diagnosed
--,ild_diag_prior_to_visit
,ild_status
from cohorts_merged_test1
where adm_date_d is not null
) as a
)as b
where encounter_id=encounter_id_diagnosed;

select * from tab2;
select count(patient_id) from tab2;--6271

/*DIAGNOSIS table*/
drop table diags;
create temporary table diags as select 
patient_id
,dx_1
,dx_desc_1
,freq
,rank
,row_number() over (partition by patient_id order by patient_id, rank desc) as rownumber
from
(
select 
patient_id, dx_1,dx_desc_1,count(dx_1) as freq ,row_number() over (partition by patient_id order by patient_id,count(dx_1) ) as rank
from(
select distinct encounter_id, patient_id, dx_1, dx_desc_1 from cohorts_merged_TEST1 where dx_1 is not null
union select distinct encounter_id, patient_id, dx_2, dx_desc_2 from cohorts_merged_TEST1 where dx_2 is not null
union select distinct encounter_id, patient_id, dx_3, dx_desc_3 from cohorts_merged_TEST1 where dx_3 is not null
union select distinct encounter_id, patient_id, dx_4, dx_desc_4 from cohorts_merged_TEST1 where dx_4 is not null
union select distinct encounter_id, patient_id, dx_5, dx_desc_5 from cohorts_merged_TEST1 where dx_5 is not null
union select distinct encounter_id, patient_id, dx_6, dx_desc_6 from cohorts_merged_TEST1 where dx_6 is not null
union select distinct encounter_id, patient_id, dx_7, dx_desc_7 from cohorts_merged_TEST1 where dx_7 is not null
union select distinct encounter_id, patient_id, dx_8, dx_desc_8 from cohorts_merged_TEST1 where dx_8 is not null
union select distinct encounter_id, patient_id, dx_9, dx_desc_9 from cohorts_merged_TEST1 where dx_9 is not null
union select distinct encounter_id, patient_id, dx_10, dx_desc_10 from cohorts_merged_TEST1 where dx_10 is not null
union select distinct encounter_id, patient_id, dx_11, dx_desc_11 from cohorts_merged_TEST1 where dx_11 is not null
union select distinct encounter_id, patient_id, dx_12, dx_desc_12 from cohorts_merged_TEST1 where dx_12 is not null
union select distinct encounter_id, patient_id, dx_13, dx_desc_13 from cohorts_merged_TEST1 where dx_13 is not null
union select distinct encounter_id, patient_id, dx_14, dx_desc_14 from cohorts_merged_TEST1 where dx_14 is not null
union select distinct encounter_id, patient_id, dx_15, dx_desc_15 from cohorts_merged_TEST1 where dx_15 is not null
union select distinct encounter_id, patient_id, dx_16, dx_desc_16 from cohorts_merged_TEST1 where dx_16 is not null
union select distinct encounter_id, patient_id, dx_17, dx_desc_17 from cohorts_merged_TEST1 where dx_17 is not null
union select distinct encounter_id, patient_id, dx_18, dx_desc_18 from cohorts_merged_TEST1 where dx_18 is not null
union select distinct encounter_id, patient_id, dx_19, dx_desc_19 from cohorts_merged_TEST1 where dx_19 is not null
union select distinct encounter_id, patient_id, dx_20, dx_desc_20 from cohorts_merged_TEST1 where dx_20 is not null
union select distinct encounter_id, patient_id, dx_21, dx_desc_21 from cohorts_merged_TEST1 where dx_21 is not null
union select distinct encounter_id, patient_id, dx_22, dx_desc_22 from cohorts_merged_TEST1 where dx_22 is not null
union select distinct encounter_id, patient_id, dx_23, dx_desc_23 from cohorts_merged_TEST1 where dx_23 is not null
union select distinct encounter_id, patient_id, dx_24, dx_desc_24 from cohorts_merged_TEST1 where dx_24 is not null
union select distinct encounter_id, patient_id, dx_25, dx_desc_25 from cohorts_merged_TEST1 where dx_25 is not null
union select distinct encounter_id, patient_id, dx_26, dx_desc_26 from cohorts_merged_TEST1 where dx_26 is not null
union select distinct encounter_id, patient_id, dx_27, dx_desc_27 from cohorts_merged_TEST1 where dx_27 is not null
union select distinct encounter_id, patient_id, dx_28, dx_desc_28 from cohorts_merged_TEST1 where dx_28 is not null
union select distinct encounter_id, patient_id, dx_29, dx_desc_29 from cohorts_merged_TEST1 where dx_29 is not null
union select distinct encounter_id, patient_id, dx_30, dx_desc_30 from cohorts_merged_TEST1 where dx_30 is not null
union select distinct encounter_id, patient_id, dx_31, dx_desc_31 from cohorts_merged_TEST1 where dx_31 is not null
union select distinct encounter_id, patient_id, dx_32, dx_desc_32 from cohorts_merged_TEST1 where dx_32 is not null
union select distinct encounter_id, patient_id, dx_33, dx_desc_33 from cohorts_merged_TEST1 where dx_33 is not null
union select distinct encounter_id, patient_id, dx_34, dx_desc_34 from cohorts_merged_TEST1 where dx_34 is not null
union select distinct encounter_id, patient_id, dx_35, dx_desc_35 from cohorts_merged_TEST1 where dx_35 is not null
union select distinct encounter_id, patient_id, dx_36, dx_desc_36 from cohorts_merged_TEST1 where dx_36 is not null
union select distinct encounter_id, patient_id, dx_37, dx_desc_37 from cohorts_merged_TEST1 where dx_37 is not null
union select distinct encounter_id, patient_id, dx_38, dx_desc_38 from cohorts_merged_TEST1 where dx_38 is not null
union select distinct encounter_id, patient_id, dx_39, dx_desc_39 from cohorts_merged_TEST1 where dx_39 is not null
union select distinct encounter_id, patient_id, dx_40, dx_desc_40 from cohorts_merged_TEST1 where dx_40 is not null
union select distinct encounter_id, patient_id, dx_41, dx_desc_41 from cohorts_merged_TEST1 where dx_41 is not null
union select distinct encounter_id, patient_id, dx_42, dx_desc_42 from cohorts_merged_TEST1 where dx_42 is not null
union select distinct encounter_id, patient_id, dx_43, dx_desc_43 from cohorts_merged_TEST1 where dx_43 is not null
union select distinct encounter_id, patient_id, dx_44, dx_desc_44 from cohorts_merged_TEST1 where dx_44 is not null
union select distinct encounter_id, patient_id, dx_45, dx_desc_45 from cohorts_merged_TEST1 where dx_45 is not null
union select distinct encounter_id, patient_id, dx_46, dx_desc_46 from cohorts_merged_TEST1 where dx_46 is not null
union select distinct encounter_id, patient_id, dx_47, dx_desc_47 from cohorts_merged_TEST1 where dx_47 is not null
union select distinct encounter_id, patient_id, dx_48, dx_desc_48 from cohorts_merged_TEST1 where dx_48 is not null
union select distinct encounter_id, patient_id, dx_49, dx_desc_49 from cohorts_merged_TEST1 where dx_49 is not null
union select distinct encounter_id, patient_id, dx_50, dx_desc_50 from cohorts_merged_TEST1 where dx_50 is not null
union select distinct encounter_id, patient_id, dx_51, dx_desc_51 from cohorts_merged_TEST1 where dx_51 is not null
union select distinct encounter_id, patient_id, dx_52, dx_desc_52 from cohorts_merged_TEST1 where dx_52 is not null
union select distinct encounter_id, patient_id, dx_53, dx_desc_53 from cohorts_merged_TEST1 where dx_53 is not null
union select distinct encounter_id, patient_id, dx_54, dx_desc_54 from cohorts_merged_TEST1 where dx_54 is not null
union select distinct encounter_id, patient_id, dx_55, dx_desc_55 from cohorts_merged_TEST1 where dx_55 is not null
union select distinct encounter_id, patient_id, dx_56, dx_desc_56 from cohorts_merged_TEST1 where dx_56 is not null
union select distinct encounter_id, patient_id, dx_57, dx_desc_57 from cohorts_merged_TEST1 where dx_57 is not null
union select distinct encounter_id, patient_id, dx_58, dx_desc_58 from cohorts_merged_TEST1 where dx_58 is not null
union select distinct encounter_id, patient_id, dx_59, dx_desc_59 from cohorts_merged_TEST1 where dx_59 is not null
union select distinct encounter_id, patient_id, dx_60, dx_desc_60 from cohorts_merged_TEST1 where dx_60 is not null
union select distinct encounter_id, patient_id, dx_61, dx_desc_61 from cohorts_merged_TEST1 where dx_61 is not null
union select distinct encounter_id, patient_id, dx_62, dx_desc_62 from cohorts_merged_TEST1 where dx_62 is not null
union select distinct encounter_id, patient_id, dx_63, dx_desc_63 from cohorts_merged_TEST1 where dx_63 is not null
union select distinct encounter_id, patient_id, dx_64, dx_desc_64 from cohorts_merged_TEST1 where dx_64 is not null
union select distinct encounter_id, patient_id, dx_65, dx_desc_65 from cohorts_merged_TEST1 where dx_65 is not null
union select distinct encounter_id, patient_id, dx_66, dx_desc_66 from cohorts_merged_TEST1 where dx_66 is not null
union select distinct encounter_id, patient_id, dx_67, dx_desc_67 from cohorts_merged_TEST1 where dx_67 is not null
union select distinct encounter_id, patient_id, dx_68, dx_desc_68 from cohorts_merged_TEST1 where dx_68 is not null
union select distinct encounter_id, patient_id, dx_69, dx_desc_69 from cohorts_merged_TEST1 where dx_69 is not null
union select distinct encounter_id, patient_id, dx_70, dx_desc_70 from cohorts_merged_TEST1 where dx_70 is not null
union select distinct encounter_id, patient_id, dx_71, dx_desc_71 from cohorts_merged_TEST1 where dx_71 is not null
union select distinct encounter_id, patient_id, dx_72, dx_desc_72 from cohorts_merged_TEST1 where dx_72 is not null
union select distinct encounter_id, patient_id, dx_73, dx_desc_73 from cohorts_merged_TEST1 where dx_73 is not null
union select distinct encounter_id, patient_id, dx_74, dx_desc_74 from cohorts_merged_TEST1 where dx_74 is not null
union select distinct encounter_id, patient_id, dx_75, dx_desc_75 from cohorts_merged_TEST1 where dx_75 is not null
union select distinct encounter_id, patient_id, dx_76, dx_desc_76 from cohorts_merged_TEST1 where dx_76 is not null
union select distinct encounter_id, patient_id, dx_77, dx_desc_77 from cohorts_merged_TEST1 where dx_77 is not null
union select distinct encounter_id, patient_id, dx_78, dx_desc_78 from cohorts_merged_TEST1 where dx_78 is not null
union select distinct encounter_id, patient_id, dx_79, dx_desc_79 from cohorts_merged_TEST1 where dx_79 is not null
union select distinct encounter_id, patient_id, dx_80, dx_desc_80 from cohorts_merged_TEST1 where dx_80 is not null
union select distinct encounter_id, patient_id, dx_81, dx_desc_81 from cohorts_merged_TEST1 where dx_81 is not null
union select distinct encounter_id, patient_id, dx_82, dx_desc_82 from cohorts_merged_TEST1 where dx_82 is not null
union select distinct encounter_id, patient_id, dx_83, dx_desc_83 from cohorts_merged_TEST1 where dx_83 is not null
union select distinct encounter_id, patient_id, dx_84, dx_desc_84 from cohorts_merged_TEST1 where dx_84 is not null
union select distinct encounter_id, patient_id, dx_85, dx_desc_85 from cohorts_merged_TEST1 where dx_85 is not null
union select distinct encounter_id, patient_id, dx_86, dx_desc_86 from cohorts_merged_TEST1 where dx_86 is not null
)as foo 
group by patient_id, dx_1, dx_desc_1
order by patient_id, rank desc
) as foo2
group by 1,2,3,4,5;

select * from diags limit 100;
select count(distinct patient_id) from diags;--95,216

drop table top_diags;
create temporary table top_diags as select 
patient_id
,max(case rownumber when 1 then dx_1 end) as top_dx_1
,max(case rownumber when 2 then dx_1 end) as top_dx_2
,max(case rownumber when 3 then dx_1 end) as top_dx_3
,max(case rownumber when 4 then dx_1 end) as top_dx_4
,max(case rownumber when 5 then dx_1 end) as top_dx_5
,max(case rownumber when 6 then dx_1 end) as top_dx_6
,max(case rownumber when 7 then dx_1 end) as top_dx_7
,max(case rownumber when 8 then dx_1 end) as top_dx_8
,max(case rownumber when 9 then dx_1 end) as top_dx_9
,max(case rownumber when 10 then dx_1 end) as top_dx_10
from diags
group by 1
;

select * from top_diags;

/* X-RAY TABLE */
drop table xray;
create temporary table xray as select distinct(b.patient_id)
,max(case b.exam_type when 'XR' then b.freq else 0 end) as total_XR
,max(case b.exam_type when 'CT' then b.freq else 0 end) as total_CT
,max(case b.exam_type when 'Other' then b.freq else 0 end) as total_Other
from
(
select patient_id, exam_type, count(exam_type) as freq, ROW_NUMBER() over (
partition by patient_id order by patient_id, count(exam_type)desc) as rownumber
from (
select patient_id
, case 
when exam_type='XR' then 'XR' 
when exam_type='CT' then 'CT' 
else 'Other' 
end as exam_type
from
(
select patient_id, trim(left(exam_type, 3)) as exam_type from cohorts_merged_test1
) as foo
) as a
group by patient_id, exam_type
) as b
group by b.patient_id;

select * from xray limit 50;

/*FINAL DATASET */
drop table final_merged_test;
create table final_merged_test as select 
*
,case when ild_status=1 then 0 else 1 end as censored
,case when ild_status=1 then date_diagnosed-first_admit_date
when ild_status=0 and date_of_death is not null then date_of_death-first_admit_date
when ild_status=0 and date_of_death is null then last_disc_date_d-first_admit_date
end as t
from
(
select
a.*
,b.total_nbr_visits
,b.total_nbr_procs
,b.avg_nbr_procs_per_encounter
--,c.nbr_visits_before_ild_diag
,d.top_dx_1
,d.top_dx_2
,d.top_dx_3
,d.top_dx_4
,d.top_dx_5
,d.top_dx_6
,d.top_dx_7
,d.top_dx_8
,d.top_dx_9
,d.top_dx_10
,e.total_XR
,e.total_CT
,total_Other
from visits_tab a
left join tab1 b on a.patient_id=b.patient_id
left join tab2 c on a.patient_id=c.patient_id
left join top_diags d on a.patient_id=d.patient_id
left join xray e on a.patient_id=e.patient_id
) as foo
;

select * from final_merged_test limit 100;
select count(patient_id) from final_merged_test;-- 36,897

select * from final_merged_test where top_dx_1 is null;--4 rows

select * from final_merged_test where t is null;--0
select * from final_merged_test where first_disc_date_d is null;--0

select * from final_merged_test where first_to_diagnosed_days is null;

/*******************************************************************************************
checks
*************************************************************************************/
select * from final_merged_training limit 10;

select min(t) from final_merged_training;

select * from final_merged_test where patient_id=3048;


select distinct top_dx_1 from final_merged_training;

select * from cohorts_merged_training limit 25;

select * from FINAL_merged_training WHERE IS_ILL_DRUG_USER IS NOT NULL limit 25;

SELECT * FROM FINAL_MERGED_TRAINING LIMIT 7;
SELECT * FROM FINAL_MERGED_TRAINING WHERE FIRST_TO_DIAGNOSED_DAYS = 1385;

SELECT * FROM COHORTS_MERGED_TRAINING WHERE PATIENT_ID=1577305;


SELECT DISTINCT SMOKING_TOB_USE FROM FINAL_MERGED_TRAINING ORDER BY SMOKING_TOB_USE DESC;

SELECT
CASE WHEN SMOKING_TOB_USE = 'Unknown If Ever Smoked' THEN '1'
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
FROM FINAL_MERGED_TRAINING;

select distinct t, count(t) from final_merged_training where ild_status=1 
group by 1 
order by t desc;

select * from final_merged_training limit 5;

select count(distinct patient_id) from final_merged_training where cigarettes_yn is null;--32069
select count(distinct patient_id) from final_merged_training;--100405
