#!/bin/bash

#SBATCH -N 1
#SBATCH --ntasks-per-node=16
#SBATCH -t 6:00:00
#SBATCH --mem=150000
#SBATCH -p standard
#SBATCH -A cni_campanula

##
## The script assumes you have the following conda environments: minimap2, flye, get_organelle, nanofilt
##
## To build these environments:
##      module load anaconda
##      conda create -n minimap2
##      source activate minimap2; conda install -c bioconda minimap2; source deactivate
##
##      conda create -n flye
##      source activate flye; conda install -c bioconda flye; source deactivate
##
##      conda create -n get_organelle
##      source activate flye; conda install -c bioconda getorganelle; source deactivate
##
##      conda create -n nanofilt
##      source activate nanofilt; conda install -c bioconda nanofilt; source deactivate
##

sample=$1
dir=/scratch/hqc5dj/AL_data/Plastid/bonito_trained_basecall/FINAL_DRAFT_ASSEMBLY

mkdir -p $dir

baits=/scratch/hqc5dj/AL_data/Plastid/pt_assembly_script/baits.fasta
readsDir=/scratch/hqc5dj/AL_data/Plastid/bonito_trained_basecall/FINAL_FASTQ
mappedDir=${dir}/reads_mapped
flyeOut=${dir}/flye_out
getorgDir=${dir}/getOrganelle_out
ptAssembly=${dir}pt_assembly

        mkdir -p ${dir}{reads_mapped,flye_out,getOrganelle_out,pt_assembly}

        module load anaconda
        module load samtools

        # Map raw reads to matk, rbcl and ndhF genes
                source activate minimap
                minimap2 -a -x map-ont -t 16 $baits $readsDir/$sample | \
                        samtools fastq -0 $mappedDir/${sample%.fastq}_baits_mapped.fastq -n -F 4 -

        # First round of flye assembly using reads mapped to matk, rbcl and ndhF genes
                source deactivate; source activate flye
                flye --nano-raw $mappedDir/${sample%.fastq}_baits_mapped.fastq --out-dir $flyeOut/flye1_${sample%.fastq} --threads 16
                source deactivate

        # Map raw reads to first flye assembly. Filter mapped reads by length (5Kbp) and quality (10)
                source activate minimap
                minimap2 -a -x map-ont -t 16 $flyeOut/flye1_${sample%.fastq}/assembly.fasta $readsDir/$sample | \
                        samtools fastq -0 $mappedDir/${sample%.fastq}_flye1_mapped.fastq -n -F 4 -
                source deactivate; source activate nanofilt
                NanoFilt -l 5000 -q 10 $mappedDir/${sample%.fastq}_flye1_mapped.fastq > $mappedDir/${sample%.fastq}_flye1_min5Kbp.fastq
                source deactivate

        # Second round of flye assembly. Then, extract plastid contigs using get_organelle
                source activate flye
                flye --nano-hq $mappedDir/${sample%.fastq}_flye1_min5Kbp.fastq --out-dir $flyeOut/flye2_${sample%.fastq} --threads 16

                source deactivate; source activate get_organelle; module load blast
                get_organelle_from_assembly.py -F embplant_pt -g $flyeOut/flye2_${sample%.fastq}/assembly_graph.gfa -o $getorgDir/getOrg_${sample%.fastq}

                for i in 1 2;
                        do cp $getorgDir/getOrg_${sample%.fastq}/*complete*1.${i}.*fasta $ptAssembly/${sample%.fastq}_path${i}.fasta;
                done
