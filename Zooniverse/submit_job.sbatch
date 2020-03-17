#!/bin/bash
#SBATCH --job-name=Everglades_rclone   # Job name
#SBATCH --mail-type=END               # Mail events
#SBATCH --mail-user=benweinstein2010@gmail.com  # Where to send mail
#SBATCH --account=ewhite
#SBATCH --nodes=1                 # Number of MPI ranks
#SBATCH --cpus-per-task=1
#SBATCH --mem=10GB
#SBATCH --time=72:00:00       #Time limit hrs:min:sec
#SBATCH --output=/home/b.weinstein/logs/rclone_%j.out   # Standard output and error log
#SBATCH --error=/home/b.weinstein/logs/rclone_%j.err

#comet debug
rclone sync everglades:"Wading Bird 2020 (1)/Deliverables" /orange/ewhite/everglades/WadingBirds2020/