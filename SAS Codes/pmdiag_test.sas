%include "/_COURSEWORK/ResMeth/AY_2020_2021/LEE_T/Publication/Full10pcSample_Code/pmdiag.sas" / source2;
%include "/_COURSEWORK/ResMeth/AY_2020_2021/LEE_T/Publication/Full10pcSample_Code/SjSILD_DefFormat.sas" /source2;

%macro pmtests(insas,
			   mpre,
			   stu_g,
			   1,
			   0,
			   age sex2 index_year pat_region2 pay_type prd_type CCIcat RA_pre SLE_pre SSc_pre,
			   weight); 
%macro pmdiag(T.step_8,
			  F.chrt_final,
			  pat_id,
			  ps,
			  stu_g,
			  1,
			  0,
			  /_COURSEWORK/ResMeth/AY_2020_2021/LEE_T/Publication/Report/stddiff_pmdiag,
			  RTF,
			  age sex2 pat_region2 index_year prd_type,
			  age sex2 index_year pat_region2 pay_type prd_type CCIcat RA_pre SLE_pre SSc_pre,
			  1.0,
			  0.7,
			  0.7, 
			  N,
			  weight,
			  matchid);
