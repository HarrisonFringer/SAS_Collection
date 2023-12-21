*Name: Harrison Fringer;
*Course Info: ST 445-001;
*Last Edited: November 10, 2023;
*Purpose: HW 06, creating joins, merges, utilizing proc report and sgpanel;

*Setting up a relative path to access the required data and results;
x "cd L:\st445\";

*Setting a fileref and a library from this path;
filename RawData "Data";
libname InputDS "Data";
libname Results "Results"; *Validation library!;

*Changing the x statement to create a spot for outputted datasets;
x "cd S:\Documents";
libname HW6 "."; 

*Setting up my PDF for data exploration;
ods pdf file = "HW6 Fringer IPUMS Report.pdf" dpi = 300 startpage = NEVER;
ods listing close;
ods pdf exclude all;

*Making some macrovariables to cut down on clunky repetitive code;
%let CompOpts = outbase outcompare outdiff outnoequal
                method = absolute criterion = 1E-15;

*Setting up a format that will help in finalizing the data (Proc 1/12);
proc format fmtlib library = HW6;
  value $MetroDesc (fuzz = 0) 0 = "Indeterminable"
                            1  = "Not in a Metro Area"
                            2 = "In Central/Principal City"
                            3 = "Not in Central/Principal City"
                            4 = "Central/Principal Indeterminable"
  ;
run;

*Options that help make the pdf pretty;
options nodate fmtsearch = (HW6);

*Beginning my data imports for the raw data files, formatting them appropriately (Data 1/7) [Contract.txt];
data HW6.HW6FringerContract;
  infile RawData("Contract.txt") firstobs = 2 dlm = "09"x dsd truncover;
  input Serial :
        Metro :
        CountyFIPS : $3.
        MortPay : dollar.
        HHI : dollar.
        HomeVal : dollar.
        ;
run;

*Another raw read (Data 2/7) [Mortgaged.txt];
data HW6.HW6FringerMortgaged;
  infile RawData("Mortgaged.txt") firstobs = 2 dlm = "09"x dsd truncover;
  input Serial :
        Metro :
        CountyFIPS : $3.
        MortPay : dollar.
        HHI : dollar.
        HomeVal : dollar.
        ;
run;

*Third raw read (Data 3/7) [Cities.txt];
data HW6.HW6FringerCities;
  length City $40;
  infile RawData("Cities.txt") firstobs = 2 dlm = "09"x;
  input _City : $40.
        CityPop : comma.
        ;
  /*A bit of cleaning was necessary at this point!*/
  City = tranwrd(_City,"/","-");
  drop _City;
run;

*Last raw data read (Data 4/7) [States.txt];
data HW6.HW6FringerStates;
  infile RawData("States.txt") firstobs = 2 dlm = "092E"x;
  input Serial :
        State : $20.
        City : $40.
        ;
run;

*A concatenation of the meaty parts of the data (Data 5/7);
data HW6.HW6FringerConcat;
  set HW6.HW6FringerContract (in = inContract)
      HW6.HW6FringerMortgaged (in = inMortgaged)
      InputDS.FreeClear (in = inFreeClear)
      InputDS.Renters (in = inRenters);

      /*This is necessary so that my first value assignment of MortStat and MetroDesc don't set the length*/
      length MortStat $45;
      length MetroDesc $32;

      /*Taking care of data parameters that rely on which file the data comes from*/
      if inRenters = 1 then 
         do; 
           CountyFIPS = FIPS;
           Ownership = "Rented";
           if HomeVal = 9999999 then HomeVal = .R;
           MortStat = "N/A";
        end;
        else do;
          Ownership = "Owned";
          if missing(HomeVal) then HomeVal = .M;
        end;
      
      /*A bit of conditional logic to finish assigning MortStat values*/
      if inMortgaged = 1 then MortStat = "Yes, mortgaged/ deed of trust or similar debt";
      if inFreeClear = 1 then MortStat = "No, owned free and clear";
      if inContract = 1 then MortStat = "Yes, contract to purchase";

      
      /*Making use of the format from earlier, as well as deriving one last variable*/
      MetroDesc = put(Metro,MetroDesc.);
      
      /*Dropping an unnecessary variable*/ 
      drop FIPS;
run;

*A sort of the state dataset for a one-to-many merge (Proc 2/12);
proc sort data = HW6.HW6FringerStates;
  by City;
run;

*Another sort for the same reason, on the city dataset (Proc 3/12);
proc sort data = HW6.HW6FringerCities;
  by City;
run;

*Carrying out the one-to-many merge by City (Data 6/7);
data HW6.HW6FringerStateMatch;
  merge HW6.HW6FringerStates
        HW6.HW6FringerCities;
  by City;
run;

*Sorting the concatenated dataset for a one-to-one merge (Proc 4/12);
proc sort data = HW6.HW6FringerConcat;
  by Serial;
run;

*Sorting the state-city dataset for the same reason (Proc 5/12);
proc sort data = HW6.HW6FringerStateMatch;
  by Serial;
run;

*Creating the finalized dataset, setting labels and whatnot here (Data 7/7);
data HW6.HW6FringerIpums2005;
  attrib Serial label = "Household Serial Number"
         CountyFIPS label = "County FIPS Code"
         Metro label = "Metro Status Code"
         MetroDesc label = "Metro Status Description"
         CityPop label = "City Population (in 100s)" format = comma6.
         MortPay label = "Monthly Mortgage Payment" format  = dollar6.
         HHI label = "Household Income" format = dollar10.
         HomeVal label = "Home Value" format = dollar10.
         State label = "State, District, or Territory" length = $20
         City label = "City Name"
         MortStat label = "Mortgage Status" length = $45
         Ownership label = "Ownership Status" length = $6
         ;
  merge HW6.HW6FringerConcat
        HW6.HW6FringerStateMatch;
  by Serial;
run;

*Creating this table from proc contents for my metadata validation;
ods output Position = HW6.HW6FringerDesc (Drop = Member);

*Proc contents for metadata validation (Proc 6/12);
proc contents data = HW6.HW6FringerIpums2005 varnum;
run;

*A proc compare of the metadata, output in a diffs dataset in the work library (Proc 7/12);
proc compare base = Results.HW6DugginsDesc compare = HW6.HW6FringerDesc
             out = work.DescDiffs &CompOpts;
run;

*A proc compare of the variable values (Proc 8/12);
proc compare base = Results.HW6DugginsIpums2005 compare = HW6.HW6FringerIpums2005
             out = work.Diffs &CompOpts;
run;

*Setting up some ods settings/presentation;
ods pdf exclude none;
title "Listing of Households in NC with Incomes Over $500,000";
footnote; /*This prevents the later footnotes from appearing earlier!*/

*Running a proc report to get observations under certain criteria (Proc 9/12);
proc report data = HW6.HW6FringerIpums2005;
  columns City Metro MortStat HHI HomeVal;
  where HHI > 500000 and State = "North Carolina";
run;

*Setting ods graphics to match provided specifications, as well as pulling what I want into the pdf;
ods graphics / width = 5.5in imagefmt = png;
title;
ods pdf select CityPop.quantiles CityPop.BasicMeasures CityPop.Histogram.Histogram MortPay.Quantiles
               HHI.BasicMeasures HHI.ExtremeObs HomeVal.BasicMeasures
               HomeVal.ExtremeObs HomeVal.MissingValues;

*Running a proc univariate to grab the statistics/graph of interest (Proc 10/12);
proc univariate data = HW6.HW6FringerIpums2005;
  var CityPop MortPay HHI HomeVal;
  histogram CityPop / kernel;
run;

*Opening listing for sgplot, as well as title/footnote housekeeping;
ods listing;
ods pdf startpage = NOW;
title "Distribution of City Population";
title2 "(For Households in a Recognized City)";
footnote j = l "Recognized cities have a non-zero value for City Population.";

*Performing a proc sgplot to create a single histogram on City Population (Proc 11/12);
proc sgplot data = HW6.HW6FringerIpums2005 (where = (CityPop ne 0));
  Histogram CityPop / scale = proportion;
  density CityPop / type = kernel lineattrs = (thickness = 2pt color = cxCC0000);
  yaxis display = (nolabel) valuesformat = percent5.;
  keylegend / position = ne location = inside;
run;

*Title/footnote housekeeping;
title "Distribution of Household Income Stratified by Mortgage Status";
footnote j = l "Kernel estimate parameters were determined automatically.";

*Performing my last proc, which is a series of graphs showing HHI distributions by Mortgage Status (Proc 12/12);
proc sgpanel data = HW6.HW6FringerIpums2005 noautolegend;
  Panelby MortStat / novarname;
  histogram HHI / scale = proportion;
  rowaxis display = (nolabel) valuesformat = percent.;
  density HHI / type = kernel lineattrs = (color = cxCC0000);
run;

*Closing pdf destination, and leaving listing open to avoid errors of any sort;
ods pdf close;

*Quit added in compliance of GPPs;
Quit;
