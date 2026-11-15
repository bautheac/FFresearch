#!/usr/bin/env Rscript
# Rebuild the committed pkgdown site in docs/ from the current package.
#
# Why this is not a plain `pkgdown::build_site()` call (see
# ../verification-spec-3.md for the memory record):
#
# - build_site() defaults to install = TRUE, which runs a full source install
#   (tools:::data2LazyLoadDB loads all seven datasets at once, ~3 GB) and would
#   OOM a 3-4 GB container -- the same failure that forced the hybrid install
#   scripts next to this one.
# - pkgload::load_all(), used for examples, loads every .rda in data/ into one
#   environment, with the same footprint.
#
# Neither is needed here: the package ships no examples ("checking examples ...
# NONE") and no vignettes/articles, so reference pages render from man/*.Rd
# alone and the home page from README.md. install = FALSE, new_process = FALSE
# and examples = FALSE therefore keep this R process at ~136 MB peak RSS while
# producing byte-identical HTML -- see the equivalence check in
# ../pkgdown-rebuild.md. The figure is printed at the end of a successful run.
#
# The build runs in a rocker/r-ver container with the repo mounted at /work:
#   docker exec <c> Rscript /work/docs/pkgdown-rebuild/build-site.R
#   docker cp <c>:/scratch/site-new /tmp/site-new
#   sh docs/pkgdown-rebuild/sync-into-docs.sh /tmp/site-new docs/
#   python3 docs/pkgdown-rebuild/check-site.py "$PWD"
#
# Options:
#   --dst <dir>       where to write the site (default /scratch/site-new)
#   --keep-agents     publish the AGENTS.md page, which is dropped by default
#   --pkg <dir>       package source (default: this script's repo root)
#   --chown <dir>     hand the output to this directory's owner (default: the
#                     package source). The container runs as root, so without
#                     this every build leaves root-owned HTML that the host
#                     user cannot move, delete, or `docker cp` over -- which is
#                     exactly the chore noted in docs/verification-spec-3.md.
#   --preflight-only  check the toolchain and exit without building, so a
#                     wrapper can ask "is this container ready?" cheaply.

args <- commandArgs(trailingOnly = TRUE)
dst <- "/scratch/site-new"
if ("--dst" %in% args) dst <- args[which(args == "--dst") + 1L]
keep_agents <- "--keep-agents" %in% args
no_chown <- "--no-chown" %in% args
chown_arg <- if ("--chown" %in% args) args[which(args == "--chown") + 1L] else NULL

# Preflight. Each of these fails later with a message that does not name the
# fix, so check them here and say what to install (rocker/r-ver ships none of
# it): `docker exec <c> apt-get install -y pandoc libuv1 && Rscript -e
# 'install.packages(c("pkgdown","data.table"))'`.
#
# Ordered, and every probe guarded: with pkgdown absent its dependencies are
# absent too, and calling into them is how this preflight once crashed with
# "there is no package called 'rmarkdown'" instead of reporting the fix.
missing <- character()
report <- function(...) missing <<- c(missing, ...)

if (!nzchar(system.file(package = "pkgdown"))) {
  # Presence on disk, not loadability: system.file() does not load namespaces,
  # so this stays informative when fs/libuv are the real problem.
  report("pkgdown: install.packages(\"pkgdown\")")
} else {
  # fs, which pkgdown imports, dyn.loads the system libuv; the p3m binary build
  # of fs does not bundle it. Without libuv1 the failure is
  # "libuv.so.1: cannot open shared object file" from inside library(pkgdown).
  if (!tryCatch({ loadNamespace("fs"); TRUE }, error = function(e) FALSE)) {
    report("libuv1 (fs dyn.loads it): apt-get install -y libuv1")
  }
  # pandoc renders README.md into the home page; without it build_home_index
  # stops with "Pandoc is not installed". rmarkdown ships with pkgdown.
  if (!tryCatch(rmarkdown::pandoc_available(), error = function(e) FALSE)) {
    report("pandoc (renders README.md into the home page): apt-get install -y pandoc")
  }
}
if (length(missing)) {
  stop("missing build prerequisites:\n  - ", paste(missing, collapse = "\n  - "),
       call. = FALSE)
}
if ("--preflight-only" %in% args) {
  message("PREFLIGHT_OK pkgdown ", as.character(packageVersion("pkgdown")),
          " | pandoc ", as.character(rmarkdown::pandoc_version()))
  quit(status = 0L)
}

src <- if ("--pkg" %in% args) {
  args[which(args == "--pkg") + 1L]
} else {
  # repo root = two levels up from this script's directory
  self <- sub("^--file=", "", grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE))
  if (length(self)) normalizePath(file.path(dirname(self), "..", "..")) else "/work"
}
# Default: hand the output to whoever owns the repo being built.
chown_dir <- if (!is.null(chown_arg)) chown_arg else src

message("pkgdown ", as.character(packageVersion("pkgdown")),
        " | pandoc ", as.character(rmarkdown::pandoc_version()),
        "\nsrc: ", src, "\ndst: ", dst)

dir.create(dst, showWarnings = FALSE, recursive = TRUE)

# Build in-process, without installing the package or running examples.
pkgdown::build_site(
  pkg = src,
  override = list(destination = dst),
  examples = FALSE,
  run_dont_run = FALSE,
  lazy = FALSE,
  new_process = FALSE,
  install = FALSE,
  devel = FALSE,
  preview = FALSE,
  quiet = FALSE
)

# AGENTS.md is agent infrastructure (repo conventions for coding agents), not
# package documentation. pkgdown renders every unhandled *.md at the source
# root into a site page, so drop that page and its sitemap entry from the
# published site instead of shipping it to the public GitHub Pages site.
if (!keep_agents) {
  agents_html <- file.path(dst, "AGENTS.html")
  if (file.exists(agents_html)) {
    unlink(agents_html)
    message("dropped AGENTS.html (agent-infrastructure page)")
  }
  sitemap <- file.path(dst, "sitemap.xml")
  if (file.exists(sitemap)) {
    lines <- readLines(sitemap, warn = FALSE)
    keep <- !grepl("/AGENTS\\.html", lines)
    if (sum(!keep)) {
      writeLines(lines[keep], sitemap)
      message("dropped ", sum(!keep), " AGENTS.html line(s) from sitemap.xml")
    }
  }
}

# Hand the output to the host user so the sync step and any later `docker cp`
# can move it: the container runs as root, and root-owned HTML in a bind mount
# is the chore docs/verification-spec-3.md warns about. Not fatal on failure --
# the site is built either way, and failing the build over file ownership would
# be worse than telling the operator to clean up via the container.
if (!no_chown && Sys.info()[["sysname"]] == "Linux") {
  st <- file.info(chown_dir)
  if (is.na(st$uid)) {
    message("NOTE: cannot stat ", chown_dir, "; output stays root-owned")
  } else {
    # base R has no chown() (Sys.chown does not exist -- an earlier version of
    # this script called it and died here), so shell out.
    rc <- system2("chown", c("-R", shQuote(sprintf("%d:%d", st$uid, st$gid)), shQuote(dst)))
    if (identical(as.integer(rc), 0L)) {
      message(sprintf("chowned %s to %d:%d (owner of %s)", dst, st$uid, st$gid, chown_dir))
    } else {
      message(sprintf(paste("NOTE: chown -R %d:%d %s failed (exit %s);",
                            "output stays root-owned, remove it via the container"),
                      st$uid, st$gid, dst, rc))
    }
  }
}

# Success here means "pkgdown ran", not "the site is publishable": that is
# check-site.py's job, run against this output or against docs/ after syncing.
#
# Own peak, for the record: /proc, not the cgroup counter. In-container
# /sys/fs/cgroup/memory.peak proved unreliable to read across `docker exec`
# states (a run that had held a 1.4 GB object reported 0.06 GiB, and apt alone
# had already raised it to 376 MB), so VmHWM of this process is the figure that
# means something. This R process peaks at ~136 MB (the container's cgroup
# high-water for the same run, ~424 MB, also covers the pandoc subprocess and
# page cache). An install of the same tree does not finish under 3 GiB.
rss <- tryCatch({
  s <- readLines("/proc/self/status", warn = FALSE)
  # VmHWM is in kB, so kB / 1024 = MB.
  as.numeric(sub("VmHWM:\\s+([0-9]+).*", "\\1", grep("^VmHWM:", s, value = TRUE)[1])) / 1024
}, error = function(e) NA_real_)
message(sprintf("SITE_BUILD_OK dst=%s | peak RSS %s", dst,
                if (is.na(rss)) "n/a" else sprintf("%.0f MB", rss)))
