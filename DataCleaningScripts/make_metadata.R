#' Make Recover metadata
#'

`%>%` <- magrittr::`%>%`

counts <- read.csv("Counts/maxcounts.csv")
under40 <- read.csv("Counts/maxcounts_under40.csv")
success <- read.csv("Nesting/nest_success.csv")

counts_metadata <- data.frame(name = as.vector(colnames(counts))) %>%
  dplyr::mutate(class=sapply(counts,class),
                min=sapply(counts,min,na.rm = TRUE),
                max=sapply(counts,max,na.rm = TRUE),
                description=c("unique location id (see colonies table)","year","see colonies table",
                              "observer colony name (see colonies table)","reported colony latitude",
                              "reported colony longitude","see species list","number of nesting pairs",
                              "observer comments"))
write.table(counts_metadata, "Counts/maxcounts_metadata.csv", row.names = FALSE, na = "", sep = ",", quote = 5)

under40_metadata <- data.frame(name = as.vector(colnames(under40))) %>%
  dplyr::mutate(class=sapply(under40,class),
                min=sapply(under40,min,na.rm = TRUE),
                max=sapply(under40,max,na.rm = TRUE),
                description=c("unique location id (see colonies table)","year","see colonies table",
                              "observer colony name (see colonies table)","reported colony latitude",
                              "reported colony longitude","wca location of observation",
                              rep("number of nesting pairs",19),"observer comments",
                              "total nesting pairs of 5 target species"))
write.table(under40_metadata, "Counts/maxcounts_under40_metadata.csv", row.names = FALSE, 
            na = "", sep = ",", quote = 5)

# nest success
success_metadata <- data.frame(name = as.vector(colnames(success))) %>%
  dplyr::mutate(class=sapply(success,class),
                min=sapply(success,min,na.rm = TRUE),
                max=sapply(success,max,na.rm = TRUE),
                description=c("year","see colonies table","unique nest id","see species list",
                              "number of days incubating","was incubation successful (1) or not (0)",
                              "number of days chicks in nest","did chicks successfully fledge",
                              "number of eggs","number of chicks","number of chicks fledged",
                              "clutch type","number of young lost","confirmed successful nest",
                              "confirmed failed nest","nest start date",
                              "fledge or failure date","observer comments"))
write.table(success_metadata, "Nesting/nest_success_metadata.csv", row.names = FALSE, 
            na = "", sep = ",", quote = 5)
