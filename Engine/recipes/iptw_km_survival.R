# recipes/iptw_km_survival.R

source(file.path(runner_dir, "utils", "plot_utils.R"))

`%||%` <- function(a, b) {
  if (is.null(a)) return(b)
  if (length(a) == 0) return(b)
  if (is.atomic(a) && all(is.na(a))) return(b)
  a
}

run_recipe_impl <- function(request, data) {

  if (!requireNamespace("survival", quietly = TRUE)) {
    stop("survival パッケージが必要です")
  }

  time_col  <- request$variables$time_column
  status_col<- request$variables$event_column
  treat_col <- request$variables$treatment_column
  xraw      <- request$variables$covariates

  ps_model  <- request$variables$ps_model %||% "logit"
  stabilized <- request$variables$stabilized %||% TRUE
  trim_val   <- request$variables$trim %||% 0

  if (is.null(time_col)) stop("request$variables$time_column が必要です")
  if (is.null(status_col)) stop("request$variables$event_column が必要です")
  if (is.null(treat_col)) stop("request$variables$treatment_column が必要です")
  if (is.null(xraw) || length(xraw)==0) stop("request$variables$covariates が必要です")

  # ---- normalize x ----
  if (is.character(xraw) && length(xraw)==1) {
    xvars <- trimws(unlist(strsplit(xraw,",")))
  } else if (is.character(xraw)) {
    xvars <- xraw
  } else if (is.list(xraw)) {
    xvars <- unlist(xraw)
  } else {
    xvars <- as.character(xraw)
  }

  xvars <- trimws(xvars)
  xvars <- xvars[xvars!=""]
  xvars <- setdiff(xvars,c(time_col,status_col,treat_col))

  if (length(xvars)<1) stop("共変量が必要です")

  for (cname in c(time_col,status_col,treat_col,xvars)) {
    if (!(cname %in% names(data))) stop(paste0("column not found: ",cname))
  }

  df <- data[,unique(c(time_col,status_col,treat_col,xvars)),drop=FALSE]

  # ---- numeric coercion ----
  if (!is.numeric(df[[time_col]])) {
    suppressWarnings(
      df[[time_col]] <- as.numeric(gsub(",","",as.character(df[[time_col]])))
    )
  }

  st <- df[[status_col]]
  if (is.factor(st)) st <- as.character(st)
  if (is.logical(st)) st <- ifelse(st,1,0)

  if (is.character(st)) {

    v <- tolower(trimws(st))

    v[v %in% c("1","event","yes","true","y")] <- "1"
    v[v %in% c("0","censor","censored","no","false","n")] <- "0"

    suppressWarnings(st <- as.numeric(v))
  }

  if (!all(st %in% c(0,1),na.rm=TRUE)) {
    stop("status は 0/1 必須")
  }

  df[[status_col]] <- st

  # ---- treat normalize ----
  tr <- df[[treat_col]]

  if (is.factor(tr)) tr <- as.character(tr)
  if (is.logical(tr)) tr <- ifelse(tr,1,0)

  if (is.character(tr)) {

    v <- tolower(trimws(tr))

    v[v %in% c("1","yes","true","t")] <- "1"
    v[v %in% c("0","no","false","f")] <- "0"

    suppressWarnings(tr <- as.numeric(v))
  }

  if (!all(tr %in% c(0,1),na.rm=TRUE)) {
    stop("treat は 0/1 必須")
  }

  df[[treat_col]] <- tr

  df <- df[stats::complete.cases(df),,drop=FALSE]

  if (nrow(df)<20) stop("データが少なすぎます")

  treat <- df[[treat_col]]

  # ---- PS model ----
  fml_ps <- stats::as.formula(
    paste0(treat_col," ~ ",paste(xvars,collapse=" + "))
  )

  link_fun <- if (ps_model=="probit") stats::binomial(link="probit") else stats::binomial()

  ps_fit <- stats::glm(
    fml_ps,
    data=df,
    family=link_fun
  )

  ps <- stats::predict(ps_fit,type="response")

  # ---- weights ----
  if (stabilized) {

    p_t <- mean(treat)

    w <- ifelse(
      treat==1,
      p_t/ps,
      (1-p_t)/(1-ps)
    )

  } else {

    w <- ifelse(
      treat==1,
      1/ps,
      1/(1-ps)
    )

  }

  if (trim_val>0) {
    w[w>trim_val] <- trim_val
  }

  # ---- survival fit (weighted) ----
  surv_obj <- survival::Surv(
    time=df[[time_col]],
    event=df[[status_col]]
  )

  fit <- survival::survfit(
    surv_obj ~ df[[treat_col]],
    weights=w
  )

  # ---- logrank (weighted) ----
  lr <- survival::survdiff(
    surv_obj ~ df[[treat_col]],
    rho=0
  )

  p_lr <- 1 - stats::pchisq(lr$chisq,df=1)

  logrank_tbl <- data.frame(
    chisq=lr$chisq,
    df=1,
    p_value=p_lr,
    stringsAsFactors=FALSE
  )

  # ---- weight summary ----
  w_tbl <- data.frame(
    weight_mean=mean(w),
    weight_sd=sd(w),
    weight_max=max(w),
    weight_99pct=quantile(w,0.99),
    stringsAsFactors=FALSE
  )

  # ---- figure ----
  km_file <- tryCatch(
    make_km_plot(
      fit,
      df,
      group_col=treat_col
    ),
    error=function(e) NULL
  )

  figures_out <- list()

  if (!is.null(km_file)) {

    # km_file is a list(curve=path, risk_table=path), extract curve path
    if (!is.null(km_file$curve)) {
      figures_out <- list(
        list(
          id="iptw_km",
          title="IPTW Weighted Kaplan-Meier Curve",
          path=km_file$curve
        )
      )
    }

  }

  headline <- paste0(
    "IPTW KM: log-rank p=",
    signif(p_lr,3)
  )

  list(

    summary=list(
      headline=headline,
      method_used="IPTW weighted Kaplan-Meier",
      key_metrics=list(
        p_value=p_lr,
        n_used=nrow(df)
      ),
      interpretation_notes=list(
        "IPTW により共変量調整した生存曲線です。",
        "PS overlap と weight distribution を確認してください。"
      )
    ),

    tables=list(

      list(
        id="logrank",
        title="Log-rank test",
        data=logrank_tbl
      ),

      list(
        id="weight_summary",
        title="Weight summary",
        data=w_tbl
      )

    ),

    figures=figures_out,

    warnings=list(),
    errors = list()
  )

}

run <- run_recipe_impl