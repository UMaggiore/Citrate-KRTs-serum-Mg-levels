clear
********************************************************************************
*# START PREPARING DATASET FOR ANALYSES
********************************************************************************
clear
cd "C:\Documenti\Regolisti\IpoMg"
import excel "DB DEF Maggiore_Mg KRT_100126.xlsx", sheet("Table 2") firstrow
drop M-P
drop if missing(id)
drop Q-S
sort id n_time
save mg_long, replace


clear
import excel "C:\Documenti\Regolisti\IpoMg\DB for revision 100726.xlsx", sheet("Foglio1") firstrow clear
sort id
cap save data_for_revision, replace
clear


clear
import excel "DB DEF Maggiore_Mg KRT_100126.xlsx", sheet("Table 1") firstrow
drop if missing(id)
sort id
destring sex, replace force
recode VM (2=1)

merge 1:1 id using "data_for_revision"
tab _merge
drop _merge



* ==============================================================================
* VARIABLE AND VALUE LABELS - CORRECTED VERSION
* ==============================================================================

* KRT - Kidney replacement therapy
label var KRT "Kidney replacement therapy"
label define KRTlbl 0 "SLED-f-f" 1 "CVVHDF" 2 "CVVH"
label values KRT KRTlbl

* ID and demographics
label var id "ID code"
label var age "Age, years"
label var sex "Sex"
label define sexlbl 1 "Male" 0 "Female"
label values sex sexlbl

* Severity scores
label var apache_ii "APACHE II score"

* Mechanical ventilation
label var VM "Mechanical ventilation"
label define VMlbl 1 "Invasive or uninvasive MV" 0 "No MV"
label values VM VMlbl
label var VMdays "Days on MV"

* Vasopressors
label var vasopressors "Vasopressors use"
label define yesnolbl 1 "Yes" 0 "No"
label values vasopressors yesnolbl

* Comorbidities
label var sepsis "Sepsis"
label values sepsis yesnolbl

label var diabetes "Diabetes"
label values diabetes yesnolbl

label var hypertension "Hypertension"
label values hypertension yesnolbl

label var copd "Chronic obstructive lung disease"
label values copd yesnolbl

label var cad "Coronary artery disease"
label values cad yesnolbl

label var chf "Cardiac heart failure"
label values chf yesnolbl

label var aop "Peripheral artery disease"
label values aop yesnolbl

* Liver disease
label var liver "Liver disease"
recode liver (2=1)
label define liverlbl 0 "No" 1 "Yes"
label values liver liverlbl

* CKD
label var ckd "Chronic kidney disease type"
label define ckdlbl 0 "No" 1 "Yes, conservative" 2 "PD or HD"
label values ckd ckdlbl

label var ckd_comb  "Chonic kidney disease type"
label define ckd_comblbl 0 "No" 1 "Conservative or Transient HD" 2 "PD or HD"
label values ckd_comb ckd_comblbl

label var ckd_cons "CKD on conservative treatment"
label values ckd_cons yesnolbl

label var ckd_hd "CKD on chronic hemodialysis"
label values ckd_hd yesnolbl

* Nutrition
label var nutrition "Nutrition"
label define nutritionlbl 0 "Oral feeding" 1 "Enteral nutrition" 2 "Parenteral nutrition"
label values nutrition nutritionlbl

* Laboratory values - baseline
label var na_base "Na, mmol/L"
label var k_base "K, mmol/L"
label var ca_base "Ca, mg/dL"
label var p_base "Phosphate, mg/dL"
label var mg_base "Mg, mg/dL"
label var hco3_base "HCO3, mmol/L"

* Mg supplementation
label var mgsuppl_base "Mg supplementation, g/day"

* Dialysis parameters
label var deliver_dd "Delivered dialysis dose, ml/Kg/h"

* Citrate parameters
label var citratemia_base "Serum citrate concentration, mmol/L"
label var citrate_dose "Citrate dose, mmol/h"
label var targetcitratehemofilter_pw "Target citrate hemofilter, mmol/h"
label var estim_citrateload "Metabolic citrate load, mmol/h"

* Outcomes
label var outcome_pz "Patient outcome"
label define outcome_pzlbl 1 "Death" 0 "Survived"
label values outcome_pz outcome_pzlbl

label var outcome_kidney "Kidney outcome"
label define outcome_kidneylbl 0 "No recovery" 1 "Complete recovery" 2 "Incomplete recovery" 3 "Not applicable"
label values outcome_kidney outcome_kidneylbl

save mg_cros, replace
clear
use mg_cros
merge 1:m id using mg_long
tab _merge

encode id, gen(ID)
tsset ID n_time
xtdes


gen hypoMg = mg_start <= 1.7
tab hypoMg

label var hypoMg "Hypomagnesemia (>= 1.7mg/dL)" 
label values hypoMg yesnolbl



egen any_hypoMg = sum(hypoMg), by(ID)
replace any_hypoMg = 1 if any_hypoMg > 0 & any_hypoMg < .

label var any_hypoMg "Any hypognasemia during stay"
label values any_hypoMg yesnolbl

label var mg_start "Mg before KRT" 
label var mg_postKRT "Mg after KRT" 
label var mg_suppl_dicotom "Mg supplementation"
label values mg_suppl_dicotom yesnolbl
label var mg_supplem "Mg supplementation, gr"

format t_start t_stop %td

* Convert to calendar date components, add 100 years, reconvert
gen year_start = year(t_start)
gen month_start = month(t_start)
gen day_start = day(t_start)

gen year_stop = year(t_stop)
gen month_stop = month(t_stop)
gen day_stop = day(t_stop)

* Add 100 years
replace year_start = year_start + 100
replace year_stop = year_stop + 100

* Recreate dates
replace t_start = mdy(month_start, day_start, year_start)
replace t_stop = mdy(month_stop, day_stop, year_stop)

* Drop temporary variables
drop year_start month_start day_start year_stop month_stop day_stop

* Format
format t_start t_stop %td

sort t_start
bysort id (t_start): replace t_stop = t_stop + 1 if id == "29_PIEANG" & _n == _N


stset t_stop, fail(death == 1) origin(t_start) id(ID)

save mg_merged, replace


********************************************************************************
*# END PREPARING DATASET FOR ANALYSES
********************************************************************************





********************************************************************************
**# START TABLE 1
********************************************************************************
clear
cd "C:\Documenti\Regolisti\IpoMg"
use mg_merged

bysort id (t_start): keep if _n == 1

unab all_vars : _all
di "`all_vars'"



dtable age i.sex apache_ii i.VM VMdays i.vasopressors i.sepsis i.hypertension ///
 i.diabetes i.copd i.cad i.chf i.aop i.liver i.ckd i.ckd_cons i.ckd_hd i.ckd_comb ///
 i.nutrition na_base k_base ca_base p_base mg_base mgsuppl_base mg_start ///
 i.mg_suppl_dicotom mg_supplem i.hypoMg i.any_hypoMg mg_postKRT hco3_base ///
 deliver_dd citratemia_base citrate_dose targetcitratehemofilter_pw ///
 estim_citrateload ///
 i.outcome_pz i.outcome_kidney   ///
	, ///	
	by(KRT, tests) ///	
	define(meansd = mean sd, delimiter(" ± ")) ///
	define(myiqr = p25 p75, delimiter("-")) ///
	define(myrange = min max, delimiter("-")) ///
	factor(sex VM vasopressors sepsis hypertension ///
	diabetes copd cad chf aop liver ckd ckd_cons ckd_hd ckd_comb ///
	nutrition   ///
    mg_suppl_dicotom hypoMg any_hypoMg  ///
	outcome_pz outcome_kidney , test(fisher)) ///
    continuous(age apache_ii ///
	na_base k_base ca_base p_base mg_base mg_start mg_supplem mgsuppl_base mg_postKRT hco3_base ///
	deliver_dd citratemia_base citrate_dose targetcitratehemofilter_pw ///
    estim_citrateload ///
	, stat(meansd) test(kwallis)) ///
   continuous(VMdays  ///
	, stat(median myrange) test(kwallis)) /// 
	column(by(hide) test(p-value)) ///
	title(Table 1. Characteristics of the KRT groups at the first day of treatment and outcome) ///
	note(Kruskal-Wallis test for continuous variables (reported as mean ± standard deviation or median (min - max)).) ///
    note(Fisher's exact test for categorical variables (reported as number (percentage)).) ///
	note(Baseline characteristics of the study population) ///
	note(HD, Hemodialysis: KRT, Kidney replacement therapy; MV, Mechanical ventilation: PD, peritoneal dialysis) ///
	sformat("%s" sd) ///
	nformat("%3.1f" mean sd median p25 p75) ///
	nformat("%3.1f" min max) ///
	sformat("(%s)" myiqr myrange) ///
    nformat("%3.0f" N count fvfrequency) ///
    nformat("%3.1f" fvpercent ) ///
    nformat("%6.3f" kwallis fisher) ///
	export(table1.html, replace)
collect export table 1.xlsx, replace
collect export table 1.docx, replace
collect export table 1.txt, replace
collect export table 1.html, replace


*°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
* Additional data for Table 1



clear
cd "C:\Documenti\Regolisti\IpoMg"
use mg_merged

bysort id (t_start): keep if _n == 1

unab all_vars : _all
di "`all_vars'"

gen severe_hypoalbunemia = albumin < 2.5
tab severe_hypoalbunemia

dtable  weight albumin i.severe_hypoalbunemia i.PPI i.GIlosses Mgintake pHa pO2 pCO2 HCO3 fiO2 lattati  ///
	, ///	
	by(KRT, tests) ///	
	define(meansd = mean sd, delimiter(" ± ")) ///
	define(myiqr = p25 p75, delimiter("-")) ///
	define(myrange = min max, delimiter("-")) ///
	factor(PPI GIlosses , test(fisher)) ///
    continuous(weight albumin  Mgintake pHa  pCO2 HCO3 fiO2  ///
	, stat(meansd) test(kwallis)) ///
   continuous(pO2 fiO2 lattati  ///
	, stat(median myrange) test(kwallis)) /// 
	column(by(hide) test(p-value)) ///
	title(Table 1. Characteristics of the KRT groups at the first day of treatment and outcome) ///
	note(Kruskal-Wallis test for continuous variables (reported as mean ± standard deviation or median (min - max)).) ///
    note(Fisher's exact test for categorical variables (reported as number (percentage)).) ///
	note(Baseline characteristics of the study population) ///
	note(HD, Hemodialysis: KRT, Kidney replacement therapy; MV, Mechanical ventilation: PD, peritoneal dialysis) ///
	sformat("%s" sd) ///
	nformat("%3.1f" mean sd median p25 p75) ///
	nformat("%3.1f" min max) ///
	sformat("(%s)" myiqr myrange) ///
    nformat("%3.0f" N count fvfrequency) ///
    nformat("%3.1f" fvpercent ) ///
    nformat("%6.3f" kwallis fisher) ///
	export(table_for_r1.html, replace)
collect export table r1.xlsx, replace
collect export table r1.docx, replace
collect export table r1.txt, replace
collect export table r1.html, replace



* ==============================================================================
* DEFINE VARIABLE LISTS FOR PAIRWISE COMPARISONS
* ==============================================================================

* CONTINUOUS VARIABLES (from your dtable)
local continuous_vars "age apache_ii VMdays na_base k_base ca_base p_base mg_base mgsuppl_base mg_start mg_supplem mg_postKRT hco3_base deliver_dd albumin citratemia_base citrate_dose targetcitratehemofilter_pw estim_citrateload"

* CATEGORICAL VARIABLES (from your dtable)
local categorical_vars "sex VM vasopressors sepsis hypertension diabetes copd cad chf aop liver ckd ckd_cons ckd_hd ckd_comb nutrition mg_suppl_dicotom hypoMg any_hypoMg outcome_pz outcome_kidney"




* ==============================================================================
* PAIRWISE COMPARISONS FOR VARIABLES WITH P < 0.05
* ==============================================================================

* Close file handle if already open
capture file close pw

* Open file for writing
file open pw using "pairwise_comparisons.txt", write replace
file write pw "PAIRWISE COMPARISONS FOR VARIABLES WITH P < 0.05" _n
file write pw "================================================================================" _n _n

* ==============================================================================
* CONTINUOUS VARIABLES
* ==============================================================================

file write pw "CONTINUOUS VARIABLES" _n
file write pw "--------------------------------------------------------------------------------" _n _n

foreach var of local continuous_vars {
    
    capture confirm variable `var'
    if _rc continue
    
    * Check data in all 3 groups
    quietly count if KRT == 0 & !missing(`var')
    local n0 = r(N)
    quietly count if KRT == 1 & !missing(`var')
    local n1 = r(N)
    quietly count if KRT == 2 & !missing(`var')
    local n2 = r(N)
    
    if `n0' == 0 | `n1' == 0 | `n2' == 0 {
        continue
    }
    
    * Run Kruskal-Wallis
    capture quietly kwallis `var', by(KRT)
    if _rc continue
    
    * Calculate p-value from chi2_adj (adjusted for ties)
    if !missing(r(chi2_adj)) & !missing(r(df)) {
        local p_kw = chi2tail(r(df), r(chi2_adj))
    }
    else if !missing(r(chi2)) & !missing(r(df)) {
        local p_kw = chi2tail(r(df), r(chi2))
    }
    else {
        continue
    }
    
    * If p < 0.05, perform pairwise comparisons
    if `p_kw' < 0.05 {
        
        * Get variable label (if exists)
        local varlabel : variable label `var'
        if "`varlabel'" == "" {
            local varlabel "`var'"
        }
        
        file write pw "Variable: `varlabel' (`var')" _n
        file write pw "Overall Kruskal-Wallis P-value: " %6.4f (`p_kw') _n _n
        
        * SLED-f (0) vs CVVHDF (1)
        capture quietly ranksum `var' if inlist(KRT, 0, 1), by(KRT)
        if !_rc {
            local p_0v1 = 2*normprob(-abs(r(z)))
            file write pw "  SLED-f-f vs CVVHDF:  P = " %6.4f (`p_0v1')
            if `p_0v1' < 0.05 file write pw " *"
            file write pw _n
        }
        
        * SLED-f (0) vs CVVH (2)
        capture quietly ranksum `var' if inlist(KRT, 0, 2), by(KRT)
        if !_rc {
            local p_0v2 = 2*normprob(-abs(r(z)))
            file write pw "  SLED-f-f vs CVVH: P = " %6.4f (`p_0v2')
            if `p_0v2' < 0.05 file write pw " *"
            file write pw _n
        }
        
        * CVVHDF (1) vs CVVH (2)
        capture quietly ranksum `var' if inlist(KRT, 1, 2), by(KRT)
        if !_rc {
            local p_1v2 = 2*normprob(-abs(r(z)))
            file write pw "  CVVHDF vs CVVH:  P = " %6.4f (`p_1v2')
            if `p_1v2' < 0.05 file write pw " *"
            file write pw _n
        }
        
        file write pw _n
    }
}

* ==============================================================================
* CATEGORICAL VARIABLES
* ==============================================================================

file write pw _n _n
file write pw "CATEGORICAL VARIABLES" _n
file write pw "--------------------------------------------------------------------------------" _n _n

foreach var of local categorical_vars {
    
    capture confirm variable `var'
    if _rc continue
    
    capture tab `var' KRT, exact
    if _rc | missing(r(p_exact)) continue
    
    local p_fisher = r(p_exact)
    
    if `p_fisher' < 0.05 {
        
        * Get variable label (if exists)
        local varlabel : variable label `var'
        if "`varlabel'" == "" {
            local varlabel "`var'"
        }
        
        file write pw "Variable: `varlabel' (`var')" _n
        file write pw "Overall Fisher's exact P-value: " %6.4f (`p_fisher') _n _n
        
        * SLED-f (0) vs CVVHDF (1)
        capture tab `var' KRT if inlist(KRT, 0, 1), exact
        if !_rc & !missing(r(p_exact)) {
            local p_0v1 = r(p_exact)
            file write pw "  SLED-f-f vs CVVHDF:  P = " %6.4f (`p_0v1')
            if `p_0v1' < 0.05 file write pw " *"
            file write pw _n
        }
        else {
            file write pw "  SLED-f-f vs CVVHDF:  Test failed" _n
        }
        
        * SLED-f (0) vs CVVH (2)
        capture tab `var' KRT if inlist(KRT, 0, 2), exact
        if !_rc & !missing(r(p_exact)) {
            local p_0v2 = r(p_exact)
            file write pw "  SLED-f vs CVVH: P = " %6.4f (`p_0v2')
            if `p_0v2' < 0.05 file write pw " *"
            file write pw _n
        }
        else {
            file write pw "  SLED-f vs CVVH: Test failed" _n
        }
        
        * CVVHDF (1) vs CVVH (2)
        capture tab `var' KRT if inlist(KRT, 1, 2), exact
        if !_rc & !missing(r(p_exact)) {
            local p_1v2 = r(p_exact)
            file write pw "  CVVHDF vs CVVH:  P = " %6.4f (`p_1v2')
            if `p_1v2' < 0.05 file write pw " *"
            file write pw _n
        }
        else {
            file write pw "  CVVHDF vs CVVH:  Test failed" _n
        }
        
        file write pw _n
    }
}

* ==============================================================================
* CLOSE FILE AND DISPLAY
* ==============================================================================

file write pw _n "================================================================================" _n
file write pw "* indicates P < 0.05" _n
file close pw

* Display completion message
di _newline(2)
di "{hline 80}"
di "PAIRWISE COMPARISONS COMPLETE"
di "{hline 80}"
di "Results saved to: pairwise_comparisons.txt"
di ""
di "To view results:"
di "  type pairwise_comparisons.txt"
di "{hline 80}"

* Display file content in Stata
type pairwise_comparisons.txt


* ==============================================================================
* AFTER YOUR DTABLE COMMANDS
* ==============================================================================

* Define variable lists
local continuous_vars "age apache_ii VMdays na_base k_base ca_base p_base mg_base mgsuppl_base mg_start mg_supplem mg_postKRT hco3_base deliver_dd albumin citratemia_base citrate_dose targetcitratehemofilter_pw estim_citrateload"

local categorical_vars "sex VM vasopressors sepsis hypertension diabetes copd cad chf aop liver ckd ckd_cons ckd_hd ckd_comb nutrition mg_suppl_dicotom hypoMg any_hypoMg outcome_pz outcome_kidney"

* ==============================================================================
* CREATE RESULTS DATASET USING TEMPFILE
* ==============================================================================

* Create temporary file
tempfile results

* Initialize results dataset
preserve
clear
set obs 100
gen str50 variable = ""
gen str80 var_label = ""
gen str20 var_type = ""
gen p_overall = .
gen p_SLED_vs_CVVHDF = .
gen p_SLED_vs_CVVH = .
gen p_CVVHDF_vs_CVVH = .
gen str5 sig_overall = ""
gen str5 sig_01 = ""
gen str5 sig_02 = ""
gen str5 sig_12 = ""
save `results', replace
restore

* ==============================================================================
* RUN PAIRWISE COMPARISONS
* ==============================================================================

local row = 1

* CONTINUOUS VARIABLES
foreach var of local continuous_vars {
    
    capture confirm variable `var'
    if _rc continue
    
    * Check data in all 3 groups
    quietly count if KRT == 0 & !missing(`var')
    local n0 = r(N)
    quietly count if KRT == 1 & !missing(`var')
    local n1 = r(N)
    quietly count if KRT == 2 & !missing(`var')
    local n2 = r(N)
    
    if `n0' == 0 | `n1' == 0 | `n2' == 0 continue
    
    * Kruskal-Wallis test
    capture quietly kwallis `var', by(KRT)
    if _rc continue
    
    * Calculate p-value
    if !missing(r(chi2_adj)) & !missing(r(df)) {
        local p_kw = chi2tail(r(df), r(chi2_adj))
    }
    else if !missing(r(chi2)) & !missing(r(df)) {
        local p_kw = chi2tail(r(df), r(chi2))
    }
    else {
        continue
    }
    
    * Only proceed if p < 0.05
    if `p_kw' < 0.05 {
        
        * Get variable label
        local varlabel : variable label `var'
        if "`varlabel'" == "" local varlabel "`var'"
        
        * SLED-f vs CVVHDF
        capture quietly ranksum `var' if inlist(KRT, 0, 1), by(KRT)
        if !_rc {
            local p_01 = 2*normprob(-abs(r(z)))
        }
        else {
            local p_01 = .
        }
        
        * SLED-f vs CVVH
        capture quietly ranksum `var' if inlist(KRT, 0, 2), by(KRT)
        if !_rc {
            local p_02 = 2*normprob(-abs(r(z)))
        }
        else {
            local p_02 = .
        }
        
        * CVVHDF vs CVVH
        capture quietly ranksum `var' if inlist(KRT, 1, 2), by(KRT)
        if !_rc {
            local p_12 = 2*normprob(-abs(r(z)))
        }
        else {
            local p_12 = .
        }
        
        * Save to results dataset
        preserve
        use `results', clear
        replace variable = "`var'" in `row'
        replace var_label = "`varlabel'" in `row'
        replace var_type = "Continuous" in `row'
        replace p_overall = `p_kw' in `row'
        replace sig_overall = "*" in `row'
        replace p_SLED_vs_CVVHDF = `p_01' in `row'
        replace sig_01 = cond(`p_01' < 0.05 & !missing(`p_01'), "*", "") in `row'
        replace p_SLED_vs_CVVH = `p_02' in `row'
        replace sig_02 = cond(`p_02' < 0.05 & !missing(`p_02'), "*", "") in `row'
        replace p_CVVHDF_vs_CVVH = `p_12' in `row'
        replace sig_12 = cond(`p_12' < 0.05 & !missing(`p_12'), "*", "") in `row'
        save `results', replace
        restore
        
        local ++row
    }
}

* CATEGORICAL VARIABLES
foreach var of local categorical_vars {
    
    capture confirm variable `var'
    if _rc continue
    
    * Fisher's exact test
    capture tab `var' KRT, exact
    if _rc | missing(r(p_exact)) continue
    
    local p_fisher = r(p_exact)
    
    if `p_fisher' < 0.05 {
        
        * Get variable label
        local varlabel : variable label `var'
        if "`varlabel'" == "" local varlabel "`var'"
        
        * SLED-f vs CVVHDF
        capture tab `var' KRT if inlist(KRT, 0, 1), exact
        if !_rc & !missing(r(p_exact)) {
            local p_01 = r(p_exact)
        }
        else {
            local p_01 = .
        }
        
        * SLED-f vs CVVH
        capture tab `var' KRT if inlist(KRT, 0, 2), exact
        if !_rc & !missing(r(p_exact)) {
            local p_02 = r(p_exact)
        }
        else {
            local p_02 = .
        }
        
        * CVVHDF vs CVVH
        capture tab `var' KRT if inlist(KRT, 1, 2), exact
        if !_rc & !missing(r(p_exact)) {
            local p_12 = r(p_exact)
        }
        else {
            local p_12 = .
        }
        
        * Save to results dataset
        preserve
        use `results', clear
        replace variable = "`var'" in `row'
        replace var_label = "`varlabel'" in `row'
        replace var_type = "Categorical" in `row'
        replace p_overall = `p_fisher' in `row'
        replace sig_overall = "*" in `row'
        replace p_SLED_vs_CVVHDF = `p_01' in `row'
        replace sig_01 = cond(`p_01' < 0.05 & !missing(`p_01'), "*", "") in `row'
        replace p_SLED_vs_CVVH = `p_02' in `row'
        replace sig_02 = cond(`p_02' < 0.05 & !missing(`p_02'), "*", "") in `row'
        replace p_CVVHDF_vs_CVVH = `p_12' in `row'
        replace sig_12 = cond(`p_12' < 0.05 & !missing(`p_12'), "*", "") in `row'
        save `results', replace
        restore
        
        local ++row
    }
}

* ==============================================================================
* LOAD AND EXPORT RESULTS
* ==============================================================================

preserve
use `results', clear

* Keep only rows with data
keep if !missing(variable)

* Format p-values
format p_* %6.4f

* Order variables
order variable var_label var_type p_overall sig_overall ///
      p_SLED_vs_CVVHDF sig_01 p_SLED_vs_CVVH sig_02 p_CVVHDF_vs_CVVH sig_12

* Display
di _newline(2)
di "{hline 120}"
di "PAIRWISE COMPARISONS - RESULTS TABLE"
di "{hline 120}"
list, separator(0) abbreviate(20) noobs

* Export to Excel
export excel using "alb_pairwise_comparisons_table.xlsx", firstrow(variables) replace

* Export to CSV  
export delimited using "alb_pairwise_comparisons_table.csv", replace

* Save as Stata dataset
save "pairwise_comparisons_results.dta", replace

di _newline(2)
di "{hline 120}"
di "RESULTS EXPORTED TO:"
di "  - pairwise_comparisons_table.xlsx"
di "  - pairwise_comparisons_table.csv"
di "  - pairwise_comparisons_results.dta"
di "{hline 120}"

restore


* ==============================================================================
* CREATE COLLECT TABLE DIRECTLY FROM ANALYSIS
* ==============================================================================

* Make sure you're in the original dataset
* use mg_merged, clear
* bysort id (t_start): keep if _n == 1

* Define variable lists
local continuous_vars "age apache_ii VMdays na_base k_base ca_base p_base mg_base mgsuppl_base mg_start mg_supplem mg_postKRT hco3_base deliver_dd albumin citratemia_base citrate_dose targetcitratehemofilter_pw estim_citrateload"

local categorical_vars "sex VM vasopressors sepsis hypertension diabetes copd cad chf aop liver ckd ckd_cons ckd_hd ckd_comb nutrition mg_suppl_dicotom hypoMg any_hypoMg outcome_pz outcome_kidney"

* Clear any existing collection
collect clear
collect create pairwise_direct

local row = 1

* CONTINUOUS VARIABLES
foreach var of local continuous_vars {
    
    capture confirm variable `var'
    if _rc continue
    
    * Check data
    quietly count if KRT == 0 & !missing(`var')
    local n0 = r(N)
    quietly count if KRT == 1 & !missing(`var')
    local n1 = r(N)
    quietly count if KRT == 2 & !missing(`var')
    local n2 = r(N)
    
    if `n0' == 0 | `n1' == 0 | `n2' == 0 continue
    
    * Kruskal-Wallis
    capture quietly kwallis `var', by(KRT)
    if _rc continue
    
    if !missing(r(chi2_adj)) & !missing(r(df)) {
        local p_kw = chi2tail(r(df), r(chi2_adj))
    }
    else if !missing(r(chi2)) & !missing(r(df)) {
        local p_kw = chi2tail(r(df), r(chi2))
    }
    else {
        continue
    }
    
    if `p_kw' < 0.05 {
        
        * Get label
        local varlabel : variable label `var'
        if "`varlabel'" == "" local varlabel "`var'"
        
        * Pairwise tests
        capture quietly ranksum `var' if inlist(KRT, 0, 1), by(KRT)
        if !_rc local p_01 = 2*normprob(-abs(r(z)))
        else local p_01 = .
        
        capture quietly ranksum `var' if inlist(KRT, 0, 2), by(KRT)
        if !_rc local p_02 = 2*normprob(-abs(r(z)))
        else local p_02 = .
        
        capture quietly ranksum `var' if inlist(KRT, 1, 2), by(KRT)
        if !_rc local p_12 = 2*normprob(-abs(r(z)))
        else local p_12 = .
        
        * Add to collection
        collect label levels varname `row' "`varlabel'", modify
        
        collect get overall_p = `p_kw', tag(varname[`row'] test[overall])
        collect get p01 = `p_01', tag(varname[`row'] test[SLED_cvvhdf]) 
        collect get p02 = `p_02', tag(varname[`row'] test[SLED_cvvh])
        collect get p12 = `p_12', tag(varname[`row'] test[cvvhdf_cvvh])
        
        local ++row
    }
}

* CATEGORICAL VARIABLES
foreach var of local categorical_vars {
    
    capture confirm variable `var'
    if _rc continue
    
    capture tab `var' KRT, exact
    if _rc | missing(r(p_exact)) continue
    
    local p_fisher = r(p_exact)
    
    if `p_fisher' < 0.05 {
        
        * Get label
        local varlabel : variable label `var'
        if "`varlabel'" == "" local varlabel "`var'"
        
        * Pairwise tests
        capture tab `var' KRT if inlist(KRT, 0, 1), exact
        if !_rc & !missing(r(p_exact)) local p_01 = r(p_exact)
        else local p_01 = .
        
        capture tab `var' KRT if inlist(KRT, 0, 2), exact
        if !_rc & !missing(r(p_exact)) local p_02 = r(p_exact)
        else local p_02 = .
        
        capture tab `var' KRT if inlist(KRT, 1, 2), exact
        if !_rc & !missing(r(p_exact)) local p_12 = r(p_exact)
        else local p_12 = .
        
        * Add to collection
        collect label levels varname `row' "`varlabel'", modify
        
        collect get overall_p = `p_fisher', tag(varname[`row'] test[overall])
        collect get p01 = `p_01', tag(varname[`row'] test[SLED_cvvhdf])
        collect get p02 = `p_02', tag(varname[`row'] test[SLED_cvvh])
        collect get p12 = `p_12', tag(varname[`row'] test[cvvhdf_cvvh])
        
        local ++row
    }
}

* Label test levels
collect label levels test overall "Overall P" ///
                          SLED_cvvhdf "SLED-f vs CVVHDF" ///
                          SLED_cvvh "SLED-f vs CVVH" ///
                          cvvhd_cvvhdf "CVVHDF vs CVVH", modify

* Format
collect style cell, nformat(%6.4f)
collect style header result, level(hide)

* Layout
collect layout (varname) (test)

* Preview
collect preview

* Export
collect export "alb_pairwise_collect_direct.html", replace
collect export "alb_pairwise_collect_direct.docx", replace
collect export "alb_pairwise_collect_direct.xlsx", replace

di _newline "Collect tables exported successfully!"

* ==============================================================================
* CREATE COLLECT TABLE WITH P<0.001 FORMATTING
* ==============================================================================

use "pairwise_comparisons_results.dta", clear

* Clear any existing collection
collect clear
collect create pairwise_formatted

* ==============================================================================
* Add data to collection with formatted p-values
* ==============================================================================

quietly count
local nrows = r(N)

forvalues i = 1/`nrows' {
    
    * Get variable info
    local var = variable[`i']
    local label = var_label[`i']
    local type = var_type[`i']
    
    * Format p-values with <0.001 where appropriate
    
    * Overall p-value
    local p_ov = p_overall[`i']
    if `p_ov' < 0.001 {
        local p_ov_str "<0.001"
    }
    else {
        local p_ov_str = string(`p_ov', "%6.4f")
    }
    
    * SLED-f vs CVVHDF
    if !missing(p_SLED_vs_CVVHDF[`i']) {
        local p_01 = p_SLED_vs_CVVHDF[`i']
        if `p_01' < 0.001 {
            local p_01_str "<0.001"
        }
        else {
            local p_01_str = string(`p_01', "%6.4f")
        }
        local sig_01 = sig_01[`i']
        if "`sig_01'" == "*" local p_01_str "`p_01_str' *"
    }
    else {
        local p_01_str "-"
    }
    
    * SLED-f vs CVVHF
    if !missing(p_SLED_vs_CVVH[`i']) {
        local p_02 = p_SLED_vs_CVVH[`i']
        if `p_02' < 0.001 {
            local p_02_str "<0.001"
        }
        else {
            local p_02_str = string(`p_02', "%6.4f")
        }
        local sig_02 = sig_02[`i']
        if "`sig_02'" == "*" local p_02_str "`p_02_str' *"
    }
    else {
        local p_02_str "-"
    }
    
    * CVVHDF vs CVVH
    if !missing(p_CVVHDF_vs_CVVH[`i']) {
        local p_12 = p_CVVHDF_vs_CVVH[`i']
        if `p_12' < 0.001 {
            local p_12_str "<0.001"
        }
        else {
            local p_12_str = string(`p_12', "%6.4f")
        }
        local sig_12 = sig_12[`i']
        if "`sig_12'" == "*" local p_12_str "`p_12_str' *"
    }
    else {
        local p_12_str "-"
    }
    
    * Create row in collection
    collect label levels rowname `i' "`label' (`type')", modify
    collect label levels colname 1 "Overall", modify
    collect label levels colname 2 "SLED-f vs CVVHDF", modify
    collect label levels colname 3 "SLED-f vs CVVH", modify
    collect label levels colname 4 "CVVHDF vs CVVH", modify
    
    * Add string values to collection
    collect get pval = "`p_ov_str'", tag(rowname[`i'] colname[1])
    collect get pval = "`p_01_str'", tag(rowname[`i'] colname[2])
    collect get pval = "`p_02_str'", tag(rowname[`i'] colname[3])
    collect get pval = "`p_12_str'", tag(rowname[`i'] colname[4])
}

* Layout
collect layout (rowname) (colname)

* Style
collect style header result, level(hide)
collect style cell, halign(center)
collect style row stack, spacer

* Title
collect title "Pairwise Comparisons of KRT Groups (P-values)"

* Preview
collect preview

* Export
collect export "alb_pairwise_collect_formatted.html", replace
collect export "alb_pairwise_collect_formatted.docx", replace
collect export "alb_pairwise_collect_formatted.xlsx", replace

di _newline(2)
di "{hline 80}"
di "FORMATTED COLLECT TABLE CREATED"
di "{hline 80}"
di "Files exported:"
di "  - pairwise_collect_formatted.html"
di "  - pairwise_collect_formatted.docx"
di "  - pairwise_collect_formatted.xlsx"
di "{hline 80}"


********************************************************************************
**# END TABLE 1
********************************************************************************


********************************************************************************
**# START CHECK Mg SUPPLEMENTATION
********************************************************************************


clear
cd "C:\Documenti\Regolisti\IpoMg"
use mg_merged
bysort id (t_start): keep if _n == 1

dtable ///
 i.mg_suppl_dicotom  ///
	, ///	
	by(KRT, tests) ///	
	define(meansd = mean sd, delimiter(" ± ")) ///
	define(myiqr = p25 p75, delimiter("-")) ///
	define(myrange = min max, delimiter("-")) ///
	factor(mg_suppl_dicotom, test(fisher)) ///
	column(by(hide) test(p-value)) ///
	title(Table 1. Characteristics of the KRT groups at the first day of treatment and outcome) ///
	note(Kruskal-Wallis test for continuous variables (reported as mean ± standard deviation or median (min - max)).) ///
    note(Fisher's exact test for categorical variables (reported as number (percentage)).) ///
	note(Baseline characteristics of the study population) ///
	note(HD, Hemodialysis: KRT, Kidney replacement therapy; MV, Mechanical ventilation: PD, peritoneal dialysis) ///
	sformat("%s" sd) ///
	nformat("%3.1f" mean sd median p25 p75) ///
	nformat("%3.1f" min max) ///
	sformat("(%s)" myiqr myrange) ///
    nformat("%3.0f" N count fvfrequency) ///
    nformat("%3.1f" fvpercent ) ///
    nformat("%6.3f" kwallis fisher) 
	
	
clear
cd "C:\Documenti\Regolisti\IpoMg"
use mg_merged

sort ID n_time
xtset ID n_time
xttab mg_suppl_dicotom
bysort KRT: xttab mg_suppl_dicotom

********************************************************************************
**# END  CHECK Mg SUPPLEMENTATION
********************************************************************************




********************************************************************************
**# START COX REGRESSION ANALYSIS
********************************************************************************



clear
cd "C:\Documenti\Regolisti\IpoMg"
use mg_merged


stcox mg_start

cap drop y
gen y = -7.5
cap drop mg_start_jitter
set seed 123
cap drop u
gen u = (0.5 - uniform()) / 10
gen mg_start_jitter = mg_start + u
fracpoly: stcox mg_start
test Img_s__1  + Img_s__2 = 0
local apval = string(`r(p)', "%4.3f")
fracplot mg_start, ///
	msymbol(i) lineopts(lpattern(solid)) ciopts(fcolor(black%20) color(white)) ///
	scheme(s1mono) ytitle("log(HR)") ///
	ylab(-10.0(5.0)20.0, grid angle(horizontal) format(%3.2f)) ///
	xtitle("Serum Mg (mg/dL)") xlab(1(0.5)4, format(%3.1f)) xline(1.7, lpattern(dash) lcolor(gs10%30)) xsc(titlegap(2)) ///
	title("") subtitle("") ///
	note("Cox regression, unadjusted; Mg fitted via fractional polynomial" " ", size(*0.7)) ///
	text(15 2.3 "Test for a zero (flat) relationship: P = `apval'") ///
	addplot(scatter y mg_start_jitter, msymbol(pipe) msize(*2) legend(off)) ///
	name(mg_cox_unadjusted, replace)
	
	
cap drop krt*
tab KRT, gen(krt)
cap drop NUTR
tab nutrition, gen(NUTR)
cap drop y
gen y = -7.5
cap drop mg_start_jitter
set seed 123
cap drop u
gen u = (0.5 - uniform()) / 10
gen mg_start_jitter = mg_start + u
* ORIGINAL MODEL: 
fracpoly: stcox mg_start age apache_ii cad p_base mg_suppl_dicotom krt2 krt3 NUTR1 NUTR2 deliver_dd //  ok U shaped curve and P< 0.05
*MODEL WITH ALBUMIN
fracpoly: stcox mg_start age apache_ii cad p_base mg_suppl_dicotom krt2 krt3 NUTR1 NUTR2 deliver_dd albumin // ok U shaped curve and P < 0.05
*MODEL WITH NO ALBUMIN AND NO DELEVERED_DOSE
fracpoly: stcox mg_start age apache_ii cad p_base mg_suppl_dicotom krt2 krt3 NUTR1 NUTR2   // no deliver_dd albumin: ok U sghape curve
*MODEL WITH NO NUTR1 AND BUTR2
fracpoly: stcox mg_start age apache_ii cad p_base mg_suppl_dicotom krt2 krt3    // no NUTR1 NUTR2deliver_dd albumin: ok U shaped curve and P value almost ok (0.082)
*MODEL WITH NO KTR2 AND KTR2
fracpoly: stcox mg_start apache_ii age p_base mg_suppl_dicotom     // no krt2 krt3 NUTR1 NUTR2deliver_dd albumin: when you remove ktr2 and ktr3 curvature disapperas
*MODEL WITH KTR2 AND KTR2 BACK IN
fracpoly: stcox mg_start cad p_base mg_suppl_dicotom  krt2 krt3   // ok U shaped curve and P almosy ok (=.071)
*MODEL WITH P_BASE OUT
fracpoly: stcox mg_start cad  mg_suppl_dicotom  krt2 krt3   // when you remoce p_base U-shapedccurvature disapperars
*MODEL WITH CAD OUT
fracpoly: stcox mg_start p_base  mg_suppl_dicotom  krt2 krt3   // also when you remove cad U shaped curvature disapperars
*MODEL WITH A MINIMAL SET OF COVARIATES
fracpoly: stcox mg_start cad p_base mg_suppl_dicotom  krt2 krt3   // here itU shaped curve is of and P is almosy ok (=.071)
* ORIGINAL MODEL: 
fracpoly: stcox mg_start age apache_ii cad p_base mg_suppl_dicotom krt2 krt3 NUTR1 NUTR2 deliver_dd //  ok U shaped curve and P< 0.05
test Img_s__1  + Img_s__2 = 0
local apval = string(`r(p)', "%4.3f")
fracplot mg_start, ///
	msymbol(i) lineopts(lpattern(solid)) ciopts(fcolor(black%20) color(white)) ///
	scheme(s1mono) ytitle("log(HR)") ///
	ylab(-10.0(5.0)20.0, grid angle(horizontal) format(%3.2f)) ///
	xtitle("Serum Mg (mg/dL)") xlab(1(0.5)4, format(%3.1f))  xline(1.7, lpattern(dash) lcolor(gs10%30) ) xsc(titlegap(2)) ///
	title("") subtitle("") ///
	note("Cox regression, adjusted for covariates; Mg fitted via fractional polynomial" "Covariates: Baseline Serum Mg, phospate & Age, APACHE II, coronary artery dis.," "Suppl. Mg, KRT type, Delivered dose, Nutrition", size(*0.7)) ///
	text(15 2.3 "Test for a zero (flat) relationship: P = `apval'") ///
	addplot(scatter y mg_start_jitter, msymbol(pipe) msize(*2) legend(off)) ///
	name(mg_cox_adjusted, replace)
	
	
graph combine mg_cox_unadjusted mg_cox_adjusted, ycommon
graph export mg_cox_combined.png, replace



* Conversion to TIFF with integrated Python
python:
from PIL import Image

# Path of PNG exported from Stata
input_png = "mg_cox_combined.png"
output_tiff = "mg_cox_combined.tif"

# Open image and convert to RGB
img = Image.open(input_png).convert("RGB")

# Save as TIFF with 900 dpi
img.save(output_tiff, dpi=(900, 900), compression="tiff_deflate")

print("Completed coversion: mg_cox_combined.tif with 900 dpi")
end


lincom mg_suppl_dicotom, hr sformat(%4.3f) pformat(%3.2f) cformat(%3.2f)

********************************************************************************
**# END COX REGRESSION ANALYSIS
********************************************************************************


********************************************************************************
**# START MIXED MODEL ANALYSIS
********************************************************************************

clear
cd "C:\Documenti\Regolisti\IpoMg"
use mg_merged

* Sort data
sort ID n_time

* Initialize plot command
local plotcmd ""

* Loop over each individual
levelsof ID, local(ids)
foreach i of local ids {
    
    * Get the KRT category for this individual (should be constant within ID)
    quietly summarize KRT if ID == `i', meanonly
    local cat = r(mean)
    
    * Choose color based on category
    if `cat' == 0 {
        local color "stc1"  // SLED-f - blue
    }
    else if `cat' == 1 {
        local color "stc3"  // CVVHDF - green
    }
    else if `cat' == 2 {
        local color "stc2"  // CVVH - red
    }
    
    * Add line for this individual to the plot command
    local plotcmd `plotcmd' (line mg_start n_time if ID == `i', ///
        lcolor(`color'%30) lwidth(thin))
}

* Execute the combined plot
twoway `plotcmd', ///
    title("Mg Trajectories by KRT Group") ///
    ytitle("Mg at start (mg/dL)") ///
    xtitle("Time point") ///
    legend(off) ///
    name(spaghetti_plot, replace)

graph export "mg_trajectories_spaghetti.png", replace width(2000)


*-------------------------------------------------------------------------------
*# Crude Model 
*-------------------------------------------------------------------------------
mixed mg_start i.KRT#i.n_time || id: ID, reml dfmethod(kroger)
margins, at(n_time=(1 2 3 4) KRT =(0 1 2)) cformat(%3.2f) sformat(%3.2f) pformat(%4.3f) nopvalues saving(mg_margins_crude, replace) 
append using mg_margins_crude
two rcap _ci_ub _ci_lb _at2 if _at1 ==0 || ///
	rcap _ci_lb _ci_ub _at2 if _at1 ==1 || ///
	rcap _ci_lb _ci_ub _at2 if _at1 ==2 || ///
	line _margin _at2 if _at1==0,  lcolor(stc1) lwidth(*1.8) || ///
	line _margin _at2 if _at1==1 , lcolor(stc3) lwidth(*1.8)|| ///
	line _margin _at2 if _at1==2 , lcolor(stc2) lwidth(*1.8)|| ///
	scatter _margin _at2 if _at1==0 , msymbol(O) mcolor(stc1) || ///
	scatter _margin _at2 if _at1==1 , msymbol(O) mcolor(stc3) || ///
	scatter _margin _at2 if _at1==2 , msymbol(O) mcolor(stc2) || ///
	`plotcmd' ///
	, ///
	ytitle("Serum Mg{sub:2} (md/dl)") xtitle("KRT session") ///
	xsc(range(0.9 4.1)) ///
	title("") ylabel(0.5(0.5)4, format(%3.1f)) ysc(range(0.5 4)) ///
	yline(1.7, lcolor(gs10%30) lpattern(dash)) ///
	legend(order(1 "SLED-f" 2 "CVVHDF" 3 "CVVH") pos(6) row(1)) ///
	note("Mixed model, unadjuted analyis")
contrast  KRT@n_time, small effects pformat(%4.3f) sformat(%3.2f) cformat(%3.2f)


matrix c_mg = r(table)

********************************************************************************
**# START MIXED MODEL MEAN AND INDIVIDUAL TRAJECTORIES CRUDE
********************************************************************************


clear
cd "C:\Documenti\Regolisti\IpoMg"
use mg_merged

* Sort data
sort ID n_time

* Initialize plot command
local plotcmd ""

* Loop over each individual
levelsof ID, local(ids)
foreach i of local ids {
    
    * Get the KRT category for this individual (should be constant within ID)
    quietly summarize KRT if ID == `i', meanonly
    local cat = r(mean)
    
    * Choose color based on category
    if `cat' == 0 {
        local color "stc1"  // SLED-f - blue
    }
    else if `cat' == 1 {
        local color "stc3"  // CVVHDF - green
    }
    else if `cat' == 2 {
        local color "stc2"  // CVVH - red
    }
    
    * Add line for this individual to the plot command
    local plotcmd `plotcmd' (line mg_start n_time if ID == `i', ///
        lcolor(`color'%30) lwidth(thin))
}



*-------------------------------------------------------------------------------
*# Model and contrasts
*-------------------------------------------------------------------------------
mixed mg_start i.KRT##i.n_time || id: ID, reml dfmethod(kroger)

margins, at(n_time=(1 2 3 4) KRT=(0 1 2)) saving(mg_margins_crude, replace) 

contrast KRT@n_time, small effects cformat(%3.2f) sformat(%3.2f) pformat(%4.3f)
matrix contrasts = r(table)

*-------------------------------------------------------------------------------
*# Prepare margins
*-------------------------------------------------------------------------------
preserve
use mg_margins_crude, clear
rename _at2 n_time
rename _at1 KRT
keep KRT n_time _margin _ci_lb _ci_ub
tempfile margins_temp
save `margins_temp'
restore

merge m:1 KRT n_time using `margins_temp', keep(master match) nogenerate

*-------------------------------------------------------------------------------
*# Get positions for asterisks
*-------------------------------------------------------------------------------
quietly summarize _ci_ub if KRT == 0 & n_time == 3
local y3_red = r(max) + 0.15
local y3_green = r(max) + 0.30

quietly summarize _ci_ub if KRT == 0 & n_time == 4
local y4_red = r(max) + 0.15
local y4_green = r(max) + 0.30

*-------------------------------------------------------------------------------
*# Create plot with spaghetti
*-------------------------------------------------------------------------------

twoway ///
    (rcap _ci_ub _ci_lb n_time if KRT == 0, lcolor(stc1) lwidth(*1.5)) ///
    (rcap _ci_lb _ci_ub n_time if KRT == 1, lcolor(stc3) lwidth(*1.5)) ///
    (rcap _ci_lb _ci_ub n_time if KRT == 2, lcolor(stc2) lwidth(*1.5)) ///
    (connected _margin n_time if KRT == 0, lcolor(stc1) mcolor(stc1) lwidth(*2) msymbol(O) msize(*2)) ///
    (connected _margin n_time if KRT == 1, lcolor(stc3) mcolor(stc3) lwidth(*2) msymbol(O) msize(*2)) ///
    (connected _margin n_time if KRT == 2, lcolor(stc2) mcolor(stc2) lwidth(*2) msymbol(O) msize(*2)) ///
	`plotcmd' ///
    , ///
    ytitle("Serum Mg{subscript:2} (mg/dl)", size(*1.2)) ///
    xtitle("KRT session", size(*1.2)) ///
    xsc(range(0.9 4.1)) xlabel(1(1)4, labsize(*1.1)) ///
    ylabel(0.5(0.5)4, format(%3.1f) labsize(*1.1)) ysc(range(0.5 4.0)) ///
    yline(1.7, lcolor(gs8%40) lpattern(dash) lwidth(medium)) ///
    legend(order(7 "SLED-f" 8 "CVVHDF" 9 "CVVH") pos(6) row(1) size(medium)) ///
    text(`y3_red' 3 "{stSymbol:*}", color(stc2) size(*2)) ///
    text(`y3_green' 3 "{stSymbol:*}", color(stc3) size(*2)) ///
    text(`y4_red' 4 "{stSymbol:*}", color(stc2) size(*2)) ///
    text(`y4_green' 4 "{stSymbol:*}", color(stc3) size(*2)) ///
    plotregion(margin(medium)) graphregion(color(white)) ///
	legend(order(1 "SLED-f" 2 "CVVHDF" 3 "CVVH") pos(6) row(1)) ///
    caption("Mixed model, unadjusted analysis. *, P<0.05 at each time point" " ", size(*0.7) span) ///
	name(mg_trajectories_mean_crude, replace)
	

********************************************************************************
**# END MIXED MODEL MEAN AND INDIVIDUAL TRAJECTORIES CRUDE
********************************************************************************


********************************************************************************
**# START MIXED MODEL MEAN AND INDIVIDUAL TRAJECTORIES ADJUSTED
********************************************************************************

clear
cd "C:\Documenti\Regolisti\IpoMg"
use mg_merged

* Sort data
sort ID n_time

* Initialize plot command
local plotcmd ""

* Loop over each individual
levelsof ID, local(ids)
foreach i of local ids {
    
    * Get the KRT category for this individual (should be constant within ID)
    quietly summarize KRT if ID == `i', meanonly
    local cat = r(mean)
    
    * Choose color based on category
    if `cat' == 0 {
        local color "stc1"  // SLED-f - blue
    }
    else if `cat' == 1 {
        local color "stc3"  // CVVHDF - green
    }
    else if `cat' == 2 {
        local color "stc2"  // CVVH - red
    }
    
    * Add line for this individual to the plot command
    local plotcmd `plotcmd' (line mg_start n_time if ID == `i', ///
        lcolor(`color'%30) lwidth(thin))
}



*-------------------------------------------------------------------------------
*# Model and contrasts
*-------------------------------------------------------------------------------

global confounders "mg_base age apache_ii cad p_base mg_suppl_dicotom i.nutrition deliver_dd"

mixed mg_start i.KRT##i.n_time $confounders || id: ID, reml dfmethod(kroger)

margins, at(n_time=(1 2 3 4) KRT=(0 1 2)) saving(mg_margins_crude, replace) 

contrast KRT@n_time, small effects cformat(%3.2f) pformat(%4.3f) sformat(%3.2f)
matrix contrasts = r(table)

*-------------------------------------------------------------------------------
*# Prepare margins
*-------------------------------------------------------------------------------
preserve
use mg_margins_crude, clear
rename _at2 n_time
rename _at1 KRT
keep KRT n_time _margin _ci_lb _ci_ub
tempfile margins_temp
save `margins_temp'
restore

merge m:1 KRT n_time using `margins_temp', keep(master match) nogenerate

*-------------------------------------------------------------------------------
*# Get positions for asterisks
*-------------------------------------------------------------------------------
quietly summarize _ci_ub if KRT == 0 & n_time == 3
local y3_red = r(max) + 0.15
local y3_green = r(max) + 0.30

quietly summarize _ci_ub if KRT == 0 & n_time == 4
local y4_red = r(max) + 0.15
local y4_green = r(max) + 0.30

*-------------------------------------------------------------------------------
*# Create plot with spaghetti
*-------------------------------------------------------------------------------

twoway ///
    (rcap _ci_ub _ci_lb n_time if KRT == 0, lcolor(stc1) lwidth(*1.5)) ///
    (rcap _ci_lb _ci_ub n_time if KRT == 1, lcolor(stc3) lwidth(*1.5)) ///
    (rcap _ci_lb _ci_ub n_time if KRT == 2, lcolor(stc2) lwidth(*1.5)) ///
    (connected _margin n_time if KRT == 0, lcolor(stc1) mcolor(stc1) lwidth(*2) msymbol(O) msize(*2)) ///
    (connected _margin n_time if KRT == 1, lcolor(stc3) mcolor(stc3) lwidth(*2) msymbol(O) msize(*2)) ///
    (connected _margin n_time if KRT == 2, lcolor(stc2) mcolor(stc2) lwidth(*2) msymbol(O) msize(*2)) ///
	`plotcmd' ///
    , ///
    ytitle("Serum Mg{subscript:2} (mg/dl)", size(*1.2)) ///
    xtitle("KRT session", size(*1.2)) ///
    xsc(range(0.9 4.1)) xlabel(1(1)4, labsize(*1.1)) ///
    ylabel(0.5(0.5)4, format(%3.1f) labsize(*1.1)) ysc(range(0.5 4.0)) ///
    yline(1.7, lcolor(gs8%40) lpattern(dash) lwidth(medium)) ///
    legend(order(7 "SLED-f" 8 "CVVHDF" 9 "CVVH") pos(6) row(1) size(medium)) ///
    text(`y4_red' 4 "{stSymbol:*}", color(stc2) size(*2)) ///
    plotregion(margin(medium)) graphregion(color(white)) ///
	legend(order(1 "SLED-f" 2 "CVVHDF" 3 "CVVH") pos(6) row(1)) ///
    caption("Mixed model, adjusted analysis. *, P<0.05 at each time point" "Adjusted for baseline Mg, age, APACHE II, coronary heart disease," "phosphate, supplemental Mg, nutrition, delivered KRT dose", size(*0.7) span) ///
	name(alb_mg_traj_mean_adjusted, replace)
	
graph combine mg_trajectories_mean_crude mg_traj_mean_adjusted, ycommon
graph export mg_traj_mean_combined.png, replace
	


* Conversion to TIFF with integrated Python
python:
from PIL import Image

# Path of PNG exported from Stata
input_png = "mg_traj_mean_combined.png"
output_tiff = "mg_traj_mean_combined.tif"

# Open image and convert to RGB
img = Image.open(input_png).convert("RGB")

# Save as TIFF with 900 dpi
img.save(output_tiff, dpi=(900, 900), compression="tiff_deflate")

print("Completed coversion: mg_traj_mean_combined.tif with 900 dpi")
end

contrast  KRT@n_time, small effects pformat(%4.3f) sformat(%3.2f) cformat(%3.2f)

********************************************************************************
**# END MIXED MODEL MEAN AND INDIVIDUAL TRAJECTORIES ADJUSTED
********************************************************************************

********************************************************************************
**# START GEE HYPOMAGNESEMIA
********************************************************************************

clear
cd "C:\Documenti\Regolisti\IpoMg"
use mg_merged

global confounders "mg_base age apache_ii cad p_base mg_suppl_dicotom i.nutrition deliver_dd"


* Sort data
sort ID n_time


xtset ID n_time
xttab hypoMg
xttrans hypoMg 

xtgee hypoMg i.KRT, corr(exc) robust eform link(logit) family(binomial)


xtgee hypoMg i.KRT mg_base age apache_ii cad p_base mg_suppl_dicotom i.nutrition deliver_dd,  corr(exc) robust eform link(logit) family(binomial)




collect clear
collect create c1

collect, name(c1): quietly xtgee hypoMg i.KRT, corr(exc) robust eform link(logit) family(binomial)

qui collect layout (colname) (result[_r_b _r_ci _r_p])

collect create c2

collect, name(c2): xtgee hypoMg i.KRT mg_base age apache_ii cad p_base mg_suppl_dicotom i.nutrition deliver_dd,  corr(exc) robust eform link(logit) family(binomial)


qui collect layout (colname) (result[_r_b _r_ci _r_p])

collect combine c= c1 c2

qui collect layout (colname) (collection#result[_r_b _r_ci _r_p]) (), name(c)

collect label levels collection c1 "Unadjusted", modify

collect label levels collection c2 "Adjusted", modify

collect style column, nodelimiter dups(center)
collect style cell border_block, border(right, pattern(nil))
collect style cell result[_r_b], nformat(%3.2f)
collect style cell result[_r_ci], nformat(%3.2f) sformat("(%s)") cidelimiter(" to ")
collect style cell result[_r_p], nformat(%4.3f) minimum(0.001)
collect recode colname 1.KRT = "CVVHDF vs SLED-f"
collect recode colname 2.KRT = "CVVH vs SLED-f"




collect title "Table X. Odds Ratio of hypomagnesemia"
collect label levels result _r_b "OR", modify
collect label levels result _r_ci "95% CI", modify
collect label levels result _r_p "P value", modify
collect notes 1: "Generalized estimating equations for hypomagnesemia"
collect notes 2: "Adjusted, adjusted for: Baseline Mg, age, APACHE II, coronary artery disease, phosphate, Mg supplementation, nutrition, delivered dose" 
collect notes 3: "CI, confidence interval; OR, Odds ratio for hypomagnesemia"
collect layout (colname["CVVHDF vs SLED-f" "CVVH vs SLED-f"]) (collection#result[_r_b _r_ci _r_p]) (), name(c)

collect export "Table OR hypomagnesemia.xlsx", replace
collect export "Table OR hypomagnesemia.docx", replace
collect export "Table OR hypomagnesemia.html", replace




// at each time point
// GEE MV logit link Unadjusted model - Mg dichotomous
xtgee  hypoMg i.KRT##i.n_time , i(ID) robust link(logit) family(binomial) corr(ind) eform
margins, at(KRT = (0 1 2) n_time =(1 2 3 4)) cformat(%3.2f) sformat(%3.2f) pformat(%4.3f) saving(gee_hypomg_crude, replace)
contrast i.KRT@n_time,  effects cformat(%3.2f) sformat(%3.2f) pformat(%4.3f) eform


// at each time point
// GEE MV logit link Adjusted model - Mg dichotomous
xtgee  hypoMg i.KRT##i.n_time $confounders , i(ID) robust link(logit) family(binomial) corr(ind) eform
margins, at(KRT = (0 1 2) n_time =(1 2 3 4)) cformat(%3.2f) sformat(%3.2f) pformat(%4.3f) saving(gee_hypomg_adju, replace)
contrast i.KRT@n_time,  effects cformat(%3.2f) sformat(%3.2f) pformat(%4.3f)

preserve
clear
cd "C:\Documenti\Regolisti\IpoMg"
use gee_hypomg_crude
cap drop model
gen model = 0
append using gee_hypomg_adju
replace model = 1 if missing(model)
label define modellbl 0 "Unadjusted" 1 "Adjusted"
label values model modellbl
cap save gee_hypomg_combined, replace
restore


clear
cd "C:\Documenti\Regolisti\IpoMg"
use gee_hypomg_combined

twoway ///
    (rcap _ci_ub _ci_lb _at2 if _at1 == 0 & model == 0, lcolor(stc1) lwidth(*1.5)) ///
    (rcap _ci_lb _ci_ub _at2 if _at1 == 1 & model == 0, lcolor(stc3) lwidth(*1.5)) ///
    (rcap _ci_lb _ci_ub _at2 if _at1 == 2 & model == 0, lcolor(stc2) lwidth(*1.5)) ///
    (connected _margin _at2 if _at1 == 0 & model == 0, lcolor(stc1) mcolor(stc1) lwidth(*2) msymbol(O) msize(*2)) ///
    (connected _margin _at2 if _at1 == 1 & model == 0, lcolor(stc3) mcolor(stc3) lwidth(*2) msymbol(O) msize(*2)) ///
    (connected _margin _at2 if _at1 == 2 & model == 0, lcolor(stc2) mcolor(stc2) lwidth(*2) msymbol(O) msize(*2)) ///
    , ///
    ytitle("Proportion with Hypomagnesemia (%)", size(*1.2))  ///
    xtitle("KRT session", size(*1.2)) ///
    xsc(range(0.9 4.1)) xlabel(1(1)4, labsize(*1.0)) ///
    ylabel(0 "0" .1 "10" .2 "20" .3 "30" .4 "40" .5 "50" .6 "60" .7 "70" .8 "80" .9 "90" 1 "100", format(%3.1f) labsize(*1.1))   ///
    legend(order(7 "SLED-f" 8 "CVVHDF" 9 "CVVH") pos(6) row(1) size(medium))  ///    
    plotregion(margin(medium)) graphregion(color(white)) ///
	legend(order(1 "SLED-f" 2 "CVVHDF" 3 "CVVH") pos(6) row(1)) ///
	text( 1.05 3 "{stSymbol:*}", color(stc2) size(*2)) ///
    text(.99 3 "{stSymbol:*}", color(stc3) size(*2)) ///
    text(1.05 4 "{stSymbol:*}", color(stc2) size(*2)) ///
    plotregion(margin(medium)) graphregion(color(white)) ///
    caption("Proprortion estimated via Generalized estimating equarions *, P<0.05 at each time point" "Unadjusted model", size(*0.7) span) ///
	name(hypoMg_proportion_crude, replace)


twoway ///
    (rcap _ci_ub _ci_lb _at2 if _at1 == 0 & model == 1, lcolor(stc1) lwidth(*1.5)) ///
    (rcap _ci_lb _ci_ub _at2 if _at1 == 1 & model == 1, lcolor(stc3) lwidth(*1.5)) ///
    (rcap _ci_lb _ci_ub _at2 if _at1 == 2 & model == 1, lcolor(stc2) lwidth(*1.5)) ///
    (connected _margin _at2 if _at1 == 0 & model == 1, lcolor(stc1) mcolor(stc1) lwidth(*2) msymbol(O) msize(*2)) ///
    (connected _margin _at2 if _at1 == 1 & model == 1, lcolor(stc3) mcolor(stc3) lwidth(*2) msymbol(O) msize(*2)) ///
    (connected _margin _at2 if _at1 == 2 & model == 1, lcolor(stc2) mcolor(stc2) lwidth(*2) msymbol(O) msize(*2)) ///
    , ///
    ytitle("Proportion with Hypomagnesemia (%)", size(*1.2))  ///
    xtitle("KRT session", size(*1.2)) ///
    xsc(range(0.9 4.1)) xlabel(1(1)4, labsize(*1.0)) ///
    ylabel(0 "0" .1 "10" .2 "20" .3 "30" .4 "40" .5 "50" .6 "60" .7 "70" .8 "80" .9 "90" 1 "100", format(%3.1f) labsize(*1.1))   ///
    legend(order(7 "SLED-f" 8 "CVVHDF" 9 "CVVH") pos(6) row(1) size(medium))  ///    
    plotregion(margin(medium)) graphregion(color(white)) ///
	legend(order(1 "SLED-f" 2 "CVVHDF" 3 "CVVH") pos(6) row(1)) ///
    caption("Proprortion estimated via Generalized estimating equarions *, P<0.05 at each time point" "Adjusted for baseline Mg, age, APACHE II, coronary heart disease," "phosphate, supplemental Mg, nutrition, delivered KRT dose", size(*0.7) span) ///
	name(alb_hypoMg_proportion_adjusted, replace)
	
	
graph combine hypoMg_proportion_crude hypoMg_proportion_adjusted, ycommon
graph export hypoMg_proportion_combined.png, replace
	


* Conversion to TIFF with integrated Python
python:
from PIL import Image

# Path of PNG exported from Stata
input_png = "hypoMg_proportion_combined.png"
output_tiff = "hypoMg_proportion_combined.tif"

# Open image and convert to RGB
img = Image.open(input_png).convert("RGB")

# Save as TIFF with 900 dpi
img.save(output_tiff, dpi=(900, 900), compression="tiff_deflate")

print("Completed coversion: hypoMg_proportion_combined.tif with 900 dpi")
end


********************************************************************************
**# START GEE HYPOMAGNESEMIA
********************************************************************************


********************************************************************************
**# FINE-GRAY REGRESSION HYPMAGNESEMIA
********************************************************************************
clear
cd "C:\Documenti\Regolisti\IpoMg"
use "mg_competing_risk.dta"

global confounders "mg_base age apache_ii cad p_base mg_suppl_dicotom i.nutrition deliver_dd"

stset t_stop, origin(t_start) failure(event_type==1) id(ID)

* Check the setup
stsum, by(KRT)


* Run Fine-Gray regression
di _newline(2) "{hline 80}"
di "FINE-GRAY COMPETING RISK REGRESSION"
di "Outcome: Hypomagnesemia (Mg ≤ 1.7 mg/dL)"
di "Competing risk: Death"
di "{hline 80}" _newline

stcrreg i.KRT, compete(event_type == 2)

* Store results
estimates store fg_crude

* Display results with clearer labels
di _newline "Subdistribution Hazard Ratios:"
stcrreg, nohr

di _newline "Subdistribution Hazard Ratios (exponentiated):"
stcrreg


* Estimate cumulative incidence for each KRT group
stcurve, cif at1(KRT=0) at2(KRT=1) at3(KRT=2)  ///
    title("Cumulative Incidence of Hypomagnesemia (%)") ///
    ytitle("Cumulative Incidence of Hypomagnesemia (%)")  ///
    legend(order(1 "SLED-f" 2 "CVVHDF" 3 "CVVH") pos(11) ring(0) col(1)) ///
    ylabel(0 "0.0" .1 "10" .2 "20" .3 "30" .4 "40" .5 "50" .6 "60" .7 "70" .8 "80" .9 "90" 1 "100", format(%3.1f)) ysc(range(0 .6)) ///
	xlabel(1 "0" 2 "1" 3 "2" 4 "3" 5 "5") ///
	title("")  ///
    name(fg_plot_unadjusted, replace)

graph export "fg_plot_unadjusted.png", replace width(2000)




stcrreg i.KRT $confounders, compete(event_type == 2)

* Store results
estimates store fg_adj

* Display results with clearer labels
di _newline "Subdistribution Hazard Ratios:"
stcrreg, nohr

di _newline "Subdistribution Hazard Ratios (exponentiated):"
stcrreg


* Estimate cumulative incidence for each KRT group
stcurve, cif at1(KRT=0) at2(KRT=1) at3(KRT=2) ///
    title("Cumulative Incidence of Hypomagnesemia (%)") ///
    ytitle("Cumulative Incidence of Hypomagnesemia (%)") xtitle("Days") ///
    legend(order(1 "SLED-f" 2 "CVVHDF" 3 "CVVH") pos(11) ring(0) col(1)) ///
    ylabel(0 "0.0" .1 "10" .2 "20" .3 "30" .4 "40" .5 "50" .6 "60" .7 "70" .8 "80" .9 "90" 1 "100", format(%3.1f)) ysc(range(0 .6)) ///
	xlabel(1 "0" 2 "1" 3 "2" 4 "3" 5 "5") ///
	title("")  ///
    name(fg_plot_adjusted, replace)

graph export "fg_plot_adjusted.png", replace width(2000)



collect clear
collect create c1

collect, name(c1): quietly stcrreg i.KRT, compete(event_type==2) 

qui collect layout (colname) (result[_r_b _r_ci _r_p])

collect create c2

collect, name(c2): quietly stcrreg i.KRT $confounders, compete(event_type==2)


qui collect layout (colname) (result[_r_b _r_ci _r_p])

collect combine c= c1 c2

qui collect layout (colname) (collection#result[_r_b _r_ci _r_p]) (), name(c)

collect label levels collection c1 "Unadjusted", modify

collect label levels collection c2 "Adjusted", modify

collect style column, nodelimiter dups(center)
collect style cell border_block, border(right, pattern(nil))
collect style cell result[_r_b], nformat(%3.2f)
collect style cell result[_r_ci], nformat(%3.2f) sformat("(%s)") cidelimiter(" to ")
collect style cell result[_r_p], nformat(%4.3f) minimum(0.001)
collect recode colname 1.KRT = "CVVHDF vs SLED-f"
collect recode colname 2.KRT = "CVVH vs SLED-f"




collect title "Table X. Subhazard ratio of hypomagnesemia"
collect label levels result _r_b "SHR", modify
collect label levels result _r_ci "95% CI", modify
collect label levels result _r_p "P value", modify
collect notes 1: "Competing risk regression (Fine-Gray) for hypomagnesemia, with death as competing event"
collect notes 2: "Adjusted, adjusted for: Baseline Mg, age, APACHE II, coronary artery disease, phosphate, Mg supplementation, nutrition, delivered dose" 
collect notes 3: "CI, confidence interval; SHR Subhazard ratio for overall transplant failure (death or graft loss)."
collect layout (colname["CVVHDF vs SLED-f" "CVVH vs SLED-f"]) (collection#result[_r_b _r_ci _r_p]) (), name(c)

collect export "Table SHR hypomagnesemia Fine-gray.xlsx", replace
collect export "Table SHR hypomagnesemia Fine-gray.docx", replace
collect export "Table SHR hypomagnesemia Fine-gray.html", replace





********************************************************************************
**# ADDITIONAL ANALYSES ON MECHANICAL VENTILATION (YES/NO) AND ON DAYS ON MV
********************************************************************************
clear
cd "C:\Documenti\Regolisti\IpoMg"
use mg_merged
sort ID n_time

xtset ID n_time
xttab hypoMg
xttrans hypoMg

cap drop y
gen y = -7.5
cap drop mg_start_jitter
set seed 123
cap drop u
gen u = (0.5 - uniform()) / 10
gen mg_start_jitter = mg_start + u
fracpoly: stcox mg_start
test Img_s__1  + Img_s__2 = 0

global confounders "mg_base age apache_ii cad p_base mg_suppl_dicotom i.nutrition deliver_dd"

* Sort data

// GEE MV logit link - Unadjusted model - Mg continuous
xtgee VM Img_s__1   Img_s__2, i(ID) robust link(logit) family(binomial) corr(ind) eform
qui test Img_s__1
test Img_s__2, accum
di "Unadjusted Test that the proportion of days on MV increased with Mg (Continuous): P = " %4.3f r(p)
// GEE MV logit link - Adjusted model - Mg continuous 
xtgee VM Img_s__1   Img_s__2 i.KRT $confounders, i(ID) robust link(logit) family(binomial) corr(ind) eform
qui test Img_s__1
test Img_s__2, accum
di "Adjusted Test that the proportion of days on MV increased with Mg (Continuous): P = " %4.3f r(p)

// GEE MV logit link Unadjusted model - Mg dichotomous
xtgee VM i.hypoMg , i(ID) robust link(logit) family(binomial) corr(ind) eform
test _b[1.hypoMg] = 0
di "Test that the proportion of days on MV increased with HypoMg (Dichotomous): P = " %4.3f r(p)

// GEE MV logit link Adjusted model - Mg dichotomous
xtgee VM i.hypoMg i.KRT $confounders, i(ID) robust link(logit) family(binomial) corr(ind) eform
test _b[1.hypoMg] = 0
di "Test that the proportion of days on MV increased with HypoMg (Dichotomous): P = " %4.3f r(p)
lincom 1.hypoMg, sformat(%3.2f) pformat(%4.3f) cformat(%3.2f) or




// GEE MV logit link Adjusted model - Mg dichotomous
xtgee VM i.hypoMg i.KRT $confounders, i(ID) robust link(logit) family(binomial) corr(ind) eform
test _b[1.hypoMg] = 0
di "Test that the proportion of days on MV increased with HypoMg (Dichotomous): P = " %4.3f r(p)
lincom 1.hypoMg, sformat(%3.2f) pformat(%4.3f) cformat(%3.2f) or




// Negative binomial regression Days on Mechanical ventilation (VM) - any episodes of hypoMg during stay - Unadjusted

nbreg VMdays i.any_hypoMg if n_time ==1
test _b[1.any_hypoMg] = 0 
di "Test that the number of days on MV increase with HypoMg (Dichotomous): P = " %4.3f r(p)
qui margins, at(any_hypoMg = (0 1)) cformat(%3.1f) nopval
di "Predicted means of days on MV according to HypoMg (any time)"
etable, margins cstat(_r_b, nformat(%4.2f))   cstat(_r_ci, cidelimiter(,) nformat(%5.2f))
collect export hypomg_marg_nbreg_crude_mar05.html, replace
collect export hypomg_marg_nbreg_crude_mar05.docx, replace

// Negative binomial regression Days on Mechanical ventilation (VM) - any episodes of hypoMg during stay - Adjusted 

nbreg VMdays i.any_hypoMg i.KRT $confounders if n_time ==1
test _b[1.any_hypoMg] = 0 
di "Test that the number of days on MV increase with HypoMg (Dichotomous): P = " %4.3f r(p)
qui margins, at(any_hypoMg = (0 1)) cformat(%3.1f) nopval
di "Predicted means of days on MV according to HypoMg (any time)"
etable, margins cstat(_r_b, nformat(%4.2f))   cstat(_r_ci, cidelimiter(,) nformat(%5.2f))
collect export hypomg_marg_nbreg_crude_mar05.html, replace
collect export hypomg_marg_nbreg_crude_mar05.docx, replace

