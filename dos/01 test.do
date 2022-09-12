capture log close
log using "C:\Users\WB585318\OneDrive - Universidad de los Andes\Personal\IPA test\dos/01 test.txt", replace text
/*==================================================
project:       STATA Test Senior Associate IPA Colombia
Author:        Angela Lopez 
E-email:       ar.lopez@uniandes.edu.co
url:           
Dependencies:  
----------------------------------------------------
Creation Date:    12 Sep 2022 - 11:16:46
Modification Date:   
Do-file version:    01
References:          
Output:             
==================================================*/

/*==================================================
              0: Program set up
==================================================*/
version 17
drop _all

global path "C:\Users\WB585318\OneDrive - Universidad de los Andes\Personal\IPA test"  // change the path to run the program 
global data "$path\data"
global do   "$path\dos"
global outcome "$path\outcome"

/*==================================================
              1: Reconciliation 
==================================================*/


use "$data\1.2. hh_nr_round1.dta", clear


*----------1.1: spliting nr crop variable and generating variables for each crop in the format of the main base 
* here, I am assuming: 1. each answer matches with the number of crop provided in the intructions. 2. Sorghum is only produced in the NR 3.-111 corresponds to nonresponce/other crops. Im coding it as crop_l9.


split crop_l, p("")

forvalues i = 1/7 {
	destring crop_l`i', replace 
	
	forvalues prod = 1/9 {
	cap gen cropl_`prod' = 	crop_l`i'==`prod'
	}
	replace cropl_9 = 1 if crop_l`i'==-111
	
}
cap drop crop_l1-crop_l7 cropl_8 crop_l

save "$data\1.2. hh_nr_round11.dta", replace 

*----------1.2: joining the two data sets 

use "$data\1.1. hh_round1.dta", clear
joinby using  "$data\1.2. hh_nr_round11.dta", unmatched(both)

save "$outcome\1.hh_round1_complete.dta", replace /// saved the new dataset in the outcome folder

/*==================================================
              2: String Matching
==================================================*/

use "$data\1.3. hh_round1_cand.dta", clear

*----------2.1: Create a dataset with the results 
preserve				
	tempfile tablas
	tempname ptablas
	postfile `ptablas' str100(Village Candidate Candidate_lb Party Party_lb Choice) Value using `tablas', replace

gen total =1
*** separating the cadidates name from the party they belong to	
split first_choice_cand, parse("(")
split first_choice_cand2, parse(")")	

split second_choice_cand, parse("(")
split second_choice_cand2, parse(")")


* correcting typos according to mayority and cadidate coherence in both choices 

replace first_choice_cand21 ="CDP" if first_choice_cand21== "BDP"
replace first_choice_cand21 ="NPD" if first_choice_cand21== "NPPD"
replace first_choice_cand21 ="SLPP" if first_choice_cand21== "SLP"
replace second_choice_cand21 ="SLPP" if second_choice_cand21== "SLP"
replace second_choice_cand21 ="C4C" if second_choice_cand21== "C4D"

* encoding 
encode first_choice_cand1 , g(first)
encode second_choice_cand1 , g(second)
encode first_choice_cand21 , g(first_party)
encode second_choice_cand21 , g(second_party)



forvalues v = 1/10 {
	forvalues c = 1/46 {
		
		sum first if first==`c' & village==`v'
		local value = r(sum_w)
		sum first_party if first==`c' & village==`v'
		local numerador = r(max)
		qui include "$do\02. formats.do"  // for formating 
		post `ptablas' ("`v'") ("`c'") ("`name'") ("`numerador'") ("`party'") ("first") (`value') 
			
    }
}

forvalues v = 1/10 {
	forvalues c = 1/47 {
		
		sum second if second==`c' & village==`v'
		local value = r(sum_w)
		sum second_party if second==`c' & village==`v'
		local numerador = r(mean)
		qui include "$do\02. formats.do" // for formating 
		post `ptablas' ("`v'") ("`c'") ("`name'") ("`numerador'") ("`party'") ("Second") (`value') 
			
    }
}

postclose `ptablas'
use `tablas', clear
save `tablas', replace
drop if Value ==0 

export excel using "${outcome}/02.String Matching.xlsx", sh("results", replace)  firstrow(var)

restore

*----------2.2: Outcomes
*** in the excel sheet in the folder output you can find the responses for each question of the task 

/*==================================================
              3: Back Check Randomization
==================================================*/

use "$data\1.1. hh_round1.dta", clear

g total =1 

by village head_gender, sort: egen count_sa = count(total)
g percentage = count_sa*0.1

set seed 123
gen rand_num = uniform()
sort village head_gender rand_num


	    
	forvalues v ==1/10 {
		forvalues s ==1/2 {	
	cap gen rand_num_aux = .
	replace rand_num_aux = sum(total) if village==`v' & head_gender==`s'
	cap gen random_benefiario = . 
	replace random_benefiario =  rand_num_aux <= percentage if village==`v' & head_gender==`s'
	}
	}


keep if random_benefiario ==1
save "$outcome\3.Back Check Randomization.dta", replace /// saved the new dataset in the outcome folder


log close
exit
/* End of do-file */

><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><

Notes:
1.
2.
3.


Version Control:


