*______________________________________________________________________
*Data Management in Stata
*Kate Cruz, Fall 2017
*Problem Set 5 due: November 28 
*Stata Version 15/IC 


/* For Problem Set 5 I began to work on my final project by organizing and simpliying my exisiting work. 
I also began to see a clearer picture about the impact of environment (food access, poverty) on health in NJ emerge through descriptive statistics. 

yes, descripive stats is great for that!
______________________________________________________________________

great to talk about this upfront:

Research questions include the following: 
1- Does inaccces to healthy food impact behavior and mental health?
2- Does increased green space decrease poverty and mental health ?
3- Who is most impacted by pollution (by race, gender, income)? 
4- Do counties with higher pollution experience worse health outcomes (physical and mental)? 
______________________________________________________________________

and great to cite data, either here or when you load it!

My completed dataset includes data from the following sources: 
1- NJ County Health Rankings Data (http://www.countyhealthrankings.org/rankings/data/nj)
2- New Jersey Behavioral Risk Factor Survey, Center for Health Statistics, New Jersey Department of Health Statistics, New Jersey State Health Assessment Data (NJSHAD) (http://nj.gov/health/shad) 
3- U.S. Census Bureau, 2016 American Community Survey 1-Year Estimates
4- Center for Disease Control and Prevention. Environmental Public Health Tracking Network. Acute Toxic Substance Releases (www.cdc.gov/ephtracking) note: I would love to have data from 2015 since most of my other datasets are from this year but this was the most recent I could find. This would be good to research further. 
5- EPA Outdoor Air Quality Report (https://www.epa.gov/outdoor-air-quality-data/air-quality-statistics-report)
6- Food Access and Research Center (FARC) and it is County SNAP (food stamp) usage from 2011-2015 and simply shows the use of the Supplemental Nutrition Assistance Program. 
7- U.S. Census Bureau population counts by County for 2010-2016 (https://factfinder.census.gov/faces/tableservices/jsf/pages/productview.xhtml?src=bkmk) 

Note: Regions are defined as North, Central and South as defined by the State of New Jersey http://www.state.nj.us/transportation/about/directory/images/regionmapc150.gif
*/ 

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                
								
								        1
										
								CLEANING DATASETS  
				   Loop, Drop, rename, Keep, Destring, Generate, Replace
			 
								
								
<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/ 
local worDir "/tmp/"
capture mkdir ps5 
cd ps5

//-----------------------------------------------------------------------------

//PART 1: NJ County Health Rankings Data 
//Loop 
loc gooPre "https://docs.google.com/uc?id="
loc gooSuf "&export=download"
loc goohealth= "`gooPre'"+"0B1opnkI-LLCiZFZKbzhlOFN4Sm8"+"`gooSuf'"
di "`goohealth'" 
import excel "`goohealth'", clear

//Drop 
drop D H L P W AA AE AR BF BK CA CF CK CL CT DC DM DC EG EM ER E I M Q S X AB AK AL AF AX AQ AW BF BG BK BL CA CB CF CG CK CM CT CU DC DD DM DN DX DY EG EH EM EN ER ES Y AU AY BH CZ EO AZ-BB BV BW BX CE-CH CJ EA EB EJ-EL EP EQ ET
drop in 1/2

//Rename 
rename (A-AO) (County deaths yearslost zyearslost perfairpoorhealth zfairpoor puhdays zpuhdays muhdays zmuhdays lowbirth livebirth perlowbirth persmoke zsmoke perobese zobese foodindex zfood perinactive zinactive perwaccess zwaccess)
rename (AP-BZ) (perdrink zdrink aldrivedeath peraldrivedeath teenbirth teenpop teenbirthrate uninsured peruninsured zuninsured PCP PCPrate zPCP dentist dentistrate zdentist MHproviders MHPrate medicaidenrolled prevhosprate)
rename (CC-DG) (zprevhosprate diabetics zmedicareenrolled cohortsize gradrate zgradrate somecollege population persomecollege zsomecollege unemployed laborforce perunemployed childpov perchildpov zchildpov eightyincome twentyincome)
rename (DH-EI) (incomeratio zincome singleparent households persingleparent zhouseholds associations associationrate zassociations violentcrimerate zviolentcrime violentcrime injurydeath injurydeathrate zinjurydeath violation zviolation severeproblems persevereproblems zsevereproblems)  

//ok the above may work and be correct, but much better:
preserve
import excel  "`goohealth'", clear firstr
d //now you bhave some names already :) and dont have to rename
//not only easier but also less mistake prone!

restore

//Recode & Create Program //Separated each county into region and created a program to use throughout datasets 
cap program drop kate1
program define kate1
//Recode- region variables 
generate region=0
//region==0 means north region==1 means south 
replace region=1 if County=="Burlington" | County=="Camden" | County=="Gloucester" | County=="Salem" | County=="Cumberland" | County=="Atlantic" | County=="Cape May" 
//region==2 means central
replace region=2 if County=="Hunterdon" | County=="Somerset" | County=="Middlesex" | County=="Monmouth" | County=="Ocean" | County=="Mercer" 
recode region (0/1=0 Non-Central) (1.1/2=1 Central), gen(region_2) //this allowed me to create a new level of comaprison looking at Central NJ in particular 
end
kate1 
drop in 22/23 
//AGAIN this may work but better be mistake prone less and create a bullet proof rule like:
drop if County==""

//Destring 
destring households region deaths yearslost zyearslost perfairpoorhealth zfairpoor puhdays zpuhdays muhdays zmuhdays lowbirth livebirth perlowbirth persmoke zsmoke perobese zobese foodindex zfood perinactive zinactive perwaccess zwaccess perdrink zdrink aldrivedeath peraldrivedeath teenbirth teenpop teenbirthrate uninsured peruninsured zuninsured PCP PCPrate zPCP dentist dentistrate zdentist MHproviders MHPrate medicaidenrolled prevhosprate zprevhosprate diabetics zmedicareenrolled, replace
destring cohortsize gradrate zgradrate somecollege population persomecollege zsomecollege unemployed laborforce perunemployed childpov perchildpov zchildpov eightyincome twentyincome incomeratio zincome singleparent households persingleparent zhouseholds associations associationrate zassociations violentcrime violentcrimerate zviolentcrime injurydeath injurydeathrate zinjurydeath violation zviolation severeproblems persevereproblems zsevereproblems, replace
//can just say 
destring *,replace

//violations for regressions- because violations would not destring because the obersvations were "yes" and "no" I created a new variable and assigned numeric values 
ta violation,mi //first check if any missings
generate violations_r=0
replace violations_r=1 if violation=="Yes"
move violations_r violation
save health_ps5, replace 

//------------------------------------------------------------------------------

//PART 2: NJ Behavioral Health Risk Factor Survey  
//Loop 
loc gooPre "https://docs.google.com/uc?id="
loc gooSuf "&export=download"
loc gooBH= "`gooPre'"+"0B1opnkI-LLCiWk1BYUc3R3FFWkE"+"`gooSuf'"
di "`gooBH'" 
import excel "`gooBH'", clear

//Rename 
rename (A-E) (County Countyid responses samplesize perstressdays)  

//Drop
drop F G 
drop Countyid
drop in 1/11 
drop in 22/66 

//Destring
destring responses, gen(responses_n)
destring samplesize, gen(samplesize_n)
destring perstressdays, gen(perstressdays_n) 

//Recode
kate1  

save behealth_ps5, replace 
//------------------------------------------------------------------------------

//PART 3: 2016 U.S. Census American Community Survey 1-Year Estimates 
//Loop 
loc gooPre "https://docs.google.com/uc?id="
loc gooSuf "&export=download"
loc goocensus= "`gooPre'"+"0B1opnkI-LLCiZHRMT3BWNEZjNW8"+"`gooSuf'"
di "`goocensus'" 
import excel "`goocensus'", clear //again as earlier cna use option firstr

//Keep
keep C D H J L N P R T V AR AJ AB AN AP CB CD EN EP GZ HB IH IF JF LD LF QB QD QF QH QN QP RD RF RL RN 

//Rename
rename (C-AB)(County households families perfamilies familieswchildren perfamilieswchildren marcouplefam permarcouplefam marcouplewchildren permarcouplewchildren singledad) 
rename (AJ-LD) (singlemom nonfamily pernonfamily livealone children perchildren givebirthpastyr pergivebirthpastyr inschool perinschool nodiploma pernodiploma perhsabove samehouse)
rename (LF-RN) (persamehouse englishonly perenglishonly notenglish pernotenglish spanish perspanish api perapi otherlang perotherlang) 

//Replace 
foreach c in "Atlantic" "Bergen" "Burlington" "Camden" "Cape May" "Cumberland" "Essex" "Gloucester" "Hudson" "Hunterdon" "Mercer" "Middlesex" "Monmouth" "Morris" "Ocean" "Passaic" "Salem" "Somerset" "Sussex" "Union" "Warren" {
replace County = "`c'"  if County == "`c' County, New Jersey"
}
//Drop
drop in 1/4

//Destring
destring households families perfamilies familieswchildren perfamilieswchildren marcouplefam permarcouplefam marcouplewchildren permarcouplewchildren livealone singlemom singledad nonfamily, replace 
destring pernonfamily children perchildren givebirthpastyr pergivebirthpastyr inschool perinschool nodiploma pernodiploma perhsabove samehouse persamehouse englishonly perenglishonly, replace 
destring notenglish pernotenglish spanish perspanish api perapi otherlang perotherlang, replace 

//Recode
kate1
save census16_ps5, replace 

//------------------------------------------------------------------------------

//PART 4: Center for Disease Control and Prevention: Acute Toxic Substance Releases 
//Loop 
loc gooPre "https://docs.google.com/uc?id="
loc gooSuf "&export=download"
loc gootoxic= "`gooPre'"+"0B1opnkI-LLCianducmRLbl84dzQ"+"`gooSuf'"
di "`gootoxic'" 
import excel "`gootoxic'", clear 

//Drop
drop A B C E G 

//Rename 
rename (D-F) (County Value) 

//Recode
kate1 

save toxic_ps5, replace  //btw can save these without ps5 string--i imagine that 
//it will be very similar for ifnal project too 
//------------------------------------------------------------------------------
 
//PART 5: EPA Outdoor Air Quality Report
//Loop
loc gooPre "https://docs.google.com/uc?id=" //btw make these into global macro
//at the beginning so you donthave to repeat them over and over again
//or make them into a program like kate1
loc gooSuf "&export=download"
loc gooEPA= "`gooPre'"+"0B1opnkI-LLCic1lHUUxUZHhvZGs"+"`gooSuf'"
di "`gooEPA'" 
import excel "`gooEPA'", firstrow clear 

//Drop
drop CountyCode  

//Replace 
foreach c in "Atlantic" "Bergen" "Burlington" "Camden" "Cape May" "Cumberland" "Essex" "Gloucester" "Hudson" "Hunterdon" "Mercer" "Middlesex" "Monmouth" "Morris" "Ocean" "Passaic" "Salem" "Somerset" "Sussex" "Union" "Warren" {
replace County = "`c'"  if County == "`c' County, NJ"
}

//Recode
kate1 
move region County 

save EPAair_ps5, replace 
//------------------------------------------------------------------------------

//PART 6: Food Access and Research Center: SNAP Usage 
//Loop
loc gooPre "https://docs.google.com/uc?id="
loc gooSuf "&export=download"
loc gooSNAP= "`gooPre'"+"0B1opnkI-LLCicWZRS3c2MFhianM"+"`gooSuf'"
di "`gooSNAP'" 
import excel "`gooSNAP'", firstrow clear

//Replace 
foreach c in "Atlantic" "Bergen" "Burlington" "Camden" "Cape May" "Cumberland" "Essex" "Gloucester" "Hudson" "Hunterdon" "Mercer" "Middlesex" "Monmouth" "Morris" "Ocean" "Passaic" "Salem" "Somerset" "Sussex" "Union" "Warren" {
replace County = "`c'"  if County == "`c' County"
}

//Drop 
drop State MetroSmallTownRuralStatus PercentMarginofError

//Recode
kate1
move region County 

save SNAP_ps5, replace 

//------------------------------------------------------------------------------

//PART 7: U.S. Census Bureau population counts by County for 2010-2016
//Loop
loc gooPre "https://docs.google.com/uc?id="
loc gooSuf "&export=download"
loc goocensus2010= "`gooPre'"+"0B1opnkI-LLCiV2tGMjhfTTZjWkE"+"`gooSuf'"
di "`goocensus2010'" 
import excel "`goocensus2010'", firstrow clear

//Drop
drop GEOid GEOid2 rescen42010 resbase42010 
drop in 1/1

//Rename
rename GEOdisplaylabel County

//Replace 
foreach c in "Atlantic" "Bergen" "Burlington" "Camden" "Cape May" "Cumberland" "Essex" "Gloucester" "Hudson" "Hunterdon" "Mercer" "Middlesex" "Monmouth" "Morris" "Ocean" "Passaic" "Salem" "Somerset" "Sussex" "Union" "Warren" {
replace County = "`c'"  if County == "`c' County, New Jersey"
}

//Recode
kate1
move region County 

save census2010_ps5, replace 
//------------------------------------------------------------------------------
 

 
/*<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                              
							      2
								 
							   MERGING  
							  
							  
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/ 
use health_ps5
merge 1:1 County using behealth_ps5
save kate_ps5, replace 

use kate_ps5
drop _merge 
merge 1:1 County using census16_ps5
save kate_ps5, replace 

use kate_ps5 
drop _merge
merge 1:1 County using toxic_ps5
save kate_ps5, replace 


use kate_ps5
drop _merge
merge 1:1 County using EPAair_ps5
drop in 6 
//the merge creates a new County observation that throws off the data so I deleted it 
save kate_ps5, replace 
//note: EPA air quality data is only for 17 counties, therefore 5 do not match 

use kate_ps5
drop _merge 
merge 1:1 County using SNAP_ps5
save kate_ps5, replace 

use kate_ps5
drop _merge
merge 1:1 County using census2010_ps5
save kate_ps5, replace 
//------------------------------------------------------------------------------


/*<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

                                     3
							Descriptive Statistics  
                          Egen, Collapse, Macro, Loop   
								   
								   
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/ 
//you do nj only but can do whole country! stats likes big numbers!

//Egen
egen unhealthy=rowmean(muhdays puhdays) //I combined mental and physical health to create a measurement of overall poor health or "unhealthy" based on the means pulled by this code I see that Atlantic, Hudson, Ocean and Salem have the poorest overall health (with Camden following right behind) 
move unhealthy deaths 

egen av_deaths=mean(deaths), by(region) // this code produced the mean number of deaths for each region and shows that Central NJ has the largest average of deaths 
move av_deaths deaths 

egen singlemomdad=rowmean(singledad singlemom) //combining the count of single mom and single dads from the 2016 census 
move singlemomdad deaths 

bys region: egen avgStress=mean(perstressdays_n) //shows the average percentage of stressful days per county. South Jersey has the highest average (15%), Central Jersey (10%) and North (9%) 
move avgStress deaths 

save, replace //dont use save replace, rather save as sth new; or move this up to right after merge and then save

//Collapse 
collapse childpov, by(region) //North Jersey has the largest population of children in poverty(20,441) followed by Central (13,627)and South Jersey (9,824)
clear
use kate_ps5
collapse perchildpov, by(region) //When accounting for population size South Jersey has the highest rate of child poverty (18.7%), North Jersey with 15.7 and Central with 11.8 
clear 
use kate_ps5
collapse muhdays, by(region) //There is not a lot of variation, however South Jersey (1) has the highest rate of mentally unhealthy days at 3.6% while North Jersey (0)has 3.3 and Central (2) is 3.2 
clear
use kate_ps5
collapse PercentwithSNAP, by(region) //South Jersey (1) has the highest percent of food stamp usage (.1%) followed by North (.09)and then Central (.05).  
clear
use kate_ps5
collapse unhealthy, by(region) // North Jersey has by far the largest number of single parents (8,267) while Central has 5,643 and South has 4,588 this could be due to population size
clear 

//Loops
use kate_ps5 ,clear
foreach v of varlist perchildpov nodiploma persevereproblems violentcrime muhdays puhdays{
 ta `v', p
}
/*I learned that the most common percentage of physically unhealthy days was 3.7 and 2.9
Similarly I found that mentally unhealthy days were most commonly reported at 3.2, 3.6 and 3.7 days 
19 percent was the most common for severe housing problems and 11% for child poverty*/  
 
//Scatterplots 
 //scatterplot graph of health and food access by County
foreach v of varlist foodindex {

  scatter `v' perfairpoorhe, mlab(County)
 
gr export `v'.pdf
}
//what we see is a correlation between access to healthy food and health- the higher the food access the lower the level of poor health 

//to better understand the relationship between food access and mentally unhealthy days 
foreach v of varlist foodindex {

scatter `v' unhealthy, mlab(County)

gr export `v'.pdf 
}
//the better access to food, the less mentally unhealthy days 

foreach v of varlist foodindex {

scatter `v' avgStress, mlab(County)

gr export `v'.pdf
}
//there does seem to be some correlation between stress level and access to food - high stress areas also have low food index scores 

//Bar Graphs 
//bar graph of the percentage of poor and fair health by County- this makes it very easy to compare quickly  
hist perfairpoorhe, freq
gr hbar perfairpoorhe, over(County, sort(perfairpoorhe))
//Hudson has the poorest reported levels of health with Cumberland following right behind 

//bar graph of the percentage of obesity by County 
hist perobese, freq
gr hbar perobese, over(County, sort(perobese)) 
//the highest rate of obesity is Cumberland County. I am seeing a pattern that Cumberland County scores very low in health rankings and has many social issues. 

hist avgStress, freq
gr hbar avgStress, over(County, sort(avgStress)) 
//helpful for displaying stress levels in order of lowest to highest: South being highest, Central and then North  

//-----------------------------------------------------------------------------

/*<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

                                4
								
                       GRAPHS & REGRESSIONS 
						 outreg2, estout 
								   
								   
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/ 

twoway (scatter foodindex yearslost), ytitle(Loss of Life (in years)) xtitle(Food Index (Access to Food)) title(Food Access and Loss of Life) //as access to food increases, life expectancy increases 
graph save Graph "C:\Users\kathr\Documents\DataManagement\yearslost_food.gph", replace
//just save in current directory; as opposed to having lengthy ugly path for each

twoway (scatter perlowbirth foodindex), ytitle(Percentage of Low Birth Rates) xtitle(Food Index (Access to Food)) title(Food Access and Low Birth Rates) //higher percetange of low birth rates in areas with lower food access 
graph save Graph "C:\Users\kathr\Documents\DataManagement\lowbirth_food.gph", replace 

graph bar avgStress, over(region)
graph save Graph "C:\Users\kathr\Documents\DataManagement\stressbyregion.gph"

twoway (scatter perobese PercentwithSNAP), ytitle(Obesity) xtitle(SNAP Use (percentage)) title(Obesity and Poverty) subtitle(SNAP Usage and Rates of Obesity) //not sure if this is a great correlation but it does seem to me that rates of obesity are higher with higher SNAP usage
graph save Graph "C:\Users\kathr\Documents\DataManagement\obesitypoverty.gph"

twoway (scatter yearslost perobese), ytitle(Obesitty (percentage)) xtitle(Years of Life Lost) title(Obesity and Loss of Life) //clear correlation between obesity and loss of life, because SNAP beneficiaries are also more likely to be obese, they are at risk of greater loss of life as well. 
graph save Graph "C:\Users\kathr\Documents\DataManagement\obesityyearslost.gph" 

graph hbar foodindex unhealthy, over(County, sort(unhealthy)) //Cape May and Passaic Counties are outliers in the sense that they have moderate levels of unhealthy but low food access, otherwise it is clear that in areas of low food access, health declines 

/* Correlations & Regressions 
DV: health, obesity, stress, poverty, race, gender 
IV:food access
*/

corr foodindex  unhealthy 
/* Results show a strong, negative correlation. As food inaccess increases, physical and mental health decreases 
            | foodin~x unheal~y
-------------+------------------
   foodindex |   1.0000
   unhealthy |  -0.8317   1.0000
*/ 

reg  unhealthy foodindex
outreg2 using reg1.xls,  bdec(2) st(coef) excel replace ct(A1)  lab
/* Results show that for every increase in food access there is a .4 decrease in mental or physical illness (unhealthy)  

      Source |       SS           df       MS      Number of obs   =        21
-------------+----------------------------------   F(1, 19)        =     42.62
       Model |  1.87606443         1  1.87606443   Prob > F        =    0.0000
    Residual |  .836316729        19   .04401667   R-squared       =    0.6917
-------------+----------------------------------   Adj R-squared   =    0.6754
       Total |  2.71238116        20  .135619058   Root MSE        =     .2098

------------------------------------------------------------------------------
   unhealthy |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
-------------+----------------------------------------------------------------
   foodindex |  -.4104105   .0628642    -6.53   0.000    -.5419867   -.2788342
       _cons |   6.659186     .51185    13.01   0.000     5.587871      7.7305
------------------------------------------------------------------------------
*/

reg  unhealthy foodindex PercentwithSNAP  
outreg2 using reg1.xls,  bdec(2) st(coef) excel append ct(A2)  lab
//follow examples from https://stats.idre.ucla.edu/stata/webbooks/reg/

/*Results show that food access alone does not determine health. When taking SNAP 
usage or poverty into account, for each increase in food access there is a decrease 
of only .2 in mental/physical health. For each increase in the percentage of 
SNAP usage, there is an increase of physical and mental illness of 4. 


      Source |       SS           df       MS      Number of obs   =        21
-------------+----------------------------------   F(2, 18)        =     58.75
       Model |  2.35206312         2  1.17603156   Prob > F        =    0.0000
    Residual |  .360318037        18  .020017669   R-squared       =    0.8672
-------------+----------------------------------   Adj R-squared   =    0.8524
       Total |  2.71238116        20  .135619058   Root MSE        =    .14148

---------------------------------------------------------------------------------
      unhealthy |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
----------------+----------------------------------------------------------------
      foodindex |  -.2030731   .0600423    -3.38   0.003    -.3292173    -.076929
PercentwithSNAP |   4.621678   .9477714     4.88   0.000     2.630485    6.612872
          _cons |   4.563711   .5511864     8.28   0.000     3.405711    5.721711
---------------------------------------------------------------------------------
*/ 	
/*<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

                                5
								
                              SUMMARY 
				  Prelimiarly discussion of findings 
								   
								   
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/

/*At this stage in my research I can see that my data confirms popular research 
about food access and health. While food access is just one of the compounding 
variables that impact a person's health (physical and mental) this is important
to look into more closely. Initial regressions show that access to food does not
mean the same for people in poverty as opposed to the general population. For
those on foodstamps, food access only improves their health at half the rate. 
And those who utilize food stamps have increased physical and mental illness. 
When looking at New Jersey at the county level it is clear that South Jersey 
(while smaller in population) does face a substantial burden in terms of social 
ills. Stress levels are high, food insecurity, child poverty,obesity, loss of 
life are all increased for counties such as Cumberland, Salem, Ocean and Atlantic.
Important to note, the data shows that food inaccess can lead to decreased life 
expectancy, low birth rates, and lower rates of health. In areas with higher 
usage of SNAP benefits there does seem to be higher rates of obesity. The data 
shows that obesity is stronly correlated to decreased life expectancy. Therefore 
it is important to think about how this places an unfair burden on people of low 
incomes who rely on food stamps and see higher rates of obesity. There are many 
social programs in place such as cooking classes but the question remains- are 
they working and what else can be done to counter these negative health outcomes?
I will continue to look into how this data intersects with race and if time 
permits- pollution. */ 

