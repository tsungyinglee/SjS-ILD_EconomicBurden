/*----------------------------------------------------------------------

   Margins macro

   Fits the specified generalized linear or GEE model and estimates predictive
   margins and/or average marginal effects for variables in the model.
   Differences and contrasts of predictive margins and average marginal effects
   with confidence limits are also available. Margins and effects can be
   estimated at specified values of other model variables or at computed values
   such as means or medians.


Requires:
   SAS/STAT and SAS/IML.


Macro options (data=, response=, and model= are required):
   data= data-set-name
    Required. Specify the name of the input data set to model.

   margins= variable(s)
    Margins are estimated for all levels or combinations of levels of the
    specified variables in the data= data set or the margindata= data set if
    specified. The specified variables must also appear in model=. The levels or
    combinations of levels defining the margins can be reduced using the
    margwhere= option.
   
   effect= variable
    Average marginal effects are estimated for the specified continuous
    variable. Only one variable can be specified and it must not be specified in
    class= or offset=. If margins= and/or at= are also specified, the average
    marginal effects for the variable are estimated within each combination of
    levels of the margins= and/or at= variables. Marginal effects for
    categorical variables can be obtained as differences of predictive margins.
    Specify the class= variable in margins= instead of effect= and request
    differences with options=diff.

   margindata= data-set-name
    Specify a data set containing the margins= variables for defining the
    margins to be computed. If not specified, the data= data set is used. The
    levels or combinations of levels defining the margins can be reduced using
    the margwhere= option.

   margwhere= where-condition
    Specify a WHERE statement condition to subset the levels or combination of
    levels defining the margins= to be computed.

   response= variable
    Required. Specify the name of the response variable to be modeled. The
    specified variable must be numeric. Events/trials syntax for aggregated data
    is not supported.

   roptions= response-options
    Specify any options for the response variable as described in the MODEL
    statement of PROC GENMOD.

   class= variable(s)
    Specify a list of any categorical predictors to be placed in a CLASS
    statement. CLASS statement options available in PROC GENMOD (such as REF=)
    are not allowed.
   
   model= model-effects
    Required. Specify the model to be fit by PROC GENMOD.  This is the list of
    model effects that would appear following the equal sign (=) in the MODEL
    statement of PROC GENMOD. Nested effects are not supported.

   dist= distribution-name
    Specify the response distribution. Valid distribution names are Normal,
    Binomial, Poisson, Negbin (for negative binomial), Gamma, Geometric,
    IGaussian (for inverse gaussian), or Tweedie. Default: Normal.

   link= link-function-name
    Specify the link function. Valid link function names are Identity, Log,
    Logit, Probit, or Power(p), where p is a numeric power value. The default
    link function is the canonical link for the specified distribution as shown
    in the description of the DIST= option in the GENMOD documentation.

   offset= variable
    Specify the offset variable if needed. Typically used for Poisson or
    negative binomial models when modeling a rate, in which case the offset
    variable should be the log of the rate denominator. This variable should not
    be specified in the EFFECT= option.

   modelopts= model-options
    Specify any options to appear in the PROC GENMOD MODEL statement other than
    DIST=, LINK=, OFFSET=, or SINGULAR=.

   at= variable(s)
    The margins requested in margins= will be estimated at each level or
    combination of levels of the specified variables in the data= data set or
    the atdata= data set if specified. The specified variables must also appear
    in model=. The levels or combinations of levels at which margins will be
    computed can be reduced using the atwhere= option.
   
   atdata= data-set-name
    Specify a data set containing the at= variables at which the requested
    margins will be computed. If not specified, the data= data set is used.  The
    levels or combinations of levels at which margins will be computed can be
    reduced using the atwhere= option.

   atwhere= where-condition
    Specify a WHERE statement condition to subset the levels or combination of
    levels of the at= variables.

   within= where-condition
    After fitting the model, margins and marginal effects are computed using 
    only the observations meeting the specified condition. Unlike margins= and
    at=, within= does not fix any variables in the model. The specified model
    is fit on the complete data= data set (minus observations with missing 
    values - see below). Any statistics options (options=atmeans, mean=, and 
    others) used to fix variables are also computed on the complete data= data
    set.

   contrasts= data-set-name
    Specify a data set containing labels and contrast coefficients defining
    contrasts of predictive margins and/or average marginal effects to be
    estimated. Note that coefficients should be given for all estimates, not
    just those within a combination of at= variable values. The data set must
    contain two character variables, LABEL and F. Each observation of the data
    set defines one contrast which can be a multi-row contrast. LABEL contains
    the labels that will identify the contrasts in the results. F contains the
    coefficients defining each contrast. If the contrast has multiple rows, use
    commas to separate the sets of coefficients in the rows.

   geesubject= variable-or-model-effect
    Specifies the effect that defines correlated clusters of observations in GEE
    models when fitting the model in PROC GENMOD. Required when fitting a GEE
    model. See the description of the SUBJECT= option in the REPEATED statement
    in the GENMOD documentation.
   
   geewithin= variable
    Optionally specifies the order of measurements within correlated clusters of
    observations in GEE models when fitting the model in PROC GENMOD. See the
    description of the WITHIN= option in the REPEATED statement in the GENMOD
    documentation.
   
   geecorr= structure-name
    Specifies the correlation structure when fitting a GEE model in PROC GENMOD.
    For valid structure names, see the description of the TYPE= option in the
    REPEATED statement in the GENMOD documentation. Default: IND (the
    independence structure).
   
   freq= variable
    Specifies a frequency variable used when fitting the model in PROC GENMOD.
    Each observation is treated as if it appears n times, where n is the value
    of the FREQ= variable for the observation.
   
   weight= variable 
    Specifies a weight variable used when fitting the model in PROC GENMOD. See
    the description of the WEIGHT statement in the GENMOD documentation.

   mean= variable(s)
   median= variable(s)
   q1= variable(s)
   q3= variable(s)
    Use these statistic options to fix model variables at computed values when
    estimating margins or marginal effects. The specified variables should not
    appear in margins= or at= but must appear in model=. Only numeric variables
    not specified in class= should appear in median=, q1=, or q3=. Variables in
    mean= can be specified in class= or not. For a class= variable specified in
    mean=, the observed proportions are used as values of the dummy variables
    that represent the variable in the model.

   balanced= variable(s)
    The specified variables must also be specified in model= and class= and not
    in margins= or at=. For a specified variable with k levels, the values of
    the dummy variables representing it in the model are all fixed at 1/k when
    computing predictive margins.
   
   alpha= value
    Specify the alpha level for confidence intervals with confidence level 1-
    alpha. Value must be between 0 and 1. Default: 0.05.

   singular= value
    Specify a singularity criterion for use in PROC GENMOD. Value must be
    between 0 and 1. See the description of the SINGULAR= option in the MODEL
    statement in the GENMOD documentation.

   options= list-of-options
    Specify desired options separated by spaces. Valid options are:
      DESC
         Adds the DESCENDING option in the PROC GENMOD statement to model the
         higher response level in binomial models. However, it is better to
         explicitly specify the response level to model using the EVENT=
         response variable option. For example, to model the probability that
         the response=1, specify roptions=event="1".
      DIFF
         Estimate all pairwise differences among the margins and/or marginal
         effects. If at= is specified, differencing is done within each unique
         combination of the at= variable levels. For differencing across the at=
         combinations, use contrasts= or specify the at= variables in margins=
         rather than in at= and specify options=diff.
      CL
         Provide confidence intervals for predictive margins, average marginal
         effects, and differences.
      NOMODEL
         Do not display the fitted model.
      NOPRINT
         Suppress all displayed results. Note that results are always saved in
         data sets as shown in the Notes section below.
      NOPRINTBYAT
         Does not display predictive margins, average marginal effects, and
         differences in separate tables defined by the at= variables as is done
         by default. Instead, all margins are displayed in one table (similarly
         for marginal effects and differences) and the at= variable values are
         included in the table.
      REVERSE
         Reverse the direction of margin and effect differences.
      ATMEANS
         Compute predictive margins at the means of all other model variables
         except for those specified in at=. For marginal effects, all variables
         other than those in margins= or at= are fixed at their means. The
         mean=, median=, q1=, q3=, and balanced= options are ignored. For a
         class= variable, its overall observed proportions are used as values
         for the dummy variables that represent the variable in the model.


Notes:
   Observations with missing values in any of the model variables are omitted 
   from the analysis. However, observations that are missing only on the 
   response are used. Note that predicted values can be computed for 
   observations missing only on the response and therefore they contribute in
   the computation of predictive margins and marginal effects. When 
   options=atmeans is specified, these observations also contribute to the 
   means. 
   
   To compute predictive margins, a data set is created that contains a complete
   replicate of the input data set for each requested margin. As a result, this
   data set can become very large if the input data set is large or a large
   number of margins are requested, or both.
   
   The delta method is used to determine the standard errors. Large-sample
   (Wald) tests and confidence intervals (if requested with options=cl) are
   provided.
   
   OUTPUT DATA SETS

   The following data sets containing results are available after successful 
   completion of the macro:
   
     If margins= is specified:
     - _Margins - contains the estimated margins, standard errors, tests, and 
        confidence intervals if requested.
     - _CovMarg - contains the estimated covariance matrix of the margins.
     - _Diffs (if options=diff is specified) - contains the differences of the
        margins with standard errors, tests, and confidence intervals (if
        requested).
     - _Contrasts (if contrasts= is specified) - contains the tests of the 
        specified contrasts or predictive margins.
     
     If effect= is specified:
     - _MEffect - contains the estimated average marginal effects, standard 
        errors, tests, and confidence intervals if requested.
     - _CovMeff - contains the estimated covariance matrix of the average 
        marginal effects.
     - _DiffME (if options=diff is specified) - contains the differences of the 
        average marginal effects with standard errors, tests, and confidence
        intervals (if requested).
     - _ContrastME (if contrasts= is specified) - contains the tests of the 
        specified contrasts of average marginal effects.


Limitations:
   The Margins macro cannot be used for multinomial models, zero-inflated 
   models, models with random effects, or models containing nested effects.
   
   Events/trials syntax is not allowed for analysis of aggregated binomial data.
   Instead, convert the data to use the freq= option.
 
 
Examples:

In addition to the following code examples, see the Results tab in the Margins 
macro documentation (http://support.sas.com/kb/63038) for examples with 
discussion of the results.

In an ordinary regression model with normal response, the following estimates
predictive margins with 95% confidence intervals for Sex levels.

   %Margins(data     = mydata,
            class    = Sex Race,
            response = y,
            model    = Sex Race,
            margins  = Sex, 
            options  = cl)

In a binary logistic model for the probability of Disease=1, the following
estimates the Sex predictive margins and their difference (the marginal effect)
and reverses the direction of the difference (Male-Female rather than the
default Female-Male).

   %Margins(data     = mydata,
            class    = Sex Race,
            response = Disease, 
            roptions = event='1',
            model    = Sex Race,
            dist     = binomial,
            margins  = Sex, 
            options  = cl diff reverse)

Estimate predictive margins for Sex holding Race, Weight, and Age at their
means. Since Race is a CLASS variable, this means that the observed proportions
are used for its dummy variables when estimating the margins. Reverse the
direction when computing the difference (effect).

   %Margins(data     = mydata,
            class    = Sex Race,
            response = Disease, 
            roptions = event='1',
            model    = Sex Race Weight Age,
            dist     = binomial,
            margins  = Sex, 
            options  = atmeans cl diff reverse)

The following uses the article publishing data in the Getting Started section of
the PROC COUNTREG documentation. The macro fits a Poisson model with two main
effects and their interaction. An offset is specified in order to model the
publishing rate. The macro then estimates predictive margins for the genders
(FEM) and their difference. 90% confidence intervals are provided.

   %Margins(data     = long97data,
            class    = fem mar,
            response = art,
            model    = fem|mar, 
            offset   = lnart,
            dist     = poisson,
            margins  = fem, 
            alpha    = 0.1,
            options  = cl diff)

 Using the same publishing data as the previous example, the following estimates
 predictive margins for the genders (FEM) within each of the four levels of KID5
 at the mean of MENT. It also estimates margin differences and tests the three
 contrasts of margins specified in data set C. Note that the third contrast
 compares the sexes in the first two KID5 levels producing a 2 degrees of
 freedom test.

   data c; 
     length label f $32767; 
     infile datalines delimiter='|';
     input label f; 
     datalines;
   f-m in kid5=1 - f-m in kid5=4 | -1 1 0 0 0 0 1 -1
   m-f avgd over kid5 levels | 1 -1 1 -1 1 -1 1 -1
   m-f in kid5 levels 1 and 2 | 1 -1 0 0 0 0 0 0, 0 0 1 -1 0 0 0 0
   ;
   %Margins(data     = long97data,
            class    = fem mar,
            response = art, 
            offset   = lnart,
            model    = fem mar kid5 ment,
            dist     = poisson,
            margins  = fem, 
            contrasts= c,
            at       = kid5, 
            mean     = ment,
            options  = cl diff)

Using the air pollution data in the Getting Started section example titled
"Generalized Estimating Equations" in the PROC GENMOD documentation, the
following estimates predictive margins for continuous predictor SMOKE in a
logistic GEE model. The data contain repeated measurements on cases at a range
of ages. An exchangable correlation structure is used.

   %Margins(data      = six,
            class     = case city age,
            response  = wheeze,
            model     = city age smoke,
            dist      = binomial,
            geesubject= case, 
            geecorr   = exch, 
            geewithin = age,
            margins   = smoke, 
            options   = cl model)
             
Using the cancer remission data in the example titled "Stepwise Logistic
Regression and Predicted Values" in the PROC LOGISTIC documentation, the
following estimates the average marginal effect for Blast at the means of Smear
and Blast.

   %Margins(data     = Remission,
            response = Remiss, 
            roptions = event='1',
            model    = Blast Smear,
            dist     = binomial,
            effect   = Blast,
            options  = atmeans)

Using the neuralgia data in the example titled "Logistic Modeling with
Categorical Predictors" in the PROC LOGISTIC documentation, the following
estimates a logistic model for Pain=No involving four predictors. Since the
macro requires a numeric response, the numeric variable PainNo is created with
value 1 when Pain=No. The macro estimates both the predictive margins and the
average marginal effects for the Treatments in each Sex at the means of Age and
Duration.

   data Neur; 
      set Neuralgia; 
      PainNo=(pain='No'); 
      run;
   %Margins(data     = Neur,
            class    = Treatment Sex,
            response = PainNo,
            roptions = event='1',
            dist     = binomial,
            model    = Treatment|Sex Age Duration,
            margins  = Treatment, 
            effect   = Duration,
            at       = Sex,
            options  = cl diff atmeans )


------------------------------------------------------------------------

DISCLAIMER:

       THIS INFORMATION IS PROVIDED BY SAS INSTITUTE INC. AS A SERVICE
TO ITS USERS.  IT IS PROVIDED "AS IS".  THERE ARE NO WARRANTIES,
EXPRESSED OR IMPLIED, AS TO MERCHANTABILITY OR FITNESS FOR A
PARTICULAR PURPOSE REGARDING THE ACCURACY OF THE MATERIALS OR CODE
CONTAINED HEREIN.

----------------------------------------------------------------------*/

%macro margins(version, data=,
       class=, response=, roptions=, model=, dist=, link=, offset=, modelopts=,
       freq=, weight=, geesubject=, geecorr=, geewithin=,
       margins=, MarginData=, margwhere=, 
       at=, AtData=, atwhere=,
       effect=, mean=, balanced=, median=, q1=, q3=,
       within=, contrasts=, alpha=0.05, singular=, options=) / minoperator;

%let time = %sysfunc(datetime());

/*  Some macros for checking inputs.
/---------------------------------------------------------------------*/
%macro existchk(data=, var=, dmsg=e, vmsg=e);
   %global status; %let status=ok;
   %if &dmsg=e %then %let dmsg=ERROR;
   %else %if &dmsg=w %then %let dmsg=WARNING;
   %else %let dmsg=NOTE;
   %if &vmsg=e %then %let vmsg=ERROR;
   %else %if &vmsg=w %then %let vmsg=WARNING;
   %else %let vmsg=NOTE;
   %if &data ne %then %do;
     %if %sysfunc(exist(&data)) ne 1 %then %do;
       %put &dmsg: Data set %upcase(&data) not found.;
       %let status=nodata;
     %end;
     %else %if &var ne %then %do;
       %let dsid=%sysfunc(open(&data));
       %if &dsid %then %do;
         %let i=1;
         %do %while (%scan(&var,&i) ne %str() );
            %let var&i=%scan(&var,&i);
            %if %sysfunc(varnum(&dsid,&&var&i))=0 %then %do;
     %put &vmsg: Variable %upcase(&&var&i) not found in data %upcase(&data).;
              %let status=novar;
            %end;
            %let i=%eval(&i+1);
         %end;
         %let rc=%sysfunc(close(&dsid));
       %end;
       %else %put ERROR: Could not open data set &data.;
     %end;
   %end;
   %else %do;
     %put &dmsg: Data set not specified.;
     %let status=nodata;
   %end;   
%mend;

%macro reqopts(opts=);
   %global status; %let status=ok;
   %let i=1;
   %do %while (%scan(&opts,&i) ne %str() );
      %let opt=%scan(&opts,&i);
      %if %quote(&&&opt)= %then %do;
        %put ERROR: %upcase(&&opt=) is required.;
        %let status=noreqopt;
      %end;
      %let i=%eval(&i+1);
   %end;
%mend;

%macro attrcomp(data1=, data2=, vars=);
   %global status; %let status=ok;
   %let i=1;
   %do %while (%scan(&vars,&i) ne %str() );
      %let v=%scan(&vars,&i);
      %let dsid=%sysfunc(open(&data1));
      %if &dsid %then %do;
        %let vnum=%sysfunc(varnum(&dsid,&v));
        %if &vnum %then %do;
          %let dfmt=%sysfunc(varfmt(&dsid,&vnum));
          %let dtyp=%sysfunc(vartype(&dsid,&vnum));
          %let dlen=%sysfunc(varlen(&dsid,&vnum));
        %end;
        %let rc=%sysfunc(close(&dsid));
      %end;
      %let dsid=%sysfunc(open(&data2));
      %if &dsid %then %do;
        %let vnum=%sysfunc(varnum(&dsid,&v));
        %if &vnum %then %do;
          %let mdfmt=%sysfunc(varfmt(&dsid,&vnum));
          %let mdtyp=%sysfunc(vartype(&dsid,&vnum));
          %let mdlen=%sysfunc(varlen(&dsid,&vnum));
        %end;
        %let rc=%sysfunc(close(&dsid));
      %end;
      %if &dfmt ne &mdfmt or &dtyp ne &mdtyp or &dlen ne &mdlen %then %do;
         %put ERROR: Variable %upcase(&v) has different type, length, or;
         %put ERROR- format in the %upcase(&data1) and %upcase(&data2) data sets.;
         %let status=AttrDiff;
      %end;
      %let i=%eval(&i+1);
   %end;
%mend;


/*  Version and debug options.
/---------------------------------------------------------------------*/
%let _version = 1.07;
%if &version ne %then %put NOTE: &sysmacroname macro Version &_version..;
%let _opts = %sysfunc(getoption(notes));
%if %index(%upcase(&version),DEBUG) %then %do;
  options notes mprint
    %if %index(%upcase(&version),DEBUG2) %then mlogic symbolgen;
  ;
  ods select all;
  %put _user_;
%end;
%else %do;
  options nonotes nomprint nomlogic nosymbolgen;
  ods exclude all;
%end;


/* Check for newer version 
/---------------------------------------------------------------------*/
%let _notfound=0;
filename _ver url 'http://ftp.sas.com/techsup/download/stat/versions.dat' 
         termstr=crlf;
data _null_;
  infile _ver end=_eof;
  input name:$15. ver;
  if upcase(name)="&sysmacroname" then do;
    call symput("_newver",ver); stop;
  end;
  if _eof then call symput("_notfound",1);
  run;
options notes;
%if &syserr ne 0 or &_notfound=1 %then
  %put NOTE: Unable to check for newer version of &sysmacroname macro.;
%else %if %sysevalf(&_newver > &_version) %then %do;
  %put NOTE: A newer version of the &sysmacroname macro is available at;
  %put NOTE- this location: http://support.sas.com/ ;
%end;
%if %index(%upcase(&version),DEBUG)=0 %then options nonotes;;


/*  Normalizations, initializations, and input checks.
/---------------------------------------------------------------------*/
%let class = %upcase(&class); 
%let at = %upcase(&at); %let mean = %upcase(&mean); 
%let balanced = %upcase(&balanced); %let effect = %upcase(&effect);

proc glmselect data=&data outdesign=_null_ namelen=200;
  %if &class ne %then class &class;;
  model &response = &model / selection=none;
  run;
%if &syserr %then %do;
   %let status=glmsfail;
   %goto exit;
%end;
%let model = %upcase(&_glsind);

%let modelvars = %sysfunc(translate(&model,"  ","*|")) 
                 %upcase(&offset &freq &weight);
%if %quote(&margins) ne %then
   %let margins = %upcase(%sysfunc(translate(&margins,"  ","*|")));
%if %quote(&geesubject) ne %then 
   %let geesubvars = %upcase(%sysfunc(translate(&geesubject,"   ","*%(%)")));
%else %let geesubvars=;
%if %quote(&geewithin) ne %then 
   %let geewvars = %upcase(%sysfunc(translate(&geewithin,"   ","*%(%)")));
%else %let geewvars=;
%if %sysevalf(&alpha <= 0 or &alpha >= 1) %then %do;
   %put ERROR: The ALPHA= value must be between 0 and 1.;
   %goto exit;
%end;
%if &singular ne %then %do;
   %if %sysevalf(&singular < 0 or &singular > 1) %then %do;
      %put ERROR: The SINGULAR= value must be between 0 and 1.;
      %goto exit;
   %end;
%end;
%let paren=%str(%();
%if %index(&class,/) or %index(&class,&paren) %then %do;
   %put ERROR: CLASS= must contain only a list of variable names.;
   %goto exit;
%end;
%if %index(&model,&paren) %then %do;
   %put ERROR: Nested effects are not supported.;
   %goto exit;
%end;
%if %index(&response,/) %then %do;
   %put ERROR: Events/Trials response syntax is not supported.;
   %goto exit;
%end;
%if %index(%upcase(&modelopts),NOINT) %then %let int=0;
%else %let int=1;
%if %sysfunc(countw(&effect, ' '))>1 %then %do;
   %put ERROR: Only one continuous variable can be specified in EFFECT=.;
   %goto exit;
%end;
%if %sysfunc(findw(&class, &effect, ' ', E)) %then %do;
   %put ERROR: To estimate the marginal effect of a CLASS variable, specify;
   %put ERROR- the variable in MARGINS= rather than EFFECT= and request;
   %put ERROR- differences with OPTIONS=DIFF.;
   %goto exit;
%end;

/* Verify OPTIONS= values. */
%let validopts=DIFF CL NOPRINT NOMODEL NOPRINTBYAT REVERSE ATMEANS DESC;
%let diff=0; %let diffPM=0; %let diffME=0; %let cl=0; %let print=1; 
%let fit=1; %let rdiff=0; %let atm=0; %let pbyat=1; %let desc=0;
%let i=1;
%do %while (%scan(&options,&i) ne %str() );
   %let option&i=%upcase(%scan(&options,&i));
   %if &&option&i=DIFF %then %do; 
     %let diff=1; %let diffPM=1; %let diffME=1;
   %end;
   %if &&option&i=CL %then %let cl=1;
   %if &&option&i=NOPRINT %then %let print=0;
   %if &&option&i=NOMODEL %then %let fit=0;
   %if &&option&i=REVERSE %then %let rdiff=1;
   %if &&option&i=ATMEANS %then %let atm=1;
   %if &&option&i=NOPRINTBYAT %then %let pbyat=0;
   %if &&option&i=DESC %then %let desc=1;
    %let chk=%eval(&&option&i in &validopts);
    %if not &chk %then %do;
      %put ERROR: Valid values of OPTIONS= are: &validopts..;
      %goto exit;
    %end;
   %let i=%eval(&i+1);
%end;

/* Verify required options are specified. */
%reqopts(opts=data response model)
%if &status=noreqopt %then %goto exit;

/* Verify specified data sets and variables exist. */
%existchk(data=&data, 
  var=&response &modelvars &class &margins &at &mean &balanced 
      &median &q1 &q3 &geesubvars &geewvars &effect)
%if &status=nodata or &status=novar %then %goto exit;
%if &margindata ne %then %do;
  %if &margins= %then %do;
    options notes;
    %put NOTE: MARGINDATA= ignored since no variables specified in MARGINS=.;
    %if %index(%upcase(&version),DEBUG)=0 %then options nonotes;;
  %end;
  %existchk(data=&margindata, var=&margins);
  %if &status=nodata or &status=novar %then %goto exit;
%end;
%if &AtData ne %then %do;
  %if &at= %then %do;
    options notes;
    %put NOTE: ATDATA= ignored since no variables specified in AT=.;
    %if %index(%upcase(&version),DEBUG)=0 %then options nonotes;;
  %end;
  %existchk(data=&AtData, var=&at);
  %if &status=nodata or &status=novar %then %goto exit;
%end;
%if &contrasts ne %then %do;
  %existchk(data=&contrasts, var=f label);
  %if &status=nodata or &status=novar %then %goto exit;
%end;

/* Verify margins= (at=) variables have same type, length, 
   and format in data= and margindata= (atdata=)
*/
%if &margins ne and &margindata ne %then %do;
  %AttrComp(data1=&data, data2=&margindata, vars=&margins)
  %if &status=AttrDiff %then %goto exit;
%end;
%if &at ne and &atdata ne %then %do;
  %AttrComp(data1=&data, data2=&atdata, vars=&at)
  %if &status=AttrDiff %then %goto exit;
%end;

/* Verify response is numeric */
%let dsid=%sysfunc(open(&data));
%if &dsid %then %do;
  %let varnum=%sysfunc(varnum(&dsid,&response));
  %if %sysfunc(vartype(&dsid,&varnum))=C %then %do;
    %put ERROR: The RESPONSE= variable, &response, must be numeric.;
    %goto exit;
  %end;
  %let rc=%sysfunc(close(&dsid));
%end;

/* For most options, a variable should be in only one. */
%let lists=margins at balanced mean median q1 q3 response;
%do i=1 %to %sysfunc(countw(&lists))-1;
  %let chkin=;
  %let chkfor=%upcase(&&%scan(&lists,&i));
  %do h=&i+1 %to %sysfunc(countw(&lists));
    %let chkin=%upcase(&chkin &&%scan(&lists,&h));
  %end;
  %let j=1; 
  %do %while (%scan(&chkfor,&j) ne %str() and &chkin ne);
    %let v=%scan(&chkfor,&j);
    %if &v in &chkin %then %do;
      %put ERROR: Variable &v should appear in only one of MARGINS=, AT=,;
      %put ERROR- BALANCED=, MEAN=, MEDIAN=, Q1=, Q3=, or RESPONSE=;
      %goto exit;
    %end;
    %let j=%eval(&j+1);
  %end;
%end;

/* For ATMEANS move all model variables not in margins= or at= to means= */
%if &atm %then %do;
   %let margateff = _null_ &margins &at;
   %let atmlist=_null_; %let i=1;
   %do %while (%scan(&modelvars,&i) ne %str() );
      %let v=%scan(&modelvars,&i);
      %if not(&v in &margateff) and not(&v in &atmlist) 
        %then %let atmlist=&atmlist &v;
      %let i=%eval(&i+1);
   %end;
   %let atmlist = %sysfunc(tranwrd(&atmlist,_null_,));
   %let mean=&atmlist; %let balanced=; %let median=; %let q1=; %let q3=;
%end;

/* CLASS variable checks and create variable lists. */
%if &class ne %then %do;
   /* Create list of all continuous variables in the model */
   %let i=1; %let allcont=;
   %do %while (%scan(&modelvars,&i) ne %str() );
     %let v=%scan(&modelvars,&i);
     %if not(&v in &class) %then %let allcont=&allcont &v;
     %let i=%eval(&i+1);
   %end;
   /* Create list of continuous Margin variables */
   %let i=1; %let margcont=;
   %do %while (%scan(&margins,&i) ne %str() );
     %let v=%scan(&margins,&i);
     %if not(&v in &class) %then %let margcont=&margcont &v;
     %let i=%eval(&i+1);
   %end;
   /* Create list of continuous mean= variables */
   %let i=1; %let meancont=;
   %do %while (%scan(&mean,&i) ne %str() );
     %let v=%scan(&mean,&i);
     %if not(&v in &class) %then %let meancont=&meancont &v;
     %let i=%eval(&i+1);
   %end;
   /* Create list of continuous AtData= variables */
   %let i=1; %let atcont=;
   %do %while (%scan(&at,&i) ne %str() );
     %let v=%scan(&at,&i);
     %if not(&v in &class) %then %let atcont=&atcont &v;
     %let i=%eval(&i+1);
   %end;
   /* Verify GEE subject and within variables are in class= */
   %let i=1; %let gee=&geesubvars &geewvars;
   %do %while (%scan(&gee,&i) ne %str() );
     %let v=%scan(&gee,&i);
     %if not(&v in &class) %then %do;     
        %put ERROR: GEESUBJECT= and GEEWITHIN= variables, if specified,;
        %put ERROR- must be specified in CLASS=.;
        %goto exit;
     %end;
     %let i=%eval(&i+1);
   %end;
   /* Verify balanced= variables are in class= */
   %let i=1; 
   %do %while (%scan(&balanced,&i) ne %str() );
     %let v=%scan(&balanced,&i);
     %if not(&v in &class) %then %do;     
        %put ERROR: BALANCED= variables must be specified in CLASS=.;
        %goto exit;
     %end;
     %let i=%eval(&i+1);
   %end;
   /* Verify offset, median, q1, q3 variables are not in class= */
   %let i=1; %let statcont=%upcase(&offset &median &q1 &q3 &freq &weight);
   %do %while (%scan(&statcont,&i) ne %str() );
     %let v=%scan(&statcont,&i);
     %if &v in &class %then %do;     
        %put ERROR: Variable &v in FREQ=, WEIGHT=, OFFSET=, MEDIAN=, Q1=,;
        %put ERROR- or Q3= should not be specified in CLASS=.;
        %goto exit;
     %end;
     %let i=%eval(&i+1);
   %end;
%end;
%else %do;
  %let margcont=&margins;
  %let meancont=&mean;
  %let atcont=&at;
  %let allcont=&modelvars;
  %if &geesubvars ne or &geewvars ne or &balanced ne %then %do;
     %put ERROR: BALANCED=, GEESUBJECT=, and GEEWITHIN= variables;
     %put ERROR- must be specified in CLASS=.;
     %goto exit;
  %end;
%end;

/* margins=, at=, effect=, balanced=, statistic option variables 
/  must be in model=. */    
%let chkinmod=%upcase(&margins &at &effect &balanced &mean &median &q1 &q3);
%let j=1; 
%do %while (%scan(&chkinmod,&j) ne %str() );
  %let v=%scan(&chkinmod,&j);
  %if not(&v in &modelvars) %then %do;
    %put ERROR: Variable &v not specified in MODEL=.;
    %goto exit;
  %end;
  %let j=%eval(&j+1);  
%end;


/*  Set distribution and link function defaults. Check specified link.
/---------------------------------------------------------------------*/
%let link=%upcase(%quote(&link));
%let vallinks=LOG LOGIT PROBIT CLL IDENTITY POWER;
%if &dist= %then %let dist=NORMAL;
%let dist=%upcase(&dist);
%let valdist=BINOMIAL POISSON NEGBIN NORMAL IGAUSSIAN GAMMA GEOMETRIC TWEEDIE;
%let chk=%eval(&dist in &valdist);
%if not &chk %then %do;
  %put ERROR: Valid DIST= values are: &valdist..;
  %goto exit;
%end;
%if %quote(&link)= %then %do;
  %if &dist=BINOMIAL        %then %let link=LOGIT;
  %else %if &dist=POISSON   %then %let link=LOG;
  %else %if &dist=NEGBIN    %then %let link=LOG;
  %else %if &dist=NORMAL    %then %let link=IDENTITY;
  %else %if &dist=IGAUSSIAN %then %let link=%quote(POWER(-2));
  %else %if &dist=GAMMA     %then %let link=%quote(POWER(-1));
  %else %if &dist=GEOMETRIC %then %let link=LOG;
  %else %if &dist=TWEEDIE   %then %let link=LOG;
%end;
%let linktype=%sysfunc(scan(&link,1,'()'));
%let chk=%eval(&linktype in &vallinks);
%if not &chk %then %do;
    %put ERROR: Valid LINK= values are: &vallinks..; 
    %goto exit;
%end;


/* Expand CLASS variables into dummy variables 
/  Delete any observations that cannot be used due to missings
/---------------------------------------------------------------------*/
data _data; set &data nobs=_in;
  %if &freq ne %then &freq=int(&freq);;
  call symput('nin',cats(_in));
  %if %quote(&within) ne %then %do;
    _within = (%str(&within));
  %end;
  run;
%if &syserr>1000 %then %goto exit; 
proc glmselect data=_data outdesign=_expdata namelen=200;
  %if &class ne %then class &class;;
  model &response = &model / selection=none;
  output out=_glmsout(keep=_p) p=_p;
  run;
data _expdata; 
  merge _expdata _glmsout;
  if _p ne .;
  drop _p;
  run;
data _data; 
  merge &data _glmsout;
  if _p ne .;
  drop _p;
  run;
%let modelDum = %upcase(&_glsmod);
%let modelDumInt = &modelDum;
%if &int %then %let modelDumInt = INTERCEPT &modelDum;
%let nmodeffs=%sysfunc(countw(&modelDumInt, ' '));
%let chk=&freq &weight &offset &geesubvars &geewvars;
%if &chk ne %then %do;
  data _expdata;
    merge _expdata _data(keep=&freq &weight &offset &geesubvars &geewvars);
    run;
%end;


/* Produce table of numbers of observations, frequencies, weights read
/  and used.
/---------------------------------------------------------------------*/
%if &freq ne or &weight ne %then %do;
   proc sql noprint;
     %if &freq ne %then %do;
       select sum(&freq) into :nfin from &data;
       select sum(&freq) into :nfout from _data;
     %end;
     %if &weight ne %then %do;
       select sum(&weight) into :nwin from &data;
       select sum(&weight) into :nwout from _data;
     %end;
     quit;
%end;
data _nobs; set _data nobs=_nout;
  v="Number of Observations Read"; Value=&nin; output;
  v="Number of Observations Used"; Value=_nout; output;
  %if &freq ne %then %do;
     v="Sum of Frequencies Used"; Value=&nfin; output;
     v="Sum of Frequencies Read"; Value=&nfout; output;
  %end;
  %if &weight ne %then %do;
     v="Sum of Weights Used"; Value=&nwin; output;
     v="Sum of Weights Read"; Value=&nwout; output;
  %end;
  label v='00'x;
  keep v value;
  stop;
  run;


/*  Fit the model and store the fit.
/---------------------------------------------------------------------*/
%if &fit and &print %then ods select all;;
proc genmod data=_expdata namelen=200
   %if &desc %then descending;
   ;
   %if &geesubvars ne %then %str(class &geesubvars &geewvars;);
   model &response 
         %if &roptions ne %then (%str(&roptions));
         = &modelDum
         / &modelopts dist=&dist 
     %if &singular ne %then singular=&singular;
     %if %quote(&link) ne %then link=&link;
     %if &offset ne %then offset=&offset;
   ;
   %if &geesubvars ne %then %do;
     repeated subject=&geesubject / 
     %if %quote(&geecorr) ne %then type=&geecorr;
     %if %quote(&geewithin) ne %then within=&geewithin;
     ;
   %end;
   %if &freq ne %then freq &freq;;
   %if &weight ne %then weight &weight;;
   store _Fit;
   %if &effect ne %then %do;
     %if %quote(&geesubject)= %then 
         %str( ods output parameterestimates = _pe; );
     %else %str( ods output GEEEmpPest = _pe; );
   %end;
   run;
%if &syserr %then %do;
   %let status=genfail;
   %goto exit;
%end;
%if %index(%upcase(&version),DEBUG)=0 %then ods exclude all;;
%if &effect ne %then %do;
   proc transpose data=_pe out=_pet(drop=_name_) prefix=b_; 
     var estimate; 
     id  %if %quote(&geesubject)= %then parameter;
         %else parm;
     ; 
     run;
   %let beffect=B_&effect;
%end;


/* Create data set of margins to estimate 
/---------------------------------------------------------------------*/
%if &margins ne %then %do;
   %let margtabl = %sysfunc(translate(&margins,"*"," "));
   proc freq data=
     %if &margindata ne %then &margindata;
     %else _data;
     order=formatted;
     %if %quote(&margwhere) ne %then where %str(&margwhere);;
     table &margtabl / out=_mlevels(drop=count percent);
     run;
   %if &syserr>0 %then %do;
      %put ERROR: Some MARGINS= variables not found in DATA= or;
      %put ERROR- MARGINDATA= data set.;
      %goto exit;
   %end;
   %let dsid=%sysfunc(open(_mlevels));
   %let nmlev=%sysfunc(attrn(&dsid,nobs));
   %let rc=%sysfunc(close(&dsid));
   %if &nmlev=0 %then %do;
     %put ERROR: No observations found for MARGINS= variables.;
     %goto exit;
   %end;
   data _mlevels; set _mlevels;
     _mlevel = _n_;
     run;
%end;
 

/* Create data set of all combinations of at variables
/---------------------------------------------------------------------*/
%if &at ne %then %do;
   %let attabl = %sysfunc(translate(&at,"*"," "));
   proc freq data=
     %if &atdata ne %then &atdata;
     %else _data;
     order=formatted;
     %if %quote(&atwhere) ne %then where %str(&atwhere);;
     table &attabl / out=_atdata(drop=count percent);
     run;
   %if &syserr>0 %then %do;
      %put ERROR: Some AT= variables not found in DATA= or ATDATA= data set.;
      %goto exit;
   %end;
   %let dsid=%sysfunc(open(_atdata));
   %let nat=%sysfunc(attrn(&dsid,nobs));
   %let rc=%sysfunc(close(&dsid));
   %if &nat=0 %then %do;
     %put ERROR: No observations found for AT= variables.;
     %goto exit;
   %end;
   data _atdata; set _atdata;
     _atlevel = _n_;
     run;
%end;

/* Create data set of all combinations of margins and at variables
/---------------------------------------------------------------------*/
%if &margins ne and &at ne %then %do;
   proc sql;
     create table _margat as
     select * from _mlevels, _atdata;
     quit;
   proc sort data=_margat; 
     by _atlevel _mlevel;
     run;
   data _margat;
     set _margat nobs=_nobs;
     call symput("nfix",cats(_nobs));
     _mlevel=_n_;
     run;
%end;
%else %if &margins ne and &at= %then %do;
   data _margat; 
     set _mlevels nobs=_nobs;
     call symput("nfix",cats(_nobs)); 
     _atlevel = 1;
     run;
%end;
%else %if &margins= and &at ne %then %do;
   data _margat; 
     set _atdata nobs=_nobs;
     call symput("nfix",cats(_nobs)); 
     _mlevel = 1;
     run;
%end;
%else %do;
   data _margat; 
     _mlevel = 1;
     _atlevel = 1;
     run;
   %let nfix=0;
   %if &margins ne %then %do;
     %put ERROR: No values found for MARGINS= variables.;
     %goto exit;
   %end;
%end;


/* Process CLASS variables to:
/  o Create sublists of CLASS variable types
/  o Expand any CLASS variables and create EFFECT statements
/---------------------------------------------------------------------*/
%let balDum=; %let meanclassDum=; %let nofixclas=; 
%let nma=0; %let nmb=0;
%let mchk=_null_ &margins;

%let j=1; 
%do %while (%scan(&class,&j) ne %str() );
  %let v=%scan(&class,&j);
  %let mavar=0; %let balvar=0; %let mnvar=0; %let inlist=0;
  %if &v in &mchk %then %do;
    %let inlist=%eval(&inlist+1);
    %let mavar=1;
  %end;
  %else %do;
     %if &balanced ne %then %if &v in &balanced %then %do;
       %let balDum=&balDum &v._:;
       %let inlist=%eval(&inlist+1);
       %let balvar=1;
     %end;
     %if &mean ne %then %if &v in &mean %then %do;
       %let meanclassDum=&meanclassDum &v._:;
       %let inlist=%eval(&inlist+1);
       %let mnvar=1;
     %end;
     %if &at ne %then %if &v in &at %then %do;
       %let inlist=%eval(&inlist+1);
       %let mavar=1;
     %end;
  %end;
  %if &inlist=0 %then %let nofixclas=&nofixclas &v;
  %else %if &inlist>1 %then %do;
    %put ERROR: Class variable &v can appear in only one of;
    %put ERROR- MARGINS=, AT=, &MEAN=, or &BALANCED=.;
    %goto exit;
  %end;
  %let geechk=_null_ &gee;
  %if not(&v in &modelvars) and not(&v in &geechk) %then %do;
    %put ERROR: Class variable &v not specified in MODEL=.;
    %goto exit;
  %end;

   /* Expand Margin= or At= CLASS variable and create EFFECT statement 
   /---------------------------------------------------------------------*/
   %if &mavar %then %do;
      %let nma=%eval(&nma+1);
      proc freq data=_data order=formatted;
         table &v / out=_levs(drop=count);
         run;
      proc transpose data=_levs prefix=e_&v._ out=_atlv(keep=e_&v._:);
         var &v;
         run;
      proc glmselect data=_levs 
           outdesign(addinputvars)=_od(drop=intercept percent) namelen=200;
         class &v;
         model percent = &v / selection=none;
         run;
      proc sql; 
         create table _fixma&nma as   
         select dum.*, f._mlevel, f._atlevel
         from _margat f,_od dum 
         where f.&v = dum.&v 
         order by _atlevel, _mlevel;
         quit;
      data _fixma&nma; 
         set _fixma&nma(drop=&v); 
         if _n_=1 then set _atlv; 
         run;
      %let eff&j = effect &v = mm(e_&v._: / weight=(&v._:))%str(;);
   %end;

   /* Expand mean= or balanced= CLASS variable and create EFFECT statement 
   /---------------------------------------------------------------------*/
   %else %if &mnvar or &balvar %then %do;
      %let nmb=%eval(&nmb+1);
      proc freq data=_data order=formatted;
         table &v / out=_levs;
         run;
      proc transpose data=_levs prefix=e_&v._ out=_atlv(keep=e_&v._:);
         var &v;
         run;
      proc glmselect data=_data 
           outdesign=_od(drop=intercept &response) namelen=200;
         class &v;
         model &response = &v / selection=none;
         run;
      %if &mnvar %then %do;
         proc summary data=_od;
            var &v._:;
            output out=_atstat(keep=&v._:) mean=;
            run;
      %end;
      %else %if &balvar %then %do;
         data _atstat; 
           set _od;
           array t (*) &v._:;
           do i=1 to dim(t);
             t(i)=1/dim(t);
           end;
           keep &v._:;
           output; stop;
           run;
      %end;
      data _fixmb&nmb;
        merge _atstat _atlv;
        run;
      %let eff&j = effect &v = mm(e_&v._: / weight=(&v._:))%str(;);
   %end;
   
   /* Create EFFECT statement for non-fixed CLASS variable 
   /---------------------------------------------------------------------*/
   %else %do;
     %let eff&j=effect &v = mm(e_&v)%str(;); 
   %end;

  /* Process next CLASS variable */
  %let j=%eval(&j+1);  
%end;
%let nclas=%eval(&j-1);


/* Get requested summary statistics for all continuous variables
/---------------------------------------------------------------------*/
%if &meancont ne or &median ne or &q1 ne or &q3 ne %then %do;
   proc summary data=_data;
     var &meancont &median &q1 &q3;
     %if &freq ne %then freq &freq;;
     %if &weight ne %then weight &weight;;
     output out=_atstats(drop=_type_ _freq_) 
       %if &meancont ne %then mean(&meancont)=;
       %if &median ne %then median(&median)=;
       %if &q1 ne %then q1(&q1)=;
       %if &q3 ne %then q3(&q3)=;
     ;
     run;
%end;


/* Create data set of all fixed variables (margins, atdata, statistics)
/---------------------------------------------------------------------*/
%if &margcont ne or &atcont ne %then %do;
   data _margatcont;
      set _margat;
      keep _mlevel _atlevel &margcont &atcont;
      run;
%end;


/* Create a replicate of the data for each fixed setting
/---------------------------------------------------------------------*/
data _fixed;
   %if &nfix=0 %then set _margat;;
      merge  
        %if &margcont ne or &atcont ne %then _margatcont;
        %do i=1 %to &nma; _fixma&i %end;
      ;
   if _n_=1 then do;
     %do i=1 %to &nmb; set _fixmb&i; %end;
     %if &meancont ne or &median ne or &q1 ne or &q3 ne %then set _atstats;;
   end;
   run;
%if &nfix=0 %then %let nfix = 1;

proc datasets nolist nowarn;
  delete _Pop;
  run; quit;
%do i=1 %to &nfix;
   data _fixoneobs;
     _ptobs=&i;
     set _fixed point=_ptobs;
     output; stop;
     run;
   data _moddat;
     set _data(drop=&margins &at &balanced &mean &median &q1 &q3);
     if _n_=1 then set _fixoneobs;
     %let j=1; 
     %do %while (%scan(&nofixclas,&j) ne %str() );
        %let v=%scan(&nofixclas,&j);
        %let dsid=%sysfunc(open(_data));
        %if &dsid %then %do;
           %let fmt=%sysfunc(varfmt(&dsid,%sysfunc(varnum(&dsid, &v))));
           %let rc=%sysfunc(close(&dsid));
        %end;
        %if &fmt ne %then e_&v = put(&v,&fmt)%str(;);
        %else e_&v = &v%str(;);
        %let j=%eval(&j+1);  
     %end;
     %if &nofixclas ne %then drop &nofixclas;;
     run;
   proc glmselect data=_moddat 
        outdesign(addinputvars)=_fixrep(drop=&response) namelen=200;
     %if &class ne %then class e_: / split;;
     %do e=1 %to &nclas; &&eff&e %end;
     model &response = &model / selection=none;
     run;
   %if &effect ne and &nofixclas ne %then %do;
      proc glmselect data=_data outdesign=_od(drop=&response) namelen=200;
        class &nofixclas;
        model &response = &nofixclas / selection=none;
        run;
      data _fixrep; 
        merge _od _fixrep;
        run;
   %end;
   proc append base=_Pop data=_fixrep;
     run;
%end;


/* Get the covariance for beta and both the linear predictor (_eta)
/  and the predicted probability (_mu) for the population data.
/---------------------------------------------------------------------*/
proc plm restore=_Fit;
   show covariance;
   ods output Cov=_Cov;
   score data=_Pop
         %if %quote(&within) ne %then (where=(_within=1));
         out=_Eta(rename=(Predicted=_eta));
   score data=_Pop
         %if %quote(&within) ne %then (where=(_within=1));
         out=_Mu (rename=(Predicted=_mu )) / ilink;
   run;
data _null_; set _mu;
   if _mu=. then do; 
      call symput('status','badlvl'); stop; 
   end; 
   run;
%if &status=badlvl %then %do;
   %put ERROR: Missing predicted values occurred, possibly due to CLASS; 
   %put ERROR- variable values in the ATDATA= data set that do not occur in;
   %put ERROR- the DATA= data set, or predicted values that are infinite.;
   %goto exit;
%end;

/* Get expression for derivative of _eta w.r.t. the effect= variable 
/---------------------------------------------------------------------*/
%if &effect ne %then %do;
   %let i=1; %let deta_dx=;
   %do %while (%quote(%scan(&modelDumInt,&i,' ')) ne %str() );
      %let modeff=%quote(%scan(&modelDumInt,&i,' ')); 
      /* replace _ with * to transform &modelDumInt back into a proper model 
         specification involving the class-expanded variables.
      */
      %let j=1;
      %do %while (%scan(&allcont,&j,' ') ne %str() );
          %let c=%scan(&allcont,&j,' ');
          %let modeff=%sysfunc(tranwrd(&modeff,&c._,&c%quote(*)));
          %let modeff=%sysfunc(tranwrd(&modeff,_&c,%quote(*)&c));
          %let modeff=%sysfunc(tranwrd(&modeff,_&c._,%quote(*)&c%quote(*)));
          %let j=%eval(&j+1);
      %end;
      %let k=1; %let nmatch=0; %let dmodeff=;
      %do %while (%scan(&modeff,&k,'*') ne %str() );
          %let v=%scan(&modeff,&k,'*');
          %if &v=&effect %then %do;
              %let nmatch=%eval(&nmatch+1);
              %if &nmatch=1 %then %let v=b_%sysfunc(translate(&modeff,"_","*"));
          %end;
          %if &k>1 %then %let dmodeff=&dmodeff*&v;
          %else %let dmodeff=&v;
          %let k=%eval(&k+1);
      %end;
      %if &nmatch %then %do; 
          %if %quote(&deta_dx) ne %then %let deta_dx=&deta_dx +;
          %if &nmatch>1 %then %let deta_dx=&deta_dx &nmatch*&dmodeff;
          %else %let deta_dx=&deta_dx &dmodeff;
      %end;
      %else %do;
          %if %quote(&deta_dx) ne %then %let deta_dx=&deta_dx +;
          %let  deta_dx=&deta_dx 0;
      %end;
      %let i=%eval(&i+1);
   %end;

   /* Create multiplier of dmu_deta forming the per parameter contributions 
      to the Jacobian. Clean it up by removing unneeded characters.
   */
   %let deta_dx2 = %sysfunc(prxchange(s/b_\w+\b/1/, -1, &deta_dx));
   %let deta_dx2 = %sysfunc(prxchange(s/1\*//, -1, &deta_dx2));
   %let deta_dx2 = %sysfunc(prxchange(s/\*1//, -1, &deta_dx2));
   %let deta_dx2 = %sysfunc(prxchange(s/\+ //, -1, &deta_dx2));

   /* Clean up deta_dx by removing most additions of zero */
   %let deta_dx = %sysfunc(prxchange(s/\+ 0//, -1, &deta_dx));
%end;

/* Compute the derivatives of the mean with respect to the linear predictor
/---------------------------------------------------------------------------*/
data _Eta; 
   set _Eta;
   %if &effect ne %then 
     if _n_=1 then set _pet;
   ;

   %if &linktype=LOGIT %then %do;
      dmu_dEta = exp(_eta)/((1+exp(_eta))**2);
      _ddm = (exp(_eta)-1)/(1+exp(_eta)); 
   %end;
   %else %if &linktype=PROBIT %then %do;
      dmu_dEta = pdf('normal',_eta);       
      _ddm = _eta;
   %end;
   %else %if &linktype=LOG %then %do;
      dmu_dEta = exp(_eta);
      _ddm = 1;
   %end;
   %else %if &linktype=CLL %then %do;
      dmu_dEta = exp(_eta-exp(_eta));
      _ddm = (1-exp(_eta));
   %end;
   %else %if &linktype=IDENTITY %then %do;
      dmu_dEta = 1;
      _ddm = 0;
   %end;
   %else %if &linktype=POWER %then %do;
      %let power=%quote(%sysfunc(scan(&link,2,'()')));
      %if &power=0 %then %do;
          dmu_dEta = exp(_eta);
          _ddm = 1;
      %end;
      %else %do;
          dmu_dEta = (1/&power)*_eta**(1/&power - 1);
          _ddm = (1-&power)/(_eta*&power);
      %end;
   %end;

   %if &effect ne %then %do;
      /* Marginal effect */
      _meff = dmu_dEta * (&deta_dx); 

      /* Jacobian contributions for variance of marginal effect */
      %do i=1 %to &nmodeffs;
          _mult&i = %scan(&deta_dx2,&i,' ');
      %end;
      array _mult (&nmodeffs);
      array _md (*) &modelDumInt;
      array _j (&nmodeffs);
      do _i=1 to dim(_md);
         _j(_i) = dmu_dEta*(_mult(_i) - _md(_i)*(&deta_dx)*_ddm);
      end;
   %end;
   run;

data _X;
   merge _Pop 
         %if %quote(&within) ne %then (where=(_within=1));
         _Eta(keep=_eta dmu_dEta  %if &effect ne %then _meff _j:; ) 
         _Mu(keep=_mu);
   run;
%let empty=0;
proc contents data=_X; 
   ods output attributes=_Xnobs(where=(label2="Observations")); 
   run;
data _null_; 
   set _Xnobs; 
   if nvalue2=0 then call symput('empty',1); 
   run;
%if &empty %then %do;
   %put ERROR: Replicates data set, _X, is empty. No data to analyze.;
   %goto exit;
%end;


/* The predicted margins are just the average predictions for each
/  fixed setting over the population data.
/---------------------------------------------------------------------*/
proc summary data=_X nway;
   %if &freq ne %then freq &freq;;
   %if &weight ne %then weight &weight;;
   class _atlevel _mlevel; 
   var _mu 
       %if &effect ne %then _meff _j:; 
   ;
   output out=_marg(drop=_type_ _freq_) mean=;
   run;
proc sort data=_margat;
   by _atlevel _mlevel;
   run;
data _parmest; 
   merge _marg _margat;
   by _atlevel _mlevel;
   keep _mu 
         %if &effect ne %then _meff; 
        _mlevel &margins _atlevel &at;
   run;

%if &contrasts ne %then %do;
   %let compat=1;
   data _ctstlabl;
      set &contrasts nobs=nct end=eof;
      call symput(cats("c",_n_),cats(f));
      _nrow=countw(f,',');
      do _i=1 to _nrow;
         _ctst=scan(f,_i,',');
         if countw(_ctst, ' ') ne &nfix then call symput('compat','0');
      end;
      do _i=2 to 3+count(f,','); 
         keep label; output; 
      end;
      if eof then call symput("nct",cats(nct));
      run;
   %if &compat=0 %then %do;
      %put ERROR: There must be &nfix contrast coefficients to multiply the;
      %put ERROR- &nfix margins or marginal effects.;
      %goto exit;
   %end;
%end;

/* The Jacobian, the derivative of the predicted margin with respect
/  to the linear parameters, is the sum of the rows of X for each
/  &margins level, weighted by the derivative of the predicted probability
/  with respect to the linear predictor, over the population data.
/  Need to divide this value by N to make it pertain to the average
/  predictions. The covariance of the predicted margins can be computed
/  using just the Jacobian and the covariance of the linear parameters.
/---------------------------------------------------------------------*/
proc iml;
   %if &margins ne or (&margins= and &effect=) %then %do;
      use _X;
        read all var {&modelDumInt} into X;
        read all var {dmu_dEta _mlevel _atlevel};
        _f=shape(1,nrow(X),1);
        %if &freq ne %then %do;
          read all var { &freq } into _f;
        %end;
      close _X;
      %if &margins= and &at ne %then %str(G = design(_atlevel);) ;
      %else %str(G = design(_mlevel);) ;
      J = shape(0,ncol(G),ncol(X));
      do i = 1 to nrow(X);
         J[loc(G[i,]),] = J[loc(G[i,]),] + _f[i]*dmu_dEta[i]*X[i,];
      end;
      J = J / (_f[+,]/ncol(G));
      use _Cov(keep=Col:); 
        read all into Cov;
      close _Cov;
      CovPred = J*Cov*J`;
      StdErr = sqrt(vecdiag(CovPred));
      cname = "Col1":"Col"+strip(char(nrow(CovPred)));
      create _CovMarg from CovPred[colname=cname];
        append from CovPred; 
        close _CovMarg; 
      create _SEMarg from StdErr[colname="StdErr"];
        append from Stderr;
        close _SEMarg;
   %end;

   %if &effect ne %then %do;
      use _marg(keep=_j:);
        read all into J;
        close _marg;
      use _Cov(keep=Col:); 
        read all into Cov;
        close _Cov;
      CovME = J*Cov*J`;
      StdErr = sqrt(vecdiag(CovME));
      cname = "Col1":"Col"+strip(char(nrow(CovME)));
      create _CovMeff from CovME[colname=cname];
        append from CovME; 
        close _CovMeff; 
      create _SEMeff from StdErr[colname="StdErr"];
        append from Stderr;
        close _SEMeff;
   %end;
  
   %if &contrasts ne %then %do;
      use _marg; 
      read all var {_mlevel};
      %if &margins ne or (&margins= and &effect=) %then %do;
         read all var {_mu};
         ctabl = {};
         do i = 1 to &nct;
            makeL="L = { " + cats('&c',i) + "};";
            call execute(makeL);
            df = round(trace(ginv(L)*L));
            C = L*_mu;
            CovC = L*CovPred*L`;
            ChiSq = C`*ginv(CovC)*C;
            Pr = 1-probchi(ChiSq,df);
            Contrast = i; Row = .; Estimate = .; 
            StdErr = .; Lower = .; Upper = .;
            ctabl = ctabl//
                    (Contrast||Row||Estimate||StdErr||ChiSq||df||Pr||
                    Lower||Upper);
            do j=1 to nrow(L);
               Row = j;
               C = L[j,]*_mu; Estimate = C;
               StdErr = sqrt(L[j,]*CovPred*L[j,]`);
               ChiSq = (Estimate / StdErr)##2;
               df = round(trace(ginv(L[j,])*L[j,]));
               Pr = 1-probchi(ChiSq,df);
               Lower = Estimate-probit(1-&alpha/2)*StdErr; 
               Upper = Estimate+probit(1-&alpha/2)*StdErr;
               ctabl = ctabl//
                       (Contrast||Row||Estimate||StdErr||ChiSq||df||Pr||
                       Lower||Upper);
            end;
         end;
         cname = {"Contrast" "Row" "Estimate" "StdErr" "ChiSq" 
                 "DF" "Pr" "Lower" "Upper"};
         create _Contrasts from ctabl[colname=cname];
            append from ctabl; 
            close _Contrasts;
      %end;
      %if &effect ne %then %do;
         use _marg; 
         read all var {_meff};
         ctabl = {};
         do i = 1 to &nct;
            makeL="L = { " + cats('&c',i) + "};";
            call execute(makeL);
            df = round(trace(ginv(L)*L));
            C = L*_meff;
            ChiSq = .;
            CovC = L*CovME*L`;
            ChiSq = C`*ginv(CovC)*C;
            Pr = 1-probchi(ChiSq,df);
            Contrast = i; Row = .; Estimate = .; 
            StdErr = .; Lower = .; Upper = .;
            ctabl = ctabl//
                    (Contrast||Row||Estimate||StdErr||ChiSq||df||Pr||
                    Lower||Upper);
            do j=1 to nrow(L);
               Row = j;
               C = L[j,]*_meff; Estimate = C;
               StdErr = sqrt(L[j,]*CovME*L[j,]`);
               ChiSq = (Estimate / StdErr)##2;
               df = round(trace(ginv(L[j,])*L[j,]));
               Pr = 1-probchi(ChiSq,df);
               Lower = Estimate-probit(1-&alpha/2)*StdErr; 
               Upper = Estimate+probit(1-&alpha/2)*StdErr;
               ctabl = ctabl//
                       (Contrast||Row||Estimate||StdErr||ChiSq||df||Pr||
                       Lower||Upper);
            end;
         end;
         cname = {"Contrast" "Row" "Estimate" "StdErr" "ChiSq" 
                 "DF" "Pr" "Lower" "Upper"};
         create _ContrastME from ctabl[colname=cname];
            append from ctabl; 
            close _ContrastME;
      %end;
      close _marg;
   %end;

   %if &diff %then %do;
      use _marg; 
      read all var {_mlevel _atlevel};
      %if &margins ne or (&margins= and &effect=) %then %do;
         read all var {_mu};
         difftab = {};
         do h = 1 to _atlevel[<>,];
            hloc=loc(_atlevel=h); 
            MarginSub=_mu[hloc]; _mlevelSub=_mlevel[hloc]; 
            CovPredSub=CovPred[hloc,hloc];
            do i = 1 to nrow(MarginSub)-1;
               Index1 = _mlevelSub[i];
               do j = i+1 to nrow(MarginSub);
                  Index2 = _mlevelSub[j];
                  L = ((1:nrow(_mlevelSub))=i) - ((1:nrow(_mlevelSub))=j);
                  Diff = %if &rdiff %then %str(-);L*MarginSub;
                  CovDiff = L*CovPredSub*L`;
                  StdErrDiff = sqrt(CovDiff);
                  ChiSq = (Diff / StdErrDiff)##2;
                  Pr = 1-probchi(ChiSq,1);
                  Lower = Diff-probit(1-&alpha/2)*StdErrDiff;
                  Upper = Diff+probit(1-&alpha/2)*StdErrDiff;
                  difftab = difftab // 
                            (h||Index1||Index2||Diff||StdErrDiff||
                             ChiSq||Pr||Lower||Upper);
               end;
            end;
         end;
         if nrow(difftab)>0 then do;
            cname = {"_atlevel" "Index1" "Index2" "Diff" "StdErrDiff" 
                     "ChiSq" "Pr" "Lower" "Upper"};
            create _Diffs from difftab[colname=cname];
               append from difftab; 
               close _Diffs;
         end;
         else call symput('diffPM','0');
      %end;
      %if &effect ne %then %do;
         use _marg; 
         read all var {_meff};
         difftab = {};
         do h = 1 to _atlevel[<>,];
            hloc=loc(_atlevel=h); 
            MeffSub=_meff[hloc]; _mlevelSub=_mlevel[hloc]; 
            CovMESub=CovME[hloc,hloc];;
            do i = 1 to nrow(MeffSub)-1;
               Index1 = _mlevelSub[i];
               do j = i+1 to nrow(MeffSub);
                  Index2 = _mlevelSub[j];
                  L = ((1:nrow(_mlevelSub))=i) - ((1:nrow(_mlevelSub))=j);
                  Diff = %if &rdiff %then %str(-);L*MeffSub;
                  StdErrDiff = .;
                  CovDiff = L*CovMESub*L`;
                  StdErrDiff = sqrt(CovDiff);
                  ChiSq = (Diff / StdErrDiff)##2;
                  Pr = 1-probchi(ChiSq,1);
                  Lower = Diff-probit(1-&alpha/2)*StdErrDiff;
                  Upper = Diff+probit(1-&alpha/2)*StdErrDiff;
                  difftab = difftab // 
                            (h||Index1||Index2||Diff||StdErrDiff||
                             ChiSq||Pr||Lower||Upper);
               end;
            end;
         end;
         if nrow(difftab)>0 then do;
            cname = {"_atlevel" "Index1" "Index2" "Diff" "StdErrDiff" 
                     "ChiSq" "Pr" "Lower" "Upper"};
            create _DiffME from difftab[colname=cname];
               append from difftab; 
               close _DiffME;
         end;
         else call symput('diffME','0');
      %end;
   %end;
   %else %do;
      call symput('diffPM','0');
      call symput('diffME','0');
   %end;
   quit;
   
/*  Create: 
/   o data set of estimates with tests and confidence limits
/   o data set of differences with tests and confidence limits
/   o data set of contrasts with tests
/---------------------------------------------------------------------*/
%if &margins ne or (&margins= and &effect=) %then %do;
   data _Margins;
      merge _parmest _SEMarg;
      Estimate = _mu;
      ChiSq = (Estimate/StdErr)**2;
      Pr = 1-probchi(ChiSq,1);
      %if &cl %then %do;
        Alpha = &alpha;
        Lower = Estimate-probit(1-&alpha/2)*StdErr;
        Upper = Estimate+probit(1-&alpha/2)*StdErr;
      %end;
      format Pr pvalue6.;
      label ChiSq = "Wald Chi-Square" Pr = "Pr > ChiSq"
            StdErr = "Standard Error" _mlevel = "Index";
      run;
%end;
%if &effect ne %then %do;
   data _MEffect;
      merge _parmest _SEMeff%str(;);
      Estimate = _meff;
      ChiSq = (Estimate/StdErr)**2;
      Pr = 1-probchi(ChiSq,1);
      %if &cl %then %do;
        Alpha = &alpha;
        Lower = Estimate-probit(1-&alpha/2)*StdErr;
        Upper = Estimate+probit(1-&alpha/2)*StdErr;
      %end;
      format Pr pvalue6.;
      label ChiSq = "Wald Chi-Square" Pr = "Pr > ChiSq"
            StdErr = "Standard Error" _mlevel = "Index";
      run;
%end;
%if &diff %then %do;
   %if &diffPM and &margins ne %then %do;
      data _Diffs; 
         %if &at ne %then %do;
            merge _Diffs _atdata; by _atlevel;
         %end;
         %else set _Diffs;;
         length Comp $9;
         Comp = 
            %if &rdiff %then translate(cats(Index2,"#-#",Index1)," ","#");
            %else            translate(cats(Index1,"#-#",Index2)," ","#");
            ;
         Alpha = &alpha;
         format Pr pvalue6.;
         label Diff = "Estimate" StdErrDiff = "Standard Error" 
            ChiSq = "Wald Chi-Square" Pr = "Pr > ChiSq" Comp="Difference";
         drop Index:;
         run;
   %end;
   %if &diffME and &effect ne %then %do;
      data _DiffME; 
         %if &margins ne and &at ne %then %do;
            merge _DiffME _atdata; by _atlevel;
         %end;
         %else set _DiffME;;
         length Comp $9;
         Comp = 
            %if &rdiff %then translate(cats(Index2,"#-#",Index1)," ","#");
            %else            translate(cats(Index1,"#-#",Index2)," ","#");
            ;
         Alpha = &alpha;
         format Pr pvalue6.;
         label Diff = "Estimate" StdErrDiff = "Standard Error" 
            ChiSq = "Wald Chi-Square" Pr = "Pr > ChiSq" Comp="Difference";
         drop Index:;
         run;
   %end;
%end;
%if &contrasts ne %then %do; 
   %if &margins ne or (&margins= and &effect=) %then %do;
      data _Contrasts; 
         merge _ctstlabl _Contrasts;
         Alpha = &alpha;
         format Pr pvalue6.;
         label label="Contrast" StdErr = "Standard Error" 
               ChiSq = "Wald Chi-Square" Pr = "Pr > ChiSq";
         run;
   %end;
   %if &effect ne %then %do;
      data _ContrastME; 
         merge _ctstlabl _ContrastME;
         Alpha = &alpha;
         format Pr pvalue6.;
         label label="Contrast" StdErr = "Standard Error"
               ChiSq = "Wald Chi-Square" Pr = "Pr > ChiSq";
         run;
   %end;
%end;

/*  Display: 
/   o table of numbers of observations read and used
/   o table of requested fixed statistics
/   o data set of estimates with tests and confidence limits
/   o data set of differences with tests and confidence limits
/   o data set of contrasts with tests
/---------------------------------------------------------------------*/
%if &print %then %do;
   ods select all;
   
   /* Display number of observations read, used */
   proc print data=_nobs label;
     id v;
     title "The &sysmacroname Macro";
     run;
     
   /* Display requested statistics for fixed variables */
   %let allstats=&balDum &meanclassDum &meancont &median &q1 &q3;
   %if &allstats ne %then %do;
      proc transpose data=_fixed(keep=&allstats) 
           out=_fixstat(keep=_name_ col1 rename=(_name_=Variable col1=Value));
         run;
      proc print data=_fixstat;
         id Variable;
         title "Variables Fixed At Requested Statistics";
         run;
   %end;
   
   /* Display predicted margins */
   %if &margins ne or (&margins= and &effect=) %then %do;
      proc print data=_Margins label;
         %if &at ne and &pbyat %then by &at notsorted;;
         id %if &diffPM %then _mlevel;
            &margins 
            %if &at ne and not &pbyat %then &at;;
         var Estimate StdErr 
             %if &cl %then Alpha Lower Upper;
             ChiSq Pr;
         %if &margins= %then %str(title "Overall Predictive Margins";) ;
         %else %str(title "&margins Predictive Margins";) ;
         %if %quote(&within) ne %then %do;
           title2 "Within: &within";
         %end;
         run;

      /* Display differences of predicted margins */   
      %if &diffPM %then %do;
         proc print data=_Diffs label;
            %if &at ne and &pbyat %then by &at notsorted;;
            id Comp;
            var Diff StdErrDiff  
                %if &cl %then Alpha Lower Upper;
                ChiSq Pr;
            title "Differences Of &margins Margins";
            %if %quote(&within) ne %then %do;
              title2 "Within: &within";
            %end;
            run;
      %end;

      /* Display contrasts of predicted margins */
      %if &contrasts ne %then %do; 
         proc print data=_Contrasts label;
            id label;
            var Row Estimate StdErr 
                %if &cl %then Alpha Lower Upper;
                ChiSq df Pr;
            title "Contrasts Of &margins Margins";
            %if %quote(&within) ne %then %do;
              title2 "Within: &within";
            %end;
            run;
      %end;
   %end;
   
   /* Display marginal effects */
   %if &effect ne %then %do;
      proc print data=_MEffect label noobs;
         %if &margins ne %then %do;
             id %if &diffME %then _mlevel;
                &margins;
         %end;
         %if &at ne %then %do;
            %if &pbyat %then by &at notsorted %str(;);
            %else id &at %str(;);
         %end;
         var Estimate StdErr 
             %if &cl %then Alpha Lower Upper;
             ChiSq Pr;
         title "&effect Average Marginal Effects";
         %if %quote(&within) ne %then %do;
           title2 "Within: &within";
         %end;
         run;

      /* Display differences of marginal effects */   
      %if &diffME %then %do;
         proc print data=_DiffME label;
            %if &margins ne and &at ne and &pbyat %then by &at notsorted;;
            id Comp;
            var Diff StdErrDiff  
                %if &cl %then Alpha Lower Upper;
                ChiSq Pr;
            title "Differences Of &effect Average Marginal Effects";
            %if %quote(&within) ne %then %do;
              title2 "Within: &within";
            %end;
            run;
      %end;

      /* Display contrasts of marginal effects */
      %if &contrasts ne %then %do;
         proc print data=_ContrastME label;
            id label;
            var Row Estimate StdErr 
                %if &cl %then Alpha Lower Upper;
                ChiSq df Pr;
            title "Contrasts Of &effect Average Marginal Effects";
            %if %quote(&within) ne %then %do;
              title2 "Within: &within";
            %end;
            run;
      %end;
   %end;
      
   %if %index(%upcase(&version),DEBUG)=0 %then ods exclude all;;
%end;


/* Clean up.
/---------------------------------------------------------------------*/
%exit:
  %if %index(%upcase(&version),DEBUG)=0 %then %do;  
     proc datasets nolist nowarn;
        delete _expdata _mlevels _atdata _marg _margat: _od _levs _atlv
               _atstat: _fix: _moddat _Pop _Cov _Eta _Mu _X _parmest
               _sem: _nobs _data _pe: _ctstlabl _Xnobs;
        run; quit;
  %end;
  %if %index(%upcase(&version),DEBUG) %then %do;
    options nomprint nomlogic nosymbolgen;
    %put _user_;
  %end;
  title;
  %let status=;
  ods select all;
  options &_opts;
  %let time = %sysfunc(round(%sysevalf(%sysfunc(datetime()) - &time), 0.01));
  %put NOTE: The &sysmacroname macro used &time seconds.;
%mend;

