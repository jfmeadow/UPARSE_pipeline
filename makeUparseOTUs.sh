#!/bin/bash -l
#PBS -N makeUparseOTUTable
#PBS -o /home4/jmeadow/pickle2/
#PBS -e /home4/jmeadow/pickle2/
#PBS -d /home4/jmeadow/pickle2/
#PBS -q xlongfat
#PBS -l nodes=1:ppn=1

#displays nodefile and contents of nodefile, useful for running MPI
echo "PBS_NODEFILE:" $PBS_NODEFILE
cat $PBS_NODEFILE > hostfile.tmp

#displays PBS jobname and jobid
echo "PBS_JOBNAME, PBS_JOBID:" $PBS_JOBNAME $PBS_JOBID

#displays username and hostname, 
export USER_NAME=`JFMeadow`
export HOST_NAME=`hostname -s`
echo "Hello from $USER_NAME at $HOST_NAME"

#source /usr/local/packages/Modules/setmodule 3.2.8

module load usearch

python scripts/uc2otutab_jl.py matchOTUs/otu.map.uc > otuTable/seqs.filtered.derep.mc2.repset.nochimeras.otu-table.txt

touch otuTable/ALLDONE.txt
