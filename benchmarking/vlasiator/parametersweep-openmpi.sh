#!/bin/bash

# Loops through a set of parameters for Vlasiator. Note that vlasiator
# uses OpenMPI, and hence the mpirun call is somewhat different. The
# parameters are (for now):
# - hyperthreads
# - threads
# - processes
# - I_MPI_PIN_ORDER (does not do anything for openmpi though)
# - KMP_AFFINITY

ulimit -c unlimited

range_hyperthreads="4 2 "
range_processes="64 32 16 8 4 2 1 "
range_i_mpi_pin_order="compact"
range_kmp_affinity="compact"
export PHIPROF_PRINTS="full"

for taff in ${range_kmp_affinity}
do
    for impo in ${range_i_mpi_pin_order}
    do

	for ht in ${range_hyperthreads}
	do
	    
	    for processes in ${range_processes}
	    do
		
		cpusperproc=$(( 64 / $processes ))
		threads=$(( $ht * 64 / $processes ))
		
		echo "$processes processes, $ht ht, $threads threads"
		export OMP_NUM_THREADS=$threads
		
		export KMP_HW_SUBSET=${ht}T
		export KMP_AFFINITY=$taff	
		export I_MPI_PIN_ORDER=$impo
		dir="run_p${processes}_t${threads}_ht${ht}_impipinorder_${impo}_kmpaffinity_${taff}"
		if [ -e $dir ] 
		    then
		    if [ -e ${dir}_old ]
		    then
			rm -rf ${dir}_old 
		    fi
		    mv $dir ${dir}_old
		    echo "Moving existing folder $dir to ${dir}_old (overwriting if it already exists)"
		fi

		cp -r template $dir
		cd $dir
		
		if [ $processes -ne 64 ]; then
		#this is openmpi
		    echo  "mpirun -cpus-per-proc $cpusperproc  -np $processes  ../vlasiator --run_config=Magnetosphere_small.cfg"
		    mpirun -cpus-per-proc $cpusperproc  -np $processes  ../vlasiator --run_config=Magnetosphere_small.cfg 2> errors.txt > out.txt

		else
		    echo "mpirun --bind-to core  -np $processes  ../vlasiator --run_config=Magnetosphere_small.cfg"
		    mpirun --bind-to core  -np $processes  ../vlasiator --run_config=Magnetosphere_small.cfg 2> errors.txt > out.txt
		    
		fi

		    perf=$(grep "Propagate   " phiprof_0.txt  | gawk -F\| '{print $7}' )		    
		cd ..

		#tot-mflups mflups time
		echo $I_MPI_PIN_ORDER $KMP_AFFINITY $processes $threads $ht  $perf  
		echo $I_MPI_PIN_ORDER $KMP_AFFINITY $processes $threads $ht  $perf >> performance.txt
	    done
	done
    done
done 
