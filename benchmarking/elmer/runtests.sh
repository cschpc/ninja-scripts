#!/bin/bash
export KMP_AFFINITY=compact,verbose
export I_MPI_ADJUST_BARRIER=0
# export KMP_BLOCKTIME=infinite 
# export MKL_FAST_MEMORY_LIMIT=0
ulimit -c unlimited # size of core-dumps
cd PoissonThreaded
# use either 64 or 8 
gausspoints=64
#for mpimode in "scatter" "compact"
# scatter turned out to be in general faster
for mpimode in "scatter"
do
    export I_MPI_PIN_ORDER=${mpimode}
    for hyperthreading in 4 2 1
    do
	export KMP_HW_SUBSET=${hyperthreading}T
	filename="L3_${mpimode}_ht${hyperthreading}_${gausspoints}GP_AVX.dat"
	rm -f ${filename}
	touch ${filename}
	sifname="poisson_blueprint_l3_${gausspoints}GP.sif"
	echo $sifname > ELMERSOLVER_STARTINFO
	logname="L3_${mpimode}_ht${hyperthreading}_${gausspoints}GP_AVX.log"
	rm -f ${logname}
	touch ${logname}
	for i in 64 32 16 8 4 2
	do
	    notasks=$i
	    nothreads=$(( (64/$i) * $hyperthreading ))
	    export OMP_NUM_THREADS=$nothreads
	    echo "running with " ${notasks} "tasks and " ${nothreads} "threads" 
	    echo  ${notasks} ${nothreads} >> ${filename}
	    echo  "******************************************************" >> ${logname}
	    echo  ${notasks} "," ${nothreads}":" >> ${logname}
	    echo  "******************************************************" >> ${logname}
	    rm -f testing.dat testing.dat.names
	    echo "  NaN   NaN   NaN   NaN   NaN   NaN" > testing.dat
	    mpirun -check_mpi -np ${notasks} ElmerSolver_mpi >> ${logname}
	    cat  testing.dat >> ${filename}
	done
	mv ${logname} ../
	mv ${filename} ../
	mv testing.dat.names ../${filename}.names
    done
done
cd ..
echo "done"
