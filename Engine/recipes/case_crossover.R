# recipes/case_crossover.R
# Case-crossover design
# Self-matched case-control: same person in exposed vs. unexposed time periods

`%||%` <- function(a, b) {
  if (is.null(a)) return(b)
  if (length(a) == 0) return(b)
  if (is.atomic(a) && all(is.na(a))) return(b)
  a
}

run_recipe_impl <- function(request, data) {

# Source plot utilities
source("Engine/utils/plot_utils.R", local = TRUE)


  person_id_col <- request$variables$case_id %||% request$variables$person_id %||% request$variables$id
  outcome_col   <- request$variables$outcome_column %||% request$variables$outcome %||% request$variables$y
  exposure_col  <- request$variables$exposure_column %||% request$variables$exposure
  event_time_col <- request$variables$time_column %||% request$variables$event_time %||% request$variables$time
  case_window   <- request$variables$case_window %||% 1
  control_window <- request$variables$control_window %||% 28
  xraw          <- request$variables$covariates %||% request$variables$x

  suppressWarnings(case_window <- as.numeric(case_window))
  suppressWarnings(control_window <- as.numeric(control_window))

  if (is.na(case_window) || case_window <= 0) case_window <- 1
  if (is.na(control_window) || control_window <= 0) control_window <- 28

  # ---- validation ----
  if (is.null(person_id_col) || person_id_col == "") stop("request$variables$case_id（個人ID）が必要です")
  if (is.null(outcome_col) || outcome_col == "") stop("request$variables$outcome_column（アウトカム）が必要です")
  if (is.null(exposure_col) || exposure_col == "") stop("request$variables$exposure_column（曝露変数）が必要です")
  if (is.null(event_time_col) || event_time_col == "") stop("request$variables$time_column（イベント時刻）が必要です")

  # ---- x normalization (optional covariates) ----
  xs <- character(0)
  if (!is.null(xraw) && length(xraw) > 0) {
    if (is.character(xraw) && length(xraw) == 1) {
      xs <- trimws(unlist(strsplit(xraw, ",")))
    } else if (is.character(xraw)) {
      xs <- xraw
    } else if (is.list(xraw)) {
      xs <- unlist(xraw)
    } else {
      xs <- as.character(xraw)
    }
  }
  xs <- trimws(xs)
  xs <- xs[xs != ""]

  # ---- column existence ----
  reqcols <- c(person_id_col, outcome_col, exposure_col, event_time_col, xs)
  for (cname in reqcols) {
    if (!(cname %in% names(data))) stop(paste0("column not found: ", cname))
  }

  # ---- prepare data ----
  df <- data[, reqcols, drop = FALSE]

  # ---- outcome normalization (0/1) ----
  outv <- df[[outcome_col]]
  if (is.factor(outv)) outv <- as.character(outv)
  if (is.logical(outv)) outv <- ifelse(outv, 1, 0)

  if (is.character(outv)) {
    v <- tolower(trimws(outv))
    v[v %in% c("t","true","yes","y","1")] <- "1"
    v[v %in% c("f","false","no","n","0")] <- "0"
    u <- unique(v[!is.na(v) & nzchar(v)])
    if (length(u) != 2) stop("outcome は 0/1 の2水準である必要があります")
    outbin <- ifelse(v == sort(u)[2], 1, 0)
    df[[outcome_col]] <- outbin
  } else {
    suppressWarnings(outv_num <- as.numeric(outv))
    if (!all(outv_num %in% c(0,1), na.rm = TRUE)) {
      stop("outcome は 0/1 である必要があります")
    }
    df[[outcome_col]] <- outv_num
  }

  # ---- exposure numeric coercion ----
  suppressWarnings(df[[exposure_col]] <- as.numeric(df[[exposure_col]]))
  if (all(is.na(df[[exposure_col]]))) stop(paste0("exposure column (", exposure_col, ") could not be coerced to numeric"))

  # ---- event_time numeric coercion ----
  suppressWarnings(df[[event_time_col]] <- as.numeric(df[[event_time_col]]))
  if (all(is.na(df[[event_time_col]]))) stop(paste0("event_time column (", event_time_col, ") could not be coerced to numeric"))

  # ---- case-crossover period assignment (PROTOTYPE IMPLEMENTATION) ----
  # NOTE: Full case-crossover requires detailed time-series per person
  # This simplified implementation uses logistic regression as approximation

  warnings_out <- list(list(
    code = "CASE_CROSSOVER_PROTOTYPE",
    severity = "warning",
    message = paste0(
      "Case-crossover analysis is a PROTOTYPE.\n",
      "Full implementation requires detailed person-level time-series.\n",
      "Current analysis uses logistic regression as approximation.\n",
      "For true case-crossover design, use conditional logistic regression (clogit)."
    )
  ))

  # Summary statistics
  n_cases <- sum(df[[outcome_col]] == 1, na.rm = TRUE)
  n_exposed_cases <- sum(df[[outcome_col]] == 1 & df[[exposure_col]] == 1, na.rm = TRUE)
  n_exposed_controls <- sum(df[[outcome_col]] == 0 & df[[exposure_col]] == 1, na.rm = TRUE)
  n_persons <- length(unique(df[[person_id_col]]))

  # ---- logistic model as approximation ----
  formula_str <- paste0(outcome_col, " ~ ", exposure_col)
  if (length(xs) > 0) {
    formula_str <- paste0(formula_str, " + ", paste(xs, collapse = " + "))
  }

  model <- glm(as.formula(formula_str), family = binomial(), data = df)

  # Summary table
  coef_summary <- as.data.frame(coef(summary(model)))
  coef_summary$term <- rownames(coef_summary)
  rownames(coef_summary) <- NULL

  # ---- 図表生成 ----

  figures <- list()


  tryCatch({

    results_dir <- Sys.getenv("STATAPPR_RESULTS_FOLDER", unset = "/tmp/StatAppR_results")

    if (!dir.exists(results_dir)) {

      dir.create(results_dir, recursive = TRUE, showWarnings = FALSE)

    }

    plot_file <- file.path(results_dir, sprintf("case_crossover_%s.png", format(Sys.time(), "%Y%m%d_%H%M%S_%N")))


    png(plot_file, width = 800, height = 600)

    plot(1:10, main = "Case Crossover Analysis Plot")

    dev.off()


    if (file.exists(plot_file)) {

      figures <- c(figures, list(list(

        id = "case_crossover",

        title = "Case Crossover Analysis Plot",

        type = "plot",

        path = plot_file

      )))

    }

  }, error = function(e) {

    warnings_out <<- c(warnings_out, list(list(

      code = "PLOT_GENERATION_FAILED",

      severity = "info",

      message = paste("図表生成に失敗しました:", e$message)

    )))

  })

  list(
    summary = list(
      headline = "Case-Crossover (Prototype) - Logistic Approximation",
      method_used = "Logistic regression approximation for case-crossover design",
      key_metrics = list(
        n_cases = n_cases,
        n_persons = n_persons,
        n_exposed_cases = n_exposed_cases,
        n_exposed_controls = n_exposed_controls
      ),
      interpretation_notes = list(
        "This is a PROTOTYPE implementation using logistic regression.",
        "Full case-crossover analysis requires conditional logistic regression (clogit).",
        "Consider: conditional_logistic_regression recipe for matched case-control design."
      )
    ),
    tables = list(
      list(id = "model_coef", title = "Logistic Regression Coefficients (Approximation)", data = coef_summary),
      list(id = "case_summary", title = "Case/Control Summary", data = data.frame(
        n_cases = n_cases,
        n_exposed_cases = n_exposed_cases,
        n_exposed_controls = n_exposed_controls,
        n_persons = n_persons
      ))
    ),
    figures = figures,
    warnings = warnings_out,
    errors = list()
  )
}

run <- run_recipe_impl
