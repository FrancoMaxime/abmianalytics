library(rvest)
library(dplyr)
library(curl)

## where to put the downloaded, unzipped results
## the script will create folders:
## ROOT/SPECIES/current
## ROOT/SPECIES/future
## with raster files etc in each.
ROOT <- "e:/peter/bam/climate-preds"

url <- "https://borealbirds.databasin.org/pages/bam-download"

links <- read_html(url) %>% html_nodes("a") %>% html_attr("href")
links <- links[grepl("amazonaws", links)]
links_current <- links[grepl("_current", links)]
links_future <- links[grepl("_future", links)]
get_spp <- function(x) sapply(strsplit(sapply(strsplit(x, "/"), "[[", 6), "_"), "[[", 1)
names(links_current) <- get_spp(links_current)
names(links_future) <- get_spp(links_future)
stopifnot(all(names(links_current) == names(links_future)))

SPP <- names(links_current)
i <- SPP[1] # set checkpoint

for (i in SPP[which(SPP == i):length(SPP)]) {
    cat("\n\n--->>> Grabbing", i, "for ya' <<<---\n")
    flush.console()
    if (!dir.exists(file.path(ROOT, i)))
        dir.create(file.path(ROOT, i))

    if (!dir.exists(file.path(ROOT, i, "current")))
        dir.create(file.path(ROOT, i, "current"))
    download.file(links_current[i], file.path(ROOT, i, "current", "tmp.zip"))
    unzip(file.path(ROOT, i, "current", "tmp.zip"), exdir=file.path(ROOT, i, "current"))
    unlink(file.path(ROOT, i, "current", "tmp.zip"))

    if (!dir.exists(file.path(ROOT, i, "future")))
        dir.create(file.path(ROOT, i, "future"))
    download.file(links_future[i], file.path(ROOT, i, "future", "tmp.zip"))
    unzip(file.path(ROOT, i, "future", "tmp.zip"), exdir=file.path(ROOT, i, "future"))
    unlink(file.path(ROOT, i, "future", "tmp.zip"))
}
