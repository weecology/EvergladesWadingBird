#!/bin/bash
#SBATCH --job-name=DeepForest   # Job name
#SBATCH --mail-type=END               # Mail events
#SBATCH --mail-user=benweinstein2010@gmail.com  # Where to send mail
#SBATCH --account=ewhite
#SBATCH --nodes=1                 # Number of MPI ranks
#SBATCH --cpus-per-task=5
#SBATCH --mem=50GB
#SBATCH --time=24:00:00       #Time limit hrs:min:sec
#SBATCH --output=/home/b.weinstein/logs/everglades_%j.out   # Standard output and error log
#SBATCH --error=/home/b.weinstein/logs/everglades_%j.err
#SBATCH --partition=gpu
#SBATCH --gpus=1

source activate Zooniverse_pytorch

#comet debug
#python aggregate.py
#python extract.py
cd species_model

#python create_species_model.py
python train.py
