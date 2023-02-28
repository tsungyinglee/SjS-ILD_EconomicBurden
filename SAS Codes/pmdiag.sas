/******************************************************************************* 
Program Name:	pmdiag.sas
Brief Description:	Create output to evaluate propensity score match 
Macro arguments:
	predat			=	 	Input dataset name of all patients, before match including libname if not temporary (e.g., mainlib.analysis).
									Must include both the cases and control populations. 
	postdat			=		Input dataset name of matched cases and controls.
									including libname if not temporary (e.g., mainlib.analysis). Must include both the cases and control populations.
	idvar			=		Name of unique patient variable (e.g. patient_id). 
	prob_graph		= 		Name of propensity score variable to use in report graphs.
	case_control 	=		Name of binary variable distinguishing case vs control records. 
	caseval			=		Value of &case_control. variable indicating a case record. 
	contval			= 		Value of &case_control. variable indicating a control record. 
	outpath			= 		Path for diagnotic report including filename excluding ".rtf". 
	style			= 		SAS ODS style to use when creating RTF file (defaults to rtf). 
	varlst			= 		Variable list used to create propensity score.
	varlst_test		= 		Variable list to compare pre and post matched standardized differences.	(Should include all variables in your propensity model (varlst) and may include additional variables).
	labwidth		= 		Width of label column in inches (defaults to 1.0). 
	cohwidth		=		Width of statistics columns in inches (defaults to 0.7).	
	pwidth			= 		Width of T-test p-value columns in inches (defaults to 0.7). 
	dographs		= 		Y or N to include propensity score distribution graphs.
									Setting to N may improve program speed with large datasets. 
	weight			=		Name of variable to use for weights if number of controls >1. 
	matchid			= 		Name of variable that contains match ID.
*******************************************************************************/

/* Macro for calculating statistics and independent t-tests */
%macro pmtests(insas,mpre,case_control,caseval,contval,varlst_test,weight); 
ods output Statistics=pm_stats(index=(variable)) TTests=pm_ttest(index=(variable)) Equality=pm_var_test(index=(variable));
proc ttest data=&insas. nobyvar;
title4 "Variable differences (&insas.)";
class &case_control.; var &varlst_test.; format _all_;
%if &weight. ne %then %do; weight &weight.;
%end; run; quit;
ods output close;

data pm_ttest(index=(variable));
merge pm_ttest pm_var_test(drop=method); by variable;
variable = lowcase(variable); length choose $100;
retain choose;
if first.variable then do;
if (probf > 0.05) then choose = 'Pooled'; else choose = 'Satterthwaite';
end;
if method = choose then output; keep variable tvalue probt choose; rename
tvalue = &mpre.ttst_tvalue probt	= &mpre.ttst_probt choose = &mpre.ttst_choose;
run;

data _case(index=(variable) rename=(n=&mpre.case_n mean=&mpre.case_mean	stddev=&mpre.case_stddev))
_cont(index=(variable) rename=(n=&mpre.cont_n mean=&mpre.cont_mean	stddev=&mpre.cont_stddev))
_diff(index=(variable) rename=(n=&mpre.diff_n mean=&mpre.diff_mean	stddev=&mpre.diff_stddev));
set pm_stats;
variable = lowcase(variable);
/* For weighted case replace stddev estimate with n* stderr (this would leave stddev unchanged in unweighted case) */
%if &weight. ne %then %do;
if n gt 0 then stddev = stderr*sqrt(n); else stddev = .;
%end;
if class = "&caseval." then output _case;
else if class = "&contval." then output _cont; else output _diff;
keep variable n mean stddev; run;

data &mpre.stats_one(index=(variable)); length variable $32;
merge _case _cont _diff pm_ttest; by variable;
run;
%mend;

/* Macro to run diagnostics on the match and produce a report */
%macro pmdiag(predat,postdat,idvar,prob_graph,case_control,caseval,contval,
outpath,style,varlst,varlst_test,labwidth,cohwidth,pwidth, dographs,weight,matchid);
options orientation=landscape missing=' ' center nodate;
%local int_weight;
/* Set default parameters */
%if &style. = %then %let style = rtf;
%if &labwidth. = %then %let labwidth = 1.0;
%if &cohwidth. = %then %let cohwidth = 0.7;
%if &pwidth. = %then %let pwidth = 0.7;
%if %upcase(&dographs.) = N %then %let dographs = N;
%else %let dographs = Y;

/* calculate approximate integer weight for post-histogram (which doesn't work with fractional weights in SAS 9.2) */
%if (&dographs. = Y) and (&weight. ne ) %then %do; proc sql noprint;
select min(&weight.) into :minweight from &postdat.
where (&weight. gt 0); quit;

data _null_;
if &minweight. le 10 then
call symput('multweight',trim(left(fact(ceil(1/&minweight.))))); else call symput('mult_weight',trim(left(1/&minweight.)));
stop; run;

data _postdatmod; set &postdat.;
int_weightmod = ceil(&multweight.*&weight.); run;

%let postdatmod = _postdatmod;
%let int_weight = int_weightmod;
%end;
%else %let postdatmod = &postdat.;

%if &matchid. ne %then %do; proc sql;
/* Calculate case-control propensity score differences */ create table outt as
select (case.&prob_graph. - cntrl.&prob_graph.) as Case_Control_Diff, case.&matchid. as matchid
from &postdat.(where=(&case_control. = &caseval.)) as case, &postdat.(where=(&case_control. = &contval.)) as cntrl
where case.&matchid. = cntrl.&matchid.;
/* calculate control counts */ create table control_counts as select count(*) as control_count from outt
group by matchid; quit;
%end;

ods rtf file = "&outpath..rtf" bodytitle style=&style. notoc_data;

ods escapechar = '^';
/*print a table of variable names and lables used to create PS*/
%if (%symexist(varlst) = 1) %then %do;
%if %quote(&varlst.) ne %then %do; data varnames;
if _n_ = 1 then set &predat.; length Variable $32 Label $260; array varnama &varlst.;
do over varnama;
Variable = lowcase(vname(varnama)); Label = vlabel(varnama);
output; end;
keep variable label; stop;
run;
proc print noobs; title3 'Variables in propensity score model'; run;
%end;
%end;

/*print frequencies of sample size pre- and post-match*/ proc freq data = &predat.;
title3 "Pre-match cohort counts"; tables &case_control.;
run;
proc freq data = &predat.; where &prob_graph. gt .Z;
title3 "Pre-match cohort counts with non-missing propensity score"; tables &case_control.;
run;
proc freq data = &postdat.;
title3 "Post-match cohort counts"; tables &case_control.;
run;
%if &matchid. ne %then %do;
proc freq data = control_counts;
title3 "Post-match number of control matches per case"; tables control_count;
run;
%end;

/*create propensity score distribution graphs*/
%if &dographs. = Y %then %do; ods rtf select SummaryPanel;
ods listing exclude SummaryPanel QQPlot; ods graphics on;
proc ttest data=&predat.(rename=(&prob_graph.=Propensity)) plot; title3 "Pre-match propensity scores by cohort";
class &case_control.; var Propensity;
run;
ods graphics off;

ods rtf select SummaryPanel; ods graphics on;
ods listing exclude SummaryPanel QQPlot;

proc ttest data=&postdatmod.(rename=(&prob_graph.=Propensity)) plot;
%if &int_weight. ne %then %do;
title3 "Weighted post-match propensity scores by cohort";
%end;
%else %do;
title3 "Post-match propensity scores by cohort";
%end;
class &case_control.; var Propensity;
%if &int_weight. ne %then %do; freq &int_weight.; %end; run;
ods graphics off; ods rtf exclude all;

%if &matchid. ne %then %do; ods rtf select SummaryPanel;
ods listing exclude SummaryPanel QQPlot; ods graphics on;
proc ttest data=outt plot;
title3 "Post-matched paired propensity score differences"; var Case_Control_Diff;
label Case_Control_Diff = 'Case-Control Propensity Difference'; run;
ods graphics off; ods rtf exclude all;
%end;

/*if there is at least one un-matched case and one-unmatched control, create output for the un-matched patients*/
proc sort data=&predat.(keep=&idvar. &prob_graph. &case_control.) out=insort; by &idvar.;
run;
proc sort data=&postdat.(keep=&idvar.) out=outsort; by &idvar.;
run;
data nomatch;
merge insort(in=inin) outsort(in=inout); by &idvar.;
if inout then delete; run;

proc freq data = nomatch;
tables &case_control. /out = nomatch_freq; run;

data _null_;
set nomatch_freq nobs =	nomatch_cnt; call symput('nomatch_cnt', nomatch_cnt);
run;

%if &nomatch_cnt. = 2 %then %do; ods rtf select SummaryPanel;
ods listing exclude SummaryPanel QQPlot; ods graphics on;
proc ttest data=nomatch(rename=(&prob_graph.=Propensity)) plot; title3 "Propensity scores for dropped records by cohort";

class &case_control.; var Propensity;
run;
%end;
ods graphics off;
%end;
ods rtf exclude all;

/*create summary table of covariates*/
%pmtests(&predat., pre_, &case_control.,&caseval.,&contval.,&varlst_test.)
%pmtests(&postdat.,post_,&case_control.,&caseval.,&contval.,&varlst_test.,&weight.)

ods listing close; data varnames_test;
if _n_ = 1 then set &predat.; length variable $32 label $260; array varnama &varlst_test.;
do over varnama;
variable = lowcase(vname(varnama)); label = vlabel(varnama);
vorder = _i_; output;
end;
keep variable label vorder; stop;
run;
proc sort nodupkey; by variable; run;

data stats_one;
merge pre_stats_one post_stats_one varnames_test; by variable;
length pre_stddiff post_stddiff post_stddiff2 post_diffred pre_diff post_diff 8; format
pre_stddiff post_stddiff post_stddiff2 post_diffred 6.2
pre_diff post_diff 8.4; label
pre_stddiff     = 'Pre-Match Standardized Difference	' post_stddiff = 'Post-Match Standardized Difference, (Pre-match variances) ' post_stddiff2 = 'Post-Match Standardized Difference, (Post-match variances)' post_diffred    = 'Post-Match Difference Percent Reduction	'
pre_diff        = 'Pre-Match Difference	'
post_diff       = 'Post-Match Difference	'
pre_ttst_probt  = 'Pre-Match T-Test P-Value	'
post_ttst_probt = 'Post-Match T-Test P-Value	';

pre_denom		= sqrt((pre_case_stddev**2 + pre_cont_stddev**2)/2); post_denom = sqrt((post_case_stddev**2 + post_cont_stddev**2)/2); pre_diff	= pre_case_mean - pre_cont_mean;
post_diff = post_case_mean - post_cont_mean; if pre_denom gt 0 then do;
pre_stddiff	= 100*(pre_case_mean - pre_cont_mean)/pre_denom; post_stddiff = 100*(post_case_mean - post_cont_mean)/pre_denom;
end; else do;
pre_stddiff	= .; post_stddiff = .;
end;
if post_denom gt 0
then post_stddiff2 = 100*(post_case_mean - post_cont_mean)/post_denom; else post_stddiff2 = .;
if abs(pre_case_mean - pre_cont_mean) gt 0
then post_diffred = 100*(1 - abs((post_case_mean - post_cont_mean)
/(pre_case_mean - pre_cont_mean))); else if ((pre_case_mean - pre_cont_mean) = 0) and
((post_case_mean - post_cont_mean) = 0) then post_diffred = 0;
else post_diffred = .; drop pre_denom post_denom;
run;
proc sort; by vorder;
run;
ods rtf select all;

title3 'Variable Balance Checks';
proc report data=stats_one nowd split = "\" style=[protectspecialchars=off]; column variable label pre_case_mean pre_cont_mean pre_diff pre_stddiff
post_case_mean post_cont_mean post_diff post_stddiff2 pre_ttst_probt post_ttst_probt;
define variable	/ display "Variable"
left	style={cellwidth=&labwidth. in}; define label	/ display "Variable\Description"
left	style={cellwidth=1.5 in}; define pre_case_mean	/ display "Pre\Match\Case\Mean"
right style={cellwidth=&cohwidth. in}; define pre_cont_mean	/ display "Pre\Match\Control\Mean"
right style={cellwidth=&cohwidth. in}; define pre_diff	/ display "Pre\Match\Diff"
right style={cellwidth=&cohwidth. in}; define pre_stddiff	/ display "Pre\Match\Stand\Diff (%)"
right style={cellwidth=&cohwidth. in}; define post_case_mean / display "Post\Match\Case\Mean"
right style={cellwidth=&cohwidth. in}; define post_cont_mean / display "Post\Match\Control\Mean"
right style={cellwidth=&cohwidth. in}; define post_diff	/ display "Post\Match\Diff"
right style={cellwidth=&cohwidth. in}; define post_stddiff2	/ display "Post\Match\Stand\Diff (%)"
right style={cellwidth=&cohwidth. in}; define pre_ttst_probt / display "Pre\Match\T-test\p-value"
right style={cellwidth = &pwidth. in}; define post_ttst_probt/ display "Post\Match\T-test\p-value"
right style={cellwidth = &pwidth. in};
run;
ods rtf exclude all; ods rtf close;
ods listing;
%mend;
