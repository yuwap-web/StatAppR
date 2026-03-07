# Complete Recipe Parameter Reference Guide

## Quick Reference Table

| Recipe | Outcome Param | Treatment Param | Covariate Param | Other Key Params |
|--------|---------------|-----------------|-----------------|------------------|
| basic_statistics | N/A | N/A | N/A | `variables` |
| two_group_continuous | `outcome_column` | N/A | N/A | `group_column` |
| two_group_categorical | `outcome_column` | N/A | N/A | `group_column` |
| anova_continuous | `outcome_column` | N/A | N/A | `group_column` (3+) |
| balance_table | N/A | `treatment` | `x` | N/A |
| linear_regression | `outcome_column` | N/A | N/A | `predictor_column` |
| multiple_regression | `outcome_column` | N/A | N/A | `predictor_columns` |
| logistic_regression | `outcome_column` | N/A | N/A | `predictor_columns` (binary Y) |
| bayesian_regression | `outcome_column` | N/A | N/A | `predictor_columns` |
| mixed_model | `y` | N/A | `x` | `group` |
| difference_in_differences | `outcome_column` | `treatment_column` | N/A | `time_column` |
| event_study | `outcome_column` | N/A | N/A | `unit_id`, `time_column`, `event_date_column` |
| synthetic_control | `y` | N/A | N/A | `group_column`, `time_column`, `treated_unit` |
| target_trial_emulation | `outcome_column` | N/A | N/A | `id`, `time_column`, `stop` |
| survival_km | N/A | N/A | N/A | `time_column`, `event_column`, `group_column` |
| cox_regression | N/A | N/A | `covariates` | `time_column`, `event_column` |
| iptw_km_survival | `outcome_column` | `treatment_column` | `covariates` | `time_column`, `event_column` |
| propensity_score | N/A | `treat` | `x` | N/A |
| ps_matching | `outcome_column` | `treatment_column` | `covariates` | N/A |
| iptw_ate | `outcome_column` | `treatment_column` | `covariates` | N/A |
| aipw_ate | `outcome_column` | `treatment_column` | `covariates` | N/A |
| double_ml_ate | `outcome_column` | `treatment_column` | `covariates` | N/A |
| causal_forest | `outcome_column` | `treatment_column` | `predictor_columns` | N/A |
| instrumental_variable | `outcome_column` | `treatment_column` | `x` | `z` (instrument) |
| placebo_test | `outcome_column` | `treatment_column` | N/A | `id`, `placebo_column` |
| pca_analysis | N/A | N/A | N/A | `predictor_columns` |
| pls_regression | `y` | N/A | N/A | `predictor_columns` |
| conditional_logistic_regression | `outcome_column` | `exposure_column` | `exposure_columns` | `matchset_column` |
| case_crossover | `outcome_column` | `exposure_column` | `covariates` | `case_id`, `time_column`, `case_window` |
| meta_analysis | N/A | N/A | N/A | `effect_size`, `se` |
| subgroup_meta_analysis | N/A | N/A | N/A | `effect_size`, `se`, `subgroup_column` |
| iv_2sls | `y` | `treat` | `x` | `z` (instrument) |

## Detailed Parameter Specifications

### Phase 1: Basic Statistics

#### basic_statistics
- **File:** `Engine/recipes/basic_statistics.R`
- **Parameters:**
  - `variables`: Vector of column names (string or comma-separated)
- **Example:**
  ```r
  variables = list(variables = c("age", "weight", "height"))
  ```

---

### Phase 2: Group Comparison

#### two_group_continuous
- **File:** `Engine/recipes/two_group_continuous.R`
- **Parameters:**
  - `group_column`: Categorical column with 2 levels
  - `outcome_column`: Continuous numeric outcome
- **Example:**
  ```r
  variables = list(group_column = "treatment", outcome_column = "score")
  ```

#### two_group_categorical
- **File:** `Engine/recipes/two_group_categorical.R`
- **Parameters:**
  - `group_column`: Categorical column with 2 levels
  - `outcome_column`: Categorical outcome
- **Example:**
  ```r
  variables = list(group_column = "group", outcome_column = "category")
  ```

#### anova_continuous
- **File:** `Engine/recipes/anova_continuous.R` (lines 9-10)
- **Parameters:**
  - `group_column`: Categorical column with **3+ levels** (required)
  - `outcome_column`: Continuous numeric outcome
- **Example:**
  ```r
  variables = list(group_column = "treatment_group", outcome_column = "score")
  ```
- **Requirements:** Must have 3 or more groups

#### balance_table
- **File:** `Engine/recipes/balance_table.R`
- **Parameters:**
  - `treatment`: Binary treatment column
  - `x`: Vector of covariates to balance
- **Example:**
  ```r
  variables = list(treatment = "treat", x = c("age", "gender", "income"))
  ```

---

### Phase 3: Regression Analysis

#### linear_regression
- **File:** `Engine/recipes/linear_regression.R`
- **Parameters:**
  - `outcome_column`: Continuous outcome
  - `predictor_column`: Single predictor (string, not array)
- **Example:**
  ```r
  variables = list(outcome_column = "price", predictor_column = "size")
  ```

#### multiple_regression
- **File:** `Engine/recipes/multiple_regression.R`
- **Parameters:**
  - `outcome_column`: Continuous outcome
  - `predictor_columns`: Vector of predictors
- **Example:**
  ```r
  variables = list(outcome_column = "price", predictor_columns = c("size", "bedrooms"))
  ```

#### logistic_regression
- **File:** `Engine/recipes/logistic_regression.R` (lines 13-14)
- **Parameters:**
  - `outcome_column`: **Binary outcome** (0/1, TRUE/FALSE, or 2-level factor)
  - `predictor_columns`: Vector of predictors
- **Example:**
  ```r
  variables = list(outcome_column = "event", predictor_columns = c("age", "score"))
  ```
- **Requirements:** Outcome must be binary

#### bayesian_regression
- **File:** `Engine/recipes/bayesian_regression.R`
- **Parameters:**
  - `outcome_column`: Continuous outcome
  - `predictor_columns`: Vector of predictors
- **Example:**
  ```r
  variables = list(outcome_column = "y", predictor_columns = c("x1", "x2"))
  ```

#### mixed_model
- **File:** `Engine/recipes/mixed_model.R` (lines 13-15)
- **Parameters:**
  - `y`: Outcome column (uses 'y' not 'outcome_column')
  - `x`: Vector of fixed effect predictors (uses 'x' not 'predictor_columns')
  - `group`: Column for random intercept grouping (uses 'group' not 'group_column')
- **Example:**
  ```r
  variables = list(y = "score", x = c("time", "treatment"), group = "subject_id")
  ```
- **Requirements:** `group` must have 2+ levels

---

### Phase 4: Time Series Analysis

#### difference_in_differences
- **File:** `Engine/recipes/difference_in_differences.R` (lines 26-28)
- **Parameters:**
  - `outcome_column`: Outcome variable
  - `treatment_column`: Binary treatment indicator (0/1)
  - `time_column`: Time period variable (numeric)
- **Optional:**
  - `id`: Unit identifier
  - `event_study`: Boolean to compute event study plot
  - `seed`: Random seed
- **Example:**
  ```r
  variables = list(
    outcome_column = "earnings",
    treatment_column = "treated",
    time_column = "year"
  )
  ```
- **Requirements:** Requires 2+ time periods

#### event_study
- **File:** `Engine/recipes/event_study.R` (lines 15-18)
- **Parameters:**
  - `outcome_column`: Outcome variable
  - `unit_id`: Panel unit identifier (uses `unit_id` or `id`)
  - `time_column`: Time variable (numeric)
  - `event_date_column`: Treatment/event date per unit
- **Optional:**
  - `min_lag`: Lags before treatment (default: -5)
  - `max_lead`: Leads after treatment (default: 5)
  - `ref_k`: Reference baseline period
- **Example:**
  ```r
  variables = list(
    outcome_column = "sales",
    unit_id = "firm_id",
    time_column = "year",
    event_date_column = "treatment_year"
  )
  ```
- **Requirements:** Panel data with multiple units and time periods

#### synthetic_control
- **File:** `Engine/recipes/synthetic_control.R` (lines 20-23)
- **Parameters:**
  - `y`: Outcome variable
  - `group_column`: Unit identifier
  - `time_column`: Time variable
  - `treated_unit`: Which unit was treated (e.g., "firm_1")
- **Example:**
  ```r
  variables = list(
    y = "revenue",
    group_column = "state",
    time_column = "year",
    treated_unit = "California"
  )
  ```
- **Requirements:** Requires 'Synth' package

#### target_trial_emulation
- **File:** `Engine/recipes/target_trial_emulation.R`
- **Parameters:**
  - `outcome_column`: Outcome variable
  - `id`: Individual identifier
  - `time_column`: Follow-up time
  - `stop`: Optional stopping rule
- **Example:**
  ```r
  variables = list(
    outcome_column = "outcome",
    id = "patient_id",
    time_column = "month"
  )
  ```

---

### Phase 5: Survival Analysis

#### survival_km
- **File:** `Engine/recipes/survival_km.R`
- **Parameters:**
  - `time_column`: Time to event (numeric)
  - `event_column`: Event indicator (0=censored, 1=event)
  - `group_column`: Optional grouping variable
- **Example:**
  ```r
  variables = list(
    time_column = "time_to_event",
    event_column = "event_occurred",
    group_column = "treatment_group"
  )
  ```

#### cox_regression
- **File:** `Engine/recipes/cox_regression.R` (lines 10-12)
- **Parameters:**
  - `time_column`: Survival time (numeric)
  - `event_column`: Event indicator (0/1)
  - `covariates`: Vector of predictors (uses 'covariates' not 'predictor_columns')
- **Optional:**
  - `check_ph`: Perform PH assumption test
  - `robust_se`: Use robust standard errors
  - `ties`: Tie handling method
- **Example:**
  ```r
  variables = list(
    time_column = "survival_days",
    event_column = "died",
    covariates = c("age", "stage", "grade")
  )
  ```

#### iptw_km_survival
- **File:** `Engine/recipes/iptw_km_survival.R` (line 34)
- **Parameters:**
  - `time_column`: Survival time
  - `event_column`: Event indicator
  - `treatment_column`: Binary treatment (0/1)
  - `covariates`: Vector of confounders
- **Example:**
  ```r
  variables = list(
    time_column = "months",
    event_column = "event",
    treatment_column = "therapy",
    covariates = c("age", "comorbidity")
  )
  ```
- **Requirements:** Treatment must be binary (0/1)

---

### Phase 6: Causal Inference

#### propensity_score
- **File:** `Engine/recipes/propensity_score.R` (lines 18-19)
- **Parameters:**
  - `treat`: Binary treatment variable (uses 'treat' not 'treatment_column')
  - `x`: Vector of covariates (uses 'x' not 'confounders')
- **Optional:**
  - `ps_model`: "logit" (default) or "probit"
- **Example:**
  ```r
  variables = list(
    treat = "received_treatment",
    x = c("age", "income", "education")
  )
  ```

#### ps_matching
- **File:** `Engine/recipes/ps_matching.R` (lines 25-27)
- **Parameters:**
  - `treatment_column`: Binary treatment
  - `outcome_column`: Outcome variable
  - `covariates`: Vector of confounders (uses 'covariates')
- **Optional:**
  - `caliper`: Matching tolerance
- **Example:**
  ```r
  variables = list(
    treatment_column = "treated",
    outcome_column = "earnings",
    covariates = c("age", "education")
  )
  ```

#### iptw_ate
- **File:** `Engine/recipes/iptw_ate.R` (line 27)
- **Parameters:**
  - `treatment_column`: Binary treatment
  - `outcome_column`: Outcome
  - `covariates`: Vector of confounders
- **Optional:**
  - `ps_model`: "logit" or "probit"
  - `stabilized`: Use stabilized weights
  - `trim`: Trim extreme weights
- **Example:**
  ```r
  variables = list(
    treatment_column = "program",
    outcome_column = "income",
    covariates = c("age", "prior_income")
  )
  ```

#### aipw_ate
- **File:** `Engine/recipes/aipw_ate.R` (line 27)
- **Parameters:**
  - `treatment_column`: Binary treatment
  - `outcome_column`: Outcome
  - `covariates`: Vector of confounders
- **Example:**
  ```r
  variables = list(
    treatment_column = "intervention",
    outcome_column = "outcome",
    covariates = c("baseline1", "baseline2")
  )
  ```

#### double_ml_ate
- **File:** `Engine/recipes/double_ml_ate.R` (line 74)
- **Parameters:**
  - `treatment_column`: Binary treatment
  - `outcome_column`: Outcome
  - `covariates`: Vector of confounders
- **Optional:**
  - `learner`: ML method ("lasso", "rf", "glm")
  - `n_folds`: Cross-fitting folds
- **Example:**
  ```r
  variables = list(
    treatment_column = "treated",
    outcome_column = "outcome",
    covariates = c("x1", "x2", "x3")
  )
  ```

#### causal_forest
- **File:** `Engine/recipes/causal_forest.R` (lines 26-28)
- **Parameters:**
  - `outcome_column`: Outcome variable
  - `treatment_column`: Binary treatment (0/1)
  - `predictor_columns`: Feature vector (uses 'predictor_columns')
- **Optional:**
  - `n_trees`: Number of trees (default: 2000)
  - `seed`: Random seed
  - `plot`: Generate ITE distribution plot
- **Example:**
  ```r
  variables = list(
    outcome_column = "y",
    treatment_column = "w",
    predictor_columns = c("x1", "x2", "x3")
  )
  ```
- **Requirements:** 50+ observations

#### instrumental_variable
- **File:** `Engine/recipes/instrumental_variable.R`
- **Parameters:**
  - `outcome_column`: Outcome variable
  - `treatment_column`: Endogenous treatment
  - `instrument_column`: Instrument variable (z)
  - `x`: Optional exogenous covariates
- **Example:**
  ```r
  variables = list(
    outcome_column = "earnings",
    treatment_column = "education",
    instrument_column = "distance_to_college",
    x = c("age", "gender")
  )
  ```
- **Requirements:** 20+ observations

#### placebo_test
- **File:** `Engine/recipes/placebo_test.R`
- **Parameters:**
  - `outcome_column`: Outcome variable
  - `treatment_column`: Treatment variable
  - `id`: Unit identifier (for panel data)
  - `placebo_column`: Placebo variable
- **Example:**
  ```r
  variables = list(
    outcome_column = "y",
    treatment_column = "treatment",
    id = "unit_id",
    placebo_column = "placebo"
  )
  ```

---

### Phase 7: Dimension Reduction

#### pca_analysis
- **File:** `Engine/recipes/pca_analysis.R` (line 16)
- **Parameters:**
  - `predictor_columns`: Vector of numeric columns (uses 'predictor_columns')
- **Optional:**
  - `center`: Center variables (default: TRUE)
  - `scale`: Scale variables (default: TRUE)
  - `n_components`: Number of PCs to display
- **Example:**
  ```r
  variables = list(
    predictor_columns = c("gene_1", "gene_2", "gene_3", "gene_4", "gene_5")
  )
  ```
- **Requirements:** 2+ numeric columns

#### pls_regression
- **File:** `Engine/recipes/pls_regression.R`
- **Parameters:**
  - `y`: Numeric outcome (uses 'y')
  - `predictor_columns`: Vector of predictors
- **Example:**
  ```r
  variables = list(
    y = "disease_score",
    predictor_columns = c("biomarker_1", "biomarker_2", "biomarker_3")
  )
  ```
- **Requirements:** y must be numeric

#### conditional_logistic_regression
- **File:** `Engine/recipes/conditional_logistic_regression.R` (lines 24-26)
- **Parameters:**
  - `outcome_column`: Binary outcome (0/1)
  - `exposure_column`: Primary exposure variable
  - `matchset_column`: Matching set/stratum column
  - `exposure_columns`: Additional exposure variables
- **Example:**
  ```r
  variables = list(
    outcome_column = "case",
    exposure_column = "exposure1",
    matchset_column = "match_group",
    exposure_columns = c("exposure1", "exposure2")
  )
  ```

#### case_crossover
- **File:** `Engine/recipes/case_crossover.R` (lines 18-22)
- **Parameters:**
  - `outcome_column`: Outcome indicator
  - `exposure_column`: Exposure variable
  - `case_id`: Person/case identifier (uses 'case_id')
  - `time_column`: Time variable (must be numeric, uses 'time_column')
  - `case_window`: Case exposure window (default: 1)
- **Optional:**
  - `control_window`: Control exposure window (default: 28)
- **Example:**
  ```r
  variables = list(
    outcome_column = "event_occurred",
    exposure_column = "pm25",
    case_id = "person_id",
    time_column = "day",
    case_window = 1,
    control_window = 28
  )
  ```
- **Requirements:** time_column must be numeric (not character like "S1", "S2")

---

### Phase 8: Meta-Analysis

#### meta_analysis
- **File:** `Engine/recipes/meta_analysis.R`
- **Parameters:**
  - `effect_size`: Column with effect sizes
  - `se`: Column with standard errors
- **Example:**
  ```r
  variables = list(
    effect_size = "beta",
    se = "se_beta"
  )
  ```

#### subgroup_meta_analysis
- **File:** `Engine/recipes/subgroup_meta_analysis.R` (line 175)
- **Parameters:**
  - `effect_size`: Column with effect sizes
  - `se`: Column with standard errors
  - `subgroup_column`: Column defining subgroups (uses 'subgroup_column')
- **Example:**
  ```r
  variables = list(
    effect_size = "estimate",
    se = "std_error",
    subgroup_column = "population_type"
  )
  ```

---

### Additional Recipes

#### iv_2sls
- **File:** `Engine/recipes/iv_2sls.R` (lines 16-22)
- **Parameters:**
  - `y`: Outcome variable (uses 'y')
  - `treat`: Endogenous treatment (uses 'treat')
  - `z`: Instrument variable
  - `x`: Optional exogenous covariates
- **Example:**
  ```r
  variables = list(
    y = "wage",
    treat = "education",
    z = "distance_to_college",
    x = c("age", "gender")
  )
  ```
- **Requirements:** Formula: y ~ treat | z (with optional x)

---

## Key Parameter Naming Patterns

### Outcome Variables
- **Standard name:** `outcome_column`
- **Exceptions:** `y` (mixed_model, pls_regression, iv_2sls)

### Treatment/Exposure Variables
- **Standard name:** `treatment_column`
- **Exceptions:** `treat` (propensity_score, iv_2sls), `exposure_column` (conditional_logistic, case_crossover)

### Covariate/Predictor Variables
- **For linear/logistic models:** `predictor_columns` or `predictor_column`
- **For causal inference:** `covariates` or `x`
- **For dimension reduction:** `predictor_columns`

### Grouping Variables
- **Standard:** `group_column` or `group`
- **Panel/unit identifier:** `unit_id` or `id`
- **Matching strata:** `matchset_column`
- **Case identifier:** `case_id`

---

## Data Type Requirements

### Binary Variables
- **Can be:** 0/1, TRUE/FALSE, 2-level factor, character ("Yes"/"No")
- **Required for:** logistic_regression, causal_forest, all IPTW/AIPW recipes, Cox regression event column

### Numeric Variables
- **Required for:** All continuous outcomes, time variables, effect sizes
- **Note:** Comma-separated numbers (e.g., "1,000") are automatically converted

### Categorical Variables
- **Can be:** Factor, character, or numeric codes
- **Validation:** Group columns with 2+ levels for simple group comparisons, 3+ for ANOVA

---

*Last updated: 2026-03-07*
*Based on: Statistical Analysis Recipe Engine v2.0*
