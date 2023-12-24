*Name: Harrison Fringer;
*Course Info: ST 445-001;
*Last Edited: November 28, 2023;
*Purpose: Final Project - Phase 1
          Creating a combined data report from a series of datasets, and doing some basic stats;

*Setting up some basic libraries for use;
x cd "L:/st445/Data/WashingtonState";
filename RawData "RawData"; /*Data area*/
libname StrcData access "StructuredData/Lookup.accdb"; /*Access area*/
libname FormCat "FormatCatalogs";

x cd "S:/Desktop";
libname Final "Final"; /*Output area, I made a folder called Final to house my things*/

*This is an area reserved for macrovariable(s), which will likely be populated in the order
in which I think of them;

%let UnkLength = 250; /*Up to 250 values can appear based on number of filled semicolons*/

*Preventing things from populating listing;
ods listing exclude all;

*This space is reserved for format(s), which will be populated in the order they are used [Proc 1/8];
proc format fmtlib library = Final;
  value CAFV (fuzz = 0)   1 = "Clean Alternative Fuel Vehicle Eligible"
                               2 = "Not eligible due to low battery range"
                               3 = "Eligibility unknown as batter range has not been researched"
                           ;
run;

*Some options for data creation;
options fmtsearch = (Final FormCat); /*This fits here conveniently*/

*Beginning the RawData inserts, starting with the (yes) set [Data 1/7];
data Work.Yes;
  infile RawData("EV-CAFV(yes).txt") firstobs = 6 dlm = "092C"x dsd;
  input Vin : $10.
        ZipC : $5.
        LegDist : $2.
        DOLID : $9.
        CensusTract2020 : $11.
        RegDate : yymmdd.
        ElecUtil : $200. 
        Location : $40.;
run;

*The no dataset, which uses formatted input [Data 2/7];
data Work.No;
  infile RawData("EV-CAFV(no).txt") firstobs = 8;
  input Vin $10. ZipC $5. LegDist $2. DOLID : $9.
        CensusTract2020 $11. RegDate 5.
        / ElecUtil $100.
        / Location $35.;
run;

*The unknown dataset, with slight data cleaning to help avoid issues with concatenation [Data 3/7];
data Work.Unk (where = (ZipC ne ""));
  attrib Zip1-Zip&UnkLength length = $5
         LegDist1-LegDist&UnkLength length = $2
         DOLID1-DOLID&UnkLength length = $9
         CT1-CT&UnkLength length = $11
         RD1-RD&UnkLength length = $40
         ElecUtil1-ElecUtil&UnkLength length = $100
         Location1-Location&UnkLength length = $35
         Month length = $3;
  infile RawData("EV-CAFV(unk).txt") firstobs = 12 dlm = ";" dsd;
  input Vin : $10. Zip1-Zip&UnkLength : $5. LegDist1-LegDist&UnkLength : $2. 
        DOLID1-DOLID&UnkLength : $9. CT1-CT&UnkLength : $11. RD1-RD&UnkLength : $40. 
        ElecUtil1-ElecUtil&UnkLength : $100. Location1-Location&UnkLength : $35.;
  array Zippy[*] $ Zip1-Zip&UnkLength;
  array Leggy[*] $ LegDist1-LegDist&UnkLength;  
  array Doly[*] $ DOLID1-DOLID&UnkLength;
  array Cency[*] $ CT1-CT&UnkLength;
  array Datey[*] $ RD1-RD&UnkLength;
  array Elecy[*] $ ElecUtil1-ElecUtil&UnkLength;
  array Locy[*] $ Location1-Location&UnkLength;
  do i = 1 to dim(Zippy);
    ZipC = Zippy[i];
    LegDist = Leggy[i];
    DOLID = Doly[i];
    CensusTract2020 = Cency[i];
    _RegDate = Datey[i];
    ElecUtil = Elecy[i];
    Location = Locy[i];
    Month = upcase(scan(_RegDate,1)); 
    Day = scan(_RegDate,2); 
    Year = scan(_RegDate,-1);
    RegDate = input(Cats(Day, Month, Year),date9.);
    output;
  end;

  drop  i Zip1-Zip&UnkLength LegDist1-LegDist&UnkLength 
        DOLID1-DOLID&UnkLength CT1-CT&UnkLength RD1-RD&UnkLength
        ElecUtil1-ElecUtil&UnkLength Location1-Location&UnkLength
        Day Month Year _RegDate;
run;

*Concatenation of the 3 different datasets, making input set-dependent variables now [Data 4/7];
data Work.AllCAFV;
  set Work.Yes (in = inYes)
      Work.No (in = inNo)
      Work.Unk (in = inUnk);
  Zip = input(ZipC, 5.);
  CAFVCode = 1*inYes + 2*inNo + 3*inUnk;
  CAFV = put(CAFVCode, CAFV.);
run;

*Sorting by VIN for an upcoming merge [Proc 2/8];
proc sort data = Work.AllCAFV;
  by VIN;
run;

*Merging my concatenated dataset with the demographics access file [Data 5/7];
data Work.VINed (where = (DOLID ne ""));
  merge Work.ALLCAFV
        Strcdata.Demographics;
  by VIN; 
run;

*Sorting by Zip for an upcoming merge [Proc 3/8];
proc sort data = Work.VINed;
  by Zip;

*Merging my concatenated dataset with the zipcode files for what I need [Data 6/7];
data Work.Zipped (where = (DOLID ne ""));
  merge Work.VINed
        Sashelp.Zipcode (keep = ZIP STATENAME STATECODE COUNTY COUNTYNM CITY STATE);
  by Zip;
run;

*Sorting by DOLID for an upcoming merge [Proc 4/8];
proc sort data = Work.Zipped;
  by DOLID;
run;

*Creating my final combined dataset using a slew of functions, variable creaton, renaming, etc. [Data 7/7];
data Final.FinalfringerEV (where = (dolid ne ""));
  Attrib Vin Label = "Vehicle Identification Number" length = $10
         MaskVin Label = "Partially Masked Vin" length = $10
         ZipC Label = "Vehicle Registration Zip Code"
         Zip Label = "Vehicle Registration Zip Code" format = Z5.
         CityName Label = "City Name" length = $35
         StateFips Label = "State FIPS" 
         StateCode Label = "State Postal Code" length = $2
         StateName Label = "State Name" length = $25
         CountyFips Label = "County FIPS"
         CountyName Label = "County Name" length = $25
         LegDist Label = "Vehicle Registration Legislative District" length = $2
         DOLID label = "WA Department of Licensing ID" 
         CensusTract2020 Label = "Vehicle Registration US Census Tract" length = $11
         RegDate label = "Last Registration Date" format = YYMMDD10.
         ModelYear label = "Vehicle Model Year"
         EVType label = "EV Type (long)" length = $50
         EVTypeShort label = "EVTypeShort" length = $4
         Erange label = "Electric Range" 
         BaseMSRP label = "Reported Base MSRP"
         Make label = "Vehicle Make" 
         Model label = "Vehicle Model" length = $25
         CAFV label = "Clean Alternative Fuel Vehicle Eligible Description" length = $60
         CAFVCode label = "Clean Alternative Fuel Vehicle Eligible (1=Y,2=N,3=U)" 
         ElecUtil label = "Electric Utilities Servicing Vehicle Registration Address" length = $200
         PrimaryUtil label = "Primary Electric Utility at Vehicle Location"
         Latitude label = "Vehicle Registration Latitude (decimal)" format = 13.8
         Longitude label = "Vehicle Registration Longitude (decimal)" format = 13.8
         Location length = $200
         ;

  merge Work.Zipped StrcData."Non-Domestic Registrations"n;
  by DOLID;

  MaskVin = CATS("*******",substr(Vin,8));
  Latitude = input(scan(Location, 2, "2820"x), 13.8);
  Longitude = input(scan(Location, -1, "2029"x), 13.8);
  EVTypeShort = scan(EVType, -1);
  PrimaryUtil = scan(ElecUtil, 1, "|");
  StateFips = State;
  CountyName = CountyNm;
  CountyFips = County;
  CityName = CITY;

  select (ST);
    when ("AP") do;
      StateName = "Armed Forces Pacific";
      StateCode = ST;
    end;
    when ("BC") do;
      StateName = "British Columbia";
      StateCode = ST;
    end;
    otherwise;
  end;
  make = input(makecat, $EvMake.);
  Model = input(modelcat, $Evmodel.);
  Rename Zip=ZipN ZipC=Zip;
  
  if BaseMSRP eq 0 then BaseMSRP = .Z;
  else if BaseMSRP lt 0 then BaseMSRP = .I;
  else if missing(BaseMSRP) then BaseMSRP = .M;
  drop location st CITY COUNTY COUNTYNM STATE makecat modelcat;
run;

*Producing the UniqueVinMask procedure using a proc sort and a NoDupKey Option [Proc 5/8)];
proc sort data = Final.Finalfringerev out = Final.FinalfringerUniqueVinMask nodupkey;
  by vin;
run;

*Producing the data for the models dataset that I need using another proc sort [Proc 6/8];
proc sort data = Final.Finalfringerev out = modelsdat nodupkey;
  by Make Model;
run;

*Creating the dataset using a proc transpose [Proc 7/8];
proc transpose data = modelsdat out = Final.Finalfringermodels (drop = _name_ _label_) prefix = Model;
  by Make;
  var Model;
run;

*Creating a frequency table of CAFV and EVType using a Proc Freq [Proc 8/8];
ods output CrossTabFreqs = Final.FinalFringerCafvCrossEV (drop = Table Frequency _TABLE_ missing);
proc freq data = Final.FinalfringerEV;
  table CAFVCode*EVTypeShort / nofreq missing;
run;

*Quit because I'm a GPPer;
Quit;
