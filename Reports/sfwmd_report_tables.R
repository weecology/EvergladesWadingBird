# SFWMD Report Table
report_year <- 2024

library(tidyr)
library(dplyr)
library(wader)
library(rJava)
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
species_list <- c("greg","whib","wost","rosp","sneg","gbhe","lbhe","trhe","glib","bcnh","caeg","ycnh","smda","smwh","anhi")
missing <- c(greg=NA,whib=NA,wost=NA,rosp=NA,sneg=NA,gbhe=NA,lbhe=NA,trhe=NA,glib=NA,bcnh=NA,caeg=NA,ycnh=NA,smda=NA,smwh=NA,anhi=NA)
# get notes for presence
main_presence <- load_datafile("Counts/maxcounts.csv", path = get_default_data_path()) %>% 
  filter(year==report_year, species %in% species_list, notes =="presence") %>%
  select(colony,species,count) %>%
  mutate(count="***")

under40_presence <- load_datafile("Counts/maxcounts_under40.csv", path = get_default_data_path()) %>%
  filter(year==report_year, notes=="1s indicate presence") %>%
  select(-c(year,group_id,wca,colony_old,latitude,longitude,total,notes)) %>% 
  pivot_longer(cols = !colony, names_to = "species", values_to = "count") %>%
  filter(species %in% species_list) %>%
  mutate(count=replace(count, count==1, "***")) %>%
  filter(count=="***")

presence <- bind_rows(main_presence,under40_presence)

main_all <- max_counts() %>% 
  ungroup() %>% 
  filter(year==report_year, species %in% species_list) %>% 
  select(-year) %>% 
  anti_join(main_presence, by = c("colony","species")) %>%
  pivot_wider(id_cols = colony, names_from = species, values_from = count) %>% 
  left_join(load_datafile("SiteandMethods/colonies.csv", path = get_default_data_path()),by = join_by(colony)) %>%
  filter(!(region %in% c("enp","other"))) %>%
  select(-colony) %>%
  rename(colony=display_name,wca=region) %>%
  tibble::add_column(!!!missing[!names(missing) %in% names(.)]) %>%
  select(colony,wca,latitude,longitude,all_of(species_list)) %>%
  mutate_at(all_of(species_list),as.numeric) %>%
  mutate(latitude = as.character(latitude), longitude = as.character(longitude),
         total = rowSums(across(all_of(species_list)), na.rm=TRUE))

main_under40 <- main_all %>% filter(total<40)
main <- main_all %>% filter(total>=40)

under40 <- load_datafile("Counts/maxcounts_under40.csv", path = get_default_data_path()) %>%
  filter(year==report_year) %>%
  tibble::add_column(!!!missing[!names(missing) %in% names(.)]) %>%
  select(colony,wca,latitude,longitude,all_of(species_list)) %>%
  filter(!(wca %in% c("enp","other"))) %>%
  mutate_at(all_of(species_list),as.numeric) %>%
  mutate(wca = substr(wca, 1, 1),
         latitude = as.character(latitude), longitude = as.character(longitude),
         total = rowSums(across(species_list), na.rm=TRUE)) %>%
  bind_rows(main_under40) %>%
  mutate(anhi = replace(anhi, colony=="123", NA))

# by WCA
lox_pre <- main %>%
  select(colony,wca,latitude, longitude,everything()) %>%
  relocate(total, .after = last_col()) %>%
  filter(wca=="1") %>%
  arrange(wca, desc(total)) %>%
  bind_rows(summarise_all(., ~if(is.numeric(.)) sum(., na.rm=TRUE) else "Total"))
under40_lox <- under40 %>% 
  filter(wca=="1") %>%
  select(colnames(lox_pre),
                -c(colony,latitude,longitude,wca)) %>%
  summarise_all(~ sum(., na.rm=TRUE)) %>%
  mutate(colony=c("Colonies < 40 nests**"))
totals_lox <- tail(lox_pre[,-c(2:4)],1) %>%
  bind_rows(under40_lox) %>%
  select(-colony) %>%
  summarise_all(~ sum(., na.rm=TRUE)) %>% 
  mutate(colony=c("Total nests by species"))
lox <- lox_pre %>%
  bind_rows(under40_lox) %>%
  bind_rows(totals_lox) %>%
  add_row(colony="Total nests excluding ANHI",total=tail(totals_lox$total,1)-tail(totals_lox$anhi,1)) %>%
  mutate(colony = replace(colony,colony=="Total","Colonies > 40 nests"),
                wca = replace(wca,wca=="Total",NA),
                latitude = replace(latitude,latitude=="Total",NA),
                longitude = replace(longitude,longitude=="Total",NA)) %>%
  rename_with(toupper, .cols = -colony) %>%
  select(Colony=colony,WCA,Latitude=LATITUDE,Longitude=LONGITUDE,GREG,WHIB,WOST,ROSP,SNEG,GBHE,LBHE,
                TRHE,GLIB,BCNH,CAEG,YCNH,SMDA,SMWH,ANHI,Total=TOTAL) %>%
  `row.names<-`(., NULL) %>% 
  tibble::column_to_rownames(var = "Colony")

wcas_pre <- main %>%
  select(colony,wca,latitude, longitude,everything()) %>%
  relocate(total, .after = last_col()) %>%
  filter(wca %in% c("2","3")) %>%
  arrange(wca, desc(total)) %>%
  bind_rows(summarise_all(., ~if(is.numeric(.)) sum(., na.rm=TRUE) else "Total"))
under40_wcas <- under40 %>% 
  filter(wca %in% c("2","3")) %>%
  select(colnames(wcas_pre),
                -c(colony,latitude,longitude,wca)) %>%
  summarise_all(~ sum(., na.rm=TRUE)) %>%
  mutate(colony="Colonies < 40 nests**")
totals_wcas <- tail(wcas_pre[,-c(2:4)],1) %>%
  bind_rows(under40_wcas) %>%
  select(-colony) %>%
  summarise_all(~ sum(., na.rm=TRUE)) %>% 
  mutate(colony=c("Total nests by species"))
wcas <- wcas_pre %>%
  bind_rows(under40_wcas) %>%
  bind_rows(totals_wcas) %>%
  add_row(colony="Total nests excluding ANHI",total=tail(totals_wcas$total,1)-tail(totals_wcas$anhi,1)) %>%
  mutate(colony = replace(colony,colony=="Total","Colonies > 40 nests"),
                wca = replace(wca,wca=="Total",NA),
                latitude = replace(latitude,latitude=="Total",NA),
                longitude = replace(longitude,longitude=="Total",NA)) %>%
  rename_with(toupper, .cols = -colony) %>%
  select(Colony=colony,WCA,Latitude=LATITUDE,Longitude=LONGITUDE,GREG,WHIB,WOST,ROSP,SNEG,GBHE,LBHE,
                TRHE,GLIB,BCNH,CAEG,YCNH,SMDA,SMWH,ANHI,Total=TOTAL) %>%
  `row.names<-`(., NULL) %>% 
  tibble::column_to_rownames(var = "Colony")

# all wcas
all_pre <- main %>%
  select(colony,wca,latitude, longitude,everything()) %>%
  relocate(total, .after = last_col()) %>%
  arrange(wca, desc(total)) %>%
  bind_rows(summarise_all(., ~if(is.numeric(.)) sum(., na.rm=TRUE) else "Total"))
under40_all <- under40 %>% 
  select(colnames(all_pre),
                -c(colony,latitude,longitude,wca)) %>%
  summarise_all(~ sum(., na.rm=TRUE)) %>%
  mutate(colony="Colonies < 40 nests**")
totals_all <- tail(all_pre[,-c(2:4)],1) %>%
  bind_rows(under40_all) %>%
  select(-colony) %>%
  summarise_all(~ sum(., na.rm=TRUE)) %>% 
  mutate(colony=c("Total nests by species"))
all <- all_pre %>%
  bind_rows(under40_all) %>%
  bind_rows(totals_all) %>%
  add_row(colony="Total nests excluding ANHI",total=tail(totals_all$total,1)-tail(totals_all$anhi,1)) %>%
  mutate(colony = replace(colony,colony=="Total","Colonies > 40 nests"),
                wca = replace(wca,wca=="Total",NA),
                latitude = replace(latitude,latitude=="Total",NA),
                longitude = replace(longitude,longitude=="Total",NA)) %>%
  rename_with(toupper, .cols = -colony) %>%
  select(Colony=colony,WCA,Latitude=LATITUDE,Longitude=LONGITUDE,GREG,WHIB,WOST,ROSP,SNEG,GBHE,LBHE,
                TRHE,GLIB,BCNH,CAEG,YCNH,SMDA,SMWH,ANHI,Total=TOTAL) %>%
  `row.names<-`(., NULL) %>% 
  tibble::column_to_rownames(var = "Colony")

# appendix
append_pre <- merge(main, under40, all = TRUE) %>%
  select(colony,wca,latitude, longitude,everything()) %>%
  relocate(total, .after = last_col()) %>%
  filter(total > 0) %>%
  arrange(wca, desc(total)) %>%
  bind_rows(summarise_all(., ~if(is.numeric(.)) sum(., na.rm=TRUE) else "Total")) %>%
  rename_with(toupper, .cols = -colony)
append <- append_pre %>%
  add_row(colony="Total nests excluding ANHI",TOTAL=tail(append_pre$TOTAL,1)-tail(append_pre$ANHI,1)) %>%
  mutate(colony = replace(colony,colony=="Total","Total nests by species"),
                WCA = replace(WCA,WCA=="Total",NA),
                LATITUDE = replace(LATITUDE,LATITUDE=="Total",NA),
                LONGITUDE = replace(LONGITUDE,LONGITUDE=="Total",NA)) %>%
  select(Colony=colony,WCA,Latitude=LATITUDE,Longitude=LONGITUDE,GREG,WHIB,WOST,ROSP,SNEG,GBHE,LBHE,
                TRHE,GLIB,BCNH,CAEG,YCNH,SMDA,SMWH,ANHI,Total=TOTAL)

# nesting
success <- read.csv("Nesting/nest_success_summary.csv") %>%
  group_by(year, species) %>%
  mutate(species = toupper(species)) %>%
  filter(year==report_year) 

colony_number <- length(unique(success$colony))
species_list <- unique(success$species)

success <- overall_success(minyear=report_year)

  incubation <- success %>%
    ungroup() %>%
    select(species, N = incubation_N , Success = incubation_Success, SD = incubation_SD) %>%
    t()
  colnames(incubation) <- incubation[1,]
  incubation <- incubation[-1,]
  
  nestling <- success %>%
    ungroup() %>%
    select(species, N = nestling_N, Success = nestling_Success, SD = nestling_SD) %>%
    t()
  colnames(nestling) <- nestling[1,]
  nestling <- nestling[-1,]
  
  overall <- success %>%
    ungroup() %>%
    select(species, Success = overall_Success, SD = overall_SD) %>%
    t()
  colnames(overall) <- overall[1,]
  overall <- overall[-1,]
  
  clutch_fledge <- read.csv("Nesting/nest_success.csv") %>%
    mutate(species = toupper(species)) %>%
    group_by(year, species) %>%
    filter(year==report_year, species %in% species_list) %>%
    group_by(species) %>%
    summarise(N_clutch = sum(!is.na(clutch)), N_fledge = sum(!is.na(fledged)),
                     "Mean Clutch Size" = mean(clutch, na.rm = TRUE), 
                     "Mean Number of Chicks" = mean(fledged, na.rm = TRUE),
                     SD_clutch = sd(clutch, na.rm = TRUE), 
                     SD_fledge = sd(fledged, na.rm = TRUE))
  
  clutch <- clutch_fledge %>%
    ungroup() %>%
    select(species, N = N_clutch, "Mean Clutch Size", SD = SD_clutch) %>%
    t()
  colnames(clutch) <- clutch[1,]
  clutch <- clutch[-1,]
  
  fledge <- clutch_fledge %>%
    ungroup() %>%
    select(species, N = N_fledge, "Mean Number of Chicks", SD = SD_fledge) %>%
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
saveWorkbook(wb, file = 'Reports/sfwmd_report_table_2024.xlsx')

