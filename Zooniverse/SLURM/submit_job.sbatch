#!/bin/bash
#SBATCH --job-name=DeepForest   # Job name
#SBATCH --mail-type=END               # Mail events
#SBATCH --mail-user=benweinstein2010@gmail.com  # Where to send mail
#SBATCH --account=ewhite
#SBATCH --nodes=1                 # Number of MPI ranks
#SBATCH --cpus-per-task=1
#SBATCH --mem=30GB
#SBATCH --time=72:00:00       #Time limit hrs:min:sec
#SBATCH --output=/home/b.weinstein/logs/everglades_%j.out   # Standard output and error log
#SBATCH --error=/home/b.weinstein/logs/everglades_%j.err
#SBATCH --partition=gpu
#SBATCH --gpus=1

module load tensorflow/1.14.0

export PATH=${PATH}:/home/b.weinstein/miniconda3/envs/everglades/bin/
export PYTHONPATH=${PYTHONPATH}:/home/b.weinstein/miniconda3/envs/everglades/lib/python3.7/site-packages/
export LD_LIBRARY_PATH=/home/b.weinstein/miniconda3/envs/everglades/lib/:${LD_LIBRARY_PATH}

cd /home/b.weinstein/EvergladesWadingBird/Zooniverse

#comet debug
python create_model.py
