# recipes/pca_analysis.R
run_recipe_impl <- function(request, data) {
  xraw <- request$variables$x
  if (is.null(xraw) || xraw == "") stop("x (comma-separated numeric columns) not specified")

  xs <- trimws(unlist(strsplit(xraw, ",")))
  xs <- xs[xs != ""]
  if (length(xs) < 2) stop("PCA requires at least 2 columns")

  miss <- xs[!(xs %in% names(data))]
  if (length(miss) > 0) stop(paste0("x columns not found: ", paste(miss, collapse = ", ")))

  X <- data[, xs, drop = FALSE]
  # numeric check
  for (nm in xs) {
    if (!is.numeric(X[[nm]])) {
      suppressWarnings(X[[nm]] <- as.numeric(X[[nm]]))
    }
  }

  X <- stats::na.omit(X)
  if (nrow(X) < 3) stop("Not enough complete rows for PCA")

  p <- prcomp(X, center = TRUE, scale. = TRUE)
  var <- (p$sdev^2)
  pve <- var / sum(var)

  scree <- data.frame(
    pc = paste0("PC", seq_along(pve)),
    proportion = as.numeric(pve),
    cumulative = as.numeric(cumsum(pve)),
    stringsAsFactors = FALSE
  )

  loadings <- as.data.frame(p$rotation)
  loadings$variable <- rownames(loadings)
  rownames(loadings) <- NULL

  scores <- as.data.frame(p$x)
  scores$row_id <- seq_len(nrow(scores))
  scores <- scores[, c("row_id", colnames(p$x)), drop = FALSE]

  list(
    summary = list(
      headline = paste0("PCA完了：PC1寄与率=", round(pve[1]*100, 1), "%"),
      method_used = "prcomp (center+scale)",
      key_metrics = list(
        list(name="pc1_pve", value=pve[1]),
        list(name="n_rows_used", value=nrow(X))
      ),
      interpretation_notes = list(
        "変数のスケールが異なる場合、scale=TRUEが重要です。",
        "寄与率が低い場合、次元削減の効果は限定的です。"
      )
    ),
    tables = list(
      pca_scree = scree,
      pca_loadings = loadings,
      pca_scores = scores
    ),
    figures = list()
  )
}
run <- run_recipe_impl