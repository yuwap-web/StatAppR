# recipes/ps_matching.R

# Utilities will be pre-loaded by runner.R into the environment
if (exists("runner_dir")) {
  tryCatch({
    source(file.path(runner_dir, "utils", "plot_utils.R"))
  }, error = function(e) {
    # Silently continue if already loaded
  })
}

`%||%` <- function(a,b){
  if(is.null(a)) return(b)
  if(length(a)==0) return(b)
  if(is.atomic(a) && all(is.na(a))) return(b)
  a
}

run_recipe_impl <- function(request,data){

  treat_col <- request$variables$treatment_column %||% request$variables$treat
  y_col     <- request$variables$outcome_column %||% request$variables$y
  xraw      <- request$variables$covariates %||% request$variables$x

  caliper <- request$variables$caliper %||% 1.0
  smd_thr <- request$variables$balance_threshold %||% 0.1

  if(is.null(treat_col)) stop("request$variables$treatment_column required")
  if(is.null(y_col)) stop("request$variables$outcome_column required")
  if(is.null(xraw)) stop("request$variables$covariates required")

  # ---- normalize x ----
  if(is.character(xraw) && length(xraw)==1){
    xvars <- trimws(unlist(strsplit(xraw,",")))
  } else if(is.character(xraw)){
    xvars <- xraw
  } else if(is.list(xraw)){
    xvars <- unlist(xraw)
  } else {
    xvars <- as.character(xraw)
  }

  xvars <- trimws(xvars)
  xvars <- xvars[xvars!=""]

  for(cname in c(treat_col,y_col,xvars)){
    if(!(cname %in% names(data))){
      stop(paste0("column not found: ",cname))
    }
  }

  df <- data[,c(treat_col,y_col,xvars),drop=FALSE]

  df <- df[stats::complete.cases(df),]

  treat <- df[[treat_col]]

  if(!all(treat %in% c(0,1))){
    stop("treat must be 0/1")
  }

  # ---- PS estimation ----

  fml <- stats::as.formula(
    paste0(treat_col,"~",paste(xvars,collapse="+"))
  )

  ps_fit <- stats::glm(
    fml,
    data=df,
    family=stats::binomial()
  )

  ps <- stats::predict(ps_fit,type="response")

  df$ps <- ps

  treated  <- df[df[[treat_col]]==1,]
  control  <- df[df[[treat_col]]==0,]

  # ---- nearest neighbor matching with adaptive caliper ----

  warnings_out <- list()

  # Try matching with initial caliper, then expand if needed
  caliper_seq <- c(caliper, caliper*1.5, caliper*2.0, caliper*3.0, Inf)
  actual_caliper <- caliper
  matches <- list()

  for(cal in caliper_seq) {

    used_control <- rep(FALSE, nrow(control))
    matches <- list()

    for(i in seq_len(nrow(treated))){
      d <- abs(control$ps - treated$ps[i])
      d[used_control] <- Inf
      j <- which.min(d)

      if(d[j] <= cal){
        matches[[length(matches)+1]] <- data.frame(
          treat=treated[i,],
          control=control[j,]
        )
        used_control[j] <- TRUE
      }
    }

    if(length(matches) >= 5) {
      actual_caliper <- cal
      break
    }
  }

  # Check minimum matches
  min_matches <- max(2, min(5, nrow(treated) %/% 3))

  if(length(matches) < min_matches) {
    stop(paste0(
      "Insufficient matches (got ", length(matches), ", need at least ", min_matches, ").\n",
      "Consider larger caliper or more data. Current data: treat=", nrow(treated),
      ", control=", nrow(control)
    ))
  }

  # Warning if caliper was expanded
  if(actual_caliper > caliper) {
    warnings_out <- c(warnings_out, list(list(
      code = "CALIPER_EXPANDED",
      severity = "info",
      message = paste0(
        "PS matching caliper expanded from ", signif(caliper,3), " to ", signif(actual_caliper,3),
        " to find sufficient matches (n=", length(matches), ")."
      )
    )))
  }

  # ---- build matched dataset ----

  treat_rows <- do.call(
    rbind,
    lapply(matches, function(m) m$treat)
  )

  control_rows <- do.call(
    rbind,
    lapply(matches, function(m) m$control)
  )

  matched <- rbind(treat_rows, control_rows)

  if (nrow(matched) == 0) {
    stop("No matches found. Consider adjusting caliper or checking data.")
  }

  treat_m <- matched[[treat_col]]
  y_m     <- matched[[y_col]]

  # Ensure numeric
  if (!is.numeric(y_m)) {
    suppressWarnings(y_m <- as.numeric(as.character(y_m)))
  }
  if (!is.numeric(treat_m)) {
    suppressWarnings(treat_m <- as.numeric(as.character(treat_m)))
  }

  # ---- ATT estimate ----

  if (any(is.na(y_m)) || any(is.na(treat_m))) {
    stop("y or treatment contains NA after matching")
  }

  att <- mean(y_m[treat_m==1], na.rm = TRUE) - mean(y_m[treat_m==0], na.rm = TRUE)

  se <- sqrt(stats::var(y_m)/length(y_m))

  ci_low  <- att - 1.96*se
  ci_high <- att + 1.96*se

  z <- att/se
  p <- 2*(1-stats::pnorm(abs(z)))

  att_tbl <- data.frame(
    treatment_effect=att,
    se=se,
    conf_low=ci_low,
    conf_high=ci_high,
    p_value=p,
    stringsAsFactors=FALSE
  )

  # ---- SMD ----

  smd_fun <- function(x,t){

    m1 <- mean(x[t==1])
    m0 <- mean(x[t==0])

    s1 <- stats::var(x[t==1])
    s0 <- stats::var(x[t==0])

    (m1-m0)/sqrt((s1+s0)/2)

  }

  smd_before <- sapply(xvars,function(v){
    smd_fun(df[[v]],df[[treat_col]])
  })

  smd_after <- sapply(xvars,function(v){
    smd_fun(matched[[v]],matched[[treat_col]])
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

  if(!is.null(balance_file)){
    figures_out <- c(figures_out,list(
      list(
        id="balance_plot",
        title="Covariate balance",
        path=balance_file
      )
    ))
  }

  ps_file <- tryCatch(
    make_ps_overlap_plot(ps,treat),
    error=function(e) NULL
  )

  if(!is.null(ps_file)){
    figures_out <- c(figures_out,list(
      list(
        id="ps_overlap",
        title="Propensity score overlap",
        path=ps_file
      )
    ))
  }

  headline <- paste0(
    "PS matching ATT=",
    signif(att,3),
    " (p=",signif(p,3),")"
  )

  list(

    summary=list(
      headline=headline,
      method_used="Propensity Score Matching (nearest neighbor)",
      key_metrics=list(
        att=att,
        p_value=p,
        n_matched=nrow(matched)
      ),
      interpretation_notes=list(
        "nearest neighbor matching を使用しています。",
        "SMD < 0.1 が共変量バランスの目安です。"
      )
    ),

    tables=list(
      list(
        id="att",
        title="Treatment effect (ATT)",
        data=att_tbl
      ),
      list(
        id="balance",
        title="Covariate balance",
        data=balance_tbl
      )
    ),

    figures=figures_out,

    warnings=list(),
    errors = list()
  )

}

run <- run_recipe_impl