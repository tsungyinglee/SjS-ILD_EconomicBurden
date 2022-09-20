/******************************************************************************
 Macro to perform case-control matching

 Calls macros NTOK and RENAMEVAR - included in file

 Parameters:

 casedata    = dataset contains all cases
 controldata = dataset of potential controls
 matchvar    = list of matching variables
 matchval    = list of maximum differences allowed for matching variables
 fopvar      = (optional) variable to indicate follow-up duration. 
               Control must have value >= to case to be eligible for match
 controlspercase= number of controls to match with each case (default=1)
 id          = patient id variable
 outmatch    = output dataset containing cases and matched controls
 outnomatch  = output dataset containing cases that do not match 
 lib         = library refererence (default is current folder) where outmatch
               and outnomatch are written

 Notes: variable names for matching must be the same on case and control datasets

 Details: For each case the control dataset is searched until a match is found.
          If a match is found then case and control are output to dataset
	  If no match is found then case data is written to separate dataset
         
 outmatch contains patient ID, matching variables, and two added variables:
          ccstat = 1 for case 2 for control
	  setnumber = numbered 1 to n for case and matched control


Example: Matching numeric clinic exactly and age within 1.

%match_cc (casedata = cases,
         controldata= controls,
         matchvar= nclinic age,
	 matchval= 0 1,
	 fopvar = fopdays,
	 outmatch = psamatch,
	 outnomatch = psanomatch,
	 id =ptid);

*******************************************************************************/

/******************************************************************************
Author: GG (July 01, 2004)

%macro renamevar(data=, clist = , p=, s=);

RENAMEVAR: Renames selected variables on a dataset adding a prefix and/or 
           suffix to the variables.

PARAMETERS: data = dataset from which variables are to be changed
            clist = list of variables to change name. Default will be all vars
	    p     = prefix to add to the variables
	    s     = suffix to add to the variables

Examples: %renamevar(data=month01, clist = cd4count hivrna, s=01);
          Adds 01 to the end of the two variables
Examples: %renamevar(data=temp, p=_);
          Adds an underscore character to the beginning of all variables
          
******************************************************************************/

%macro renamevar(data=, clist = , p=, s=);

 data _temp_;
  set &data (keep= &clist);
 run;
 proc sql;
   create table _names_ as
     select name, label, length
     from dictionary.columns 
     where libname = 'WORK' and memname = '_TEMP_';
     ;
 quit;
 data _temp_;
  length name $28. newname $36. label $40.  ;
  set _names_;
  newname = "&p"||trim(name)||"&s";
  keep name newname;
 run;

 data _null_;
   set _temp_ end=last;
   call symput ('var'||left(put(_n_,4.)),name);
   call symput ('xvar'||left(put(_n_,4.)),newname);
  if last then call symput('numvar',left(put(_n_,4.)));
 run;
 proc datasets;
  modify &data;
  rename
     %do i = 1 %to &numvar;
       &&var&i = &&xvar&i
     %end;
   ;
   delete _temp_ _names_;
 %mend renamevar;
 
 
%MACRO NTOK(LIST,NTOK,TOKEN=%STR( ),VNAME=);                                    
                                                                                
%LOCAL I;
%GLOBAL &NTOK;                                                                  
%IF &VNAME = %STR() %THEN %DO;                                                  
 %DO I = 1 %TO 100;                                                             
  %IF %LENGTH(%SCAN(&LIST,&I,&TOKEN)) = 0 %THEN %GOTO DONE;                     
 %END;                                                                          
%END;                                                                           
                                                                                
%DO I = 1 %TO 100;                                                              
  %GLOBAL &VNAME&I;                                                             
  %LET &VNAME&I = %SCAN(&LIST,&I,&TOKEN) ;                                      
  %IF %LENGTH(&&&VNAME&I) = 0 %THEN %GOTO DONE;                                 
%END ;                                                                          
                                                                                
%DONE: %LET &NTOK= %EVAL(&I-1);                                                 
%MEND;                                                                          
                                                                                
%macro match_cc (casedata =,
                 controldata=,
				 matchvar=,
				 matchval=,
				 fopvar =,
				 outmatch = outmatch,
				 outnomatch = outnomatch,
				 libref = ,
      			 controlspercase=1,
				 id =ptid);



%ntok(&matchvar,nmatchvar, vname=matchvar);
%ntok(&matchval,nmatchval,vname=matchval);

* Sort control dataset by a random number;
proc sql;
 create table random_controls as
 select *, ranuni(12345) as random
 from &controldata
 order by random;
quit;

*Rename control variable names - put c_ at beginning;
%renamevar(data=random_controls, p=c_, clist=&matchvar &fopvar &id);

* Find number of cases;
%let dsid = %sysfunc(open(&casedata));
%let numcases = %sysfunc(attrn(&dsid,NOBS));
%let rc = %sysfunc(close(&dsid));
%put numcases = &numcases;


%do setnumber = 1 %to &numcases;
%do numcontrols = 1 %to &controlspercase;

data active;
 setnumber = &setnumber;
 x = setnumber;
 set &casedata point=x ;
 output;
 stop;
run;

data match   (keep = &id &matchvar &fopvar setnumber ccstat)
     nomatch (keep = &id &matchvar &fopvar setnumber )
     used (keep= c_&id);
 set active ;

 do i = 1 to totobs;
  set random_controls point=i nobs=totobs;

 %if &nmatchvar > 0 %then %do;
   if 
  %do i = 1 %to &nmatchvar;
   abs (&&matchvar&i - c_&&matchvar&i) <= &&matchval&i
    %if &i ne &nmatchvar %then %do;
     and
    %end;
  %end;
  then do;
  %if %length(&fopvar) ne 0 %then %do;
   if c_&fopvar >= &fopvar then do;
  %end;
  ccstat= 1;
  %if &numcontrols = 1 %then %do;
  output match;
  %end;
  %do i = 1 %to &nmatchvar;
   &&matchvar&i = c_&&matchvar&i;
  %end;
  %if %length(&fopvar) ne 0 %then %do;
   &fopvar = c_&fopvar;
  %end;
   &id = c_&id;
  ccstat= 2;
  output match;
  output used;
  return;
  end;
  %if %length(&fopvar) ne 0 %then %do;
  end;
  %end;
  %end;
 end;
 output nomatch;

run;

proc append data=match base=matchall;
proc append data=nomatch base=nomatchall;
proc sort data=random_controls; by c_&id;
data random_controls;
 merge random_controls used (in=used); by c_&id;
 if used ne 1;
run;
proc sort data=random_controls; by random; 

%end;
%end;

proc means data=nomatchall maxdec=1;
title "Case Values for Cases NOT Matched";
run;
data tempcase tempcontrol;
 set matchall;
 if ccstat = 1 then output tempcase; else
 if ccstat = 2 then output tempcontrol; 
run;
proc means data=tempcase maxdec=1;
title "Case Values for Cases Matched";
run;
proc means data=tempcontrol maxdec=1;
title "Control Values for Cases Matched";
run;
%renamevar(data=tempcontrol, p=c_, clist=&matchvar &fopvar &id);

%let diflist = ; 
  %do i = 1 %to &nmatchvar;
   %let diflist = &diflist d_&&matchvar&i;
  %end;
  %put diflist = &diflist;
 

data cc ;
 merge tempcase tempcontrol; by setnumber;
  %do i = 1 %to &nmatchvar;
   D_&&matchvar&i = &&matchvar&i - c_&&matchvar&i;
  %end;
  %if %length(&fopvar) > 0 %then %do;
  D_&fopvar = &fopvar - c_&fopvar;
  %end;
run;
proc means data = cc n mean std min max;
title "Differences in Matching Variables Between Case and Control for Cases Matched";
 var &diflist d_&fopvar;
run;
proc print data=matchall;
title "List of Matched Cases and Controls";
run;
proc print data=nomatchall;
title "List of Cases Not Matched";
run;

data &libref..&outmatch;
 set matchall;
run;
data &libref..&outnomatch;
 set nomatchall ;
run;

proc datasets;
 delete match matchall nomatch tempcase tempcontrol cc;
run;

%mend match_cc;
