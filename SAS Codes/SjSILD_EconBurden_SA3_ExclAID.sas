/************************************************************************************************************
 * Project	: Individual Project with 10% IQVIA PharMetrics Sample - EB in SjS with ILD
 * Section	: SA - remove other AID and check if result change
 * Created	: 2022-03-18
 * Edited	: 2021-08-29
 * Author	: Tsung-Ying Lee
 *************************************************************************************************************/
libname I "/_PHSR_CDB_SASDS/IMS_HEALTH" access=readonly;
libname T "/_COURSEWORK/ResMeth/AY_2020_2021/LEE_T/Publication/Tasks" access=readonly;
libname F "/_COURSEWORK/ResMeth/AY_2020_2021/LEE_T/Publication/Full10pcSample_AnalyticalFile" access=readonly;
options nocenter ls=132 ps=63 msglevel=i mprint mlogic mautosource;

/*	Step 9 - Match cases to controls on index year, age, sex, geographic region of residence, insurance type */
data step_8_SA;
set T.step_8;
if RA_pre=1 or SLE_pre=1 or SSc_pre=1 or DMMyositis_pre=1 or PLMyositis_pre=1 then delete;
run;
proc freq; table stu_g; run;
proc freq data=T.step_8; table stu_g; run;

proc logistic data=step_8_SA descending;
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
	create table chrt_final_SA as
	select a.*, ps
		from step_8_SA a inner join 
			 matched_pairs2 b
	on a.pat_id=b.pat_id
	order by stu_g desc, index_dt;
quit;

proc freq data=chrt_final_SA; table stu_g; run;



/************************************************************************************************************
 * Section	: 5- Regression Modeling
 *************************************************************************************************************/

/* 	Step 11 - Report mean and SD of total costs for each group, and by categories */
%include "/_COURSEWORK/ResMeth/AY_2020_2021/LEE_T/Publication/Full10pcSample_Code/SjSILD_DefFormat.sas" /source2;

ods rtf file="/_COURSEWORK/ResMeth/AY_2020_2021/LEE_T/Publication/Report/table3_outcome_&sysdate..rtf" style=analysis;

proc tabulate data=chrt_final_SA noseps missing;
var totsum inpsum EDsum rxsum officesum othersum;
class stu_g/descending;
table 	(totsum='Total cost' inpsum='Inpatient' EDsum='ED visit' rxsum='Pharmacy' officesum='Physician office visit' othersum='Other outpatient')
			*(mean*f=dollar8. std*f=dollar8.),
		stu_g=""/box='' row=float;
;
format stu_g f_stu_g.;
run;


/* 	Step 12 - Assessments of distribution by frequency of zeros, histogram, and ppplot*/

*assess distribution moments;
proc means data=chrt_final_SA n nmiss min max mean std median q1 q3 skewness kurtosis;
var totsum inpsum EDsum rxsum officesum othersum;
class stu_g;
run;

proc means data=chrt_final_SA mean std median qrange;
var totsum inpsum EDsum rxsum officesum othersum;
class stu_g;
run;

proc ttest data=chrt_final_SA;
var totsum inpsum EDsum rxsum officesum;
class stu_g;
run;

*assess number of zeros;
proc sql;
	select 
		((select count(distinct pat_id) from chrt_final_SA where totsum=0)/count(distinct pat_id)) label='% of zeros in total sum of cost' format percent10.,
		((select count(distinct pat_id) from chrt_final_SA where inpsum=0)/count(distinct pat_id)) label='% of zeros in sum of inpatient cost' format percent10.,
		((select count(distinct pat_id) from chrt_final_SA where EDsum=0)/count(distinct pat_id)) label='% of zeros in sum of ED cost' format percent10.,
		((select count(distinct pat_id) from chrt_final_SA where rxsum=0)/count(distinct pat_id)) label='% of zeros in sum of pharmacy cost' format percent10.,
		((select count(distinct pat_id) from chrt_final_SA where officesum=0)/count(distinct pat_id)) label='% of zeros in sum of office cost' format percent10.,
		((select count(distinct pat_id) from chrt_final_SA where othersum=0)/count(distinct pat_id)) label='% of zeros in sum of other outpatient cost' format percent10.
	from chrt_final_SA;
quit;

*assess % of aged 65+, % of missing CCI;
proc sql;
	select 	count(distinct pat_id) label='N subjects aged 65+' from chrt_final_SA where age>=65;
	select 	count(distinct pat_id) label='N subjects with missing CCI' from chrt_final_SA where CCI=.;
	select	((select count(distinct pat_id) from chrt_final_SA where age>=65)/count(distinct pat_id)) label='% subjects aged 65+' format percent10.,
			((select count(distinct pat_id) from chrt_final_SA where CCI=.)/count(distinct pat_id)) label='% subjects with missing CCI' format percent10.
	from chrt_final_SA;
quit;

data chrt_final_SA_nonzero chrt_final_SA_addEN6tozero;
set chrt_final_SA;
if totsum ne 0 then do;
	log_totsum=log(totsum); *have log transformed cost ready if wanted to do an OLS regression;
	output chrt_final_SA_nonzero;
end;
if totsum = 0 then totsum=totsum+1E-6; *test how it looks like if adding only a small value to zeros;
log_totsum=log(totsum);
output chrt_final_SA_addEN6tozero;
run;

title "N of each group in the non-zero cost subsample";
proc freq data=chrt_final_SA_nonzero; table stu_g; run;
title;

proc univariate data=chrt_final_SA_nonzero plots; 
var totsum;
histogram / normal lognormal gamma weibull;
ppplot/ normal;
ppplot/ lognormal;
ppplot/ gamma;
ppplot/ weibull;
run;

proc lifereg data=chrt_final_SA_nonzero;
model totsum=/dist=weibull;
probplot/plower=0.01;
run;
proc lifereg data=chrt_final_SA_nonzero;
model totsum=/dist=gamma;
probplot/plower=0.01;
run;
proc lifereg data=chrt_final_SA_nonzero;
model log_totsum=/dist=normal;
probplot/plower=0.01;
run;

/* 	13 - Build a regression model of total cost on ILD */

*	create dummy variable for CCIcat (0, 1, 2) and index_year_gp (0, 1, 2);
data final_model_SA;
set chrt_final_SA_nonzero;
if CCIcat=0 then do; CCIcat_1=0; CCIcat_2=0; end;
else if CCIcat=1 then do; CCIcat_1=1; CCIcat_2=0; end;
else if CCIcat=2 then do; CCIcat_1=0; CCIcat_2=1; end;
if index_year_gp=0 then do; index_year_gp_1=0; index_year_gp_2=0; end;
else if index_year_gp=1 then do; index_year_gp_1=1; index_year_gp_2=0; end;
else if index_year_gp=2 then do; index_year_gp_1=0; index_year_gp_2=1; end;
run;

*	using Gamma-GLM with log link;
title "GLM with log link and gamma distribution of total costs on ILD and CCIcat";
proc genmod data=final_model_SA;
model totsum = stu_g age index_year_gp_1 index_year_gp_2 CCIcat_1 CCIcat_2 RA_pre SLE_pre SSc_pre / link=log dist=gamma type3 itprint; *converge;
output out=glm_res pred=p reschi=reschi resdev=resdev reslik=reslik resraw=resraw;
estimate "ILD" stu_g 1 / exp;
run;
title;


proc plot data=glm_res; *use scatter plot to check assumption;
 plot reschi*p /vref=0;
 plot resdev*p /vref=0;
 plot reslik*p /vref=0;
 plot resraw*p /vref=0;
run;


/* 	Step 14 - Estimate average marginal effect with 95%CI using delta method */
%include "/_COURSEWORK/ResMeth/AY_2020_2021/LEE_T/Publication/Full10pcSample_Code/margins.sas" /source2;
%Margins   (data	 = final_model_SA,
            response = totsum,
            model  	 = stu_g age index_year_gp_1 index_year_gp_2 CCIcat_1 CCIcat_2 RA_pre SLE_pre SSc_pre,
            dist  	 = gamma,
            link  	 = log,
            margins  = stu_g,  
            options  = diff cl reverse);

ods rtf close;

/* 	Step 15 - Compare characteristics of subjects with zero total cost with subjects with positive total costs */

data step_15;
set chrt_final_SA;
if totsum=0 then zerocost=1;
else if totsum>0 then zerocost=0;
run;
