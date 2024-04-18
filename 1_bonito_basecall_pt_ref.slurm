#!/bin/bash

#SBATCH -A cni_campanula
#SBATCH --partition=gpu
#SBATCH --gres=gpu:a100:1
#SBATCH --mem=100000
#SBATCH --ntasks=1
#SBATCH --time=12:00:00

module load anaconda
source activate bonito
module load cuda

model="dna_r9.4.1_e8_hac@v3.3"
cudaDevice="cuda:0"
reference="/scratch/hqc5dj/AL_data/Plastid/bonito1/illumina.and.pacbio.assemblies.fa"
fast5Dir="/project/lfg_lab/MinionFast5Alfredo/VA73/fast5/"

mkdir $(basename $reference .fasta)~$(basename $fast5Dir)

bonito basecaller $model        \
    --device $cudaDevice        \
    --save-ctc                  \
    --reference $reference      \
    $fast5Dir                   \
    > $(basename $reference .fasta)~$(basename $fast5Dir)/basecalls.sam
