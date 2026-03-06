# recipes/iptw_ate.R

# Utilities will be pre-loaded by runner.R into the environment
# These source() calls are kept for backward compatibility
if (exists("runner_dir")) {
  tryCatch({
    source(file.path(runner_dir, "utils", "plot_utils.R"))
  }, error = function(e) {
    # Silently continue if already loaded
  })

  tryCatch({
    source(file.path(runner_dir, "utils", "balance_plot.R"))
  }, error = function(e) {
    # Silently continue if already loaded
  })
}

run_recipe_impl <- function(request, data) {

  treat_col <- request$variables$treat
  y_col     <- request$variables$y
  xraw      <- request$variables$x

  ps_model  <- request$variables$ps_model %||% "logit"
  stabilized <- request$variables$stabilized %||% TRUE
  trim_val   <- request$variables$trim %||% 0
  smd_thr    <- request$variables$balance_threshold %||% 0.1

  if (is.null(treat_col) || treat_col == "") stop("variables.treat が必要です")
  if (is.null(y_col)     || y_col     == "") stop("variables.y が必要です")
  if (is.null(xraw) || length(xraw) == 0) stop("variables.x が必要です")

  # ---- normalize x columns ----
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
  xvars <- setdiff(xvars, c(treat_col, y_col))

  if (length(xvars) < 1) stop("共変量が指定されていません")

  for (cname in c(treat_col, y_col, xvars)) {
    if (!(cname %in% names(data))) stop(paste0("column not found: ", cname))
  }

  df <- data[, unique(c(treat_col, y_col, xvars)), drop=FALSE]

  # ---- treat normalize ----
  tr <- df[[treat_col]]

  if (is.factor(tr)) tr <- as.character(tr)
  if (is.logical(tr)) tr <- ifelse(tr,1,0)

  if (is.character(tr)) {
    v <- tolower(trimws(tr))
    v[v %in% c("1","t","true","yes","y")] <- "1"
    v[v %in% c("0","f","false","no","n")] <- "0"
    suppressWarnings(tr <- as.numeric(v))
  }

  if (!all(tr %in% c(0,1), na.rm=TRUE)) {
    stop("treat は 0/1 である必要があります")
  }

  df[[treat_col]] <- tr

  # ---- y numeric ----
  if (!is.numeric(df[[y_col]])) {
    y0 <- df[[y_col]]
    suppressWarnings(df[[y_col]] <- as.numeric(gsub(",", "", as.character(df[[y_col]]))))
    if (all(is.na(df[[y_col]])) && any(!is.na(y0))) {
      stop("y は数値列である必要があります")
    }
  }

  # ---- drop NA ----
  df <- df[stats::complete.cases(df), , drop=FALSE]

  if (nrow(df) < 10) stop("有効データが少なすぎます")

  # ---- PS model ----
  fml <- stats::as.formula(
    paste0(treat_col," ~ ",paste(xvars,collapse=" + "))
  )

  link_fun <- if (ps_model == "probit") stats::binomial(link="probit") else stats::binomial()

  ps_fit <- stats::glm(
    fml,
    data=df,
    family=link_fun
  )

  ps <- stats::predict(ps_fit,type="response")

  # ---- weights ----
  treat <- df[[treat_col]]

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

  if (!is.null(trim_val) && trim_val > 0) {
    w[w > trim_val] <- trim_val
  }

  # ---- weighted ATE ----
  y <- df[[y_col]]

  ate <- weighted.mean(y[treat==1],w[treat==1]) -
         weighted.mean(y[treat==0],w[treat==0])

  se <- sqrt(stats::var(y)/length(y))

  ci_low <- ate - 1.96*se
  ci_high<- ate + 1.96*se

  z <- ate/se
  p <- 2*(1-stats::pnorm(abs(z)))

  ate_tbl <- data.frame(
    treatment_effect=ate,
    se=se,
    conf_low=ci_low,
    conf_high=ci_high,
    p_value=p,
    stringsAsFactors=FALSE
  )

  # ---- PS summary ----
  ps_tbl <- data.frame(
    ps_mean=mean(ps),
    ps_sd=stats::sd(ps),
    ps_min=min(ps),
    ps_max=max(ps),
    stringsAsFactors=FALSE
  )

  # ---- weight summary ----
  w_tbl <- data.frame(
    weight_mean=mean(w),
    weight_sd=stats::sd(w),
    weight_max=max(w),
    weight_99pct=stats::quantile(w,0.99),
    stringsAsFactors=FALSE
  )

  # ---- SMD function ----
  smd_fun <- function(x,t,w=NULL) {

    if (is.null(w)) {

      m1 <- mean(x[t==1])
      m0 <- mean(x[t==0])
      s1 <- stats::var(x[t==1])
      s0 <- stats::var(x[t==0])

    } else {

      m1 <- weighted.mean(x[t==1],w[t==1])
      m0 <- weighted.mean(x[t==0],w[t==0])

      s1 <- stats::var(x[t==1])
      s0 <- stats::var(x[t==0])
    }

    (m1-m0)/sqrt((s1+s0)/2)
  }

  smd_before <- sapply(xvars,function(v){
    smd_fun(df[[v]],treat)
  })

  smd_after <- sapply(xvars,function(v){
    smd_fun(df[[v]],treat,w)
  })

  balance_tbl <- data.frame(
    covariate=xvars,
    smd_before=as.numeric(smd_before),
    smd_after=as.numeric(smd_after),
    stringsAsFactors=FALSE
  )

  # ---- plots ----
  figures_out <- list()

  balance_file <- tryCatch(
    make_balance_plot(balance_tbl,smd_thr),
    error=function(e) NULL
  )

  if (!is.null(balance_file)) {
    figures_out <- c(figures_out,list(
      list(
        id="balance_plot",
        title="Covariate Balance Plot",
        path=balance_file
      )
    ))
  }

  ps_file <- tryCatch(
    make_ps_overlap_plot(ps,treat),
    error=function(e) NULL
  )

  if (!is.null(ps_file)) {
    figures_out <- c(figures_out,list(
      list(
        id="ps_overlap",
        title="Propensity Score Overlap",
        path=ps_file
      )
    ))
  }

  w_file <- tryCatch(
    make_weight_hist(w),
    error=function(e) NULL
  )

  if (!is.null(w_file)) {
    figures_out <- c(figures_out,list(
      list(
        id="weight_hist",
        title="IPTW Weight Distribution",
        path=w_file
      )
    ))
  }

  headline <- paste0("IPTW推定 ATE = ",signif(ate,3),
                     " (p=",signif(p,3),")")

  list(

    summary=list(
      headline=headline,
      method_used="Inverse Probability of Treatment Weighting",
      key_metrics=list(
        ate=ate,
        p_value=p,
        n_used=nrow(df)
      ),
      interpretation_notes=list(
        "PSモデルにより逆確率重みを計算しています。",
        "Balance plotで共変量バランスを確認してください。",
        "SMD < 0.1 が一般的なバランス基準です。"
      )
    ),

    tables=list(
      list(id="ate",title="Treatment Effect (ATE)",data=ate_tbl),
      list(id="ps_summary",title="Propensity Score Summary",data=ps_tbl),
      list(id="weight_summary",title="Weight Summary",data=w_tbl),
      list(id="balance",title="Covariate Balance",data=balance_tbl)
    ),

    figures=figures_out,

    warnings=list()

  )
}

run <- run_recipe_impl