/************************************************************************************************************
 * Project	: Individual Project with 10% IQVIA PharMetrics Sample - EB in SjS with ILD
 * Section	: 3-PS matching
 * Created	: 2021-02-07
 * Edited	: 2021-08-29
 * Author	: Tsung-Ying Lee
 *************************************************************************************************************/
libname I "/_PHSR_CDB_SASDS/IMS_HEALTH" access=readonly;
libname T "/_COURSEWORK/ResMeth/AY_2020_2021/LEE_T/Publication/Tasks";
libname F "/_COURSEWORK/ResMeth/AY_2020_2021/LEE_T/Publication/Full10pcSample_AnalyticalFile";
options nocenter ls=132 ps=63 msglevel=i mprint mlogic mautosource;

/*	Step 9 - Match cases to controls on index year, age, sex, geographic region of residence, insurance type */

proc logistic data=T.step_8 descending;
model stu_g = age sex2 pat_region2 index_year prd_type;
output out=propensity_scores
pred = prob_treat;
run;

data prop_score_treated
	 prop_score_untreated;
set propensity_scores;
if stu_g = 1 then output prop_score_treated;
else if stu_g = 0 then output prop_score_untreated;
run;

%include "/_COURSEWORK/ResMeth/AY_2020_2021/LEE_T/Publication/Full10pcSample_Code/Macro_PSMatch_Multi_2017.sas" /source2;

%psmatch_multi(	subj_dsn	= prop_score_treated,
				subj_idvar 	= pat_id,
				subj_psvar 	= prob_treat,
				cntl_dsn 	= prop_score_untreated,
				cntl_idvar 	= pat_id,
				cntl_psvar 	= prob_treat,
				match_dsn 	= matched_pairs1,
				match_ratio	= 5,
				score_diff 	= 0.10,
				opt=none,
				seed=1234567890);

data matched_case;
set matched_pairs1 (keep=subj_idvar subj_score);
by subj_idvar;
if first.subj_idvar;
run;

data matched_cntl;
set matched_pairs1 (keep=cntl_idvar cntl_score);
run;

proc sql;
	create table matched_pairs2 as
	select subj_idvar as pat_id, subj_score as ps
		from matched_case
	union 
	select cntl_idvar as pat_id, cntl_score as ps
		from matched_cntl;
quit;

proc sql;
	create table F.chrt_final as
	select a.*, ps
		from T.step_8 a inner join 
			 matched_pairs2 b
	on a.pat_id=b.pat_id
	order by stu_g desc, index_dt;
quit;

proc freq data=F.chrt_final; table stu_g; run;
