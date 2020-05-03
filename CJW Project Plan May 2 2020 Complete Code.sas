/**********************************************************************************
Description:  This program generatees the 2017 estimated National Healtchare Expenses:
	           (1) Respondants by Expenses/No expenses by Age Category
	           (2) 2017 People with a Health Expense
	           (3) Mean expense per person
	           (4) Mean Expense per person by Age Category 
	           
INPUT FILE:   H201.SAS7BDAT (2017 FULL-YEAR Consolidated File)
Built off of example by 
Mitchell, E. (2020) HHS-AHRQ/MEPS: Example Code for Loading and Analyzing Data from 
	AHRQ’s Medical Expenditure Panel Survey (MEPS). Retrieved from Gitbhub:
	https://github.com/HHS-AHRQ/MEPS
*********************************************************************************/;
/*Set destination for SAS procedure outputs */

%LET MyFolder= /folders/myfolders/SASDATA;
OPTIONS LS=132 PS=79 NODATE FORMCHAR="|----|+|---+=|-/\<>*" PAGENO=1;
FILENAME MYLOG "&MyFolder/CJW_Project_log_Final.TXT";
FILENAME MYPRINT "&MyFolder/CJW_Project_OUTPUT_Final.TXT";
PROC PRINTTO LOG=MYLOG PRINT=MYPRINT NEW;
RUN;

proc datasets lib=work nolist kill; quit; /* delete  all files in the WORK library */
libname CDATA "/folders/myfolders/SASDATA";

PROC FORMAT;

	Value  TOTALCAT
	.			= 	'All Totals'
	0- 9999		= 	'$0 to $9,999'
	10000-19999	= 	'$10,000 to $19,999'
	20000-29999	=	'$20,000 to $29,999'
	30000-39999	=	'$30,000 to $39,999'
	40000-49999	=	'$40,000 to $49,999'
	50000-HIGH	=	'Above $50,000';
	
  VALUE AGEF
     .      = 'ALL AGES'
     0-  9  = '0 to 9'
     10- 19 = '10 to 19'
     20- 29 = '20 to 29'
     30- 39 = '30 to 39'
     40- 49 = '40 to 49'
     50- 59 = '50 to 59'
     60- 69 = '60 to 69'
     70- 79 = '70 to 79'
     80- 89 = '80 to 89'
     90-HIGH = '90+';
 

  VALUE AGECAT
      .      = 'ALL AGES'
	   1 = '0 to 9'
	   2 = '10 to 19'
	   3 = '20 to 29'
	   4 = '30 to 39'
	   5 = '40 to 49'
	   6 = '50 to 59'
	   7 = '60 to 69'
	   8 = '70 to 79'
	   9 = '80 to 89'
	  10 = '90+';
	 

  VALUE GTZERO
     0         = '0'
     0 <- HIGH = '>0';

  VALUE FLAG
      .         = 'No or any expense'
      0         = 'No expense'
      1         = 'Any expense';
      
RUN;

TITLE1 '2020 MIS500 Christopher Weller Module 8 Project';
TITLE2 "National Health Care Expenses, 2017";

/* READ IN DATA FROM 2017 CONSOLIDATED DATA FILE (HC-201) */
DATA PUF201;
  SET CDATA.H201 (KEEP= TOTEXP17 AGE17X AGE42X AGE31X
	                      VARSTR   VARPSU   PERWT17F );

  TOTAL                = TOTEXP17;

  /* CREATE FLAG (1/0) VARIABLES FOR PERSONS WITH AN EXPENSE */
  Expense_Status=0;
  IF TOTAL > 0 THEN Expense_Status=1;

  /* CREATE A SUMMARY VARIABLE FROM END OF YEAR, 42, AND 31 VARIABLES*/

       IF AGE17X >= 0 THEN AGE = AGE17X ;
  ELSE IF AGE42X >= 0 THEN AGE = AGE42X ;
  ELSE IF AGE31X >= 0 THEN AGE = AGE31X ;

       IF 0 LE AGE LE 9 THEN AGECAT=1 ;
  ELSE IF 10 LE AGE LE 19 THEN AGECAT=2 ;   
  ELSE IF 20 LE AGE LE 29 THEN AGECAT=3 ;   
  ELSE IF 30 LE AGE LE 39 THEN AGECAT=4 ;   
  ELSE IF 40 LE AGE LE 49 THEN AGECAT=5 ;    
  ELSE IF 50 LE AGE LE 59 THEN AGECAT=6 ;    
  ELSE IF 60 LE AGE LE 69 THEN AGECAT=7 ;    
  ELSE IF 70 LE AGE LE 79 THEN AGECAT=8 ;   
  ELSE IF 80 LE AGE LE 89 THEN AGECAT=9 ; 
  ELSE IF     AGE > 90 THEN AGECAT=10 ; 
RUN;

Proc univariate data=puf201;
	VAR AGE;
	Histogram AGE/Normal;
Run;


TITLE3 "Respondants with 2017 Health Expenses";
PROC FREQ DATA=PUF201;
   TABLES 	Expense_Status*AGE
   			AGECAT*AGE
   			/LIST MISSING;
     FORMAT TOTAL        		GTZERO.
          	AGE            		AGEF.
          	Expense_Status		FLAG.;
RUN;

Title3 'Chi Square Analysis of people with an expense, by AGE';
PROC FREQ DATA=PUF201; WEIGHT Expense_Status;
	TABLES Total*AGE/CHISQ;
	Format 	AGE				AGEF.
			Total			TotalCAT.;
Run;

Title3 'Correlation between AGE and Total Expense';
PROC CORR Data=puf201;
	VAR AGE17X TOTEXP17;
RUN;

/*ods graphics off;
ods exclude all; Suppress the printing of output */


TITLE3 '2017 People with an expense';
PROC SURVEYMEANS DATA=PUF201 MEAN NOBS SUMWGT STDERR SUM STD;
	STRATUM VARSTR;
	CLUSTER VARPSU;
	WEIGHT PERWT17F;
	VAR  Expense_Status TOTAL ;
	ods output Statistics=work.Overall_results;
RUN;

ods exclude none ; /* Unsuppress the printing of output */
TITLE3 '2017 People with an Expense (%)';
proc print data=work.Overall_results (firstobs=1 obs=1) noobs split='*';
var  SumWgt  mean StdErr  Sum stddev;
 label 	SumWgt 	= 'US Population*Size'
       mean 	= 'Percentage of People*with Expenses'
       StdErr 	= 'Standard Error of*Percentage of People*with Expenses'
       Sum 		= 'Estimated People*with Expenses in 2017'
       Stddev 	= 'Standard Error of*Estimated People*with Expenses in 2017';
       format N SumWgt Comma12. mean comma7.2 stderr 7.5
              sum Stddev comma17.;
run;

TITLE3 'Total 2017 Expenses';
proc print data=work.Overall_results (firstobs=2) noobs split='*';
var  SumWgt  mean StdErr  Sum stddev;
 label SumWgt 	= 	'US Population*Size'
       mean 	= 	'Mean of*Total Expenses($)'
       StdErr 	= 	'Standard Error of*Mean of*Total Expenses($)'
       Sum 		= 	'US Total*Expense($)'
       Stddev 	= 	'Standard Error of*US Total*Expense($)';
       format N SumWgt Comma12. mean comma9.2 stderr 9.2
              sum Stddev comma17.;
run;

ods exclude all; /* suspend all destinations */
TITLE3 '2017 Age Categorization Statistics';
PROC SURVEYMEANS DATA= PUF201 MEAN NOBS SUMWGT STDERR SUM STD;
	STRATUM VARSTR ;
	CLUSTER VARPSU ;
	WEIGHT  PERWT17F ;
	VAR  TOTAL;
	DOMAIN Expense_Status('1')  Expense_Status('1')*AGECAT ;
	FORMAT  AGECAT agecat.;
	ods output domain= work.domain_results;
RUN;

ods exclude none ; /* Unsuppress the printing of output */
proc print data= work.domain_results noobs split='*';
 var AGECAT  N  SumWgt  mean StdErr  Sum stddev;
 label N		= 'Number*of People*with*Expenses'	
 	   AGECAT 	= 'Age Group'
       SumWgt 	= 'US Population*Size*with*Expenses'
       mean 	= 'Mean*of *Total*Expenses($)'
       StdErr 	= 'Standard Error of *Mean of*Total*Expenses($)'
       Sum 		= 'US Total*Expenses ($)'
       Stddev 	= 'Standard Error of* US Total*Expenses($)';
       format AGECAT agecat. N SumWgt Comma12. mean comma9.2 stderr 9.2
              sum Stddev comma17.;
run;

TITLE3 'ANOVA Analysis of 2017 Total Expense Mean by AGE Category';
PROC ANOVA DATA=puf201;
	CLASS AGECAT;
	MODEL TOTAL=AGECAT;
	MEANS AGECAT/TUKEY;
	Format AGECAT AGECAT.;
run;

ODS _ALL_ CLOSE;
/* THE PROC PRINTTO null step is required to close the PROC PRINTTO */
PROC PRINTTO;
RUN;