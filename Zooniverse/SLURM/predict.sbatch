#!/bin/bash
#SBATCH --job-name=predict_everglades   # Job name
#SBATCH --mail-type=END               # Mail events
#SBATCH --mail-user=benweinstein2010@gmail.com  # Where to send mail
#SBATCH --account=ewhite
#SBATCH --nodes=1                 # Number of MPI ranks
#SBATCH --cpus-per-task=1
#SBATCH --mem=30GB
#SBATCH --time=72:00:00       #Time limit hrs:min:sec
#SBATCH --output=/home/b.weinstein/logs/everglades_predict%j.out   # Standard output and error log
#SBATCH --error=/home/b.weinstein/logs/everglades_predict%j.err
#SBATCH --partition=gpu
#SBATCH --gpus=1

module load tensorflow/1.14.0

export PATH=${PATH}:/home/b.weinstein/miniconda3/envs/Zooniverse/bin/
export PYTHONPATH=${PYTHONPATH}:/home/b.weinstein/miniconda3/envs/Zooniverse/lib/python3.7/site-packages/
export LD_LIBRARY_PATH=/home/b.weinstein/miniconda3/envs/Zooniverse/lib/:${LD_LIBRARY_PATH}
export GDAL_DATA=/home/b.weinstein/miniconda3/envs/Zooniverse/share/gdal

cd /home/b.weinstein/EvergladesWadingBird/Zooniverse

#Predict birds and run nest detections
python predict.py
python nest_detection.py
