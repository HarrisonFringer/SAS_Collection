*
Programmed by: Michael Whittington and Harrison Fringer (and Dr. Duggins)
Last Modified: Nov. 18, 2024
Modifications Made: Created a categorical variable through IML
Presentation title: Creating Synthetic Data for Education Using SAS 
;

/* The purpose of this program is to be used for teaching students about different scenarios in Simple and Multi Linear Regression. */

/* Data Synthesis Setup */
%let SLRsize = 50; /*This sets the size of each variable in MLR as well*/
%let mus = 0 0 0;  /*This variable allows for the selection of means for each cont. var*/
%let Covar = "1 0.3 0.3,0.3 1 0.3,0.3 0.3 1";   /*Sigma matrix setup*/
%let ContSpec = "Y" "X1" "X2" "X3"; /*Define/label your variables here, first your response variable, then the predictors*/
/*DO NOT PLACE SPACES AFTER COMMAS OR THE MATRIX WILL NOT PROPERLY GENERATE (maybe they will? don't risk it)*/
%let nRows = 3;               /*For how the matrix is constructed, the number of rows in sig matrix is required*/
%let betam = 3 2 7 1 6 2; /*A space-delimited list of slope parameters*/
%let betac = 4;    /*How many of the parameters (from the far left) are related to continuous variables/int?*/
%let evar = 1;     /*CONSTANT variance of the error term (Model cannot be violated with NC Variance with this setup)*/
%let nomods = 1;   /*This condition sets no modifications to the linear model, REGARDLESS of the below macrovars*/
%let Outcount = 3; /*This sets the number of outlier points, perhaps this can become a function of SLRsize*/
%let hedskat = 1;  /*Setting whether data lends itself to funneling*/
%let indind = 1;   /*Independence indicator (Applies to heteroskedastic data)*/
%let mixdat = 1;   /*Creation of both categorical and continuous data*/

/* Creating datasets */
*NOTE: Michael's datasets are not gone! They have been moved to the bottom, and may be deleted upon creation of all distributions
through proc IML;
*This is done through IML with Ricklin, so brush up on IML before reading this;
*This IML is encompassing all normal-based, two-predictor MLR (i.e. Outliers, leverage);
*As of now, outliers can be easily created by applying a uniform linear alteration to x1 and x2,
as the slopes are considerably dissimilar. A new approach will be needed for similar slopes;
%macro datamaker(ContSpec, Covar, nRows, SLRsize, evar, OutCount, betam, betac, nomods, hedskat, indind, mixdat);
proc iml;
call randseed(1324);
mu = t({&mus});
sig = j(&nRows,&nRows);
/*Sigma Matrix Setup*/
  do i = 1 to &nRows;
    rowvals = scan(&covar, i, ",");
      do j = 1 to &nRows;
        ijval = num(scan(rowvals, j, " "));
        sig[i,j] = ijval;
      end;
  end;
print sig;
prob = {0.3, 0.4, 0.3}; /*Probabilities for EACH level of a categorical variable*/
hedvar = j(1*&SLRsize,1);
hetind = RandNormal(1*&SlrSize,0,&evar); /*A resorting variable that reinstates independence*/
  x = j(&SLRsize,1)||RandNormal(&SLRsize, mu, sig);
print(x);
  
  
/*MODEL BUILDING AREA (pre-specified parameters in macros)*/
if &mixdat = 1 then do;
 catmake = Randmultinomial(1*&SLRSize, 1, prob)[,1:2]; *This approach can make any form of categorical variable;
 xmix = x||catmake;
 print xmix;
 betamix = t({&betam});
 betamcount = dimension(betamix)[,1];
 print betamcount;
 print betamix;
 ymix = xmix*betamix + RandNormal(&SLRSize,0,&evar);
 outmix = ymix||xmix[,2:betamcount];
 create mlrmixed from outmix[c={&ContSpec "C1" "C2"}];
   append from outmix;
 close mlrmixed;
end;

/*Solely Continuous Data*/
betacont = betamix[1:&Betac,];
betacount = dimension(betacont)[,1];
y = x*betacont + RandNormal(&SlrSize,0,&evar);
print y;
out1 = y||x[,2:betacount];
print out1;
if &nomods = 1 then do;
  create mlrnorm from out1[c={&ContSpec}];  /*SAS Dataset creation*/
    append from out1;
  close mlrnorm;
end;

/*OUTLIER DECISION AREA (conditioned by macro)*/
outlierscalar = std(y);
if &nomods = 0 & &OutCount > 0 then do i = 1 to &OutCount;  /*Do loop that iterates as many outliers as one wants*/
  randob = floor(rand("Uniform", 1, &SLRsize));
  y[randob] = outlierscalar + y[randob];     /*Please don't iterate every variable to be an "outlier"*/
end;
print y;
out2 = y||x[,2:betacount];
if &nomods = 0 & &OutCount > 0 then do;
  create mlrout from out2[c={&ContSpec}];  /*SAS Dataset creation*/
    append from out2;
  close mlrout;
end;

/*HETEROSKEDASTIC DATA CREATION (conditioned by macro)*/
if &hedskat = 1 then do l = 1 to &SLRSize; /*A very hard-coded, but functional, heteroskedastic approach*/
  hedvar[l] = rand("uniform", -l/20, l/20);          
end;
call sort (out1, {1});
if &hedskat = 1 & &nomods = 0 then do;
  out1[,1] = out1[,1] + hedvar;
  create mlrhed from out1[c={&ContSpec}];
    append from out1;
  close mlrhed;
end;

/*INDEPENDENT HETEROSKEDASTIC DATA (Experimental)*/
if &hedskat = 1 & &indind = 1 & &nomods = 0 then do;
  indmaker = hetind || out1;
  call sort(indmaker, {1});
  indout = indmaker[,2:4];
    create mlrhedind from indout[c={&ContSpec}];
    append from indout;
  close mlrhedind;
end;
quit;
%mend;

%datamaker(&ContSpec, &Covar, &nRows, &SLrsize, &evar, &outcount, &betam, &betac, &nomods, &hedskat, &indind, &mixdat);
*Correlation/Assumption Code, replace with appropriate model(s); 

proc reg data = mlrout;
  model y = x1 x2;
run;
proc reg data = mlrnorm;
  model y = x1 x2;
run;
proc reg data = mlrmixed;
  model y = x1 x2 c1 c2;
run;
proc reg data = mlrhed;
  model y = x1 x2;
run;
proc corr data = mlrhed;
  var x1 x2;
run;

/*INDEPENDENCE TESTING done with durbin watson*/
*proc autoreg data= mlrnorm; /*This should never be violated*/
*   title "Harrison Fringer";
*   model y = / dw = 1 dwprob;
*run;
*proc autoreg data= mlrhed; /*Given data order, independence is clearly violated*/
*   title "Harrison Fringer";
*   model y = / dw = 1 dwprob;
*run;
*proc autoreg data = mlrhedind; /*This should result in fail to reject most of (if not all of) the time*/
*  model y = / dw = 1 dwprob;
*run;


/* Appending Macro code */
/*
  This macro is designed to append multiple files and 
  it uses three parameters:
    1. Outlib: Library for storing final data set. 
         Default value: Work
    2. OutDS: Name of final data set.
         No default value.
    3. DSlist: List of source data sets to be appended.
         No default value.
*/

%macro slrappend(outlib = work, 
                 outDS=,          
                 DSlist=
                );

  /*Check if output data already exists. If so, delete it.*/
  %if %sysfunc(exist(&outlib..&outds)) %then %do;
    proc datasets library = &outlib;
        delete &outds;
      run;
    quit;
  %end; *conditinal data deletion;

  /*Create final data set*/

  *Determine the first data set from the list;
  %let w = 1;
  %let dset = %scan(&dslist,&w," ");
  
  *Loop until no more data sets can be read from list;
  %do %until (&dset = ); *is this text string null;
    proc append base = &outlib..&outDS 
                data = &dset;
    run;

    *Increment to next data set in list;
    %let w = %sysevalf(&w + 1);
    %let dset = %scan(&dslist,&w," ");
  %end; *append loop;
%mend slrappend;

quit;

/* Appending data sets using Appending Macro */
/*This iteration of the combined dataset requires running the IML twice, notably changing the value of nomods from 0 to 1*/
%slrappend(outDS = full, DSlist = MLRMIXED MLRHED MLRHEDIND MLRNORM MLROUT)
/*The generated warnings are non-problematic, as these datasets are expected to have no value for C1/C2*/
