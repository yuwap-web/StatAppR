# recipes/pca_analysis.R

`%||%` <- function(a, b) {
  if (is.null(a)) return(b)
  if (length(a) == 0) return(b)
  if (is.atomic(a) && all(is.na(a))) return(b)
  a
}

run_recipe_impl <- function(request, data) {

  xraw <- request$variables$numeric_columns

  # advanced (optional; from recipes.json)
  center <- request$variables$center %||% TRUE
  scale_ <- request$variables$scale %||% TRUE
  n_components <- request$variables$n_components %||% 0  # 0 = all

  if (is.null(xraw) || length(xraw) == 0) {
    stop("request$variables$numeric_columns が必要です（数値列）")
  }

  # x normalization (array or "a,b")
  if (is.character(xraw) && length(xraw) == 1) {
    xs <- trimws(unlist(strsplit(xraw, ",")))
  } else if (is.character(xraw)) {
    xs <- xraw
  } else if (is.list(xraw)) {
    xs <- unlist(xraw)
  } else {
    xs <- as.character(xraw)
  }

  xs <- trimws(xs)
  xs <- xs[xs != ""]

  if (length(xs) < 2) stop("PCA requires at least 2 columns")

  miss <- xs[!(xs %in% names(data))]
  if (length(miss) > 0) stop(paste0("x columns not found: ", paste(miss, collapse = ", ")))

  X <- data[, xs, drop = FALSE]

  # numeric coercion
  for (nm in xs) {
    if (!is.numeric(X[[nm]])) {
      x0 <- X[[nm]]
      suppressWarnings(X[[nm]] <- as.numeric(gsub(",", "", as.character(X[[nm]]))))
      if (all(is.na(X[[nm]])) && any(!is.na(x0))) {
        stop(paste0("column not numeric: ", nm))
      }
    }
  }

  X <- stats::na.omit(X)
  if (nrow(X) < 3) stop("Not enough complete rows for PCA")

  # prcomp
  p <- stats::prcomp(X, center = isTRUE(center), scale. = isTRUE(scale_))

  var <- (p$sdev^2)
  pve <- var / sum(var)

  # how many PCs to show
  k_all <- length(pve)
  k <- k_all
  if (!is.null(n_components) && is.numeric(n_components) && length(n_components) == 1 && !is.na(n_components)) {
    if (n_components > 0) k <- min(k_all, as.integer(n_components))
  }
  # UI safety cap (still keep recipe intent)
  k <- min(k, 30)

  # scree (limit to k for readability)
  scree <- data.frame(
    pc = paste0("PC", seq_len(k)),
    proportion = as.numeric(pve[seq_len(k)]),
    cumulative = as.numeric(cumsum(pve)[seq_len(k)]),
    stringsAsFactors = FALSE
  )

  # loadings (limit columns to k)
  loadings <- as.data.frame(p$rotation[, seq_len(k), drop = FALSE])
  loadings$variable <- rownames(loadings)
  rownames(loadings) <- NULL
  loadings <- loadings[, c("variable", paste0("PC", seq_len(k))), drop = FALSE]

  # scores (limit columns to k)
  scores <- as.data.frame(p$x[, seq_len(k), drop = FALSE])
  scores$row_id <- seq_len(nrow(scores))
  scores <- scores[, c("row_id", paste0("PC", seq_len(k))), drop = FALSE]

  headline <- paste0("PCA完了：PC1寄与率=", round(pve[1] * 100, 1), "%（表示PC=", k, "）")

  list(
    summary = list(
      headline = headline,
      method_used = paste0("prcomp(center=", isTRUE(center), ", scale=", isTRUE(scale_), ")"),
      key_metrics = list(
        pc1_pve = unname(pve[1]),
        pc2_pve = ifelse(length(pve) >= 2, unname(pve[2]), NA_real_),
        n_rows_used = nrow(X),
        n_variables = length(xs),
        n_components_shown = k
      ),
      interpretation_notes = list(
        if (isTRUE(scale_)) "scale=TRUE: 変数の単位が異なる場合に推奨です。" else "scale=FALSE: 同一スケールの指標群に適します。",
        "寄与率が低い場合、次元削減の効果は限定的です。",
        "負荷量（loadings）は各変数が主成分にどれだけ寄与したかを示します。"
      )
    ),
    tables = list(
      list(id = "pca_scree", title = "寄与率（Scree）", data = scree),
      list(id = "pca_loadings", title = "主成分負荷量", data = loadings),
      list(id = "pca_scores", title = "主成分スコア", data = scores)
    ),
    figures = list(),
    warnings = list(),
    errors = list()
  )
}

run <- run_recipe_impl