/************************************************************************************************************
 * Project	: ResMeth Class Paper - SjS with ILD
 * Section	: 2- Report characteristics and outcomes
 * Created	: 2021-04-03
 * Edited	: 2021-08-29
 * Author	: Tsung-Ying Lee
 * SAS software version: 9.4
 *************************************************************************************************************/
%put SYSVER = &SYSVER; *Write SAS version to the log;
libname I "/_PHSR_CDB_SASDS/IMS_HEALTH" access=readonly;
libname T "/_COURSEWORK/ResMeth/AY_2020_2021/LEE_T/Publication/Tasks";
libname F "/_COURSEWORK/ResMeth/AY_2020_2021/LEE_T/Publication/Full10pcSample_AnalyticalFile";
options nocenter ls=132 ps=63 msglevel=i mprint mlogic mautosource;

/* ods rtf file="/_COURSEWORK/ResMeth/AY_2020_2021/LEE_T/Publication/Report/Report_SelectFlow_&sysdate..rtf" style=analysis; */
/* 4. Report selection flow chart */
title 'Report Patient Flow Chart';
proc sql;
select '1+ claims with dx codes of SjS' label='Flow Title', count(distinct pat_id) label='N of Subjects' format comma9.
from T.step_1a union all
select 'SjS patients who had at least one claim with ILD between 2006/1/1-2015/9/30 and had index date occurred during 2006/7/1-2015/3/31' label='Flow Title', count(distinct pat_id) label='N of Subjects'
from T.step_1c2 union all
select 'SjS patients who did not have any evidence of ILD diagnosis between 2006/01/01-2015/9/30 and had index date occurred during 2006/7/1-2015/3/31' label='Flow Title', count(distinct pat_id) label='N of Subjects'
from T.step_2a2 union all
select 'SjS-ILD Continuous enrollment during the 180-day pre- and the 180-day post-index period, 18+ years of age at the index date' label='Flow Title', count(distinct pat_id) label='N of Subjects'
from T.step_8 where stu_g=1 union all
select 'SjS-only Continuous enrollment during the 180-day pre- and the 180-day post-index period, 18+ years of age at the index date' label='Flow Title', count(distinct pat_id) label='N of Subjects'
from T.step_8 where stu_g=0 union all
select 'Matched SjS-ILD patients' label='Flow Title', count(distinct pat_id) label='N of Subjects'
from F.chrt_final where stu_g=1 union all
select 'Matched SjS-only patients as control group' label='Flow Title', count(distinct pat_id) label='N of Subjects'
from F.chrt_final where stu_g=0
;
quit;
title;
ods rtf close;

/* 	Step 10 - Report Baseline Characteristics Table */
%include "/_COURSEWORK/ResMeth/AY_2020_2021/LEE_T/Publication/Full10pcSample_Code/SjSILD_DefFormat.sas" /source2;

*	Before PS matching;
ods rtf file="/_COURSEWORK/ResMeth/AY_2020_2021/LEE_T/Publication/Report/table1_psm_a_&sysdate..rtf" style=analysis;
title "Baseline Characteristics before PS matching";

proc ttest data=T.step_8; class stu_g; var age; run;
proc freq data=T.step_8; table stu_g*sex2 /chisq; format sex2 f_sex.; run;
proc freq data=T.step_8; table stu_g*pat_region2 /cmh; format pat_region2 f_pat_region.; run;
proc freq data=T.step_8; table stu_g*index_year /cmh; format index_year f_index_yeargp.; run;
proc freq data=T.step_8; table stu_g*pay_type /cmh; format pay_type f_pay_type.; run;
proc freq data=T.step_8; table stu_g*prd_type /cmh; format prd_type f_prd_type.; run;
proc freq data=T.step_8; table stu_g*CCIcat /cmh; format CCIcat f_CCIcat.; run;
proc freq data=T.step_8; table stu_g*RA_pre /cmh; format RA_pre f_RA_pre.; run;
proc freq data=T.step_8; table stu_g*SLE_pre /cmh; format SLE_pre f_SLE_pre.; run;
proc freq data=T.step_8; table stu_g*SSc_pre /cmh; format SSc_pre f_SSc_pre.; run;

proc tabulate data=T.step_8 noseps missing;
class stu_g /descending;
class sex2 index_year pat_region2 pay_type prd_type CCIcat RA_pre SLE_pre SSc_pre;
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
	 CCIcat=''
	 RA_pre=' ' 
	 SLE_pre=' ' 
	 SSc_pre=' ')*(N colpctn)
	,
	stu_g=""/box='Characteristics' row=float;
format 	stu_g f_stu_g. sex2 f_sex. pat_region2 f_pat_region. index_year f_index_yeargp. index_season f_index_season. 
		pay_type f_pay_type. prd_type f_prd_type. CCIcat f_CCIcat.
		RA_pre f_RA_pre. SLE_pre f_SLE_pre. SSc_pre f_SSc_pre.;
run;
title;
ods rtf close;

*	After PS matching;
ods rtf file="/_COURSEWORK/ResMeth/AY_2020_2021/LEE_T/Publication/Report/table2_psm_p_&sysdate..rtf" style=analysis;
title "Baseline Characteristics after PS matching";

proc ttest data=F.chrt_final; class stu_g; var age; run;
proc freq data=F.chrt_final; table stu_g*sex2 /chisq; format sex2 f_sex.; run;
proc freq data=F.chrt_final; table stu_g*pat_region2 /cmh; format pat_region2 f_pat_region.; run;
proc freq data=F.chrt_final; table stu_g*index_year /cmh; format index_year f_index_yeargp.; run;
proc freq data=F.chrt_final; table stu_g*pay_type /cmh; format pay_type f_pay_type.; run;
proc freq data=F.chrt_final; table stu_g*prd_type /cmh; format prd_type f_prd_type.; run;
proc freq data=F.chrt_final; table stu_g*CCIcat /cmh; format CCIcat f_CCIcat.; run;
proc freq data=F.chrt_final; table stu_g*RA_pre /cmh; format RA_pre f_RA_pre.; run;
proc freq data=F.chrt_final; table stu_g*SLE_pre /cmh; format SLE_pre f_SLE_pre.; run;
proc freq data=F.chrt_final; table stu_g*SSc_pre /cmh; format SSc_pre f_SSc_pre.; run;

proc tabulate data=F.chrt_final noseps missing;
class stu_g /descending;
class sex2 index_year pat_region2 pay_type prd_type CCIcat RA_pre SLE_pre SSc_pre;
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
	 CCIcat=''
	 RA_pre=' ' 
	 SLE_pre=' ' 
	 SSc_pre=' ')*(N colpctn)
	,
	stu_g=""/box='Characteristics' row=float;
format 	stu_g f_stu_g. sex2 f_sex. pat_region2 f_pat_region. index_year f_index_yeargp. index_season f_index_season. 
		pay_type f_pay_type. prd_type f_prd_type. CCIcat f_CCIcat.
		RA_pre f_RA_pre. SLE_pre f_SLE_pre. SSc_pre f_SSc_pre.;
run;
title;

/* Call stddiff macro to calculate MSD before PSM */
%include "/_COURSEWORK/ResMeth/AY_2020_2021/LEE_T/Publication/Full10pcSample_Code/stddiff.sas" / source2;

data prepsm;
set T.step_8;
if prd_type=0 then prd_type_gp='Preferred Provider Organization';
else if prd_type=1 then prd_type_gp='Health Maintenance Organization';
else prd_type_gp='Other/Unknown';
proc freq; table prd_type prd_type_gp; run;

data postpsm;
set F.chrt_final;
if prd_type=0 then prd_type_gp='Preferred Provider Organization';
else if prd_type=1 then prd_type_gp='Health Maintenance Organization';
else prd_type_gp='Other/Unknown';
proc freq; table prd_type prd_type_gp; run;


%stddiff(inds = prepsm,
         groupvar = stu_g,
         numvars = age/r,
         charvars = sex2 index_year_gp pat_region2 prd_type_gp CCIcat RA_pre SLE_pre SSc_pre,
         stdfmt = 8.5,
         outds = std_result);
         
%stddiff(inds = postpsm,
         groupvar = stu_g,
         numvars = age/r,
         charvars = sex2 index_year_gp pat_region2 prd_type_gp CCIcat RA_pre SLE_pre SSc_pre,
         stdfmt = 8.5,
         outds = std_result);

/* ods rtf close; */

