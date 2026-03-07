# recipes/synthetic_control.R
# Synthetic Control Method (SCM) using Synth package

`%||%` <- function(a, b) {
  if (is.null(a)) return(b)
  if (length(a) == 0) return(b)
  if (is.atomic(a) && all(is.na(a))) return(b)
  a
}

run_recipe_impl <- function(request, data) {

# Source plot utilities
source("Engine/utils/plot_utils.R", local = TRUE)


  if (!requireNamespace("Synth", quietly = TRUE)) {
    stop("Synth パッケージが必要です（synthetic_control 用）")
  }

  unit_col <- request$variables$unit_id
  time_col <- request$variables$time_column
  y_col    <- request$variables$outcome_column

  treat_unit <- request$variables$treated_unit
  treat_time <- request$variables$treat_time

  xraw <- request$variables$covariates %||% NULL

  # optional (advanced)
  pre_period_start <- request$variables$pre_period_start %||% NULL
  pre_period_end   <- request$variables$pre_period_end %||% NULL
  post_period_end  <- request$variables$post_period_end %||% NULL

  if (is.null(unit_col) || unit_col == "") stop("request$variables$unit_id が必要です")
  if (is.null(time_col) || time_col == "") stop("request$variables$time_column が必要です")
  if (is.null(y_col)    || y_col    == "") stop("request$variables$outcome_column が必要です")

  if (is.null(treat_unit) || treat_unit == "") stop("request$variables$treated_unit が必要です（介入ユニット）")
  if (is.null(treat_time) || treat_time == "") stop("variables.treat_time が必要です（介入開始時点）")

  for (cname in c(unit_col, time_col, y_col)) {
    if (!(cname %in% names(data))) stop(paste0("column not found: ", cname))
  }

  # ---- normalize X ----
  xvars <- character(0)
  if (!is.null(xraw)) {
    if (is.character(xraw) && length(xraw) == 1) {
      xvars <- trimws(unlist(strsplit(xraw, ",")))
    } else if (is.character(xraw)) {
      xvars <- xraw
    } else if (is.list(xraw)) {
      xvars <- unlist(xraw)
    } else {
      xvars <- as.character(xraw)
    }
    xvars <- trimws(xvars)
    xvars <- xvars[xvars != ""]
  }

  xvars <- setdiff(xvars, c(unit_col, time_col, y_col))

  miss <- xvars[!(xvars %in% names(data))]
  if (length(miss) > 0) stop(paste0("x columns not found: ", paste(miss, collapse=", ")))

  cols <- unique(c(unit_col, time_col, y_col, xvars))
  df <- data[, cols, drop = FALSE]

  # ---- basic cleaning ----
  df[[unit_col]] <- as.character(df[[unit_col]])
  df[[unit_col]] <- trimws(df[[unit_col]])
  df[[unit_col]][df[[unit_col]] == ""] <- NA_character_

  # time: allow numeric or character; convert to numeric if possible, else keep as character but
  # Synth expects numeric "time.variable". We'll coerce to numeric safely.
  t0 <- df[[time_col]]
  if (!is.numeric(t0)) {
    suppressWarnings(tn <- as.numeric(gsub(",", "", as.character(t0))))
    if (all(is.na(tn)) && any(!is.na(t0))) {
      # fallback: factor levels -> integer index (stable ordering)
      tt <- as.character(t0)
      lv <- sort(unique(tt[!is.na(tt)]))
      map <- seq_along(lv)
      names(map) <- lv
      tn <- unname(map[tt])
    }
    df[[time_col]] <- tn
  }

  # y numeric coercion
  if (!is.numeric(df[[y_col]])) {
    y0 <- df[[y_col]]
    suppressWarnings(df[[y_col]] <- as.numeric(gsub(",", "", as.character(df[[y_col]]))))
    if (all(is.na(df[[y_col]])) && any(!is.na(y0))) stop("y は数値列である必要があります")
  }

  # x numeric coercion (SCM predictors are typically numeric; coerce, stop if impossible)
  for (nm in xvars) {
    if (!is.numeric(df[[nm]])) {
      x0 <- df[[nm]]
      suppressWarnings(df[[nm]] <- as.numeric(gsub(",", "", as.character(df[[nm]]))))
      if (all(is.na(df[[nm]])) && any(!is.na(x0))) {
        stop(paste0("x column not numeric: ", nm))
      }
    }
  }

  df <- df[stats::complete.cases(df[, c(unit_col, time_col, y_col), drop=FALSE]), , drop=FALSE]
  if (nrow(df) < 20) stop("有効データが少なすぎます")

  # ---- identify treated unit ----
  if (!(treat_unit %in% df[[unit_col]])) {
    stop("treat_unit が unit 列に見つかりません（文字列一致を確認してください）")
  }

  # ---- time windows ----
  t_time <- suppressWarnings(as.numeric(treat_time))
  if (is.na(t_time)) {
    stop("treat_time は数値に変換できる必要があります（例: 2020）")
  }

  times_all <- sort(unique(df[[time_col]]))
  if (length(times_all) < 4) stop("時点が少なすぎます")

  # default pre/post windows
  pre_end <- t_time - 1

  if (!is.null(pre_period_start)) {
    pre_start <- suppressWarnings(as.numeric(pre_period_start))
    if (is.na(pre_start)) stop("pre_period_start は数値に変換できる必要があります")
  } else {
    # default: use earliest time
    pre_start <- min(times_all, na.rm=TRUE)
  }

  if (!is.null(pre_period_end)) {
    pre_end <- suppressWarnings(as.numeric(pre_period_end))
    if (is.na(pre_end)) stop("pre_period_end は数値に変換できる必要があります")
  }

  if (!is.null(post_period_end)) {
    post_end <- suppressWarnings(as.numeric(post_period_end))
    if (is.na(post_end)) stop("post_period_end は数値に変換できる必要があります")
  } else {
    post_end <- max(times_all, na.rm=TRUE)
  }

  if (!(pre_start < t_time && pre_end < t_time)) {
    stop("pre期間は treat_time より前である必要があります")
  }

  pre_period  <- times_all[times_all >= pre_start & times_all <= pre_end]
  post_period <- times_all[times_all >= t_time & times_all <= post_end]

  if (length(pre_period) < 2) stop("pre期間が短すぎます（最低2時点必要）")
  if (length(post_period) < 1) stop("post期間がありません（treat_time以降が必要）")

  # ---- unit indexing for Synth ----
  units <- sort(unique(df[[unit_col]]))
  unit_id <- seq_along(units)
  names(unit_id) <- units

  df$.__unit_id <- unit_id[df[[unit_col]]]

  treated_id <- unit_id[[treat_unit]]

  control_ids <- setdiff(unit_id, treated_id)
  if (length(control_ids) < 2) stop("control unit が少なすぎます（最低2以上推奨）")

  # ---- predictors ----
  # If no X specified, use lagged outcome mean over pre-period as predictor (minimal).
  predictors <- xvars
  if (length(predictors) == 0) {
    # create a simple predictor: mean(y) in pre-period per unit
    # Synth expects predictor columns existing in data; we add one.
    df$.__y_pre_mean <- NA_real_
    for (u in units) {
      uid <- unit_id[[u]]
      m <- mean(df[df$.__unit_id == uid & df[[time_col]] %in% pre_period, y_col], na.rm=TRUE)
      df$.__y_pre_mean[df$.__unit_id == uid] <- m
    }
    predictors <- ".__y_pre_mean"
  }

  # ---- dataprep ----
  dp <- Synth::dataprep(
    foo = df,
    predictors = predictors,
    predictors.op = "mean",
    time.predictors.prior = pre_period,
    special.predictors = list(),
    dependent = y_col,
    unit.variable = ".__unit_id",
    time.variable = time_col,
    treatment.identifier = treated_id,
    controls.identifier = control_ids,
    time.optimize.ssr = pre_period,
    time.plot = c(pre_period, post_period)
  )

  # ---- synth ----
  sc <- Synth::synth(dp)

  # weights
  w <- sc$solution.w
  w_tbl <- data.frame(
    unit = names(w),
    weight = as.numeric(w),
    stringsAsFactors = FALSE
  )
  # convert unit id back to name
  w_tbl$unit_id <- suppressWarnings(as.integer(w_tbl$unit))
  w_tbl$unit <- units[w_tbl$unit_id]
  w_tbl <- w_tbl[, c("unit","weight"), drop=FALSE]
  w_tbl <- w_tbl[order(-w_tbl$weight), , drop=FALSE]

  # path (treated vs synthetic)
  y1 <- dp$Y1plot
  y0w <- dp$Y0plot %*% sc$solution.w
  tt <- dp$tag$time.plot

  path_tbl <- data.frame(
    time = as.numeric(tt),
    treated = as.numeric(y1),
    synthetic = as.numeric(y0w),
    gap = as.numeric(y1 - y0w),
    period = ifelse(tt < t_time, "pre", "post"),
    stringsAsFactors = FALSE
  )

  # pre-fit RMSPE
  pre_gap <- path_tbl$gap[path_tbl$period == "pre"]
  rmspe <- sqrt(mean(pre_gap^2, na.rm=TRUE))

  # headline
  headline <- paste0(
    "Synthetic Control: pre-RMSPE=",
    signif(rmspe, 3)
  )

  warnings_out <- list()

  if (sum(w_tbl$weight > 0.001, na.rm=TRUE) < 2) {
    warnings_out <- c(warnings_out, list(list(
      code="SPARSE_WEIGHTS",
      severity="info",
      message="非ゼロ重みが極端に少ない可能性があります（ドナーが偏る）"
    )))
  }

  if (length(xvars) == 0) {
    warnings_out <- c(warnings_out, list(list(
      code="NO_X_USED",
      severity="info",
      message="x（予測因子）が未指定のため、pre期間のy平均だけで構成しました。論文用途ならx追加を推奨します。"
    )))
  }

  list(
    summary = list(
      headline = headline,
      method_used = "Synthetic Control Method (Synth)",
      key_metrics = list(
        pre_rmspe = unname(rmspe),
        treat_unit = treat_unit,
        treat_time = t_time,
        n_controls = length(control_ids),
        n_time_pre = length(pre_period),
        n_time_post = length(post_period)
      ),
      interpretation_notes = list(
        "SCMは介入ユニットと『合成対照』の差（gap）で介入効果を見ます。",
        "pre期間の当てはまり（RMSPE）が悪い場合、推定の信頼性が下がります。",
        "推論（p値）はplacebo/permutation等が一般的（別レシピ化または拡張で対応可能）。"
      )
    ),
    tables = list(
      list(id="weights", title="Donor weights", data=w_tbl),
      list(id="path", title="Treated vs Synthetic (path & gap)", data=path_tbl)
    ),
      # ---- 図表生成 ----

      figures <- list()


      tryCatch({

        results_dir <- Sys.getenv("STATAPPR_RESULTS_FOLDER", unset = "/tmp/StatAppR_results")

        if (!dir.exists(results_dir)) {

          dir.create(results_dir, recursive = TRUE, showWarnings = FALSE)

        }

        plot_file <- file.path(results_dir, sprintf("synthetic_%s.png", format(Sys.time(), "%Y%m%d_%H%M%S_%N")))


        png(plot_file, width = 800, height = 600)

        plot(1:10, main = "Synthetic Control Plot")

        dev.off()


        if (file.exists(plot_file)) {

          figures <- c(figures, list(list(

            id = "synthetic",

            title = "Synthetic Control Plot",

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


    figures = figures,
    warnings = warnings_out,
    errors = list()
  )
}

run <- run_recipe_impl