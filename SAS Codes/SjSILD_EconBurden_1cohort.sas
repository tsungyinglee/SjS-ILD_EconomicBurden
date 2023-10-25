/************************************************************************************************************
 * Project	: Individual Project with 10% IQVIA PharMetrics Sample - EB in SjS with ILD
 * Section	: 1-Cohort Selection and Baseline Characteristics
 * Created	: 2021-02-07
 * Edited	: 2021-08-28
 * Author	: Tsung-Ying Lee
 *************************************************************************************************************/
libname I "/_PHSR_CDB_SASDS/IMS_HEALTH" access=readonly;
libname T "/_COURSEWORK/ResMeth/AY_2020_2021/LEE_T/Publication/Tasks";
libname F "/_COURSEWORK/ResMeth/AY_2020_2021/LEE_T/Publication/Full10pcSample_AnalyticalFile";
options nocenter ls=132 ps=63 msglevel=i mprint mlogic mautosource;

/* 	Step 1 - Cohort Selection - Target Group: SjS-ILD patient-level file with patient ID and index date */
*	Step 1a - Find people with SjS dx and their first observed SjS dx date;
* 	Case Attrition 1: Beneficiaries who had at least one claim with SjS diagnosis;
options obs=max;

%macro m_step1a;
%do c = 1 %to 9;

data T._temp_&c.;
	set I.PMTXPLUS_CLAIMS_00&c. (keep=pat_id rectype rend_spec diag_admit diag1-diag12 from_dt 
						where=(from_dt<=mdy(9, 30, 2015) AND rectype NE 'A'));
	array _dxs(13) diag_admit diag1-diag12;
	sjs=0;

	do n=1 to 13;

	if _dxs(n)='7102' then
			sjs=1;
	end;
	drop n;

	if sjs=1;
run;

%end;
%mend m_step1a;
%m_step1a;


%macro m_step1a;
%do c = 10 %to 13;

data T._temp_&c.;
	set i.PMTXPLUS_CLAIMS_0&c. (keep=pat_id rectype rend_spec diag_admit diag1-diag12 from_dt 
						where=(from_dt<=mdy(9, 30, 2015) AND rectype NE 'A'));
	array _dxs(13) diag_admit diag1-diag12;
	sjs=0;

	do n=1 to 13;

	if _dxs(n)='7102' then
			sjs=1;
	end;
	drop n;

	if sjs=1;
run;

%end;
%mend m_step1a;
%m_step1a;


%macro m_set;

data T._temp_;
set 
%do c = 1 %to 13;
T._temp_&c.
%end;
;
run;

%mend m_set;
%m_set;


proc sort data=T._temp_;
	by pat_id;
run;

data T.step_1a;
	set T._temp_;
	by pat_id;

	if first.pat_id;
	FrstSjSdx_dt=from_dt;
	keep pat_id FrstSjSdx_dt;
	format FrstSjSdx_dt yymmdd10.;
run;

proc sql;
	select count(distinct pat_id) label='N of subjects with 1+ claim with SjS dx 2006/1/1-2015/09/30' 
		from T.step_1a;
quit;

*	Step 1b Find people with ILD dx and their first observed ILD dx date;

%macro m_step1b;
%do c = 1 %to 9;

data T._temp_&c.;
	set i.PMTXPLUS_CLAIMS_00&c. (keep=pat_id rectype rend_spec diag_admit diag1-diag12 from_dt 
						where=(from_dt<=mdy(9, 30, 2015) AND rectype NE 'A'));
	array _dxs(13) diag_admit diag1-diag12;
	ild=0;

	do n=1 to 13;

		if _dxs(n) in ('515', '51630', '51631', '51632', '51635', '51636', '5168', '5178', '51889') then
				ild=1;
	end;
	drop n;

	if ild=1;
run;

%end;
%mend m_step1b;
%m_step1b;


%macro m_step1b;
%do c = 10 %to 13;

data T._temp_&c.;
	set i.PMTXPLUS_CLAIMS_0&c. (keep=pat_id rectype rend_spec diag_admit diag1-diag12 from_dt 
						where=(from_dt<=mdy(9, 30, 2015) AND rectype NE 'A'));
	array _dxs(13) diag_admit diag1-diag12;
	ild=0;

	do n=1 to 13;

		if _dxs(n) in ('515', '51630', '51631', '51632', '51635', '51636', '5168', '5178', '51889') then
				ild=1;
	end;
	drop n;

	if ild=1;
run;

%end;
%mend m_step1b;
%m_step1b;


%macro m_set;

data T._temp_;
set 
%do c = 1 %to 13;
T._temp_&c.
%end;
;
run;

%mend m_set;
%m_set;


proc sort data=T._temp_;
	by pat_id;
run;

data T.step_1b;
	set T._temp_;
	by pat_id;

	if first.pat_id;
	FrstILDdx_dt=from_dt;
	keep pat_id FrstILDdx_dt;
	format FrstILDdx_dt yymmdd10.;
run;

proc sql;
	select count(distinct pat_id) label='N of subjects with 1+ claim with ILD dx 2006/1/1-2015/9/30' 
		from T.step_1b;
quit;

*	Step 1c - Find people with both SjS dx and ILD dx;

title "Cases";

proc sql;
	create table T.step_1c1 as 
	select a.pat_id, FrstSjSdx_dt, FrstILDdx_dt, max(FrstSjSdx_dt, FrstILDdx_dt) as index_dt format=yymmdd10., 1 as Stu_g Label="SjS with ILD" 
	from T.step_1a as a inner join 
		 T.step_1b as b 
	on a.pat_id=b.pat_id;
quit;

proc sql;
	select count(distinct pat_id) 
		label='N of subjects with both SjS dx and ILD dx 2006/1/1-2015/9/30' from T.step_1c1;
quit;

data T.step_1c2;
set T.step_1c1 (where=(mdy(7, 1, 2006) <=index_dt <=mdy(3, 31, 2015)));
run;

proc sql;
	select count(distinct pat_id) 
		label='N of subjects with both SjS dx and ILD dx and with their index date between 2006/7/1-2015/3/31' from T.step_1c2;
quit;

*	Step 1d - Attach enrollment info;

proc sql;
	create table T._temp_ as 
	select a.*, b.estring, year(a.index_dt)-b.der_yob as age, b.der_sex as sex, b.pat_region 
	from T.step_1c2 a left join 
		 i.PMTXPLUS_POP b 
	on a.pat_id=b.pat_id 
	order by pat_id asc;
quit;

data T.step_1d;
	set T._temp_;
	start_dt=mdy(01, 01, 2001);
	format start_dt yymmdd10.;
	begdate=index_dt - 180;
	*6 months prior to index date as baseline period;
	enddate=index_dt + 180;
	*6 months after index date as follow-up period;
	format begdate enddate YYMMDD10.;
	label begdate='Date 180 days prior to the index date' 
		  enddate='Date 180 days after the index date';
	firstmon=intck('month', start_dt, begdate)+1; 
	lastmon=intck('month', start_dt, enddate)+1;

	totalmos=lastmon-firstmon+1;
	newestring=substr(estring, firstmon, totalmos);
	ln=lengthn(compress(newestring, '-'));

	if ln=totalmos then
		cont_enr=1;
	else
		cont_enr=0;

	if _n_<11 then
		put pat_id=totalmos=ln=cont_enr=;

	indexmon=intck('month', start_dt, index_dt)+1;
	whereisdash_postindex=find(estring, '-', indexmon);
	EoCEnr_dt=intnx('month',start_dt, whereisdash_postindex-2, 'end');
	format EoCEnr_dt YYMMDD10.;
	
	if _n_<5 then
		put pat_id=start_dt=begdate=firstmon=enddate=lastmon=index_dt=indexmon=whereisdash_postindex=EoCEnr_dt=estring=;
		
	drop start_dt begdate enddate firstmon lastmon indexmon whereisdash_postindex totalmos estring newestring ln;
run;

* 	Step 1e - Apply additional selection criteria; 

proc sql;
	select count(distinct pat_id) "Age 18+"
		from T.step_1d
		where age>=18;
	select count(distinct pat_id) "With continuous enrollment 180 days pre- and 180 days post-index date"
		from T.step_1d
		where cont_enr=1;
	select count(distinct pat_id) "With continuous enrollment 180 days pre- and 180 days post-index date and Age 18+"
		from T.step_1d
		where cont_enr=1 and age>=18;
	create table T.step_1e as
	select *
		from T.step_1d
		where cont_enr=1 and age>=18;
quit;

title; 

/* 	Step 2 - Cohort Selection - Comparator Group: SjS-only */

title "Controls";

*	Step 2a - Find people with SjS dx without evidence of ILD dx;

proc sql;
create table T.step_2a1 as
select a.pat_id, FrstSjSdx_dt, FrstILDdx_dt, FrstSjSdx_dt as index_dt, 0 as Stu_g Label="SjS without ILD"
    from T.step_1a as a left join
         T.step_1b as b
    on a.pat_id = b.pat_id
    where b.pat_id is null;
quit;

proc sql;
	select count(distinct pat_id) label='N of subjects with SjS dx without evidence of ILD dx between 2006/1/1-2015/9/30' 
		from T.step_2a1;
quit;

data T.step_2a2;
set T.step_2a1 (where=(mdy(7,1,2006)<=index_dt<=mdy(3,31,2015)));
run;

proc sql;
	select count(distinct pat_id) label='N of subjects with SjS dx without evidence of ILD dx and with the index date between 2006/7/1-2015/3/31' 
		from T.step_2a2;
quit;


*	Step 2b - Attach enrollment info;

proc sql;
	create table T._temp_ as 
	select a.*, b.estring, year(a.index_dt)-b.der_yob as age, b.der_sex as sex, b.pat_region 
	from T.step_2a2 a left join 
		 i.PMTXPLUS_POP b 
	on a.pat_id=b.pat_id 
	order by pat_id asc;
quit;

data T.step_2b;
	set T._temp_;
	start_dt=mdy(01, 01, 2001);
	format start_dt yymmdd10.;
	begdate=index_dt - 180;
	*6 months prior to index date as baseline period;
	enddate=index_dt + 180;
	*6 months after index date as follow-up period;
	format begdate enddate YYMMDD10.;
	label begdate='Date 180 days prior to the index date' 
		  enddate='Date 180 days after the index date';
	firstmon=intck('month', start_dt, begdate)+1; 
	lastmon=intck('month', start_dt, enddate)+1;

	totalmos=lastmon-firstmon+1;
	newestring=substr(estring, firstmon, totalmos);
	ln=lengthn(compress(newestring, '-'));

	if ln=totalmos then
		cont_enr=1;
	else
		cont_enr=0;

	if _n_<11 then
		put pat_id=totalmos=ln=cont_enr=;

	indexmon=intck('month', start_dt, index_dt)+1;
	whereisdash_postindex=find(estring, '-', indexmon);
	EoCEnr_dt=intnx('month',start_dt, whereisdash_postindex-2, 'end');
	format EoCEnr_dt YYMMDD10.;
	
	if _n_<5 then
		put pat_id=start_dt=begdate=firstmon=enddate=lastmon=index_dt=indexmon=whereisdash_postindex=EoCEnr_dt=estring=;
		
	drop start_dt begdate enddate firstmon lastmon indexmon whereisdash_postindex totalmos estring newestring ln;
run;

* 	Step 2c - Apply additional selection criteria; 

proc sql;
	select count(distinct pat_id) "Age 18+"
		from T.step_2b
		where age>=18;
	select count(distinct pat_id) "With continuous enrollment 180 days pre- and 180 days post-index date"
		from T.step_2b
		where cont_enr=1;
	select count(distinct pat_id) "With continuous enrollment 180 days pre- and 180 days post-index date and Age 18+"
		from T.step_2b
		where cont_enr=1 and age>=18;
	create table T.step_2c as
	select *
		from T.step_2b
		where cont_enr=1 and age>=18;
quit;

title;

data T.step_3;
set T.step_1e T.step_2c;
postindex_contenr_ln=EoCEnr_dt-index_dt;
EoS_dt=mdy(9,30,2015);
EoF_dt=min(EoCEnr_dt, EoS_dt);
format EoS_dt EoF_dt yymmdd10.;
if EoCEnr_dt<EoS_dt then EoF_rs='Disenrollment'; else EoF_rs='End of Study';
FUT=EoF_dt-index_dt;
run;

proc sort data=T.step_3; by descending stu_g index_dt; run;

proc sql;
	select count(distinct pat_id) label='N of subjects with SjS dx with or without ILD dx' 
		from T.step_3;
quit;

/* Step 4 - Attach insurance payer and product types information from pop2 file */

proc sql;
	create table T.step_4a as select a.*, b.string as pay_type_string
		from T.step_3 a left join 
			 I.PMTXPLUS_POP2 b 
		on a.pat_id=b.pat_id
		where string_type='pay_type';
quit;

proc sql;
	create table T.step_4b as select a.*, b.string as prd_type_string
		from T.step_4a a left join 
			 I.PMTXPLUS_POP2 b 
	 	on a.pat_id=b.pat_id 
	 	where b.string_type='prd_type';
quit;

data T.step_4c;
	set T.step_4b;
	length pay_type_code $1  prd_type_code $1;
	start_dt=mdy(01, 01, 2001);
	format start_dt yymmdd10.;
	indexmon=intck('month', start_dt, index_dt)+1;
	pay_type_code=substr(pay_type_string, indexmon, 1);
	prd_type_code=substr(prd_type_string, indexmon, 1);

	if pay_type_code='C' then
		pay_type=0;
	else if pay_type_code='S' then
		pay_type=1;
	else if pay_type_code='R' then
		pay_type=2;
	else if pay_type_code='T' then
		pay_type=3;
	else if pay_type_code='M' then
		pay_type=4;
	else if pay_type_code in ('K', 'U', 'X') then
		pay_type=5;
		
	if prd_type_code='P' then
		prd_type=0;
	else if prd_type_code='H' then
		prd_type=1;
	else if prd_type_code='S' then
		prd_type=2;
	else if prd_type_code='I' then
		prd_type=3;
	else if prd_type_code in ('D', 'U') then
		prd_type=4;
		
	if _n_<5 then put pat_id= pay_type_string= prd_type_string= index_dt= indexmon= pay_type_code= pay_type= prd_type_code= prd_type=;
	drop start_dt indexmon pay_type_string prd_type_string;
run;


/*	Step 5 - Recode demographic variables and create format to label value*/
data T.step_5;
	set T.step_4c;

	if sex='F' then
		sex2=0;
	else if sex='M' then
		sex2=1;
	
	index_year=year(index_dt);
	if 2006<=year(index_dt)<=2008 then index_year_gp=0;
	else if 2009<=year(index_dt)<=2011 then index_year_gp=1;
	else if 2012<=year(index_dt)<=2015 then index_year_gp=2;
	
	if month(index_dt) in (3, 4, 5) then
		index_season=0;
	else if month(index_dt) in (6, 7, 8) then
		index_season=1;
	else if month(index_dt) in (9, 10, 11) then
		index_season=2;
	else if month(index_dt) in (12, 1, 2) then
		index_season=3;

	if pat_region='E' then
		pat_region2=0;
	else if pat_region='MW' then
		pat_region2=1;
	else if pat_region='S' then
		pat_region2=2;
	else if pat_region='W' then
		pat_region2=3;
run;


/* 	Step 6 - Attach other baseline clinical characteristics (i.e., CCI, other AIDs) */

* 	Join pre-index claims to cohort;
proc sort data=T.step_5;by pat_id;run;


%macro m_step6;
%do c = 1 %to 9;

data T._temp_&c.;
  merge T.step_5 (in=a keep=pat_id index_dt) I.PMTXPLUS_CLAIMS_00&c. (in=b keep=pat_id from_dt rectype diag1-diag12);
  by pat_id;
  if a and b;
  if index_dt-180<=from_dt<index_dt and rectype ne 'A';
run;

%end;
%mend m_step6;
%m_step6;


%macro m_step6;
%do c = 10 %to 13;

data T._temp_&c.;
  merge T.step_5 (in=a keep=pat_id index_dt) I.PMTXPLUS_CLAIMS_0&c. (in=b keep=pat_id from_dt rectype diag1-diag12);
  by pat_id;
  if a and b;
  if index_dt-180<=from_dt<index_dt and rectype ne 'A';
run;

%end;
%mend m_step6;
%m_step6;


%macro m_set;

data T._temp_;
set 
%do c = 1 %to 13;
T._temp_&c.
%end;
;
run;

%mend m_set;
%m_set;


* 	Flags for different disease conditions during pre-index period;
data T._temp_;
set T._temp_;
by pat_id;
array _diag (12) diag1-diag12;
retain MI_CCIpre CHF_CCIpre PVD_CCIpre CeVD_CCIpre CPD_CCIpre Dementia_CCIpre
Paralysis_CCIpre DMnocc_CCIpre DMcc_CCIpre Renal_CCIpre ModSevLiver_CCIpre MildLiver_CCIpre
PepUlcer_CCIpre Rheum_CCIpre MetSldTumor_CCIpre Malig_CCIpre AIDSHIV_CCIpre 
RA_pre SLE_pre SSc_pre DMMyositis_pre PLMyositis_pre;
if first.pat_id then
do;
MI_CCIpre=0;
CHF_CCIpre=0;
PVD_CCIpre=0;
CeVD_CCIpre=0;
CPD_CCIpre=0;
Dementia_CCIpre=0;
Paralysis_CCIpre=0;
DMnocc_CCIpre=0;
DMcc_CCIpre=0;
Renal_CCIpre=0;
ModSevLiver_CCIpre=0;
MildLiver_CCIpre=0;
PepUlcer_CCIpre=0;
Rheum_CCIpre=0;
MetSldTumor_CCIpre=0;
Malig_CCIpre=0;
AIDSHIV_CCIpre=0;
RA_pre=0; 
SLE_pre=0; 
SSc_pre=0; 
DMMyositis_pre=0; 
PLMyositis_pre=0;
end;
do i=1 to dim (_diag);

if 	substr(_diag(i),1,3) in ("410","412") then
MI_CCIpre=1;

if 	(substr(_diag(i),1,3) = "428") OR
	(_diag(i) IN ("39891", "40201", "40211", "40291", "40401", "40403", "40411", "40413", "40491", "40493")) OR 
	("4254" <=substr(_diag(i),1,4)<= "4259") then
CHF_CCIpre=1;

if 	("4431" <=substr(_diag(i),1,4) <= "4439") OR
	(substr(_diag(i),1,3) = "440") OR
	(substr(_diag(i),1,3) = "441") OR
	(_diag(i) IN ("0930", "4373", "4471", "5571", "5579", "V434")) then
PVD_CCIpre=1;

if 	("430" <=substr(_diag(i),1,3) <= "438") OR
	(_diag(i)="36234") then
CeVD_CCIpre=1;

if 	(substr(_diag(i),1,3) ="290") OR
	(_diag(i) IN ("2941", "3312")) then
Dementia_CCIpre=1;

if 	("490" <=substr(_diag(i),1,3) <= "505") OR
	(_diag(i) IN ("4168", "4169", "5064", "5081", "5088")) then
CPD_CCIpre=1;

if 	("7100" <=substr(_diag(i),1,4) <= "7104") OR
	("7140" <=substr(_diag(i),1,4) <= "7142") OR
	(substr(_diag(i),1,3) = "725") OR
	(_diag(i) IN ("4465", "7148")) then
Rheum_CCIpre=1;

if 	"531" <=substr(_diag(i),1,3) <= "534" then
PepUlcer_CCIpre=1;

if 	(substr(_diag(i),1,3) in ("570", "571")) OR
	(_diag(i) IN ("07022", "07023", "07032", "07033", "07044", "07054", "0706", "0709", "5733", "5734", "5738", "5739", "V427")) then
MildLiver_CCIpre=1;

if 	("4560" <=substr(_diag(i),1,4) <= "4562") OR
	("5722" <=substr(_diag(i),1,4) <= "5728") then
ModSevLiver_CCIpre=1;

if 	("2500" <=substr(_diag(i),1,4) <= "2503") OR
	(_diag(i) IN ("2508", "2509")) then
DMnocc_CCIpre=1;

if 	"2504" <=substr(_diag(i),1,4) <= "2507" then
DMcc_CCIpre=1;

if 	("3440" <=substr(_diag(i),1,4) <= "3446") OR
	(substr(_diag(i),1,3) in ("342", "343")) OR
	(_diag(i) IN ("3341", "3449")) then
Paralysis_CCIpre=1;

if 	("5830" <=substr(_diag(i),1,4) <= "5837") OR
	(substr(_diag(i),1,3) in ("582", "585", "586", "V56")) OR
	(_diag(i) IN ("40301", "40311", "40391", "40402", "40403", "40412", "40413", "40492", "40493", "5880", "V420", "V451")) then
Renal_CCIpre=1;

if 	("140" <=substr(_diag(i),1,3) <= "172") OR
	("174" <=substr(_diag(i),1,3) <= "195") OR
	("200" <=substr(_diag(i),1,3) <= "208") OR
	(_diag(i) = "2386") then
Malig_CCIpre=1;

if 	("196" <=substr(_diag(i),1,3) <= "199") then
MetSldTumor_CCIpre=1;

if 	("042" <=substr(_diag(i),1,3) <= "044") then
AIDSHIV_CCIpre=1; * code 043, 044 does not exist, but indicated in the Quan paper;

if 	substr(_diag(i),1,4) in ("7140", "7141", "7142", "7148") then
RA_pre=1;
if 	substr(_diag(i),1,4) in ("7100") then
SLE_pre=1;
if 	substr(_diag(i),1,4) in ("7101") then
SSc_pre=1;
if 	substr(_diag(i),1,4) in ("7103") then
DMMyositis_pre=1;
if 	substr(_diag(i),1,4) in ("7104") then
PLMyositis_pre=1;
drop i;
end;
if last.pat_id then output;
drop from_dt rectype diag1-diag12;
run;

data T._temp_;
set T._temp_;
CCI = (MI_CCIpre * 1) + (CHF_CCIpre * 1) + (PVD_CCIpre * 1) + (CeVD_CCIpre * 1 ) + (CPD_CCIpre * 1) + (Dementia_CCIpre * 1)
+ (Paralysis_CCIpre * 2) + (DMnocc_CCIpre * 1) + (DMcc_CCIpre * 2) + (Renal_CCIpre * 2) + (MildLiver_CCIpre * 1) + (ModSevLiver_CCIpre * 3) 
+ (PepUlcer_CCIpre * 1) + (Rheum_CCIpre * 1) + (AIDSHIV_CCIpre * 6) + (Malig_CCIpre * 2) + (MetSldTumor_CCIpre * 6);
run;

proc sort data=T.step_5;by pat_id;run;
proc sort data=T._temp_;by pat_id;run;
data T.step_6;
  merge T.step_5 (in=a) T._temp_ (in=b);
  by pat_id;
  if a;
if CCI=0 or CCI=. then CCIcat = 0;
if CCI=1 then CCIcat = 1;
if CCI>=2 then CCIcat = 2;
if RA_pre=. then RA_pre=0;
if SLE_pre=. then SLE_pre=0;
if SSc_pre=. then SSc_pre=0;
if DMMyositis_pre=. then DMMyositis_pre=0;
if PLMyositis_pre=. then PLMyositis_pre=0;
run;

/* proc contents data=T.step_6; run; */
proc freq data=T.step_6; table Stu_g; run;
proc means data=T.step_6 n nmiss; run;

proc datasets library=T nodetails nolist;
delete _temp:;
run;
proc datasets library=T; run;
