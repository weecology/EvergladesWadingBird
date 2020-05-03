#!/bin/bash
#SBATCH --job-name=mapbox_upload   # Job name
#SBATCH --mail-type=END               # Mail events
#SBATCH --mail-user=benweinstein2010@gmail.com  # Where to send mail
#SBATCH --account=ewhite
#SBATCH --nodes=1                 # Number of MPI ranks
#SBATCH --cpus-per-task=1
#SBATCH --mem=5GB
#SBATCH --time=72:00:00       #Time limit hrs:min:sec
#SBATCH --output=/home/b.weinstein/logs/mapbox_upload.out   # Standard output and error log
#SBATCH --error=/home/b.weinstein/logs/mapbox_upload.err

source activate mapbox

#Get key
source  /orange/ewhite/everglades/mapbox/source_token.txt

cd /orange/ewhite/everglades/WadingBirds2020/6th\ Bridge/

#Generate tiles

#Project to web mercator
gdalwarp 6thBridge_03182020.tif  6thBridge_03182020_webmercator.tif -t_srs "EPSG:3857" 
rio mbtiles 6thBridge_03182020_webmercator.tif -o /orange/ewhite/everglades/mapbox/riotest.mbtiles --zoom-levels 17..22 -j 4 -f PNG --overwrite

mapbox upload bweinstein.6thBridge_03182020_noproject /orange/ewhite/everglades/mapbox/riotest_notprojected.mbtiles

mapbox upload bweinstein.6thBridge_03182020_riotiles /orange/ewhite/everglades/mapbox/riotest.mbtiles

echo "done"

mapbox upload bweinstein.6thBridge_03182020 6thBridge_03182020.tif