# SFWMD Report Table
report_year <- 2023

library(wader)
library(xlsx)

wb <- createWorkbook()
#--------------------
# DEFINE CELL STYLES 
#--------------------
# title and subtitle styles
title_style <- CellStyle(wb) + 
  Font(wb, heightInPoints = 12,
       name="Calibri", 
       underline = 1)

subtitle_style <- CellStyle(wb) + 
  Font(wb, 
       name="Calibri",
       heightInPoints = 10)

nesting_style <- CellStyle(wb) + 
  Font(wb, heightInPoints = 11,
       name="Calibri",
       color = "red",
       isItalic = FALSE,
       isBold = FALSE)

# data table styles
cs <- CellStyle(wb) +
  Font(wb, heightInPoints=11, name="Calibri") +
  Alignment(horizontal = "ALIGN_CENTER")

rowname_style <- CellStyle(wb)  +
  Font(wb, name = "Calibri") +
  Alignment(horizontal = "ALIGN_CENTER") +
  Border(position = c("RIGHT"),
         pen = c("BORDER_THIN"))  

colname_style <- CellStyle(wb) +
  Font(wb, name = "Calibri") +
  Alignment(horizontal = "ALIGN_CENTER") +
  Border(position = c("TOP", "BOTTOM"),
         pen = c("BORDER_THIN"))

xlsx.addTitle <- function(sheet, rowIndex, title, titleStyle) {
  rows <- createRow(sheet, rowIndex = rowIndex)
  sheetTitle <- createCell(rows, colIndex = 1)
  setCellValue(sheetTitle[[1,1]], title)
  setCellStyle(sheetTitle[[1,1]], titleStyle)
}

#### Get data ###
# counts
main <- max_counts() %>% 
  dplyr::ungroup() %>% 
  dplyr::filter(year==report_year) %>% 
  dplyr::select(-year) %>% 
  tidyr::pivot_wider(id_cols = colony, names_from = species, values_from = count) %>% 
  dplyr::mutate(total = rowSums(dplyr::across(where(is.numeric)), na.rm=TRUE)) %>%
  dplyr::full_join(load_datafile("SiteandMethods/colonies.csv", path = get_default_data_path()),by = dplyr::join_by(colony)) %>%
  dplyr::select(-c(group_id,subregion,colony,aka)) %>%
  dplyr::rename(wca=region, colony=display_name)
under40 <- load_datafile("Counts/maxcounts_under40.csv", path = get_default_data_path()) %>%
  dplyr::filter(year==report_year) %>%
  dplyr::select(-c(year,notes,colony_old,group_id))

# by WCA
lox <- main %>%
  dplyr::select(colony,wca,latitude, longitude,everything()) %>%
  dplyr::relocate(total, .after = last_col()) %>%
  dplyr::filter(total >= 40, wca=="1") %>%
  dplyr::arrange(wca, desc(total)) %>%
  dplyr::mutate(latitude = as.character(latitude), longitude = as.character(longitude)) %>%
  dplyr::bind_rows(dplyr::summarise_all(., ~if(is.numeric(.)) sum(., na.rm=TRUE) else "Total"))
under40_lox <- under40 %>% 
  dplyr::filter(wca=="1") %>%
  dplyr::select(colnames(lox),
                -c(colony,latitude,longitude,wca)) %>%
  dplyr::summarise_all(~ sum(., na.rm=TRUE)) %>%
  dplyr::mutate(colony=c("Colonies < 40 nests**"))
totals_lox <- tail(lox[,-c(2:4)],1) %>%
  dplyr::bind_rows(under40_lox) %>%
  dplyr::select(-colony) %>%
  dplyr::summarise_all(~ sum(., na.rm=TRUE)) %>% 
  dplyr::mutate(colony=c("Total nests by species"))
lox <- lox %>%
  dplyr::bind_rows(under40_lox) %>%
  dplyr::bind_rows(totals_lox) %>%
  dplyr::add_row(colony="Total nests excluding ANHI",total=tail(lox$total,1)-tail(lox$anhi,1)) %>%
  dplyr::mutate(colony = replace(colony,colony=="Total","Colonies > 40 nests"),
                wca = replace(wca,wca=="Total",NA),
                latitude = replace(latitude,latitude=="Total",NA),
                longitude = replace(longitude,longitude=="Total",NA),
                ycnh = NA,
                smda = NA) %>%
  dplyr::rename_with(toupper, .cols = -colony) %>%
  dplyr::select(Colony=colony,WCA,Latitude=LATITUDE,Longitude=LONGITUDE,GREG,WHIB,WOST,ROSP,SNEG,GBHE,LBHE,
                TRHE,GLIB,BCNH,CAEG,YCNH,SMDA,SMWH,ANHI,Total=TOTAL) %>%
  `row.names<-`(., NULL) %>% 
  tibble::column_to_rownames(var = "Colony")

wcas <- main %>%
  dplyr::select(colony,wca,latitude, longitude,everything()) %>%
  dplyr::relocate(total, .after = last_col()) %>%
  dplyr::filter(total >= 40, wca %in% c("2","3")) %>%
  dplyr::arrange(wca, desc(total)) %>%
  dplyr::mutate(latitude = as.character(latitude), longitude = as.character(longitude)) %>%
  dplyr::bind_rows(dplyr::summarise_all(., ~if(is.numeric(.)) sum(., na.rm=TRUE) else "Total"))
under40_wcas <- under40 %>% 
  dplyr::filter(wca %in% c("2","3")) %>%
  dplyr::select(colnames(wcas),
                -c(colony,latitude,longitude,wca)) %>%
  dplyr::summarise_all(~ sum(., na.rm=TRUE)) %>%
  dplyr::mutate(colony="Colonies < 40 nests**")
totals_wcas <- tail(wcas[,-c(2:4)],1) %>%
  dplyr::bind_rows(under40_wcas) %>%
  dplyr::select(-colony) %>%
  dplyr::summarise_all(~ sum(., na.rm=TRUE)) %>% 
  dplyr::mutate(colony=c("Total nests by species"))
wcas <- wcas %>%
  dplyr::bind_rows(under40_wcas) %>%
  dplyr::bind_rows(totals_wcas) %>%
  dplyr::add_row(colony="Total nests excluding ANHI",total=tail(wcas$total,1)-tail(wcas$anhi,1)) %>%
  dplyr::mutate(colony = replace(colony,colony=="Total","Colonies > 40 nests"),
                wca = replace(wca,wca=="Total",NA),
                latitude = replace(latitude,latitude=="Total",NA),
                longitude = replace(longitude,longitude=="Total",NA),
                ycnh = NA,
                smda = NA) %>%
  dplyr::rename_with(toupper, .cols = -colony) %>%
  dplyr::select(Colony=colony,WCA,Latitude=LATITUDE,Longitude=LONGITUDE,GREG,WHIB,WOST,ROSP,SNEG,GBHE,LBHE,
                TRHE,GLIB,BCNH,CAEG,YCNH,SMDA,SMWH,ANHI,Total=TOTAL) %>%
  `row.names<-`(., NULL) %>% 
  tibble::column_to_rownames(var = "Colony")

# all wcas
all <- main %>%
  dplyr::select(colony,wca,latitude, longitude,everything()) %>%
  dplyr::relocate(total, .after = last_col()) %>%
  dplyr::filter(total >= 40) %>%
  dplyr::arrange(wca, desc(total)) %>%
  dplyr::mutate(latitude = as.character(latitude), longitude = as.character(longitude)) %>%
  dplyr::bind_rows(dplyr::summarise_all(., ~if(is.numeric(.)) sum(., na.rm=TRUE) else "Total"))
under40_all <- under40 %>% 
  dplyr::select(colnames(all),
                -c(colony,latitude,longitude,wca)) %>%
  dplyr::summarise_all(~ sum(., na.rm=TRUE)) %>%
  dplyr::mutate(colony="Colonies < 40 nests**")
totals_all <- tail(all[,-c(2:4)],1) %>%
  dplyr::bind_rows(under40_all) %>%
  dplyr::select(-colony) %>%
  dplyr::summarise_all(~ sum(., na.rm=TRUE)) %>% 
  dplyr::mutate(colony=c("Total nests by species"))
all <- all %>%
  dplyr::bind_rows(under40_all) %>%
  dplyr::bind_rows(totals_all) %>%
  dplyr::add_row(colony="Total nests excluding ANHI",total=tail(all$total,1)-tail(all$anhi,1)) %>%
  dplyr::mutate(colony = replace(colony,colony=="Total","Colonies > 40 nests"),
                wca = replace(wca,wca=="Total",NA),
                latitude = replace(latitude,latitude=="Total",NA),
                longitude = replace(longitude,longitude=="Total",NA),
                ycnh=NA,
                smda=NA) %>%
  dplyr::rename_with(toupper, .cols = -colony) %>%
  dplyr::select(Colony=colony,WCA,Latitude=LATITUDE,Longitude=LONGITUDE,GREG,WHIB,WOST,ROSP,SNEG,GBHE,LBHE,
                TRHE,GLIB,BCNH,CAEG,YCNH,SMDA,SMWH,ANHI,Total=TOTAL) %>%
  `row.names<-`(., NULL) %>% 
  tibble::column_to_rownames(var = "Colony")

# appendix
append <- merge(main, under40, all = TRUE) %>%
  dplyr::select(colony,wca,latitude, longitude,everything()) %>%
  dplyr::relocate(total, .after = last_col()) %>%
  dplyr::filter(total > 0) %>%
  dplyr::arrange(wca, desc(total)) %>%
  dplyr::mutate(latitude = as.character(latitude), longitude = as.character(longitude)) %>%
  dplyr::bind_rows(dplyr::summarise_all(., ~if(is.numeric(.)) sum(., na.rm=TRUE) else "Total")) %>%
  dplyr::rename_with(toupper, .cols = -colony)
append <- append %>%
  dplyr::add_row(colony="Total nests excluding ANHI",TOTAL=tail(append$TOTAL,1)-tail(append$ANHI,1)) %>%
  dplyr::mutate(colony = replace(colony,colony=="Total","Total nests by species"),
                WCA = replace(WCA,WCA=="Total",NA),
                LATITUDE = replace(LATITUDE,LATITUDE=="Total",NA),
                LONGITUDE = replace(LONGITUDE,LONGITUDE=="Total",NA),
                SMDA=NA) %>%
  dplyr::select(Colony=colony,WCA,Latitude=LATITUDE,Longitude=LONGITUDE,GREG,WHIB,WOST,ROSP,SNEG,GBHE,LBHE,
                TRHE,GLIB,BCNH,CAEG,YCNH,SMDA,SMWH,ANHI,Total=TOTAL)

# nesting
success <- read.csv("Nesting/nest_success_summary.csv") %>%
  dplyr::group_by(year, species) %>%
  dplyr::mutate(species = toupper(species)) %>%
  dplyr::filter(year==report_year) 

colony_number <- length(unique(success$colony))
species_list <- unique(success$species)

success <- success %>%
  dplyr::summarise(incubation_N=sum(incubation_k), incubation_sumy=sum(incubation_sumy), 
                   incubation_e=sum(incubation_e), incubation_j=mean(incubation_j),
                   nestling_N=sum(nestling_k), nestling_sumy=sum(nestling_sumy), nestling_e=sum(nestling_e), 
                   nestling_j=mean(nestling_j)) %>%
  dplyr::mutate(incubation_p = 1-((incubation_N-incubation_sumy)/incubation_e), 
                incubation_Success = incubation_p^incubation_j, 
                incubation_varp=(incubation_p*(1-incubation_p))/incubation_e, 
                incubation_var = incubation_varp*((incubation_j*(incubation_p^(incubation_j-1)))^2),
                incubation_SD = sqrt(incubation_var),
                nestling_p = 1-((nestling_N-nestling_sumy)/nestling_e), 
                nestling_Success = nestling_p^nestling_j, 
                nestling_varp=(nestling_p*(1-nestling_p))/nestling_e, 
                nestling_var = nestling_varp*((nestling_j*(nestling_p^(nestling_j-1)))^2),
                nestling_SD = sqrt(nestling_var),
                overall_Success = (incubation_p^incubation_j)*(nestling_p^nestling_j),
                overall_var = ((incubation_Success^2)*nestling_var)+((nestling_Success^2)*incubation_var)+(incubation_var*nestling_var),
                overall_SD = sqrt(overall_var))

  incubation <- success %>%
    dplyr::ungroup() %>%
    dplyr::select(species, N = incubation_N , Success = incubation_Success, SD = incubation_SD) %>%
    t()
  colnames(incubation) <- incubation[1,]
  incubation <- incubation[-1,]
  
  nestling <- success %>%
    dplyr::ungroup() %>%
    dplyr::select(species, N = nestling_N, Success = nestling_Success, SD = nestling_SD) %>%
    t()
  colnames(nestling) <- nestling[1,]
  nestling <- nestling[-1,]
  
  overall <- success %>%
    dplyr::ungroup() %>%
    dplyr::select(species, Success = overall_Success, SD = overall_SD) %>%
    t()
  colnames(overall) <- overall[1,]
  overall <- overall[-1,]
  
  clutch_fledge <- read.csv("Nesting/nest_success.csv") %>%
    dplyr::mutate(species = toupper(species)) %>%
    dplyr::group_by(year, species) %>%
    dplyr::filter(year==report_year, species %in% species_list) %>%
    dplyr::group_by(species) %>%
    dplyr::summarise(N_clutch = sum(!is.na(clutch)), N_fledge = sum(!is.na(fledged)),
                     "Mean Clutch Size" = mean(clutch, na.rm = TRUE), 
                     "Mean Number of Chicks" = mean(fledged, na.rm = TRUE),
                     SD_clutch = sd(clutch, na.rm = TRUE), 
                     SD_fledge = sd(fledged, na.rm = TRUE))
  
  clutch <- clutch_fledge %>%
    dplyr::ungroup() %>%
    dplyr::select(species, N = N_clutch, "Mean Clutch Size", SD = SD_clutch) %>%
    t()
  colnames(clutch) <- clutch[1,]
  clutch <- clutch[-1,]
  
  fledge <- clutch_fledge %>%
    dplyr::ungroup() %>%
    dplyr::select(species, N = N_fledge, "Mean Number of Chicks", SD = SD_fledge) %>%
    t()
  colnames(fledge) <- fledge[1,]
  fledge <- fledge[-1,]

#--------------------
# BUILD WORKBOOK 
#--------------------

#### Build WCAS sheet ####
WCAS <- createSheet(wb, sheetName = "WCAs")

xlsx.addTitle(sheet = WCAS, rowIndex = 1,
              title = paste("Number of nesting pairs found in Loxahatchee NWR during aerial surveys, January through June of ", report_year,".", sep=""),
              titleStyle = title_style)

addDataFrame(lox, sheet = WCAS, startRow = 3, startColumn = 1,
             colnamesStyle = colname_style, colStyle = cs,
             rownamesStyle = rowname_style)
xlsx.addTitle(sheet = WCAS, rowIndex = dim(lox)[1]+4,
              title = "*Totals by species including ANHI",
              titleStyle = subtitle_style)
xlsx.addTitle(sheet = WCAS, rowIndex = dim(lox)[1]+5,
              title = "** Includes count of wading bird nesting pairs from ground surveys",
              titleStyle = subtitle_style)
xlsx.addTitle(sheet = WCAS, rowIndex = dim(lox)[1]+6,
              title = "***present but not counted",
              titleStyle = subtitle_style)

xlsx.addTitle(sheet = WCAS, rowIndex = dim(lox)[1]+8,
              title = paste("Number of nesting pairs found in WCAs 2 and 3 during aerial surveys, January through June of ", report_year,".", sep=""),
              titleStyle = title_style)

addDataFrame(wcas, sheet = WCAS, startRow = dim(lox)[1]+10, startColumn = 1,
             colnamesStyle = colname_style, colStyle = cs,
             rownamesStyle = rowname_style)
xlsx.addTitle(sheet = WCAS, rowIndex = dim(lox)[1]+10+dim(wcas)[1]+1,
              title = "*Totals by species including ANHI",
              titleStyle = subtitle_style)
xlsx.addTitle(sheet = WCAS, rowIndex = dim(lox)[1]+10+dim(wcas)[1]+2,
              title = "** Includes count of wading bird nesting pairs from ground surveys",
              titleStyle = subtitle_style)
xlsx.addTitle(sheet = WCAS, rowIndex = dim(lox)[1]+10+dim(wcas)[1]+3,
              title = "***present but not counted",
              titleStyle = subtitle_style)
setColumnWidth(WCAS, 1, 22)
autoSizeColumn(WCAS, 2:26)

#### Build Colonies sheet ####
all_colonies <- createSheet(wb, sheetName = "All Colonies")
xlsx.addTitle(sheet = all_colonies, rowIndex = 1,
              title = paste("Number of nesting pairs found in Loxahatchee NWR and WCA's 2 and 3 during aerial surveys, January through June of ", report_year,".", sep=""),
              titleStyle = title_style)

addDataFrame(all, sheet = all_colonies, startRow = 3,
             colnamesStyle = colname_style, colStyle = cs,
             rownamesStyle = rowname_style)
xlsx.addTitle(sheet = all_colonies, rowIndex = dim(all)[1]+4,
              title = "*Totals by species including ANHI",
              titleStyle = subtitle_style)
xlsx.addTitle(sheet = all_colonies, rowIndex = dim(all)[1]+5,
              title = "** Includes count of wading bird nesting pairs from ground surveys",
              titleStyle = subtitle_style)
xlsx.addTitle(sheet = all_colonies, rowIndex = dim(all)[1]+6,
              title = "***present but not counted",
              titleStyle = subtitle_style)
setColumnWidth(all_colonies, 1, 22)
autoSizeColumn(all_colonies, 2:26)

#### Build Appendix sheet ####
Appendix <- createSheet(wb, sheetName = "Appendix")
xlsx.addTitle(sheet = Appendix, rowIndex = 1,
              title = paste("Number of nesting pairs found in Loxahatchee NWR and WCA's 2 and 3 during aerial surveys, January through June of ", report_year,".", sep=""),
              titleStyle = title_style)
addDataFrame(append, sheet = Appendix, startRow = 3,
             colnamesStyle = colname_style, colStyle = cs,
             rownamesStyle = rowname_style, row.names = FALSE)
xlsx.addTitle(sheet = Appendix, rowIndex = dim(append)[1]+4,
              title = "*Totals by species including ANHI",
              titleStyle = subtitle_style)
xlsx.addTitle(sheet = Appendix, rowIndex = dim(append)[1]+5,
              title = "** Includes count of wading bird nesting pairs from ground surveys",
              titleStyle = subtitle_style)
xlsx.addTitle(sheet = Appendix, rowIndex = dim(append)[1]+6,
              title = "***present but not counted",
              titleStyle = subtitle_style)
setColumnWidth(Appendix, 1, 22)
autoSizeColumn(Appendix, 2:26)

#### Build nesting sheet ####
Nest_Success <- createSheet(wb, sheetName = "Nest Success")
xlsx.addTitle(sheet = Nest_Success, rowIndex = 1,
              title = paste("Nest success metrics of wading birds monitored in ", colony_number, " colonies throughout WCA 3 in ", report_year,".", sep=""),
              titleStyle = title_style)
xlsx.addTitle(sheet = Nest_Success, rowIndex = 3,
              title = "Incubation",
              titleStyle = nesting_style)
addDataFrame(incubation, sheet = Nest_Success, startRow = 4,
             colnamesStyle = colname_style, 
             rownamesStyle = rowname_style, colStyle = cs)
xlsx.addTitle(sheet = Nest_Success, rowIndex = 9,
              title = "Nestling",
              titleStyle = nesting_style)
addDataFrame(nestling, sheet = Nest_Success, startRow = 10,
             colnamesStyle = colname_style, 
             rownamesStyle = rowname_style, colStyle = cs)
xlsx.addTitle(sheet = Nest_Success, rowIndex = 15,
              title = "Overall Success (P)",
              titleStyle = nesting_style)
addDataFrame(overall, sheet = Nest_Success, startRow = 16,
             colnamesStyle = colname_style, 
             rownamesStyle = rowname_style, colStyle = cs)
xlsx.addTitle(sheet = Nest_Success, rowIndex = 20,
              title = "Mean Clutch Size",
              titleStyle = nesting_style)
addDataFrame(clutch, sheet = Nest_Success, startRow = 21,
             colnamesStyle = colname_style, 
             rownamesStyle = rowname_style, colStyle = cs)
xlsx.addTitle(sheet = Nest_Success, rowIndex = 26,
              title = "Mean Number of Chicks Fledged",
              titleStyle = nesting_style)
addDataFrame(fledge, sheet = Nest_Success, startRow = 27,
             colnamesStyle = colname_style, 
             rownamesStyle = rowname_style, colStyle = cs)
setColumnWidth(Nest_Success, 1, 27)
autoSizeColumn(Nest_Success, 2:9)

#### Write ####
saveWorkbook(wb, file = 'Reports/sfwmd_report_table_2023.xlsx')

