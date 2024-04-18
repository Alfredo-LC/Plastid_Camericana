#!/bin/bash

#SBATCH -A cni_campanula
#SBATCH --partition=gpu
#SBATCH --gres=gpu:v100:1
#SBATCH --ntasks=1
#SBATCH --mem=200000
#SBATCH --time=12:00:00

module load anaconda
source activate bonito
module load cuda

basecallingOutput="7_final_consensus_PB_VA73~barcode19_PA104_10/" # eg. for single training set


model="dna_r10.4.1_e8.2_400bps_hac@v4.3.0"
cudaDevice="cuda:0"
#epochs=12      # number of training cycles
#epochs=75 # This is what I used with 9.4 chemistry
epochs=27 # used with pod5 files
#batch_size=10000 # number of training reads utilized in one iteration. This is what I used with 9.4 chemistry
batch_size=200 # used with pod5 files
#num_chunks=0   # Splits the reads into lengths of size X. 0 = don't split
#num_chunks=1000000 # This is what I used with 9.4 chemistry
num_chunks=1000000
#learning_rate=1e-4 # Step size at each epoch
                   # to big = overshoot convergent point
                   # to small = slow learn.
learning_rate=1e-5
# batch and chunk = resource optimisation.
#torch.cuda.empty_cache()
export 'PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512'

first=1
for run in $basecallingOutput
do
    if [ $first == 1 ]
    then
        bonito train                \
            --pretrained $model     \
            --device $cudaDevice    \
            --epochs $epochs        \
            --lr $learning_rate     \
            --batch $batch_size     \
            --chunks $num_chunks    \
            --directory $run        \
            $(basename $run)~trained

        preRun=$(basename $run)~trained
        first=0
    else
        bonito train                \
            --pretrained $preRun    \
            --device $cudaDevice    \
            --epochs $epochs        \
            --lr $learning_rate     \
            --batch $batch_size     \
            --chunks $num_chunks    \
            --directory $run        \
            $(basename $run)~trained

        preRun=$(basename $run)~trained
    fi
done
