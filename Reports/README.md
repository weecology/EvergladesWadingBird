# EvergladesWadingBird Reports

These are our automated reports generated for our federal sponsors. 
The annual report is written via .Rmd file. Please edit the relevant .Rmd,
rather than the resulting Word doc. Supplementary data tables are written to Excel
via R scripts.

## Instructions to write the annual report

### Setup
The report will most easily be created by using RStudio. Open the `usace_year.Rmd`, or if 
it does not exist create it by copying a previous year and updating the file name with 
the current year.

#### Package installs

RStudio will typically tell you what packages you need to install when you have the file open.
If it doesn't, you can also see the required packages in the first block of code at the top 
of the .Rmd (in the library() calls).

In particular, you need `wader` and `edenR`, which you can install from GitHub:
```
install.packages("remotes")
remotes::install_github("weecology/wader")
remotes::install_github("weecology/edenR")
```
  * Make sure that all `wader` and `edenr` dependencies have installed successfully.

#### Update wader data

The easiest way to use wader is to set an environmental variable, `WADER_DATA_PATH`, in your
.Renviron. This will ensure that wader always knows where to find the data, regardless of 
your working directory.

  * Call `usethis::edit_r_environ()` to open '.Renviron'
  * Store your data path with a line like: `WADER_DATA_PATH="/Users/GlendaYenni/wader-data"`
  * Make sure '.Renviron' ends with a newline!
  * Download the latest version of the data: `wader::download_observations()`

#### Update water data with edenR

For the report to automatically pull in water data without having to change anything,
the water data should be stored in `~/water` ie a directory in the same location as your 
local copy of `EvergladesWadingBird`.
Update the data:
```
library(edenR)
download_eden_depths() 
eden_depths <- get_eden_depths()
write.csv(eden_depths,"~/water/eden_depth.csv")
```
  * By default the download function will only download new files or files that have changed, 
  you will not need to download all the data every time
  * Alternatively, you can just get the updated `eden_depth.csv` from Glenda so you don't have to wait 

#### GGMAP
We use `ggmap` for creating fast maps of the colonies throughout the study site. This requires
you have a GGMAP_GOOGLE_API_KEY saved in your .Renviron. 

* We have a Google Cloud Platform account. Get the key from Glenda.
* Register it in your R session using `register_google(key = "YOUR_API_KEY")`

### Editing the .Rmd

#### Tables and Figures
* Table and Figure numbers are determined automatically by knitr. The number doesn't get assigned 
until you knit the Word doc and the number will change automatically if you reorder the figures.
* Table and Figure captions need to come from .Rmd coding, they cannot be edited manually in Word.
  * Captions are set at the beginning of the chunk, eg
  ```
  {r groundplot, fig.cap="Numbers of Tricolored Heron (blue), Little Blue Heron (red) and 
  Black-crowned Night Heron (green) nests in the constant survey area in WCA 3A by year."} 
  ```
  * The first value (eg groundplot) is the label which creates the number, followed by fig.cap
  * Usually for tables the caption is set in the chunk, not in the chunk header. In these 
  cases the label in the chunk header also will not work. You need to include the label where 
  you set the caption. 
  * eg to set the label `watertable` to go before the table caption:
    ```
    flextable::set_caption("Water level recession rates (mm/day) in the Everglades.",
    autonum = officer::run_autonum(
      seq_id = "tab",
      bkm = "watertable"
    ))
    ```
  
#### Editing Text
* Be careful not to delete encoded references in text while you are writing. Use the encoding.
* All tables and figures must be referenced in the text, so if you remove a reference from one 
location, make sure to add it back somewhere else.
* Table and Figure number references in text need to come from knitr coding, they cannot be 
added manually in Word.
  * Tables and figures are referenced by their label
    * Add a table number with `\@ref(tab:label)`
    * Add a figure number with `\@ref(fig:label)`
  * In the example above, `groundplot` is the label for the plot, and that's how you reference it 
  in the text.
    * eg (Figure `\@ref(fig:groundplot)`)
    * This will look like Figure 9 in the Word doc.
* Values added to text via encoding should be surrounded in backticks (` ``  `) so it is 
identified as code.
* The report year is saved as a parameter. Never write the current year! Always add the year with
`` `r params$report_year` ``.
  * The only years that should be written are those that don't change, eg when describing the 
  period of record.
* Numbers in text should be encoded whenever possible. See the first code chunk to see what 
variables are available to reference (add more if you want to use them).
  * Add numbers in text with R code:
  * eg Wood Storks initiated nesting in WCA 3 (`` `r stork_max` `` nests)
  * eg Roseate Spoonbills continued to nest in the WCAs and were present in at least 
  `` `r rosp_colonies` `` colonies, with a total of `` `r totals$rosp` `` nests.
* Anything else that changes from year to year can also be encoded, like at which colonies Wood 
Storks nested:
  * Wood Storks initiated nesting in WCA 3 (`` `r stork_max` `` nests) at 
  `` `r stork_colony` ``, `` `r stork_colony2` ``.

### Knitting the .Rmd

* When you are done editing, click the **Knit** button at the top of the editing window.
* This should produce only a Word document in the same location as the .Rmd. If it produces a 
folder of files, that likely means it did not successfully finish knitting.
* Go to the Render tab in the Console window and see what errors were created.
* Find the chunk of code creating the error and run just that chunk to begin debugging.
* Once all errors are fixed and the document successfully knits, it will open the resulting 
Word file automatically.
* A message will pop up, "This document contains fields that refer to other files, do you want 
to update?" Click Yes.

### Editing the Word Doc
No editing should be necessary in the Word doc. If something looks wrong, go back and correct it in
the .Rmd and re-knit. 

#### Page Numbers
The exception is page numbers, which get lost in translation sometimes when resolving all
the page breaks switching from portrait to landscape. 

If they are missing you should add them before submitting the final version. 

* Double-click in the footer to show the footer field
* In the menu bar, click Page number
* Select right aligned

#### Table of Contents

* **Never** edit the table of contents by hand. It is an update-able field.
* You can update it in the Word doc if you're worried you changed something that would affect 
headers or page numbers
  * Right-click
  * Update Field... 
  * Select update everything.
* Be sure to always update the Table of Contents at the final step before submitting report.

