/************************************************************************************************************
 * Project	: ResMeth Class Paper - SjS with ILD
 * Section	: 2-Cost Outcome Meaasurement
 * Created	: 2021-04-03
 * Edited	: 2021-04-03
 * Author	: Tsung-Ying Lee
 *************************************************************************************************************/
libname I "/_PHSR_CDB_SASDS/IMS_HEALTH" access=readonly;
libname T "/_COURSEWORK/ResMeth/AY_2020_2021/LEE_T/Publication/Tasks";
libname F "/_COURSEWORK/ResMeth/AY_2020_2021/LEE_T/Publication/Full10pcSample_AnalyticalFile";
options nocenter ls=132 ps=63 msglevel=i mprint mlogic mautosource;

/* 	Step 7 - Prepare claims for summing total cost and by HcRU categories */

%macro m_step7;
%do c = 1 %to 9;

* join post-index claims to cohort;
proc sql;
create table T._temp_&c. as
select p.*, from_dt, RECTYPE, pos, conf_num, PROC_CDE, REV_CODE, ndc, pmt_st_cd, paid
    from T.step_6 as p inner join
         I.PMTXPLUS_CLAIMS_00&c. as c
    on p.pat_id= c.pat_id
    where index_dt<=from_dt<=index_dt+180;
quit;

%end;
%mend m_step7;
%m_step7;


%macro m_step7;
%do c = 10 %to 13;

* join post-index claims to cohort;
proc sql;
create table T._temp_&c. as
select p.*, from_dt, RECTYPE, pos, conf_num, PROC_CDE, REV_CODE, ndc, pmt_st_cd, paid
    from T.step_6 as p inner join
         I.PMTXPLUS_CLAIMS_0&c. as c
    on p.pat_id= c.pat_id
    where index_dt<=from_dt<=index_dt+180;
quit;

%end;
%mend m_step7;
%m_step7;


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


data T.step_7;
set T._temp_;

*	Step 7a - Delete claims that were denied and claims with negative costs;
if pmt_st_cd = 'D' then delete;
if paid < 0 then delete;

*	Step 7b - Classify HcRU categories;
if PROC_CDE = ' ' AND REV_CODE NE ' ' then PROC_CDE = REV_CODE; 
if conf_num NE ' ' then HCRU=1;   /* Flagging Inpatient Claims */
else if conf_num = ' ' AND (proc_cde in ('450', '451', '452', '456', '459', '981')
                       OR proc_cde in ("99281", "99282", "99283", "99284", "99285", "99286", "99287", "99288") 
                       OR (pos = "23" AND ('10040'<=proc_cde<='69979') AND length(proc_cde)=5)) then HCRU=2;  /* Flagging ED visits */
else if conf_num = ' ' AND NDC NE ' ' then HCRU=3;  /* Flagging Pharmacy Claims */
else if conf_num = ' ' AND proc_cde NE ' ' AND pos='11' AND RECTYPE='M' then HCRU=4; /* Flagging Physician Office Visit Claims */
else if conf_num = ' ' then HCRU=5; /* Flagging other outpatient claims */

*	Step 7c - Adjust costs to 2020 USD based on annual medical care CPI in the US to account for inflation;
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

*	Step 7d - Create category-specific cost variable;
if hcru = 1 then inp_cost = adj_paid;
if hcru = 2 then ED_cost = adj_paid;
if hcru = 3 then rx_cost = adj_paid;
if hcru = 4 then office_cost = adj_paid;
if hcru = 5 then other_cost = adj_paid;
run;

proc means data=T.step_7 n nmiss min max mean median std skew kurt;
var adj_paid inp_cost ED_cost rx_cost office_cost other_cost;
run;

/* 	Step 8 - Sum up the costs per subject */
data T.step_8;
set T.step_7;
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


proc datasets library=T nodetails nolist;
delete _temp:;
run;
proc datasets library=T; run;