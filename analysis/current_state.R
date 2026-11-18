# Independent synthetic operational-data assessment.
# Copyright (c) 2026 David Brown. All rights reserved.
# This file does not include any original client analytical code or records.

read_conversations <- function(path) {
  data <- read.csv(path, stringsAsFactors = FALSE, na.strings = "", colClasses = "character")
  needed <- c("conversation_id", "started_at", "channel", "team", "tags")
  if (!all(needed %in% names(data))) stop("Missing required columns")
  if (anyNA(data$conversation_id) || any(!nzchar(trimws(data$conversation_id)))) stop("Missing conversation IDs")
  if (anyDuplicated(data$conversation_id)) stop("Duplicate conversation IDs")
  dates <- as.Date(data$started_at, format = "%Y-%m-%d")
  if (anyNA(dates)) stop("Invalid interaction date")
  data$month <- format(dates, "%Y-%m")
  data$has_tag <- !is.na(data$tags) & nzchar(trimws(data$tags))
  data
}

expand_tags <- function(data) {
  parts <- lapply(seq_len(nrow(data)), function(i) {
    if (!data$has_tag[i]) return(NULL)
    tokens <- unique(trimws(strsplit(data$tags[i], ";", fixed = TRUE)[[1]]))
    tokens <- tokens[nzchar(tokens)]
    if (!length(tokens)) return(NULL)
    data.frame(conversation_id = data$conversation_id[i],
               tag = tokens, stringsAsFactors = FALSE)
  })
  parts <- Filter(Negate(is.null), parts)
  if (!length(parts)) return(data.frame(conversation_id = character(), tag = character()))
  unique(do.call(rbind, parts))
}

profile_quality <- function(data) {
  n <- nrow(data)
  data.frame(conversations = n,
             tagged = sum(data$has_tag),
             untagged = sum(!data$has_tag),
             tag_coverage_pct = if (n) round(100 * mean(data$has_tag), 1) else 0,
             stringsAsFactors = FALSE)
}

monthly_volume <- function(data) {
  if (!nrow(data)) return(data.frame(month = character(), conversations = integer(), tagged = integer(), untagged = integer(), coverage_pct = numeric()))
  months <- sort(unique(data$month))
  do.call(rbind, lapply(months, function(m) {
    slice <- data[data$month == m, , drop = FALSE]
    data.frame(month = m, conversations = nrow(slice),
               tagged = sum(slice$has_tag), untagged = sum(!slice$has_tag),
               coverage_pct = round(100 * mean(slice$has_tag), 1))
  }))
}

tag_frequencies <- function(tags) {
  if (!nrow(tags)) return(data.frame(tag = character(), conversations = integer()))
  tab <- as.data.frame(table(tags$tag), stringsAsFactors = FALSE)
  names(tab) <- c("tag", "conversations")
  tab[order(-tab$conversations, tab$tag), , drop = FALSE]
}

cooccurrence <- function(tags) {
  if (!nrow(tags)) return(data.frame(tag_a = character(), tag_b = character(), conversations = integer()))
  groups <- split(tags$tag, tags$conversation_id)
  pairs <- unlist(lapply(groups, function(x) {
    if (length(x) < 2) return(character())
    apply(combn(sort(unique(x)), 2), 2, paste, collapse = "|||")
  }), use.names = FALSE)
  if (!length(pairs)) return(data.frame(tag_a = character(), tag_b = character(), conversations = integer()))
  tab <- sort(table(pairs), decreasing = TRUE)
  split_pairs <- strsplit(names(tab), "|||", fixed = TRUE)
  result <- data.frame(tag_a = vapply(split_pairs, `[`, character(1), 1),
                       tag_b = vapply(split_pairs, `[`, character(1), 2),
                       conversations = as.integer(tab))
  result[order(-result$conversations, result$tag_a, result$tag_b), , drop = FALSE]
}

recommendations <- function(quality, monthly, frequencies) {
  rows <- c()
  if (quality$untagged > 0) rows <- c(rows, "Audit missing classifications and define clear fallback values.")
  if (nrow(monthly) > 1 && length(unique(monthly$coverage_pct)) > 1)
    rows <- c(rows, "Monitor classification coverage by month to detect consistency changes.")
  if (any(startsWith(frequencies$tag, "source_")) && any(startsWith(frequencies$tag, "intent_")))
    rows <- c(rows, "Keep source and intent as separate governed reporting dimensions.")
  if (!length(rows)) rows <- "Review the data model and monitor quality before automation changes."
  data.frame(recommendation = rows, stringsAsFactors = FALSE)
}

analyse <- function(path) {
  data <- read_conversations(path)
  tags <- expand_tags(data)
  q <- profile_quality(data)
  m <- monthly_volume(data)
  f <- tag_frequencies(tags)
  p <- cooccurrence(tags)
  if (sum(m$conversations) != nrow(data)) stop("Monthly counts fail reconciliation")
  if (q$tagged + q$untagged != nrow(data)) stop("Coverage counts fail reconciliation")
  list(quality = q, monthly = m, tags = f, cooccurrence = p,
       recommendations = recommendations(q, m, f))
}

write_results <- function(result, directory, charts = TRUE) {
  dir.create(directory, showWarnings = FALSE, recursive = TRUE)
  for (name in names(result))
    write.csv(result[[name]], file.path(directory, paste0(name, ".csv")), row.names = FALSE)
  if (!charts) return(invisible(result))
  if (!requireNamespace("ggplot2", quietly = TRUE)) stop("Install ggplot2 to render charts")
  monthly <- result$monthly
  p1 <- ggplot2::ggplot(monthly, ggplot2::aes(x = month, y = conversations, group = 1)) +
    ggplot2::geom_line() + ggplot2::geom_point() +
    ggplot2::labs(title = "Fictional conversation volume by month", x = "Month", y = "Distinct conversations") +
    ggplot2::theme_minimal()
  p2 <- ggplot2::ggplot(monthly, ggplot2::aes(x = month, y = coverage_pct)) +
    ggplot2::geom_col() + ggplot2::coord_cartesian(ylim = c(0, 100)) +
    ggplot2::labs(title = "Fictional tagging coverage", x = "Month", y = "Share of conversations tagged (%)") +
    ggplot2::theme_minimal()
  ggplot2::ggsave(file.path(directory, "monthly_volume.png"), p1, width = 7, height = 4, dpi = 140)
  ggplot2::ggsave(file.path(directory, "tag_coverage.png"), p2, width = 7, height = 4, dpi = 140)
  invisible(result)
}

# Execute only when invoked directly as an Rscript, not when sourced by tests.
if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  input <- if (length(args) >= 1) args[[1]] else "data/fictional_conversations.csv"
  output <- if (length(args) >= 2) args[[2]] else "output/r-analysis"
  result <- analyse(input)
  write_results(result, output)
  print(result$quality)
  cat("Synthetic outputs written to", output, "\n")
}
