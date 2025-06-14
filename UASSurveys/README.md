# UAV Surveys

Please see the [methods](https://everglades-wading-bird-data.netlify.app/) for details about collection and how to use the data.

### Ground Control Points

`ground_control_points.csv` contains information on which sites have ground control points in which years.
This is important for knowing which sites can be use for comparing precise point locations through time for things like nest detection.

year
colony
ground_control_points - True if there are ground control points, False if there are not

### Image processing

#### Imagery naming conventions

Names for imagery are based on the following structure:

`site_month_day_year`

* `site` is the name of the site, e.g., JetportSouth, with multiple words combined and indicated by capitalizing the first letter of each word
* `month` is the two digit month
* `day` is the two digit day
* `year` is the four digit year

E.g., `JetportSouth_04_07_2021.tif`.

In cases where additional information is needed to uniquely distinguish flights this can be added using the optional `event`:

`site_month_day_year_event`

* `event` is optional and can be used to indicate multiple flights on the same day with different parameters (e.g., different heights, different drones, etc.). If it is being used then one flight should be selected as the primary flight for image processing and the value of `event` for this flight should be `_A` or `_primary`. `event` for the other flight(s) can be any alphabetic string with multiple words combined and indicated by capitalizing the first letter of each word. `event` can also be used to flag flights and incomplete by using `partial` as for `event`.

E.g.,

* `JetportSouth_04_07_2021_A.tif` and `JetportSouth_04_07_2021_B.tif`
* `AlleyNorth_03_31_2021_partial.tif`
* `JetportSouth_04_07_2021_primary.tif` and `JetportSouth_04_07_2021_AfterFieldCrew.tif`

#### Orthomosaics

Orthomosaics created from the raw UAS imagery are stored as GeoTIFF's with LZW compression.
BigTIFF format is used since most orthomosaics are greater than the 4GB file size limit for normal TIFFs.
