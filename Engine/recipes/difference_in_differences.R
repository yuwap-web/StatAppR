# recipes/difference_in_differences.R
# Difference-in-Differences with optional event study

# Create persistent results directory (respects STATAPPR_RESULTS_FOLDER env var)
.ensure_results_dir <- function() {
  results_dir <- Sys.getenv("STATAPPR_RESULTS_FOLDER", unset = "/tmp/StatAppR_results")
  if (!dir.exists(results_dir)) {
    dir.create(results_dir, recursive = TRUE, showWarnings = FALSE)
  }
  results_dir
}

`%||%` <- function(a, b) {
  if (is.null(a)) return(b)
  if (length(a) == 0) return(b)
  if (is.atomic(a) && all(is.na(a))) return(b)
  a
}

run_recipe_impl <- function(request, data) {

# Source plot utilities
source("Engine/utils/plot_utils.R", local = TRUE)


  y_col <- request$variables$outcome_column %||% request$variables$y
  t_col <- request$variables$time_column %||% request$variables$time %||% request$variables$post
  g_col <- request$variables$treatment_column %||% request$variables$treat
  id_col <- request$variables$id %||% request$variables$unit %||% NULL

  event_plot <- request$variables$event_study %||% TRUE
  seed <- request$variables$seed %||% 1

  if (is.null(y_col) || y_col == "") stop("request$variables$outcome_column が必要です")
  if (is.null(t_col) || t_col == "") stop("request$variables$time_column が必要です")
  if (is.null(g_col) || g_col == "") stop("request$variables$treatment_column が必要です")

  for (cname in c(y_col, t_col, g_col)) {
    if (!(cname %in% names(data))) stop(paste0("column not found: ", cname))
  }

  df <- data[, unique(c(y_col, t_col, g_col, id_col)), drop = FALSE]

  # numeric coercion
  num_cast <- function(v) {
    if (is.numeric(v)) return(v)
    suppressWarnings(as.numeric(gsub(",", "", as.character(v))))
  }

  df[[y_col]] <- num_cast(df[[y_col]])
  df[[t_col]] <- num_cast(df[[t_col]])
  df[[g_col]] <- num_cast(df[[g_col]])

  df <- df[stats::complete.cases(df), , drop = FALSE]

  if (!all(df[[g_col]] %in% c(0,1))) {
    stop("treatment は 0/1 必須")
  }

  # ---- define post indicator ----

  tvals <- sort(unique(df[[t_col]]))

  if (length(tvals) < 2) {
    stop("time は2時点以上必要です")
  }

  t_cut <- median(tvals)

  df$post <- ifelse(df[[t_col]] > t_cut, 1, 0)

  # ---- DID regression ----

  fml <- stats::as.formula(
    paste0(y_col," ~ ",g_col," + post + ",g_col,":post")
  )

  fit <- stats::lm(fml, data=df)

  sm <- summary(fit)

  coef_mat <- sm$coefficients

  # Robust term detection (handles various naming conventions)
  term_candidates <- c(
    paste0(g_col, ":post"),           # Standard: treat:post
    paste0("`", g_col, "`:post"),     # Backticks: `1`:post
    paste0(g_col, ":1"),              # Numeric post: treat:1
    paste0("`", g_col, "`:1")         # Both backticks: `1`:1
  )

  # Search for matching term
  matching_idx <- which(rownames(coef_mat) %in% term_candidates)

  if(length(matching_idx) == 0) {
    # If no exact match, try flexible pattern matching
    matching_idx <- grep(":post|:1", rownames(coef_mat))
  }

  if(length(matching_idx) == 0) {
    available <- paste(rownames(coef_mat), collapse = ", ")
    stop(paste0(
      "DID interaction term not found.\n",
      "Available coefficients: ", available, "\n",
      "Expected pattern: treat:post or treat:1"
    ))
  }

  term <- rownames(coef_mat)[matching_idx[1]]

  est <- coef_mat[term, "Estimate"]
  se  <- coef_mat[term, "Std. Error"]
  p   <- coef_mat[term, "Pr(>|t|)"]

  ci_low  <- est - 1.96*se
  ci_high <- est + 1.96*se

  did_tbl <- data.frame(
    DID_effect = est,
    conf_low = ci_low,
    conf_high = ci_high,
    p_value = p,
    stringsAsFactors = FALSE
  )

  # ---- group means table ----

  means <- aggregate(
    df[[y_col]],
    by=list(
      treat=df[[g_col]],
      post=df$post
    ),
    FUN=mean
  )

  names(means)[3] <- "mean_y"

  # ---- event study ----

  event_tbl <- data.frame()
  figures <- list()

  if (event_plot && requireNamespace("ggplot2", quietly = TRUE)) {

    df$time_factor <- as.factor(df[[t_col]])

    fml2 <- stats::as.formula(
      paste0(
        y_col,
        " ~ ",
        g_col,
        "*time_factor"
      )
    )

    fit2 <- stats::lm(fml2, data=df)

    coefs <- summary(fit2)$coefficients

    idx <- grep(paste0(g_col,":time_factor"), rownames(coefs))

    if (length(idx) > 0) {

      event_tbl <- data.frame(
        term = rownames(coefs)[idx],
        estimate = coefs[idx,"Estimate"],
        se = coefs[idx,"Std. Error"]
      )

      event_tbl$time <- as.numeric(
        gsub(".*time_factor","",event_tbl$term)
      )

      event_tbl$conf_low  <- event_tbl$estimate - 1.96*event_tbl$se
      event_tbl$conf_high <- event_tbl$estimate + 1.96*event_tbl$se

      p1 <- ggplot2::ggplot(
        event_tbl,
        ggplot2::aes(x=time,y=estimate)
      ) +
        ggplot2::geom_point() +
        ggplot2::geom_errorbar(
          ggplot2::aes(
            ymin=conf_low,
            ymax=conf_high
          ),
          width=0.1
        ) +
        ggplot2::geom_hline(
          yintercept=0,
          linetype="dashed"
        ) +
        ggplot2::theme_minimal() +
        ggplot2::labs(
          title="Event Study",
          x="Time",
          y="Treatment Effect"
        )

      # Save to persistent directory (not temp)
      results_dir <- .ensure_results_dir()
      file <- file.path(results_dir, sprintf("event_study_%s.png", format(Sys.time(), "%Y%m%d_%H%M%S_%N")))

      ggplot2::ggsave(
        file,
        p1,
        width=6,
        height=4,
        dpi=150
      )

      figures <- list(
        list(
          id="event_study",
          title="Event Study",
          path=file
        )
      )
    }
  }

  headline <- paste0(
    "Difference-in-Differences: ",
    signif(est,3),
    " (p=",
    signif(p,3),
    ")"
  )

  list(
    summary=list(
      headline=headline,
      method_used="Difference-in-Differences",
      key_metrics=list(
        did_estimate=est,
        p_value=p,
        n=nrow(df)
      ),
      interpretation_notes=list(
        "DIDは平行トレンド仮定を前提とします",
        "Event Studyで事前トレンドを確認してください"
      )
    ),
    tables=list(
      list(
        id="did_effect",
        title="DID 推定",
        data=did_tbl
      ),
      list(
        id="group_means",
        title="Group means",
        data=means
      )
    ),
    figures=figures,
    warnings=list(),


    errors = list()
  )

}

run <- run_recipe_impl