/************************************************************************************************************
 * Project	: ResMeth Class Paper - SjS with ILD
 * Section	: 5- Regression Modeling
 * Created	: 2021-04-03
 * Edited	: 2021-08-29
 * Author	: Tsung-Ying Lee
 *************************************************************************************************************/
libname F "C:\Users\n7296\OneDrive - University of Maryland Baltimore\O Ongoing\2 UMB PHSR PhD 201908-2024\1 Courses\Y2 20210125-20210518 Spring\PHSR702 Research Method II\Class Project SjS\Publication 10% Sample\FAF SASDS";
options nocenter ls=132 ps=63 msglevel=i mprint mlogic mautosource;

/* 	Step 11 - Report mean and SD of total costs for each group, and by categories */
%include "C:\Users\n7296\OneDrive - University of Maryland Baltimore\O Ongoing\2 UMB PHSR PhD 201908-2024\1 Courses\Y2 20210125-20210518 Spring\PHSR702 Research Method II\Class Project SjS\Publication 10% Sample\Prgm\Full 10% Smaple SAS Codes/SjSILD_DefFormat.sas" /source2;

proc tabulate data=F.Chrt_final_deidentified noseps missing;
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
proc means data=F.chrt_final_deidentified n nmiss min max mean std median q1 q3 skewness kurtosis;
var totsum inpsum EDsum rxsum officesum othersum;
class stu_g;
run;

proc means data=F.chrt_final_deidentified mean std median qrange;
var totsum inpsum EDsum rxsum officesum othersum;
class stu_g;
run;

proc ttest data=F.chrt_final_deidentified;
var totsum inpsum EDsum rxsum officesum;
class stu_g;
run;

*assess number of zeros;
proc sql;
	select 
		((select count(distinct newid) from F.chrt_final_deidentified where totsum=0)/count(distinct newid)) label='% of zeros in total sum of cost' format percent10.,
		((select count(distinct newid) from F.chrt_final_deidentified where inpsum=0)/count(distinct newid)) label='% of zeros in sum of inpatient cost' format percent10.,
		((select count(distinct newid) from F.chrt_final_deidentified where EDsum=0)/count(distinct newid)) label='% of zeros in sum of ED cost' format percent10.,
		((select count(distinct newid) from F.chrt_final_deidentified where rxsum=0)/count(distinct newid)) label='% of zeros in sum of pharmacy cost' format percent10.,
		((select count(distinct newid) from F.chrt_final_deidentified where officesum=0)/count(distinct newid)) label='% of zeros in sum of office cost' format percent10.,
		((select count(distinct newid) from F.chrt_final_deidentified where othersum=0)/count(distinct newid)) label='% of zeros in sum of other outpatient cost' format percent10.
	from F.chrt_final_deidentified;
quit;

*assess % of aged 65+, % of missing CCI;
proc sql;
	select 	count(distinct newid) label='N subjects aged 65+' from F.chrt_final_deidentified where age>=65;
	select 	count(distinct newid) label='N subjects with missing CCI' from F.chrt_final_deidentified where CCI=.;
	select	((select count(distinct newid) from F.chrt_final_deidentified where age>=65)/count(distinct newid)) label='% subjects aged 65+' format percent10.,
			((select count(distinct newid) from F.chrt_final_deidentified where CCI=.)/count(distinct newid)) label='% subjects with missing CCI' format percent10.
	from F.chrt_final_deidentified;
quit;

data F.chrt_final_nonzero_deid F.chrt_final_adden6tozero_deid;
set F.chrt_final_deidentified;
if totsum ne 0 then do;
	log_totsum=log(totsum); *have log transformed cost ready if wanted to do an OLS regression;
	output F.chrt_final_nonzero_deid;
end;
if totsum = 0 then totsum=totsum+1E-6; *test how it looks like if adding only a small value to zeros;
log_totsum=log(totsum);
output F.chrt_final_adden6tozero_deid;
run;

title "N of each group in the non-zero cost subsample";
proc freq data=F.chrt_final_nonzero_deid; table stu_g; run;
title;

proc univariate data=F.chrt_final_nonzero_deid plots; 
var totsum;
histogram / normal lognormal gamma weibull;
ppplot/ normal;
ppplot/ lognormal;
ppplot/ gamma;
ppplot/ weibull;
run;

proc lifereg data=F.chrt_final_nonzero_deid;
model totsum=/dist=weibull;
probplot/plower=0.01;
run;
proc lifereg data=F.chrt_final_nonzero_deid;
model totsum=/dist=gamma;
probplot/plower=0.01;
run;
proc lifereg data=F.chrt_final_nonzero_deid;
model log_totsum=/dist=normal;
probplot/plower=0.01;
run;

/* 	13 - Build a regression model of total cost on ILD */

*	create dummy variable for CCIcat (0, 1, 2) and index_year_gp (0, 1, 2);
data F.final_model_deidentified;
set F.chrt_final_nonzero_deid;
if CCIcat=0 then do; CCIcat_1=0; CCIcat_2=0; end;
else if CCIcat=1 then do; CCIcat_1=1; CCIcat_2=0; end;
else if CCIcat=2 then do; CCIcat_1=0; CCIcat_2=1; end;
if index_year_gp=0 then do; index_year_gp_1=0; index_year_gp_2=0; end;
else if index_year_gp=1 then do; index_year_gp_1=1; index_year_gp_2=0; end;
else if index_year_gp=2 then do; index_year_gp_1=0; index_year_gp_2=1; end;
run;

*	using Gamma-GLM with log link;
title "GLM with log link and gamma distribution of total costs on ILD and CCIcat";
proc genmod data=F.final_model_deidentified;
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
%include "C:\Users\n7296\OneDrive - University of Maryland Baltimore\O Ongoing\2 UMB PHSR PhD 201908-2024\1 Courses\Y2 20210125-20210518 Spring\PHSR702 Research Method II\Class Project SjS\Publication 10% Sample\Prgm\Full 10% Smaple SAS Codes\margins.sas" /source2;
%Margins   (data	 = F.final_model_deidentified,
            response = totsum,
            model  	 = stu_g age index_year_gp_1 index_year_gp_2 CCIcat_1 CCIcat_2 RA_pre SLE_pre SSc_pre,
            dist  	 = gamma,
            link  	 = log,
            margins  = stu_g,  
            options  = diff cl reverse);

ods rtf close;

/* 	Step 15 - Compare characteristics of subjects with zero total cost with subjects with positive total costs */

/*data T.step_15;*/
/*set F.chrt_final;*/
/*if totsum=0 then zerocost=1;*/
/*else if totsum>0 then zerocost=0;*/
/*run;*/
/**/
/*%include "/_COURSEWORK/ResMeth/AY_2020_2021/LEE_T/Publication/Full10pcSample_Code/SjSILD_DefFormat.sas" /source2;*/
/*ods rtf file="/_COURSEWORK/ResMeth/AY_2020_2021/LEE_T/Publication/Report/suppltable1_&sysdate..rtf" style=analysis;*/
/**/
/*title "Compare characteristics of subjects with zero total cost with subjects with positive total costs";*/
/*proc ttest data=T.step_15;*/
/*	class zerocost;*/
/*	var age;*/
/*run;*/
/**/
/*proc freq data=T.step_15;*/
/*	table zerocost*sex2 /chisq;*/
/*	format sex2 f_sex.;*/
/*run;*/
/**/
/*proc freq data=T.step_15;*/
/*	table zerocost*pat_region2 /cmh;*/
/*	format pat_region2 f_pat_region.;*/
/*run;*/
/**/
/*proc freq data=T.step_15;*/
/*	table zerocost*index_year /cmh;*/
/*	format index_year f_index_yeargp.;*/
/*run;*/
/**/
/*proc freq data=T.step_15;*/
/*	table zerocost*pay_type /cmh;*/
/*	format pay_type f_pay_type.;*/
/*run;*/
/**/
/*proc freq data=T.step_15;*/
/*	table zerocost*prd_type /cmh;*/
/*	format prd_type f_prd_type.;*/
/*run;*/
/**/
/*proc freq data=T.step_15;*/
/*	table zerocost*CCIcat /cmh;*/
/*	format CCIcat f_CCIcat.;*/
/*run;*/
/**/
/*proc tabulate data=T.step_15 noseps;*/
/*class zerocost /descending;*/
/*class sex2 index_year pat_region2 pay_type prd_type CCIcat;*/
/*classlev /s=[just=right];*/
/*keylabel colpctn='%';*/
/*var age FUT;*/
/*table all='N'*/
/*	(age='Age')*(mean std)*/
/*	(sex2='' */
/*	 pat_region2='' */
/*	 index_year='' */
/*	 pay_type=''*/
/*	 prd_type=''*/
/*	 CCIcat='')*(N colpctn)*/
/*	,*/
/*	zerocost=""/box='Characteristics' row=float;*/
/*format zerocost f_zerocost. sex2 f_sex. pat_region2 f_pat_region. index_year f_index_yeargp. index_season f_index_season. pay_type f_pay_type. prd_type f_prd_type. CCIcat f_CCIcat.;*/
/*run;*/
/*title;*/
/*ods rtf close;*/
