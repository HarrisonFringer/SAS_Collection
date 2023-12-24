*Personal Fun/Project
 Name: Harrison Fringer
 Goal(s): Working through various material covered in class,
          and applying it to generalized content;

*Setting up filerefs;
x "cd S:/Downloads";
filename RawData ".";

*Setting up my library, where files will be output;
x "cd S:/Documents";
libname Test ".";

*Macrovariable creation area;
%let FootNoteOpts = j = l h = 8pt;

*ods options block;
ods listing close;
ods noproctitle;
options nodate nonumber fmtsearch = (Test);
ods pdf file = "Fringer Test Score Report.pdf" style = Sapphire;

*Setting up formats that I will use for data readability;
ods exclude all;
proc format fmtlib library = Test;
  value $Deg2Form (fuzz = 0)   "high school" = "HS"
                               "bachelor's degree" = "BA"
                               "master's degree" = "MA"
                               "some college" = "SC"
                               "some high school" = "SHS"
                               "associate's degree" = "AS"
                               ;
  value $EthForm (fuzz = 0)    "group A" = "A"
                               "group B" = "B"
                               "group C" = "C"
                               "group D" = "D"
                               "group E" = "E"
                               ;
  value GradeCol (fuzz = 0)    low -< 60 = "cxFF6962"
                               60 -< 70 = "cxFF8989"
                               70 -< 80 = "cxFFB3A5"
                               80 -< 90 = "cx7ABD91"
                               90 - 100 = "cx5FA777"
                               ;
run;

*Reading in my raw data, which is a simple list (.csv);
data Test.Full;
  attrib Gender label = "Gender"
         Ethnicity label = "Race/Ethnicity"
         _LoE length = $30
         LoE label = "Parent Level of Education" 
         Lunch label = "Lunch Type" length = $20
         PrepCourse label = "Test Preparation Completion Status" length = $15
         Math label = "Math Score"
         Reading label = "Reading Score"
         Writing label = "Writing Score"
         ;
  infile RawData("StudentsPerformance.csv") dsd firstobs = 2;
  input Gender $ Ethnicity $ _LoE $ Lunch $ PrepCourse $ Math Reading Writing;
  LoE = propcase(_LoE);
  drop _LoE;
run;

title "List of Variables contained in Test.Full";
footnote &FootnoteOpts "Data is fictional, and is being used solely for demonstrative purposes";
footnote2 &FootnoteOpts  "Data collected from http://roycekimmons.com/tools/generated_data/exams";

*Running a proc contents to make sure things are set up as intended;
ods select Position;
proc contents data = Test.Full varnum;
run;


title "Frequency Analysis of Parental Education Level and Lunch Status";
footnote;
*Running a proc freq to check possible values for LoE and Lunch, as values were not provided in data source;
proc freq data = Test.Full;
  table LoE Lunch / nopercent;
run;

*Using a sort to complete the following proc freq;
ods exclude all;
proc sort data = Test.Full;
  by Lunch;
run;

title "Frequency Analysis of Parental Level of Education, by Lunch Status";
footnote &FootnoteOpts "Only using observations where Ethnicity = group B";
ods exclude none;
ods pdf startpage = NOW;
*Running a proc freq of the full dataset by Lunch, only where Ethnicity = group B;
proc freq data = Test.Full;
  table LoE / nopercent;
  by Lunch;
  where Ethnicity = "group B";
run;

*Running a Proc Means for basic data comparisons;
title "Five Number Summary (and extras) for Reading and Math Scores";
footnote &FootnoteOpts "Writing scores are excluded per request";
ods output Summary = Test.Stats;
proc means data = Test.Full nonobs nolabels min q1 mean median q3 max std maxdec = 2;
  var math reading;
  class Ethnicity;
run;

*Creating a nicer formatted version of the previous table, using a proc report over proc means;
title "Report of English and Reading Scores, by Ethnicity Group*";
footnote &FootnoteOpts "Ethnic groups are undefined in source material";
footnote2 &FootnoteOpts "*S indicates a summary row";
footnote3 &FootnoteOpts "**Median values are rounded to the nearest integer";
proc report data = Test.Full 
            style(header) = [backgroundcolor = cx1FD655 color = cxFFFFFF]
            nowd
            out = Test.MathStats;
  columns Ethnicity math = min math = q1 math = mean math = median math = q3 math = max math = std;
  define Ethnicity / group "Ethnicity (Groups)" format = $EthForm. style(column) = [backgroundcolor = cxC2C2C2 color = cxFFFFFF];
  define min / analysis "Math Min" min format = 2.;
  define q1 / analysis "Math Q1" q1 format = 2.;
  define mean / analysis "Math Mean" mean format = 4.2 style(column) = [backgroundcolor = GradeCol.];
  define median / analysis "Math Median" median format = 2.;
  define q3 / analysis "Math Q3" q3 format = 2.;
  define max / analysis "Math Max" max format = 3.;
  define std / analysis std "Math Std. Dev." format = 5.2;
  rbreak after / summarize style = [backgroundcolor = cx0a0a0a
                                    color = cxFFFFFF];
  compute after;
    if _break_ = "_RBREAK_" then Ethnicity = "S";
  endcomp;
run;

ods pdf startpage = NEVER;
*A second proc report, for the reading data;
proc report data = Test.Full 
            style(header) = [backgroundcolor = cx3CDFFF color = cxFFFFFF]
            nowd
            out = Test.ReadStats;
  columns Ethnicity reading = rmin reading = rq1 reading = rmean reading = rmedian 
          reading = rq3 reading = rmax reading = rstd;
  define Ethnicity / group 'Ethnicity (Groups)' format = $EthForm. style(column) = [backgroundcolor = cxC2C2C2 color = cxFFFFFF];
  define rmin / analysis "Reading Min" min format = 2.;
  define rq1 / analysis "Reading Q1" q1 format = 2.;
  define rmean / analysis "Reading Mean" mean format = 4.2 style(column) = [backgroundcolor = GradeCol.];
  define rmedian / analysis "Reading Median" median format = 2.;
  define rq3 / analysis "Reading Q3" q3 format = 2.;
  define rmax / analysis "Reading Max" max format = 3.;
  define rstd / analysis "Reading Std. Dev." std format = 5.2;
  rbreak after / summarize style = [backgroundcolor = cx0a0a0a
                                    color = cxFFFFFF];
  compute after;
    if _break_ = "_RBREAK_" then Ethnicity = "S";
  endcomp;
run;
run;


*Taking the previous data and making a few graphs out of it;
title j = c "Math Report Visualization with Comparison";
title2 j = c "to Overall Median";
footnote &FootnoteOpts "Boxplot Style #1";
*The first style of boxplot;
proc sgplot data = Test.Full noautolegend;
  styleattrs datacolors = (cxFFFFD4 cxFED98E cxFE9929 cxD95F0E cx993404);
  vbox Math / category = Ethnicity
              group = Ethnicity
              lineattrs = (color = cx000000);
  yaxis grid gridattrs = (thickness = 3pt)
        label = "Score"
        offsetmax = .05
        ;
  xaxis label = "Ethnic Group"
        valuesformat = $EthForm.;
  refline 66 / axis = Y 
                 lineattrs = (color = cx1FD655 thickness = 2pt)
                 label = "Overall Median";
run;

title j = c "Reading Report Visualization with Comparison";
title2 j = c "to Overall Median";
footnote &FootnoteOpts "Boxplot Style #2";
*Providing a different style of boxplot, just to mess around with settings (more simplistic);
proc sgplot data = Test.Full;
  vbox Reading / category = Ethnicity;
  yaxis grid gridattrs = (thickness = 2pt)
        label = "Score"
        offsetmax = .05;
  xaxis label = "Ethnicity";
  refline 70 / axis = Y 
                 lineattrs = (color = cx3CDFFF thickness = 2pt)
                 label = "Overall Median";
run;

*Title changing;
title "Exploring A Linear Model Between Reading and Math";
footnote &FootnoteOpts "Accounting for all reported test scores";
*Running a Proc GLM for graphing math against reading, and viewing some test statistics;
proc glm data = Test.Full;
  model math = reading;
run;

*Closing destination and quitting;
ods pdf close;
quit;
