---
editor_options: 
  markdown: 
    wrap: 72
---

# University of Florida South Florida Wading Bird Study

Wading birds are of special interest with regard to the restoration of
the Everglades and are considered a measure of the overall health of the
ecosystem. Nest colony formation, location, site fidelity, nest timing,
total numbers of nesting pairs, and yearly variation all give important
clues to the effectiveness of Everglades restoration activities. This
research provides systematic monitoring of nesting activity in the Water
Conservation Areas for the endangered Wood Stork and others species. It
is conducted in conjunction with similar monitoring efforts elsewhere in
South Florida and part of a long-term MAPS monitoring effort.

### Habitat

Aerial surveys are conducted over all of WCA 1 (145,920 acres), 2
(133,120 acres) and 3 (563,200 acres). See
[colonies](../SiteandMethods/colonies.csv) for locations. Habitat is
Freshwater Everglades, ranging from cypress dominated to open sawgrass
with tree islands. The Central Everglades haave an extremely low
elevation gradient. Soils vary from peat dominated to marl dominated to
rocky limestone outcrops. The climate is subtropical, with a marked
wet/dry monsoonal system.

### Sampling design

In the middle of each month from February through June, we perform air
surveys on established E-W transects, 1.6 nm apart, over the whole of
WCAs 1 (Lox), 2, and 3. Two observers, one on each side of a Cessna 172
flying 800ft AGL, searched for colonies, make visual count estimates
(primarily of white waders), and take digital photographs for additional
review.

Permanent plots many of the colonies are used repeatedly over the years
but the area surveyed is constant, including all of WCAs 1, 2, and 3.
When ground checks are conducted to better establish species composition
or timing/success of nests, visits to colonies are in the mornings or
evenings, and for no more than one hour per visit, to minimize heat
stress on eggs and young. Nests are checked with mirror poles.
Navigation along transects conducted by pilot-operated aviation-grade
GPS receivers. Camera used for digital aerial photographs: Canon EOS
20D, 8.2 megapixel, digital SLR. Camera lens: Canon EF (electronic
focus) 28-135mm 1:3.5-5.6 IS (image stabilizer). Software used of photo
analyses: Adobe Photoshop 2.0.

### Counts

#### Max counts

These are estimates of maximum nest counts based on a combination of
observations and surveys, including aerial estimates made by both UF and
SFWMD, aerial photo analysis, and ground surveys conducted by airboat.
In most cases, only the date of the max count is reported. Previous
lower counts are often not recorded, and if photos were taken after
numbers clearly began to decrease, those photos were not countted. For
most colonies, reported estimates in the
[maxcount](../Counts/maxcount.csv) table are the peak count for each
species as determined from aerial photographs (taken from either
fixed-wing (aerial) or UAV). When counting photos, areas with no nesting
birds are ignored. Thus, 'roosting' numbers represent only roosting
birds in nesting areas, not total roosting birds. Because some nests
within each colony are obscured by vegetation, the figures reported here
are minimums. For those colonies where we established nest-check
transects, estimates of dark-colored species were modified by on-site
observations and by extrapolating from ratios of their nest numbers
relative to the more visible GREG nests. For the largest colonies,
several waves of nesting may occur, and a combination of stage of
nesting, species, and ground observations were used to piece together
the most likely number of nest starts at any given colony.

### Nesting

#### Nest counts

As part of a long-term monitoring strategy, we conducted weekly nest
checks in a number of major colonies within the Everglades system
through the breeding season (February - June).\
Transects are set up through colonies and individual nests are marked
and revisited weekly to determine fate of nest. Visits to colonies are
in the mornings or evenings, and for no more than one hour per visit, to
minimize heat stress on eggs and young. Nest checks are conducted using
mirror poles and numbered flagging to mark and recheck nests. GPS units
are used to mark the initial trail so it can be re-found for each visit.
Number of eggs and chicks are recorded, and the nest is assigned a stage
(see table). "Pipping," "wet_chick," and "chick_dry" always refer to
youngest egg or chick.

| Nest Stage  |                                                                     Description                                                                     |
|:----------------|:-----------------------------------------------------:|
| pipping     |                       Important aid to determine hatch date of first chick (usually hatch 24 hours after pipping observation)                       |
| wet_chick   |                                More indicative of hatch date than pipping, outweighs pipping of second or third eggs                                |
| incubating  |                                                                      All eggs                                                                       |
| nestling    |                                                                     All chicks                                                                      |
| empty       |                                                           No live eggs or chicks in nest.                                                           |
| fledged     |          Chicks definitely fledged for example, chicks run or fly out of nest. Behavior observation, not based on age or size, subjective           |
| collapsed   |                                           Useful information for field activities, but not nest success.                                            |
| failed      |                   Don't assume, better to leave nest categorized as "empty" unless purely obvious (chicks may have run off, etc.)                   |
| unknown     |                                                               Superseded by "missed"                                                                |
| missed      |                                                 Nest was not checked, fate not known for that date                                                  |
| branchling  |  Nest is empty but fledged chicks observed in canopy above nest, usually after chicks have fledge and only a minimum number of chicks are observed  |
| pulled      |                                  Useful information for field activites but not nest success. Superseded by empty                                   |
| hatching    |                                                    Eggs AND chicks in the nest at the same time                                                     |
| pre_flagged | Empty nest platform flagged before eggs were laid to help determine nest start date. Some platforms never have eggs, does not mean they have failed |
| chick_dry   |                                     Youngest chick in nest is dry (suggests hatched previous day at the latest)                                     |
| re_lay      |                                                   Eggs present in nest that was previously empty                                                    |

Only young little blue herons are readily visible from the air. When
these colonies were found, nest numbers were based on an assumed 1.5
young per nest.

#### Nest success

Nest success is calculated from nest counts using the Mayfield Method.
This determines the probability of at least one chick surviving until
fledgling (species nesting traits can be found in the species table).

### Feather Mercury

Mercury is a heavy metal that has no known biological function in any
organism. It is therefore not a trace element, and a contaminant at any
level. Its detrimental effects on wildlife at high doses have been known
for some time (severe neuronal degeneration, powerful developmental
effects) but the effects at low levels are only just being discovered,
particularly in wild populations of fish and birds (reproductive
failure, endocrine disruption, loss of appetite, increased
susceptibility to disease, and others).

We sample feathers from Great Egret chicks -- these animals feed almost
exclusively on fish, they are relatively high in the trophic web, they
nest reliably from year to year, and typically nest throughout the study
area. \#### Field Collection Methods

Field collection methods are described in
[Feather_Mercury_Collection](../SiteandMethods/Feather_Mercury_Collection.md).

#### Hg Analyzer Methods

A quick guide to protocol is listed in
[DMA_Protocol](../SiteandMethods/DMA_Protocol.md).

### Image processing

#### Imagery naming conventions

Names for imagery are based on the following structure:

`site_month_day_year`

-   `site` is the name of the site, e.g., JetportSouth, with multiple
    words combined and indicated by capitalizing the first letter of
    each word
-   `month` is the two digit month
-   `day` is the two digit day
-   `year` is the four digit year

E.g., `JetportSouth_04_07_2021.tif`.

In cases where additional information is needed to uniquely distinguish
flights this can be added using the optional `event`:

`site_month_day_year_event`

-   `event` is optional and can be used to indicate multiple flights on
    the same day with different parameters (e.g., different heights,
    different drones, etc.). If it is being used then one flight should
    be selected as the primary flight for image processing and the value
    of `event` for this flight should be `_A` or `_primary`. `event` for
    the other flight(s) can be any alphabetic string with multiple words
    combined and indicated by capitalizing the first letter of each
    word. `event` can also be used to flag flights and incomplete by
    using `partial` as for `event`.

E.g.,

-   `JetportSouth_04_07_2021_A.tif` and `JetportSouth_04_07_2021_B.tif`
-   `AlleyNorth_03_31_2021_partial.tif`
-   `JetportSouth_04_07_2021_primary.tif` and
    `JetportSouth_04_07_2021_AfterFieldCrew.tif` \#### Orthomosaics

Orthomosaics created from the raw UAS imagery are stored as GeoTIFF's
with LZW compression. BigTIFF format is used since most orthomosaics are
greater than the 4GB file size limit for normal TIFFs.
