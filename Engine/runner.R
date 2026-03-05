#!/usr/bin/env Rscript
# =========================================
# Engine/runner.R  (v1 skeleton / near-ready)
# - Reads analysis_request.json
# - Validates / reads data / casts types / filters / missing
# - Dispatches recipe
# - Writes tables, figures, report (optional), repro pack
# - ALWAYS writes analysis_result.json (even on error)
# =========================================

suppressWarnings(suppressMessages({
  # Minimal dependencies (you can expand as needed)
  library(jsonlite)
}))

# ---------- Utilities ----------
now_iso <- function() {
  format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")
}

ensure_dir <- function(path) {
  if (!dir.exists(path)) dir.create(path, recursive = TRUE, showWarnings = FALSE)
}

safe_write_json <- function(obj, path) {
  ensure_dir(dirname(path))
  jsonlite::write_json(obj, path, pretty = TRUE, auto_unbox = TRUE, null = "null")
}

as_abs_path <- function(path) {
  # Accept absolute or relative; normalize
  tryCatch(normalizePath(path, winslash = "/", mustWork = FALSE), error = function(e) path)
}

# Convert relative artifact paths to relative-to-workdir (we keep relative in result.json)
rel_path <- function(workdir, fullpath) {
  w <- normalizePath(workdir, winslash = "/", mustWork = FALSE)
  f <- normalizePath(fullpath, winslash = "/", mustWork = FALSE)
  if (startsWith(f, w)) {
    sub(paste0("^", gsub("([\\^\\$\\.|\\(\\)\\[\\]\\*\\+\\?\\\\])", "\\\\\\1", w), "/?"), "", f)
  } else {
    fullpath
  }
}

append_error <- function(result, code, message, hint = "") {
  result$status <- "error"
  result$errors <- c(result$errors, list(list(code = code, severity = "error", message = message, hint = hint)))
  result
}

append_warning <- function(result, code, severity = "info", message = "") {
  result$warnings <- c(result$warnings, list(list(code = code, severity = severity, message = message)))
  result
}

# ---------- Load core modules ----------
# You can keep these as separate files; runner stays thin.
# If not yet implemented, create stubs in core/ to avoid runtime errors.
source_local <- function(path) {
  p <- file.path(dirname(sys.frame(1)$ofile %||% ""), path)
  if (!file.exists(p)) p <- file.path("Engine", path) # fallback for dev runs
  if (!file.exists(p)) p <- path
  if (!file.exists(p)) stop(sprintf("Missing source file: %s", path))
  source(p, local = TRUE)
}

`%||%` <- function(a, b) {
  if (is.null(a)) return(b)
  if (length(a) == 0) return(b)
  if (is.atomic(a) && all(is.na(a))) return(b)
  a
}

# Try to source core files; if you haven't created them yet, comment out progressively.
try({ source_local("core/validate.R") }, silent = TRUE)
try({ source_local("core/read_data.R") }, silent = TRUE)
try({ source_local("core/type_cast.R") }, silent = TRUE)
try({ source_local("core/missing.R") }, silent = TRUE)
try({ source_local("core/tables.R") }, silent = TRUE)
try({ source_local("core/plots.R") }, silent = TRUE)
try({ source_local("core/repro.R") }, silent = TRUE)
try({ source_local("core/report.R") }, silent = TRUE)

# ---------- Recipe dispatcher ----------
run_recipe <- function(recipe_id, request, data) {
  # Locate recipes dir based on this runner file location
  runner_file <- NULL

  # when executed via Rscript, --file=... が入ることが多い
  cf <- commandArgs(trailingOnly = FALSE)
  farg <- grep("^--file=", cf, value = TRUE)
  if (length(farg) >= 1) runner_file <- sub("^--file=", "", farg[1])

  # fallback: script is in workdir/Engine/runner.R (bundle copy)
  if (is.null(runner_file) || runner_file == "") {
    runner_file <- file.path(workdir, "Engine", "runner.R")
  }

  runner_dir <- dirname(normalizePath(runner_file, winslash = "/", mustWork = FALSE))
  recipes_dir <- normalizePath(file.path(runner_dir, "recipes"), winslash = "/", mustWork = FALSE)

  candidates <- c(
    file.path(recipes_dir, paste0(recipe_id, ".R")),
    file.path(recipes_dir, recipe_id),                 # just in case (no extension)
    file.path(workdir, "Engine", "recipes", paste0(recipe_id, ".R")),
    file.path(workdir, "Engine", "recipes", recipe_id)
  )

  recipe_path <- candidates[file.exists(candidates)][1]
  if (is.na(recipe_path) || is.null(recipe_path) || recipe_path == "") {
    stop(paste0("Recipe not found: ", recipe_id))
  }

  env <- new.env(parent = globalenv())
  env$request <- request
  env$data <- data
  sys.source(recipe_path, envir = env)

  # Expect recipe to define `run_recipe_impl(request, data)` OR `run(request, data)`
  if (exists("run_recipe_impl", envir = env, inherits = FALSE)) {
    return(get("run_recipe_impl", envir = env)(request, data))
  }
  if (exists("run", envir = env, inherits = FALSE)) {
    return(get("run", envir = env)(request, data))
  }

  stop(paste0("Recipe loaded but entry function not found in: ", recipe_path))
}
# ---------- Minimal fallback implementations (only for early Phase0) ----------
# If core/* not implemented yet, these provide basic behavior.
if (!exists("validate_request", mode = "function")) {
  validate_request <- function(req) {
    # Minimal checks; expand in core/validate.R
    required <- c("schema_version", "analysis_run_id", "recipe_id", "dataset", "output")
    missing_keys <- required[!required %in% names(req)]
    if (length(missing_keys) > 0) stop(paste("Missing keys:", paste(missing_keys, collapse = ", ")))
    if (is.null(req$output$workdir) || req$output$workdir == "") stop("output.workdir is required")
    TRUE
  }
}

if (!exists("read_dataset", mode = "function")) {
  read_dataset <- function(dataset_spec) {
    # Minimal CSV only; expand in core/read_data.R
    path <- dataset_spec$path
    fmt <- dataset_spec$format %||% "csv"
    if (fmt != "csv") stop("Fallback read_dataset supports csv only (implement core/read_data.R for excel).")
    enc <- dataset_spec$encoding %||% "utf-8"
    delim <- dataset_spec$delimiter %||% ","
    na_strings <- dataset_spec$na_strings %||% c("", "NA", "NaN", "NULL")

    # Use base read.csv for portability; swap to readr later.
    df <- utils::read.csv(path,
                          fileEncoding = enc,
                          sep = delim,
                          na.strings = na_strings,
                          stringsAsFactors = FALSE,
                          check.names = FALSE)
    df
  }
}

if (!exists("apply_column_types", mode = "function")) {
  apply_column_types <- function(df, column_types, tz = "Asia/Tokyo") {
    # Minimal conversions; implement robust parsing in core/type_cast.R
    if (is.null(column_types)) return(df)
    for (nm in names(column_types)) {
      if (!nm %in% names(df)) next
      t <- column_types[[nm]]
      if (is.null(t)) next

      if (t == "numeric") {
        suppressWarnings(df[[nm]] <- as.numeric(gsub(",", "", as.character(df[[nm]]))))
      } else if (t %in% c("factor", "ordered", "id")) {
        df[[nm]] <- as.factor(df[[nm]])
        if (t == "ordered") df[[nm]] <- as.ordered(df[[nm]])
      } else if (t == "logical") {
        v <- tolower(as.character(df[[nm]]))
        v[v %in% c("t", "true", "1")] <- "TRUE"
        v[v %in% c("f", "false", "0")] <- "FALSE"
        suppressWarnings(df[[nm]] <- as.logical(v))
      } else if (t == "date") {
        # Try common formats
        v <- as.character(df[[nm]])
        suppressWarnings({
          d <- as.Date(v)
          bad <- is.na(d) & !is.na(v) & nzchar(v)
          if (any(bad)) d[bad] <- as.Date(v[bad], format = "%Y/%m/%d")
          df[[nm]] <- d
        })
      } else if (t == "datetime") {
        v <- as.character(df[[nm]])
        suppressWarnings({
          dt <- as.POSIXct(v, tz = tz)
          bad <- is.na(dt) & !is.na(v) & nzchar(v)
          if (any(bad)) dt[bad] <- as.POSIXct(v[bad], format = "%Y/%m/%d %H:%M:%S", tz = tz)
          df[[nm]] <- dt
        })
      } else {
        df[[nm]] <- as.character(df[[nm]])
      }
    }
    df
  }
}

if (!exists("apply_filters", mode = "function")) {
  apply_filters <- function(df, filters) {
    # Minimal where filters: op in / == / != / < / <= / > / >=
    if (is.null(filters) || length(filters) == 0) return(df)

    for (f in filters) {
      if (is.null(f$type) || f$type != "where") next
      col <- f$column
      op <- f$op
      val <- f$value
      if (!col %in% names(df)) next

      x <- df[[col]]
      keep <- rep(TRUE, nrow(df))

      if (op == "in") {
        keep <- x %in% val
      } else if (op == "==") {
        keep <- x == val
      } else if (op == "!=") {
        keep <- x != val
      } else if (op == "<") {
        keep <- x < val
      } else if (op == "<=") {
        keep <- x <= val
      } else if (op == ">") {
        keep <- x > val
      } else if (op == ">=") {
        keep <- x >= val
      } else {
        next
      }
      df <- df[which(keep %in% TRUE), , drop = FALSE]
    }
    df
  }
}

if (!exists("apply_missing_strategy", mode = "function")) {
  apply_missing_strategy <- function(df, required_columns, missing) {
    # v1 default: complete_cases on required columns only
    strategy <- missing$strategy %||% "complete_cases"
    keep_na_level <- missing$keep_na_as_level_for_factors %||% FALSE

    # Optionally keep NA as factor level (rare in v1)
    if (keep_na_level) {
      for (nm in names(df)) {
        if (is.factor(df[[nm]])) df[[nm]] <- addNA(df[[nm]], ifany = TRUE)
      }
    }

    if (strategy == "complete_cases") {
      cols <- intersect(required_columns, names(df))
      if (length(cols) == 0) return(list(df = df, n_excluded = 0))
      before <- nrow(df)
      df2 <- df[stats::complete.cases(df[, cols, drop = FALSE]), , drop = FALSE]
      list(df = df2, n_excluded = before - nrow(df2))
    } else {
      # pairwise: do not drop rows globally (recipe should handle)
      list(df = df, n_excluded = 0)
    }
  }
}

if (!exists("write_tables", mode = "function")) {
 write_tables <- function(workdir, tables) {
  out <- list()
  if (length(tables) == 0) return(out)
  ensure_dir(file.path(workdir, "tables"))

  for (t in tables) {
    id <- t$id %||% ""
    title <- t$title %||% ""

    # ★保険：id が空なら書かない（.csv を防ぐ）
    if (!is.character(id) || length(id) == 0 || is.na(id[1]) || id[1] == "") next
    id <- id[1]

    df <- t$data
    if (is.null(df)) next

    path <- file.path(workdir, "tables", paste0(id, ".csv"))
    utils::write.csv(df, path, row.names = FALSE, na = "")
    out <- c(out, list(list(id = id, title = title, path = rel_path(workdir, path))))
  }
  out
}
}
if (!exists("write_figures", mode = "function")) {
  write_figures <- function(workdir, figures, width = 7, height = 5, dpi = 150) {
    out <- list()
    if (length(figures) == 0) return(out)
    ensure_dir(file.path(workdir, "figures"))
    for (f in figures) {
      id <- f$id
      title <- f$title
      p <- f$plot
      path <- file.path(workdir, "figures", paste0(id, ".png"))
      # Try ggsave if ggplot2 is available; else error
      if (!requireNamespace("ggplot2", quietly = TRUE)) stop("ggplot2 required to save figures")
      ggplot2::ggsave(filename = path, plot = p, width = width, height = height, dpi = dpi)
      out <- c(out, list(list(id = id, title = title, path = rel_path(workdir, path))))
    }
    out
  }
}

if (!exists("write_repro", mode = "function")) {
  write_repro <- function(workdir, request, stdout_path, stderr_path) {
    ensure_dir(file.path(workdir, "repro"))
    # Copy request
    safe_write_json(request, file.path(workdir, "repro", "analysis_request.json"))

    # session info
    si <- utils::capture.output(sessionInfo())
    writeLines(si, file.path(workdir, "repro", "sessionInfo.txt"))

    # minimal input hash info (you can replace with real sha256)
    hash_lines <- c(
      paste0("dataset_path=", request$dataset$path %||% ""),
      paste0("recipe_id=", request$recipe_id %||% ""),
      paste0("analysis_run_id=", request$analysis_run_id %||% "")
    )
    writeLines(hash_lines, file.path(workdir, "repro", "input_hash.txt"))

    # Save stdout/stderr copies if present
    if (file.exists(stdout_path)) file.copy(stdout_path, file.path(workdir, "repro", "stdout.txt"), overwrite = TRUE)
    if (file.exists(stderr_path)) file.copy(stderr_path, file.path(workdir, "repro", "stderr.txt"), overwrite = TRUE)

    # analysis.R (re-run script) – minimal starter; replace with a full generator later
    analysis_r <- c(
      "library(jsonlite)",
      "req <- read_json('analysis_request.json', simplifyVector = TRUE)",
      "# TODO: call runner.R with this request path or re-implement same steps",
      "# This file is a placeholder in Phase0; in Phase1 generate a complete runnable script."
    )
    writeLines(analysis_r, file.path(workdir, "repro", "analysis.R"))

    list(
      r_script = "repro/analysis.R",
      session_info = "repro/sessionInfo.txt",
      lockfile = "repro/renv.lock",
      request_copy = "repro/analysis_request.json",
      data_hash = "repro/input_hash.txt"
    )
  }
}

# ---------- Main ----------
args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) {
  cat("Usage: runner.R <analysis_request.json>\n", file = stderr())
stop("RUNNER_BAD_ARGS")
}

request_path <- as_abs_path(args[[1]])
if (!file.exists(request_path)) {
  cat(sprintf("Request file not found: %s\n", request_path), file = stderr())
stop("RUNNER_BAD_ARGS")
}

# Read request
request <- NULL
try({
  request <- jsonlite::read_json(request_path, simplifyVector = TRUE)
}, silent = TRUE)

# Workdir must be available even if request parsing failed
workdir <- NULL
if (!is.null(request) && !is.null(request$output$workdir)) {
  workdir <- as_abs_path(request$output$workdir)
} else {
  # fallback: put next to request
  workdir <- dirname(request_path)
}
ensure_dir(workdir)
ensure_dir(file.path(workdir, "tables"))
ensure_dir(file.path(workdir, "figures"))
ensure_dir(file.path(workdir, "report"))
ensure_dir(file.path(workdir, "repro"))
ensure_dir(file.path(workdir, "logs"))

# --- ここから追加 ---
# clear previous error log (so old errors don't confuse)
old_err <- file.path(workdir, "repro", "error_log.txt")
if (file.exists(old_err)) file.remove(old_err)
# --- ここまで ---

# Prepare base result (always written)
analysis_run_id <- (request$analysis_run_id %||% "unknown_run")
recipe_id <- (request$recipe_id %||% "unknown_recipe")

result <- list(
  schema_version = "1.0",
  analysis_run_id = analysis_run_id,
  recipe_id = recipe_id,
  status = "ok",
  started_at = now_iso(),
  ended_at = NULL,
  summary = list(
    headline = "",
    method_used = "",
    key_metrics = list(),
    interpretation_notes = list()
  ),
  data_used = list(
    n_rows_in = NA,
    n_rows_used = NA,
    exclusions = list()
  ),
  artifacts = list(
    tables = list(),
    figures = list(),
    report = list(),
    repro = list()
  ),
  warnings = list(),
  errors = list()
)

# Capture stdout/stderr to files (avoid leaking data; keep it minimal)
stdout_tmp <- file.path(workdir, "logs", "stdout.txt")
stderr_tmp <- file.path(workdir, "logs", "stderr.txt")

zz_out <- file(stdout_tmp, open = "wt")
zz_err <- file(stderr_tmp, open = "wt")

sink(zz_out, type = "output")
sink(zz_err, type = "message")

on.exit({
  # Always attempt to write result JSON. If it fails, write a diagnostic file.
  tryCatch({
    out_path <- file.path(workdir, "analysis_result.json")
    safe_write_json(result, out_path)
  }, error = function(e) {
    # Write a minimal diagnostic log so we can see why result.json couldn't be written.
    ensure_dir(file.path(workdir, "logs"))
    msg <- paste0("FAILED_TO_WRITE_RESULT_JSON: ", conditionMessage(e))
    writeLines(msg, file.path(workdir, "logs", "result_write_error.txt"))
  })
}, add = TRUE)

# Also copy request into workdir for transparency
if (!is.null(request)) {
  safe_write_json(request, file.path(workdir, "analysis_request.json"))
}

# Set TZ & locale basics (best-effort)
Sys.setenv(TZ = "Asia/Tokyo")

# Run pipeline with robust error handling
tryCatch({
  if (is.null(request)) stop("Failed to parse analysis_request.json")

  # 1) Validate request schema (core/validate.R preferred)
  validate_request(request)

  # 2) Read data
  df <- read_dataset(request$dataset)
  result$data_used$n_rows_in <- nrow(df)

  # 3) Apply column type casting (R is source of truth)
  df <- apply_column_types(df, request$column_types, tz = "Asia/Tokyo")

  # 4) Apply filters
  df <- apply_filters(df, request$filters)

  # 5) Missing handling (limit to required columns when possible)
  #    Required columns: recipe variables + any explicit filter columns + group columns, etc.
  #    In Phase0 we approximate: all columns referenced in variables + filters.
  required_cols <- c()
  if (!is.null(request$variables)) {
    # Collect strings and string vectors from variables recursively
    collect_cols <- function(x) {
      cols <- c()
      if (is.null(x)) return(cols)
      if (is.character(x)) return(x)
      if (is.list(x)) {
        for (k in names(x)) cols <- c(cols, collect_cols(x[[k]]))
      }
      cols
    }
    required_cols <- unique(collect_cols(request$variables))
  }
  if (!is.null(request$filters) && length(request$filters) > 0) {
    required_cols <- unique(c(required_cols, vapply(request$filters, function(f) f$column %||% NA_character_, "")))
    required_cols <- required_cols[!is.na(required_cols)]
  }
  miss_res <- apply_missing_strategy(df, required_cols, request$missing %||% list(strategy = "complete_cases"))
  df2 <- miss_res$df
  n_excl <- miss_res$n_excluded %||% 0
  if (n_excl > 0) {
    result$data_used$exclusions <- c(result$data_used$exclusions,
                                    list(list(reason = "complete_cases", n_excluded = n_excl)))
  }

  # 6) Run recipe
  out <- run_recipe(request$recipe_id, request, df2)
if (is.null(out$tables)) out$tables <- list()
if (is.null(out$figures)) out$figures <- list()

  # 7) Write tables / figures
  result$artifacts$tables <- write_tables(workdir, out$tables %||% list())
  result$artifacts$figures <- write_figures(workdir, out$figures %||% list())

  # 8) Summary
  if (!is.null(out$summary)) {
    result$summary$headline <- out$summary$headline %||% ""
    result$summary$method_used <- out$summary$method_used %||% ""
    result$summary$key_metrics <- out$summary$key_metrics %||% list()
    result$summary$interpretation_notes <- out$summary$interpretation_notes %||% list()
  }

  # 9) Data used
  result$data_used$n_rows_used <- nrow(df2)

  # 10) Warnings
  if (!is.null(out$warnings) && length(out$warnings) > 0) {
    result$warnings <- c(result$warnings, out$warnings)
  }

  # 11) Repro (always)
  result$artifacts$repro <- write_repro(workdir, request, stdout_tmp, stderr_tmp)

  # 12) Report (optional; implement core/report.R later)
  if (!is.null(request$output$report$enabled) && isTRUE(request$output$report$enabled)) {
    # Placeholder: report generation can be added later
    # result$artifacts$report <- render_report(...)
    # For Phase0 we just leave empty.
    result$artifacts$report <- list()
  }

  # Safety: fill headline if empty
hl <- result$summary$headline
if (is.null(hl) || length(hl) == 0 || !is.character(hl) || is.na(hl[1]) || hl[1] == "") {
  result$summary$headline <- "解析が完了しました（詳細を確認してください）。"
} else if (length(hl) > 1) {
  result$summary$headline <- hl[1]
}

}, error = function(e) {
  # Capture details without dumping data
  msg <- conditionMessage(e)

  # Save full stack/log to repro/error_log.txt
  ensure_dir(file.path(workdir, "repro"))
  err_path <- file.path(workdir, "repro", "error_log.txt")
  trace <- utils::capture.output(traceback())
  writeLines(c(paste0("ERROR: ", msg), "", "TRACEBACK:", trace), err_path)

  result <<- append_error(
    result,
    code = "RUNNER_FAILED",
    message = "解析の実行中にエラーが発生しました。",
    hint = "repro/error_log.txt と repro/stderr.txt を確認してください。"
  )
  result$summary$headline <<- "エラーのため解析を完了できませんでした。"

  # Still attempt to write repro artifacts
  if (!is.null(request)) {
    try({
      result$artifacts$repro <<- write_repro(workdir, request, stdout_tmp, stderr_tmp)
    }, silent = TRUE)
  }
})
# ---- Force-write result at end (do not rely on on.exit) ----
tryCatch({
  out_path2 <- file.path(workdir, "analysis_result.json")
  safe_write_json(result, out_path2)
}, error = function(e) {
  ensure_dir(file.path(workdir, "logs"))
  writeLines(paste0("FORCED_WRITE_FAILED: ", conditionMessage(e)),
             file.path(workdir, "logs", "result_write_error.txt"))
})

# Close sinks (best-effort)
try(sink(type = "message"), silent = TRUE)
try(sink(type = "output"), silent = TRUE)
try(close(zz_out), silent = TRUE)
try(close(zz_err), silent = TRUE)
# Note: analysis_result.json is written in on.exit() no matter what
