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
source  ~/miniconda3/envs/mapbox/etc/activate.d

cd /orange/ewhite/everglades/WadingBirds2020/6th\ Bridge/

mapbox upload bweinstein.6thBridge_03182020 6thBridge_03182020.tif