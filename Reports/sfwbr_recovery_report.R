library(tidyr)
library(dplyr)
library(wader)
library(ggplot2)
library(rJava)
library(xlsx)

report_year = 2024

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

indicator_data <- max_count_indicator(maxyear = report_year) %>%
  filter(species %in% c("greg","sneg","whib","wost")) %>%
  pivot_wider(id_cols = year, names_from = species, values_from = count_mean) %>%
  mutate(across(2:5, \(x) round(x, 0))) %>%
  rename_with(toupper, .cols = -year)

#--------------------
# BUILD WORKBOOK
#--------------------

#### Build WCAS sheet ####
maxcount <- createSheet(wb, sheetName = "Max Count")

xlsx.addTitle(sheet = maxcount, rowIndex = 1,
              title = paste("Three-year running averages of numbers of nesting pairs of Great Egrets, Snowy Egrets, White Ibises, and Wood Storks in the mainland Everglades (WCAs + ENP, not including Florida Bay) in ", report_year,".", sep=""),
              titleStyle = title_style)

addDataFrame(indicator_data, sheet = maxcount, startRow = 3, startColumn = 1,
             colnamesStyle = colname_style, colStyle = cs,
             rownamesStyle = rowname_style)

#### Write ####
saveWorkbook(wb, file = 'Reports/recovery_report_table_2024.xlsx')


### Write figures ####

# Do max count plot in Excel
# max_count_plot(maxyear = report_year)
# ggsave("my_plot.png", plot = my_plot, width = 6, height = 4, units = "in", dpi = 300)

coastal <- plot_coastal(maxyear = report_year)
ggsave("coastal.png", plot = coastal, width = 6, height = 4, units = "in", dpi = 300)
foraging <- plot_foraging(maxyear = report_year)
ggsave("foraging.png", plot = foraging, width = 6, height = 4, units = "in", dpi = 300)
initiation <- plot_initiation(maxyear = report_year)
ggsave("initiation.png", plot = initiation, width = 6, height = 4, units = "in", dpi = 300)
supercolony <- plot_supercolony(maxyear = report_year)
ggsave("supercolony.png", plot = supercolony, width = 6, height = 4, units = "in", dpi = 300)
