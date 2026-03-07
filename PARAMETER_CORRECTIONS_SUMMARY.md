# Test Script Parameter Corrections Summary

## Overview
Updated `/Users/uts/StatAppR/test_all_recipes.R` with correct parameter names by analyzing actual recipe implementations. The test script was using mismatched parameter names that caused test failures.

## Parameter Corrections Applied

### Phase 1: Basic Statistics
No changes required.

### Phase 2: Group Comparison

#### anova_continuous
**Old Parameters:**
```r
group_column = "treatment"  # Wrong column name
outcome_column = "final_score"
```

**Correct Parameters:**
```r
group_column = "group"  # Correct column from sample data
outcome_column = "final_score"
```

**Recipe File:** `/Users/uts/StatAppR/Engine/recipes/anova_continuous.R` (lines 9-10)
- Expects: `request$variables$group_column`, `request$variables$outcome_column`

---

### Phase 3: Regression Analysis

#### logistic_regression
**Old Parameters:**
```r
outcome_column = "bedrooms"  # Wrong: not binary
predictor_columns = c("price_usd", "age_years")
sample = "3_Regression_house_price_prediction.csv"  # Wrong dataset
```

**Correct Parameters:**
```r
outcome_column = "treatment"  # Binary column (0/1)
predictor_columns = c("age", "baseline_score")
sample = "2_GroupComparison_treatment_vs_control.csv"  # Correct dataset
```

**Recipe File:** `/Users/uts/StatAppR/Engine/recipes/logistic_regression.R` (line 13-14)
- Expects: `request$variables$outcome_column`, `request$variables$predictor_columns`
- Requires: Binary outcome (0/1, TRUE/FALSE, or 2-level factor)

#### mixed_model
**Old Parameters:**
```r
outcome_column = "price_usd"
predictor_columns = c("size_sqft")
group_var = "bedrooms"  # Wrong parameter name
```

**Correct Parameters:**
```r
y = "price_usd"  # Recipe uses 'y' not 'outcome_column'
x = c("size_sqft")  # Recipe uses 'x' not 'predictor_columns'
group = "bedrooms"  # Recipe uses 'group' not 'group_var'
```

**Recipe File:** `/Users/uts/StatAppR/Engine/recipes/mixed_model.R` (lines 13-15)
- Expects: `request$variables$y`, `request$variables$x`, `request$variables$group`

---

### Phase 4: Time Series Analysis

#### difference_in_differences
**Old Parameters:**
```r
y = "sales_usd"
x = c("marketing_spend_usd")
group_var = "company_id"  # Wrong parameter name
time_var = "year"  # Wrong parameter name
```

**Correct Parameters:**
```r
outcome_column = "sales_usd"  # Uses outcome_column not y
treatment_column = "company_id"  # Uses treatment_column not group_var
time_column = "year"  # Uses time_column not time_var
```

**Recipe File:** `/Users/uts/StatAppR/Engine/recipes/difference_in_differences.R` (lines 26-28)
- Expects: `request$variables$outcome_column`, `request$variables$treatment_column`, `request$variables$time_column`

#### event_study
**Old Parameters:**
```r
y = "sales_usd"
event_time = "year"
before_window = 2
after_window = 2
```

**Correct Parameters:**
```r
outcome_column = "sales_usd"  # Uses outcome_column not y
unit_id = "company_id"  # Unit identifier (panel identifier)
time_column = "year"  # Time variable
event_date_column = "year"  # Event/treatment date column
```

**Recipe File:** `/Users/uts/StatAppR/Engine/recipes/event_study.R` (lines 15-18)
- Expects: `outcome_column`, `unit_id` (or `id`), `time_column`, `event_date_column`

#### synthetic_control
**Old Parameters:**
```r
y = "sales_usd"
group_var = "company_id"
time_var = "year"
treatment_date = 2020
```

**Correct Parameters:**
```r
y = "sales_usd"
group_column = "company_id"  # Uses group_column not group_var
time_column = "year"  # Uses time_column not time_var
treated_unit = "company_1"  # Which unit was treated
```

**Recipe File:** `/Users/uts/StatAppR/Engine/recipes/synthetic_control.R` (lines 20-23)
- Expects: `y`, `group_column`, `time_column`, `treated_unit`

#### target_trial_emulation
**Old Parameters:**
```r
outcome = "sales_usd"
treatment = "company_id"
baseline_vars = c("marketing_spend_usd", "employees")
```

**Correct Parameters:**
```r
outcome_column = "sales_usd"
id = "company_id"  # Unit/participant ID
time_column = "year"  # Time variable
```

**Recipe File:** `/Users/uts/StatAppR/Engine/recipes/target_trial_emulation.R`
- Expects: `outcome_column`, `id`, `time_column`

---

### Phase 5: Survival Analysis

#### cox_regression
**Old Parameters:**
```r
predictor_columns = c("age", "stage")
```

**Correct Parameters:**
```r
covariates = c("age", "stage")  # Uses 'covariates' not 'predictor_columns'
```

**Recipe File:** `/Users/uts/StatAppR/Engine/recipes/cox_regression.R` (line 12)
- Expects: `time_column`, `event_column`, `covariates`

#### iptw_km_survival
**Old Parameters:**
```r
confounders = c("age")
```

**Correct Parameters:**
```r
covariates = c("age")  # Uses 'covariates' not 'confounders'
```

**Recipe File:** `/Users/uts/StatAppR/Engine/recipes/iptw_km_survival.R` (line 34)
- Expects: `treatment_column`, `outcome_column`, `covariates`

---

### Phase 6: Causal Inference

#### propensity_score
**Old Parameters:**
```r
treatment_column = "treatment_received"
confounders = c("age", "years_education", "prior_income_usd")
```

**Correct Parameters:**
```r
treat = "treatment_received"  # Uses 'treat' not 'treatment_column'
x = c("age", "years_education", "prior_income_usd")  # Uses 'x' not 'confounders'
```

**Recipe File:** `/Users/uts/StatAppR/Engine/recipes/propensity_score.R` (lines 18-19)
- Expects: `treat` (or `treatment`), `x`

#### ps_matching
**Old Parameters:**
```r
confounders = c("age", "years_education")
```

**Correct Parameters:**
```r
covariates = c("age", "years_education")  # Uses 'covariates' not 'confounders'
```

**Recipe File:** `/Users/uts/StatAppR/Engine/recipes/ps_matching.R` (lines 25-27)
- Expects: `treatment_column`, `outcome_column`, `covariates`

#### iptw_ate
**Old Parameters:**
```r
confounders = c("age", "prior_income_usd")
```

**Correct Parameters:**
```r
covariates = c("age", "prior_income_usd")  # Uses 'covariates' not 'confounders'
```

**Recipe File:** `/Users/uts/StatAppR/Engine/recipes/iptw_ate.R` (line 27)
- Expects: `treatment_column`, `outcome_column`, `covariates`

#### aipw_ate
**Old Parameters:**
```r
confounders = c("age", "years_education")
```

**Correct Parameters:**
```r
covariates = c("age", "years_education")  # Uses 'covariates' not 'confounders'
```

**Recipe File:** `/Users/uts/StatAppR/Engine/recipes/aipw_ate.R` (line 27)
- Expects: `treatment_column`, `outcome_column`, `covariates`

#### double_ml_ate
**Old Parameters:**
```r
confounders = c("age", "prior_income_usd")
```

**Correct Parameters:**
```r
covariates = c("age", "prior_income_usd")  # Uses 'covariates' not 'confounders'
```

**Recipe File:** `/Users/uts/StatAppR/Engine/recipes/double_ml_ate.R` (line 74)
- Expects: `treatment_column`, `outcome_column`, `covariates`

#### causal_forest
**Old Parameters:**
```r
confounders = c("age", "years_education")
```

**Correct Parameters:**
```r
predictor_columns = c("age", "years_education")  # Uses 'predictor_columns' not 'confounders'
```

**Recipe File:** `/Users/uts/StatAppR/Engine/recipes/causal_forest.R` (lines 26-28)
- Expects: `outcome_column`, `treatment_column`, `predictor_columns`

#### instrumental_variable
**Old Parameters:**
```r
outcome = "outcome_earnings_usd"
treatment = "treatment_received"
instrument = "region"
```

**Correct Parameters:**
```r
outcome_column = "outcome_earnings_usd"  # Uses outcome_column not outcome
treatment_column = "treatment_received"  # Uses treatment_column not treatment
instrument_column = "region"  # Uses instrument_column not instrument
```

**Recipe File:** `/Users/uts/StatAppR/Engine/recipes/instrumental_variable.R`
- Expects: `outcome_column`, `treatment_column`, `instrument_column`

#### placebo_test
**Old Parameters:**
```r
outcome = "outcome_earnings_usd"
treatment = "treatment_received"
placebo_var = "gender"
```

**Correct Parameters:**
```r
outcome_column = "outcome_earnings_usd"  # Uses outcome_column not outcome
treatment_column = "treatment_received"  # Uses treatment_column not treatment
placebo_column = "gender"  # Uses placebo_column not placebo_var
```

**Recipe File:** `/Users/uts/StatAppR/Engine/recipes/placebo_test.R`
- Expects: `outcome_column`, `treatment_column`, `placebo_column`

---

### Phase 7: Dimension Reduction

#### pca_analysis
**Old Parameters:**
```r
variables = "gene_1,gene_2,gene_3,gene_4,gene_5"  # Wrong parameter name
```

**Correct Parameters:**
```r
predictor_columns = c("gene_1","gene_2","gene_3","gene_4","gene_5")  # Uses predictor_columns
```

**Recipe File:** `/Users/uts/StatAppR/Engine/recipes/pca_analysis.R` (line 16)
- Expects: `predictor_columns`

#### pls_regression
**Old Parameters:**
```r
outcome_column = "disease_status"
```

**Correct Parameters:**
```r
y = "disease_status"  # Uses 'y' not 'outcome_column'
```

**Recipe File:** `/Users/uts/StatAppR/Engine/recipes/pls_regression.R`
- Expects: `y`, `predictor_columns`

#### conditional_logistic_regression
**Old Parameters:**
```r
outcome = "disease_status"
predictor_columns = c("gene_1", "gene_2")
strata = "sample_id"
```

**Correct Parameters:**
```r
outcome_column = "disease_status"  # Uses outcome_column not outcome
exposure_column = "gene_1"  # Primary exposure variable
matchset_column = "sample_id"  # Matching set/stratum
exposure_columns = c("gene_1", "gene_2")  # Additional exposures
```

**Recipe File:** `/Users/uts/StatAppR/Engine/recipes/conditional_logistic_regression.R` (lines 24-26)
- Expects: `outcome_column`, `exposure_column`, `matchset_column`, `exposure_columns`

#### case_crossover
**Old Parameters:**
```r
outcome = "disease_status"
exposure = "gene_1"
time_var = "sample_id"
case_window = 2
```

**Correct Parameters:**
```r
outcome_column = "disease_status"
exposure_column = "gene_1"  # Uses exposure_column not exposure
case_id = "sample_id"  # Person/case ID
time_column = "sample_id"  # Time variable
case_window = 2
```

**Recipe File:** `/Users/uts/StatAppR/Engine/recipes/case_crossover.R` (lines 18-22)
- Expects: `outcome_column`, `exposure_column`, `case_id`, `time_column`, `case_window`

---

### Phase 8: Meta-Analysis

#### subgroup_meta_analysis
**Old Parameters:**
```r
subgroup_var = "study_type"
```

**Correct Parameters:**
```r
subgroup_column = "study_type"  # Uses subgroup_column not subgroup_var
```

**Recipe File:** `/Users/uts/StatAppR/Engine/recipes/subgroup_meta_analysis.R` (line 175)
- Expects: `effect_size`, `se`, `subgroup_column`

---

### Additional Recipes

#### iv_2sls
**Old Parameters:**
```r
outcome = "price_usd"
endogenous = "bedrooms"
exogenous = c("size_sqft", "age_years")
instrument = c("garage_spaces", "location_score")
```

**Correct Parameters:**
```r
y = "price_usd"  # Uses 'y' not 'outcome'
treat = "bedrooms"  # Treatment/endogenous variable (uses 'treat')
x = c("size_sqft")  # Exogenous variables (optional)
z = "age_years"  # Instrument variable
```

**Recipe File:** `/Users/uts/StatAppR/Engine/recipes/iv_2sls.R` (lines 16-22)
- Expects: `y`, `treat` (or `treatment`), `z`, `x` (optional)

---

## Key Patterns Identified

### Parameter Name Conventions

**Outcome Variables:**
- Most recipes: `outcome_column`
- Mixed model: `y`
- IV/2SLS: `y`
- PLS regression: `y`
- Propensity score: None (only predictors)

**Treatment/Exposure Variables:**
- Most recipes: `treatment_column`
- Propensity score: `treat`
- IV/2SLS: `treat`
- Case crossover: `exposure_column`
- Conditional logistic: `exposure_column`

**Predictor/Covariate Variables:**
- Causal forest: `predictor_columns`
- PCA: `predictor_columns`
- Logistic regression: `predictor_columns`
- Cox regression: `covariates`
- IPTW/AIPW: `covariates`
- PS matching: `covariates`
- Propensity score: `x`
- Mixed model: `x`

**Grouping/Stratification Variables:**
- Mixed model: `group`
- Event study: `unit_id` (or `id`)
- Synthetic control: `group_column`
- Conditional logistic: `matchset_column`
- Case crossover: `case_id`

---

## Files Modified

- **`/Users/uts/StatAppR/test_all_recipes.R`**: Updated all 31 test cases with correct parameter names

## Testing Recommendations

1. Run the test script to verify all corrections:
   ```bash
   Rscript /Users/uts/StatAppR/test_all_recipes.R
   ```

2. Check the log file for results:
   ```bash
   cat /tmp/StatAppR_test_results/test_results.log
   ```

3. Key recipes to verify first (highest complexity):
   - `difference_in_differences`
   - `event_study`
   - `causal_forest`
   - `iv_2sls`
   - `conditional_logistic_regression`

---

## Summary Statistics

- **Total recipes corrected:** 23 recipes with parameter name issues
- **Total parameter corrections:** 45+ individual parameter name updates
- **Most common issue:** Using wrong parameter names (confounders vs covariates vs x)
- **Second most common:** Using wrong dataset for binary outcome tests
- **Recipes affected by abbreviations:** y, x, z, treat (vs full names)

---

*Generated: 2026-03-07*
*Updated test script: `/Users/uts/StatAppR/test_all_recipes.R`*
