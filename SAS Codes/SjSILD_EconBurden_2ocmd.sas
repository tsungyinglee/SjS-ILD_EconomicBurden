************************************************************************************************************
 * Project	: ResMeth Class Paper - SjS with ILD
 * Section	: 2-Outcome Meaasurement and Regression Modeling
 * Created	: 2021-04-03
 * Edited	: 2021-04-03
 * Author	: Tsung-Ying Lee
 *************************************************************************************************************/

/* 	Step 9 - Prepare claims for summing total cost and by HcRU categories */

* join post-index claims to cohort;
proc sql;
create table T._temp_ as
select p.*, from_dt, RECTYPE, pos, conf_num, PROC_CDE, REV_CODE, ndc, pmt_st_cd, paid
    from F.chrt_final as p inner join
             I.ims10_claims as c
    on p.pat_id= c.pat_id
    where index_dt<=from_dt<=index_dt+180;
quit;

data T.step_9;
set T._temp_;

*	Step 9a - Delete claims that were denied and claims with negative costs;
if pmt_st_cd = 'D' then delete;
if paid < 0 then delete;

*	Step 9b - Classify HcRU categories;
if PROC_CDE = ' ' AND REV_CODE NE ' ' then PROC_CDE = REV_CODE; 
if conf_num NE ' ' then HCRU=1;   /* Flagging Inpatient Claims */
else if conf_num = ' ' AND (proc_cde in ('450', '451', '452', '456', '459', '981')
                       OR proc_cde in ("99281", "99282", "99283", "99284", "99285", "99286", "99287", "99288") 
                       OR (pos = "23" AND ('10040'<=proc_cde<='69979') AND length(proc_cde)=5)) then HCRU=2;  /* Flagging ED visits */
else if conf_num = ' ' AND NDC NE ' ' then HCRU=3;  /* Flagging Pharmacy Claims */
else if conf_num = ' ' AND proc_cde NE ' ' AND pos='11' AND RECTYPE='M' then HCRU=4; /* Flagging Physician Office Visit Claims */
else if conf_num = ' ' then HCRU=5; /* Flagging other outpatient claims */

*	Step 9c - Adjust costs to 2020 USD based on annual medical care CPI in the US to account for inflation;
if year(from_dt)='2006' then adj_paid = paid*(518.876/336.183);
if year(from_dt)='2007' then adj_paid = paid*(518.876/351.054);
if year(from_dt)='2008' then adj_paid = paid*(518.876/364.065);
if year(from_dt)='2009' then adj_paid = paid*(518.876/375.613);
if year(from_dt)='2010' then adj_paid = paid*(518.876/388.436);
if year(from_dt)='2011' then adj_paid = paid*(518.876/400.258);
if year(from_dt)='2012' then adj_paid = paid*(518.876/414.924);
if year(from_dt)='2013' then adj_paid = paid*(518.876/425.135);
if year(from_dt)='2014' then adj_paid = paid*(518.876/435.292);
if year(from_dt)='2015' then adj_paid = paid*(518.876/446.752);

*	Step 9d - Create category-specific cost variable;
if hcru = 1 then inp_cost = adj_paid;
if hcru = 2 then ED_cost = adj_paid;
if hcru = 3 then rx_cost = adj_paid;
if hcru = 4 then office_cost = adj_paid;
if hcru = 5 then other_cost = adj_paid;
run;

proc means data=T.step_9 n nmiss min max mean median std skew kurt;
var adj_paid inp_cost ED_cost rx_cost office_cost other_cost;
run;

/* 	Step 10 - Sum up the costs per subject */
data F.chrt_final_outcome;
set T.step_9;
by pat_id;
if first.pat_id then
	do;
		totsum = 0;
	    inpsum = 0;
	    EDsum = 0;
	    rxsum = 0;
	    officesum = 0;
	    othersum = 0;
	end;
 
totsum + adj_paid;
inpsum + inp_cost;
EDsum + ED_cost;
rxsum + rx_cost;
officesum + office_cost;
othersum + other_cost;
if _n_<10 then put totsum=adj_paid=inpsum=inp_cost=officesum=office_cost=;

if last.pat_id then output;
drop rectype pos conf_num proc_cde rev_code ndc pmt_st_cd paid HCRU adj_paid inp_cost ED_cost rx_cost office_cost other_cost;
run;

/* 	Step 11 - Report mean and SD of total costs for each group, and by categories */
%include "/_COURSEWORK/ResMeth/AY_2020_2021/LEE_T/Codes/SjSILD_DefFormat.sas" /source2;

ods rtf file="/_COURSEWORK/ResMeth/AY_2020_2021/LEE_T/Report/table3_outcome.rft" style=analysis;

proc tabulate data=F.chrt_final_outcome noseps;
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
proc means data=F.chrt_final_outcome n nmiss min max mean std median q1 q3 skewness kurtosis;
var totsum inpsum EDsum rxsum officesum othersum;
class stu_g;
run;

*assess number of zeros;
proc sql;
	select 
		((select count(distinct pat_id) from F.chrt_final_outcome where totsum=0)/count(distinct pat_id)) label='% of zeros in total sum of cost' format percent10.,
		((select count(distinct pat_id) from F.chrt_final_outcome where inpsum=0)/count(distinct pat_id)) label='% of zeros in sum of inpatient cost' format percent10.,
		((select count(distinct pat_id) from F.chrt_final_outcome where EDsum=0)/count(distinct pat_id)) label='% of zeros in sum of ED cost' format percent10.,
		((select count(distinct pat_id) from F.chrt_final_outcome where rxsum=0)/count(distinct pat_id)) label='% of zeros in sum of pharmacy cost' format percent10.,
		((select count(distinct pat_id) from F.chrt_final_outcome where officesum=0)/count(distinct pat_id)) label='% of zeros in sum of office cost' format percent10.,
		((select count(distinct pat_id) from F.chrt_final_outcome where othersum=0)/count(distinct pat_id)) label='% of zeros in sum of other outpatient cost' format percent10.
	from F.chrt_final_outcome;
quit;

*assess % of aged 65+, % of missing CCI;
proc sql;
	select 	count(distinct pat_id) label='N subjects aged 65+' from F.chrt_final_outcome where age>=65;
	select 	count(distinct pat_id) label='N subjects with missing CCI' from F.chrt_final_outcome where CCI=.;
	select	((select count(distinct pat_id) from F.chrt_final_outcome where age>=65)/count(distinct pat_id)) label='% subjects aged 65+' format percent10.,
			((select count(distinct pat_id) from F.chrt_final_outcome where CCI=.)/count(distinct pat_id)) label='% subjects with missing CCI' format percent10.
	from F.chrt_final_outcome;
quit;

data F.chrt_final_outcome_nonzero F.chrt_final_outcome_addEN6tozero;
set F.chrt_final_outcome;
if totsum ne 0 then do;
	log_totsum=log(totsum); *have log transformed cost ready if wanted to do an OLS regression;
	output F.chrt_final_outcome_nonzero; *581;
end;
if totsum = 0 then totsum=totsum+1E-6; *test how it looks like if adding only a small value to zeros;
log_totsum=log(totsum);
output F.chrt_final_outcome_addEN6tozero;*588;
run;

proc univariate data=F.chrt_final_outcome_nonzero plots; 
var totsum;
histogram / normal lognormal gamma weibull;
ppplot/ normal;
ppplot/ lognormal;
ppplot/ gamma;
ppplot/ weibull;
run;

proc lifereg data=F.chrt_final_outcome_nonzero;
model totsum=/dist=weibull;
probplot/plower=0.01;
run;
proc lifereg data=F.chrt_final_outcome_nonzero;
model totsum=/dist=gamma;
probplot/plower=0.01;
run;
proc lifereg data=F.chrt_final_outcome_nonzero;
model log_totsum=/dist=normal;
probplot/plower=0.01;
run;

/* 	13 - Build a regression model of total cost on ILD */

*	create dummy variable for CCIcat (0, 1, 2);
data F.final_model;
set F.chrt_final_outcome_nonzero;
if CCIcat=0 then do; CCIcat_1=0; CCIcat_2=0; end;
else if CCIcat=1 then do; CCIcat_1=1; CCIcat_2=0; end;
else if CCIcat=2 then do; CCIcat_1=0; CCIcat_2=1; end;
run;

*	using Gamma-GLM with log link;
title "GLM with log link and gamma distribution of total costs on ILD and CCIcat";
proc genmod data=F.final_model;
model totsum = stu_g CCIcat_1 CCIcat_2 RA_pre SLE_pre / link=log dist=gamma type3 itprint; *converge;
/* output out=T.glm_res pred=p reschi=reschi resdev=resdev reslik=reslik resraw=resraw; */
estimate "ILD" stu_g 1 / exp;
run;
title;


/* proc plot data=T.glm_res; *use scatter plot to check assumption; */
/*  plot reschi*p /vref=0; */
/*  plot resdev*p /vref=0; */
/*  plot reslik*p /vref=0; */
/*  plot resraw*p /vref=0; */
/* run; */


/* 	Step 14 - Estimate average marginal effect with 95%CI using delta method */
%include "/_COURSEWORK/ResMeth/AY_2020_2021/LEE_T/Codes/margins.sas" /source2;
%Margins   (data	 = F.final_model,
            response = totsum,
            model  	 = stu_g CCIcat_1 CCIcat_2 RA_pre SLE_pre,
            dist  	 = gamma,
            link  	 = log,
            margins  = stu_g,  
            options  = diff cl reverse);

ods rtf close;

/* 	Step 15 - Compare characteristics of subjects with zero total cost with subjects with positive total costs */

data T.step_15;
set F.chrt_final_outcome;
if totsum=0 then zerocost=1;
else if totsum>0 then zerocost=0;
run;

%include "/_COURSEWORK/ResMeth/AY_2020_2021/LEE_T/Codes/SjSILD_DefFormat.sas" /source2;
ods rtf file="/_COURSEWORK/ResMeth/AY_2020_2021/LEE_T/Report/suppltable1.rft" style=analysis;

title "Compare characteristics of subjects with zero total cost with subjects with positive total costs";
proc ttest data=T.step_15;
	class zerocost;
	var age;
run;

proc freq data=T.step_15;
	table zerocost*sex2 /chisq;
	format sex2 f_sex.;
run;

proc freq data=T.step_15;
	table zerocost*pat_region2 /cmh;
	format pat_region2 f_pat_region.;
run;

proc freq data=T.step_15;
	table zerocost*index_year /cmh;
	format index_year f_index_yeargp.;
run;

proc freq data=T.step_15;
	table zerocost*pay_type /cmh;
	format pay_type f_pay_type.;
run;

proc freq data=T.step_15;
	table zerocost*prd_type /cmh;
	format prd_type f_prd_type.;
run;

proc freq data=T.step_15;
	table zerocost*CCIcat /cmh;
	format CCIcat f_CCIcat.;
run;

proc tabulate data=T.step_15 noseps;
class zerocost /descending;
class sex2 index_year pat_region2 pay_type prd_type CCIcat;
classlev /s=[just=right];
keylabel colpctn='%';
var age FUT;
table all='N'
	(age='Age')*(mean std)
	(sex2='' 
	 pat_region2='' 
	 index_year='' 
	 pay_type=''
	 prd_type=''
	 CCIcat='')*(N colpctn)
	,
	zerocost=""/box='Characteristics' row=float;
format zerocost f_zerocost. sex2 f_sex. pat_region2 f_pat_region. index_year f_index_yeargp. index_season f_index_season. pay_type f_pay_type. prd_type f_prd_type. CCIcat f_CCIcat.;
run;
title;
ods rtf close;
