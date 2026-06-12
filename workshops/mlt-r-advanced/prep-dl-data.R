# prep-dl-data.R : provenance of the datasets used in step 02 (run ONCE, NOT part of the build).
# You do NOT need to run this. The workshop already ships the prepared data in each data-raw/ folder.
# It is here so you can see exactly where the data comes from and regenerate it if you want.
# It downloads two real, public medical datasets and writes plain R arrays:
#   pneumoniamnist.rds : list(x = [N,1,28,28] float in [0,1], y = [N] in {1,2})  real chest X-rays
#   ecg.rds            : list(x = [N,140,1] float,            y = [N] in {1,2})  real ECG5000 traces
# Sources: PneumoniaMNIST (Zenodo record 10519652); ECG5000 (UCR, via the TensorFlow CSV mirror).
# The real-data path is base R only (download + a tiny .npy reader). torch/torchvision are used
# ONLY by the optional MNIST fallback, reached if Zenodo is unreachable. To regenerate into a
# folder of your choice, set MLT_OUT to that path and run this script with R.
suppressMessages({
  library(torch)
})
set.seed(123)
# default assumes run-from-repo-root; MLT_OUT lets a dev run point at an absolute data-raw path.
out_dir <- Sys.getenv("MLT_OUT", "workshops/mlt-r-advanced/data-raw")
per_class <- 400L

# --- minimal .npy / .npz reader (C-order, little-endian): avoids reticulate/numpy --------------
read_npy <- function(path) {
  con <- file(path, "rb"); on.exit(close(con))
  invisible(readBin(con, "raw", 6))                                   # magic \x93NUMPY
  invisible(readBin(con, "raw", 2))                                   # version
  hlen   <- readBin(con, "integer", n = 1, size = 2, endian = "little", signed = FALSE)
  header <- rawToChar(readBin(con, "raw", hlen))
  descr  <- sub(".*'descr':\\s*'([^']+)'.*", "\\1", header)           # e.g. |u1, <f4
  shape  <- as.integer(strsplit(gsub("[^0-9,]", "", sub(".*'shape':\\s*\\(([^)]*)\\).*", "\\1", header)), ",")[[1]])
  shape  <- shape[!is.na(shape)]
  size   <- if (grepl("[1]$", descr)) 1L else if (grepl("[2]$", descr)) 2L else 4L
  is_flt <- grepl("f", descr)
  signed <- !grepl("u", descr)
  dat <- readBin(con, what = if (is_flt) "double" else "integer",
                 n = prod(shape), size = size, endian = "little", signed = signed)
  aperm(array(dat, dim = rev(shape)), length(shape):1)                # C-order -> R column-major
}
read_npz <- function(path, keys) {
  ex <- tempfile(); dir.create(ex)
  utils::unzip(path, exdir = ex)
  stats::setNames(lapply(keys, function(k) read_npy(file.path(ex, paste0(k, ".npy")))), keys)
}

# --- 2D images: PneumoniaMNIST (28x28, binary), with an MNIST 2-class fallback ------------------
prep_pneumonia <- function() {
  url <- "https://zenodo.org/records/10519652/files/pneumoniamnist.npz?download=1"
  dst <- tempfile(fileext = ".npz")
  utils::download.file(url, dst, mode = "wb", quiet = TRUE)
  z <- read_npz(dst, c("train_images", "train_labels"))
  list(x = z$train_images, y = as.integer(z$train_labels) + 1L, src = "PneumoniaMNIST")  # 0/1 -> 1/2
}
prep_mnist_fallback <- function() {
  ds  <- torchvision::mnist_dataset(tempdir(), train = TRUE, download = TRUE)
  tg  <- as.integer(ds$targets)
  two <- sort(unique(tg))[1:2]                                        # the two lowest classes
  keep <- which(tg %in% two)
  xi  <- as.array(ds$data[keep, , ])                                  # [n,28,28] uint8
  list(x = xi, y = as.integer(factor(tg[keep])), src = "MNIST-2class")  # -> {1,2}
}

img <- tryCatch(prep_pneumonia(), error = function(e) { message("Pneumonia failed: ", conditionMessage(e)); NULL })
if (is.null(img)) {
  message("-> MNIST 2-class fallback")
  img <- prep_mnist_fallback()
}
idx <- {
  c1 <- which(img$y == 1L); c2 <- which(img$y == 2L)
  c(sample(c1, min(per_class, length(c1))), sample(c2, min(per_class, length(c2))))
}
# Save PLAIN R arrays (torch tensors do not round-trip through saveRDS, an external pointer);
# the workshop rebuilds the tensors with torch_tensor() at load time.
x_img <- array(img$x[idx, , ], dim = c(length(idx), 1L, 28L, 28L)) / 255   # [N,1,28,28] in [0,1]
y_img <- as.integer(img$y[idx])                                            # [N] in {1,2}
saveRDS(list(x = x_img, y = y_img), file.path(out_dir, "pneumoniamnist.rds"))
cat("images src:", img$src, "| shape:", paste(dim(x_img), collapse = "x"),
    "| labels:", paste(sort(unique(y_img)), collapse = ","), "\n")

# --- sequences: real ECG (ECG5000, binary normal/abnormal) from a stable public mirror ----------
# The TF-hosted CSV is ECG5000: 5000 rows = 140 signal columns + a trailing label column (1=normal,0=abnormal).
ecg_url <- "http://storage.googleapis.com/download.tensorflow.org/data/ecg.csv"
ecg <- utils::read.csv(ecg_url, header = FALSE)
sig  <- as.matrix(ecg[ , 1:140])
lab  <- as.integer(ecg[ , 141] == 1) + 1L                            # normal(1) -> 2 ; abnormal(0) -> 1
keep <- {
  c1 <- which(lab == 1L); c2 <- which(lab == 2L)
  c(sample(c1, min(per_class, length(c1))), sample(c2, min(per_class, length(c2))))
}
sig <- scale(sig[keep, ])                                            # z-score per time step across the cohort
x_seq <- array(as.numeric(sig), dim = c(nrow(sig), 140L, 1L))       # [N,140,1] plain array
y_seq <- as.integer(lab[keep])                                      # [N] in {1,2}
saveRDS(list(x = x_seq, y = y_seq), file.path(out_dir, "ecg.rds"))
cat("ecg shape:", paste(dim(x_seq), collapse = "x"),
    "| labels:", paste(sort(unique(y_seq)), collapse = ","), "\n")
cat("PREP OK\n")
