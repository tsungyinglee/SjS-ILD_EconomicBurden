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

