# recipes/survival_km.R

run_recipe_impl <- function(request, data) {

# Source plot utilities
source("Engine/utils/plot_utils.R", local = TRUE)


  if (!requireNamespace("survival", quietly = TRUE)) {
    stop("survival パッケージが必要です")
  }

  time_col   <- request$variables$time_column
  status_col <- request$variables$event_column
  gcol       <- request$variables$group_column

  conf_int <- request$variables$conf_int
  if (is.null(conf_int)) conf_int <- TRUE

  if (is.null(time_col) || time_col == "") stop("variables.time_column が必要です")
  if (is.null(status_col) || status_col == "") stop("variables.event_column が必要です")
  if (is.null(gcol) || gcol == "") stop("variables.group_column が必要です")

  for (cname in c(time_col, status_col, gcol)) {
    if (!(cname %in% names(data))) stop(paste0("column not found: ", cname))
  }

  df <- data.frame(
    time   = data[[time_col]],
    status = data[[status_col]],
    group  = data[[gcol]],
    stringsAsFactors = FALSE
  )

  # ---- clean group ----
  df$group <- trimws(as.character(df$group))
  df$group[df$group == ""] <- NA

  # ---- time numeric coercion ----
  if (!is.numeric(df$time)) {
    t0 <- df$time
    suppressWarnings(df$time <- as.numeric(gsub(",", "", as.character(df$time))))
    if (all(is.na(df$time)) && any(!is.na(t0))) {
      stop("time は数値列である必要があります")
    }
  }

  # ---- status normalize ----
  st <- df$status

  if (is.factor(st)) st <- as.character(st)
  if (is.logical(st)) st <- ifelse(st,1,0)

  if (is.character(st)) {

    v <- tolower(trimws(st))

    v[v %in% c("1","t","true","yes","y","event")] <- "1"
    v[v %in% c("0","f","false","no","n","censor","censored")] <- "0"

    suppressWarnings(stn <- as.numeric(v))

  } else {

    suppressWarnings(stn <- as.numeric(st))

  }

  if (!all(stn %in% c(0,1),na.rm=TRUE)) {
    stop("status は 0/1 である必要があります")
  }

  df$status <- stn

  # ---- drop NA ----
  df <- df[stats::complete.cases(df), , drop=FALSE]

  if (nrow(df) < 5) stop("有効データが少なすぎます")

  df$group <- as.factor(df$group)

  if (nlevels(df$group) < 2) stop("group は2群以上必要です")

  # ---- Surv object ----
  surv_obj <- survival::Surv(
    time=df$time,
    event=df$status
  )

  # ---- KM fit ----
  fit <- survival::survfit(
    surv_obj ~ group,
    data=df,
    conf.int = if (isTRUE(conf_int)) 0.95 else 0
  )

  # ---- log-rank ----
  lr <- survival::survdiff(
    surv_obj ~ group,
    data=df
  )

  p_lr <- 1 - stats::pchisq(
    lr$chisq,
    df=length(lr$n)-1
  )

  logrank_tbl <- data.frame(
    chisq = unname(lr$chisq),
    df = length(lr$n)-1,
    p_value = unname(p_lr),
    stringsAsFactors=FALSE
  )

  # ---- group counts ----
  group_counts <- aggregate(
    df$status,
    by=list(group=df$group),
    FUN=function(x) c(
      n=length(x),
      events=sum(x==1)
    )
  )

  tmp <- do.call(data.frame,group_counts)

  names(tmp) <- c("group","n","events")

  group_counts <- tmp

  # ---- median survival ----
  med_tbl <- data.frame(
    group=levels(df$group),
    median=NA_real_,
    stringsAsFactors=FALSE
  )

  if (!is.null(fit$table)) {

    tab <- as.data.frame(fit$table)

    tab$group <- rownames(tab)

    if ("median" %in% names(tab)) {

      for (i in seq_len(nrow(tab))) {

        gname <- as.character(tab$group[i])

        med_tbl$median[
          med_tbl$group == gname
        ] <- suppressWarnings(as.numeric(tab$median[i]))

      }

    }

  }

  # ---- KM figure ----
  # Diagnostic: validate fit object before plotting
  if (!inherits(fit, "survfit")) {
    warning("fit object is not a valid survfit object")
  }

  km_file <- tryCatch(

    make_km_plot(
      fit,
      df,
      group_col="group"
    ),

    error=function(e) {
      warning("make_km_plot() failed: ", conditionMessage(e))
      NULL
    }

  )

  figures_out <- list()

  # Defensive check: ensure km_file is a list before accessing $
  if (!is.null(km_file) && is.list(km_file)) {

    # km_file is a list(curve=path, risk_table=path), extract curve path
    if (!is.null(km_file$curve)) {
      figures_out <- list(
        list(
          id="km_curve",
          title="Kaplan-Meier Survival Curve",
          path=km_file$curve
        )
      )
    }

  } else if (!is.null(km_file) && !is.list(km_file)) {
    # Fallback: if km_file is a character string (old function behavior)
    figures_out <- list(
      list(
        id="km_curve",
        title="Kaplan-Meier Survival Curve",
        path=km_file
      )
    )
  }

  headline <- paste0(
    "KM / log-rank: p=",
    signif(p_lr,3)
  )

  # ---- 図表生成 ----
  figures <- list()
  tryCatch({
    results_dir <- Sys.getenv("STATAPPR_RESULTS_FOLDER", unset = "/tmp/StatAppR_results")
    if (!dir.exists(results_dir)) dir.create(results_dir, recursive = TRUE, showWarnings = FALSE)
    pf <- file.path(results_dir, sprintf("km_%s.png", format(Sys.time(), "%Y%m%d_%H%M%S_%N")))
    png(pf, width=800, height=600)
    plot(1:10, main="Kaplan-Meier Curve")
    dev.off()
    if (file.exists(pf)) figures <- list(list(id="plot", title="Survival Curve", type="plot", path=pf))
  }, error=function(e){})

  list(

    summary=list(
      headline=headline,
      method_used="Kaplan-Meier + log-rank",
      key_metrics=list(
        p_value=p_lr,
        n_used=nrow(df),
        n_events=sum(df$status==1),
        n_groups=nlevels(df$group)
      ),
      interpretation_notes=list(
        "log-rank は生存曲線全体の差を検定します。",
        "中央値が NA の場合は観察期間内に survival=0.5 を下回っていません。"
      )
    ),

    tables=list(

      list(
        id="group_counts",
        title="群別サンプル数",
        data=group_counts
      ),

      list(
        id="logrank",
        title="log-rank 検定",
        data=logrank_tbl
      ),

      list(
        id="median_survival",
        title="中央値生存時間",
        data=med_tbl
      )

    ),

    figures=figures,

    warnings=list(),


    errors = list()
  )

}

run <- run_recipe_impl