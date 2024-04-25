*-----------------------------------------------------------------------------------*
|                     Global Academic Programs Workshop                             |
| 				Learning SAS Programming with Help from ChatGPT						|
*-----------------------------------------------------------------------------------*;
options 	orientation=landscape mlogic symbolgen pageno=1 error=3;
title1 		"Global Academic Programs Workshop";
title2 		"Learning SAS Programming with Help from ChatGPT";
footnote 	"File = SAS Programming + ChatGPT";

libname 	HHS "~/HHS_OTJ";


*-----------------------------------------------------------*
|					 Import Data from GitHub				|
*-----------------------------------------------------------*;
/* Specify the URL of the CSV file */
filename git_url url "https://raw.githubusercontent.com/lincolngroves/SAS-OTJ-HHS/main/ACS_2015_2022_ltd.csv";

/* Use PROC IMPORT to read the CSV file */
proc import datafile=git_url
            out=HHS.HHS_OTJ_Raw
            dbms=csv
            replace;
			guessingrows=100000;
run;


*-----------------------------------------------------------*
|						Explore Data Set					|
*-----------------------------------------------------------*;
/* Summarize numeric variables */
proc means data=HHS.HHS_OTJ_Raw maxdec=2;
    var _numeric_; /* Select all numeric variables */
    output out=summary_numeric mean=mean median=median min=min max=max n=n;
run;

/* Summarize non-numeric variables */
proc freq data=HHS.HHS_OTJ_Raw;
    table _character_ / out=summary_non_numeric; /* Select all non-numeric variables */
run;

/* Display the summaries */
proc print data=summary_numeric;
    title "Summary Statistics for Numeric Variables";
run;

proc print data=summary_non_numeric;
    title "Summary Statistics for Non-Numeric Variables";
run;


/* Graphs for numeric variables */
proc univariate data=HHS.HHS_OTJ_Raw;
    var _numeric_; /* Select all numeric variables */
    histogram / normal kernel; /* Histogram and normal density plot */
run;

/* Graphs for non-numeric variables */
proc freq data=HHS.HHS_OTJ_Raw;
    tables _character_ / plots=freqplot; /* Bar charts for non-numeric variables */
run;


*-------------------------------------------------------------------------------------*
|    	   						  Collapse Data 									  | 
|	                    	Produce State-Level Estimates          	          		  |
*-------------------------------------------------------------------------------------*;

********************************************************  By State ;
proc sql;
	create 	table hhs.covid_labor_supply as 
	select	distinct state_fip, state_name, 
            year(yearquarter) as Year format 9.,
			
/*******************************************************************  Labor Force Status | All  */
			sum( ( unemp=1 ) * WTFINL ) 											/ sum( ( in_LF=1 ) *   	WTFINL )									as UE_Women				label="Unemployment Rate"	format percent9.1 		,
			sum( ( in_LF=1 ) * WTFINL ) 											/ sum(  				WTFINL )									as LFP_Women			label="LFP Rate"			format percent9.1 		,


/*******************************************************************  Labor Force Status | By Education  */

			/*******************************************************  Unemployment */
			sum( ( educ_ltd="High School Diploma" ) * ( unemp=1 ) * WTFINL ) 		/ sum( ( educ_ltd="High School Diploma" ) * ( in_LF=1 ) * WTFINL )	as UE_Women_HS			label="EDUC <= HS" 		format percent9.1 		,
			sum( ( educ_ltd="Some College" ) * ( unemp=1 ) * WTFINL ) 				/ sum( ( educ_ltd="Some College" ) * ( in_LF=1 ) * WTFINL ) 		as UE_Women_SCollege	label="Some College"	format percent9.1 		,
			sum( ( educ_ltd="College +" ) * ( unemp=1 ) * WTFINL ) 					/ sum( ( educ_ltd="College +" ) * ( in_LF=1 ) * WTFINL ) 			as UE_Women_CollegeP	label="College +" 		format percent9.1 		,

			/*******************************************************  LFP */
			sum( ( educ_ltd="High School Diploma" ) * ( in_LF=1 ) * WTFINL ) 		/ sum( ( educ_ltd="High School Diploma" ) * WTFINL ) 				as LFP_Women_HS			label="EDUC <= HS" 		format percent9.1 		,
			sum( ( educ_ltd="Some College" ) * ( in_LF=1 ) * WTFINL ) 				/ sum( ( educ_ltd="Some College" ) * WTFINL ) 						as LFP_Women_SCollege	label="Some College" 	format percent9.1 		,
			sum( ( educ_ltd="College +" ) * ( in_LF=1 ) * WTFINL ) 					/ sum( ( educ_ltd="College +" ) * WTFINL ) 							as LFP_Women_CollegeP	label="College +" 		format percent9.1 		,


/*******************************************************************  Labor Force Status | By Child Status  */

			/*******************************************************  Unemployment */
			sum( ( child_status="No Children" ) * ( unemp=1 ) * WTFINL ) 			/ sum( ( child_status="No Children" ) * ( in_LF=1 ) * WTFINL ) 		as UE_Women_NoKids		label="No Children" 	format percent9.1 		,
			sum( ( child_status="Older Children" ) * ( unemp=1 ) * WTFINL ) 		/ sum( ( child_status="Older Children" ) * ( in_LF=1 ) * WTFINL ) 	as UE_Women_OlderKids	label="Older Children" 	format percent9.1 		,
			sum( ( child_status="Child < 5" ) * ( unemp=1 ) * WTFINL ) 				/ sum( ( child_status="Child < 5" ) * ( in_LF=1 ) * WTFINL ) 		as UE_Women_YoungKids	label="Young Children"	format percent9.1 		,

			/*******************************************************  LFP */
			sum( ( child_status="No Children" ) * ( in_LF=1 ) * WTFINL ) 			/ sum( ( child_status="No Children" ) * WTFINL ) 					as LFP_Women_NoKids		label="No Children" 	format percent9.1 		,
			sum( ( child_status="Older Children" ) * ( in_LF=1 ) * WTFINL ) 		/ sum( ( child_status="Older Children" ) * WTFINL ) 				as LFP_Women_OlderKids	label="Older Children" 	format percent9.1 		,
			sum( ( child_status="Child < 5" ) * ( in_LF=1 ) * WTFINL ) 				/ sum( ( child_status="Child < 5" ) * WTFINL ) 						as LFP_Women_YoungKids	label="Young Children"	format percent9.1 		


	from 	hhs.hhs_otj_raw
	group	by 1,2,3 
	order	by 1,2,3 ;
quit;


*-------------------------------------------------------------------------------------*
|		                    Examine State-Level Estimates          	          		  |
*-------------------------------------------------------------------------------------*;
/* Create a summary table */
proc means data=hhs.covid_labor_supply maxdec=2;
    var UE_Women LFP_Women UE_Women_HS UE_Women_SCollege UE_Women_CollegeP LFP_Women_HS LFP_Women_SCollege LFP_Women_CollegeP UE_Women_NoKids UE_Women_OlderKids UE_Women_YoungKids LFP_Women_NoKids LFP_Women_OlderKids LFP_Women_YoungKids;
    title 'Summary of Labor Statistics';
run;


*-------------------------------------------------------------------------------------*
|					            Plots over time by State     	          		  	  |
*-------------------------------------------------------------------------------------*;
/* Create the line plot */
proc sgplot data=hhs.covid_labor_supply;
	by state_name ;
    title 'Unemployment Rates of Women by State Over Time';
    series x=year y=UE_Women / group=state_name ;
    series x=year y=UE_Women_NoKids / group=state_name;
    series x=year y=UE_Women_OlderKids / group=state_name;
    series x=year y=UE_Women_YoungKids / group=state_name;
    xaxis label='Year';
    yaxis label='Unemployment Rate';
    keylegend / location=inside position=bottomright across=1;
run;
