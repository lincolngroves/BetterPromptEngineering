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
filename cps url "https://raw.githubusercontent.com/lincolngroves/SAS-OTJ-HHS/main/CPS_2015_2023_ltd.csv";

proc import datafile=cps
    out=hhs.hhs_otj_raw
    dbms=csv
    replace;
    guessingrows=100000;
run;


*-----------------------------------------------------------*
|						Explore Data Set					|
*-----------------------------------------------------------*;
/* Point to your table */
%let DS = HHS.HHS_OTJ_Raw;

/* 1) Quick inventory of variables (names, types, labels) */
proc contents data=&DS
  out=work._contents(keep=name type length label format varnum)
  noprint;
run;

proc sort data=work._contents; by varnum; run;

title "Variable Inventory: &DS";
proc print data=work._contents label noobs; run;

/* 2) Numeric variables: summary stats + histograms */
title "Numeric Summary: &DS";
proc means data=&DS n nmiss mean std min p25 median p75 max maxdec;
  var _numeric_;
run;

title "Numeric Distributions (Histograms): &DS";
proc univariate data=&DS noprint;
  var _numeric_;
  histogram _numeric_ / normal;
  inset n mean std median min max / position=ne;
run;

/* 3) Character variables: levels + one-way frequencies
      Tip: Change MAXLEVELS=25 if you want more/fewer categories shown */
title "Character Variables: Number of Distinct Levels";
proc freq data=&DS nlevels;
  tables _character_ / noprint;
run;

title "Top Values for Character Variables (includes missing)";
proc freq data=&DS order=freq;
  tables _character_ / missing nocum nopercent /* limit long lists: */ maxlevels=25;
run;

title;


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
/* Step 1: Quick overview of variables */
title "Variable Inventory for HHS.COVID_LABOR_SUPPLY";
proc contents data=HHS.COVID_LABOR_SUPPLY varnum;
run;


/* Step 2: Summary statistics for all numeric variables */
title "Summary Statistics for Key Labor Supply Variables";
proc means data=HHS.COVID_LABOR_SUPPLY n nmiss mean std min max maxdec=2;
  var _numeric_;
run;


/* Step 3: (Optional) Average rates by year, nicely formatted */
title "Average Labor Supply Measures by Year";
proc tabulate data=HHS.COVID_LABOR_SUPPLY format=percent8.1;
  class year;
  var UE_Women LFP_Women 
      UE_Women_HS UE_Women_SCollege UE_Women_CollegeP
      LFP_Women_HS LFP_Women_SCollege LFP_Women_CollegeP
      UE_Women_NoKids UE_Women_OlderKids UE_Women_YoungKids
      LFP_Women_NoKids LFP_Women_OlderKids LFP_Women_YoungKids;
  table year,
        (UE_Women LFP_Women
         UE_Women_HS UE_Women_SCollege UE_Women_CollegeP
         LFP_Women_HS LFP_Women_SCollege LFP_Women_CollegeP
         UE_Women_NoKids UE_Women_OlderKids UE_Women_YoungKids
         LFP_Women_NoKids LFP_Women_OlderKids LFP_Women_YoungKids)*mean=' ';
run;


/* Step 4: Bonus — quick visualization of unemployment trends by year */
title "Average Unemployment Rate by Year (All Women)";
proc sgplot data=HHS.COVID_LABOR_SUPPLY;
  vbar year / response=UE_Women stat=mean datalabel;
  yaxis label="Unemployment Rate" grid;
run;

title;


*-------------------------------------------------------------------------------------*
|					            Plots over time by State     	          		  	  |
*-------------------------------------------------------------------------------------*;
title "Unemployment Rates for Women by State and Year";
proc sort data=HHS.COVID_LABOR_SUPPLY out=work.covid_sorted;
  by state_name year;
run;

proc print data=work.covid_sorted noobs label;
  var state_name year UE_Women UE_Women_NoKids UE_Women_OlderKids UE_Women_YoungKids;
  format UE_Women--UE_Women_YoungKids percent8.1;
run;

/* Small multiples: one panel per state, four lines per panel */
ods graphics on;

proc sgpanel data=HHS.COVID_LABOR_SUPPLY;
  panelby state_name / columns=5 novarname uniscale=column onepanel;
  series x=year y=UE_Women           / legendlabel="All Women";
  series x=year y=UE_Women_NoKids    / legendlabel="No Children"        lineattrs=(pattern=shortdash);
  series x=year y=UE_Women_OlderKids / legendlabel="Older Children"     lineattrs=(pattern=dot);
  series x=year y=UE_Women_YoungKids / legendlabel="Young Children"     lineattrs=(pattern=dashdot);
  colaxis label="Year" integer;
  rowaxis label="Unemployment Rate" valuesformat=percent8.1 grid;
  keylegend / position=bottom across=2;
  title "Unemployment Trends by Child Status — One Panel per State";
run;

ods graphics off;


proc sgplot data=HHS.COVID_LABOR_SUPPLY;
  where state_name in ("California", "Texas", "New York");
  series x=year y=UE_Women / group=state_name lineattrs=(thickness=2);
  yaxis label="Unemployment Rate" grid;
run;


title "Unemployment Rate (All Women) by State and Year";

proc sgplot data=HHS.COVID_LABOR_SUPPLY;
  heatmap x=year y=state_name / 
          colorresponse=UE_Women
          colormodel=(white orange red);
*  colorbar title="Unemployment Rate";
  xaxis discreteorder=data;
  yaxis discreteorder=data;
run;

title;





