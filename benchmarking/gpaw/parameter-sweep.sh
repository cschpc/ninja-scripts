#!/bin/bash
ulimit -c unlimited

#####################################################################################################
# Run parameters - please edit
#####################################################################################################

range_hyperthreads="1 2 4"
range_processes="64 32 16 8 4 2 1"
range_i_mpi_pin_order="compact"
range_kmp_affinity="compact scatter balanced"
mpilibrary="intel"                          #openmpi or intel
forcemcdram="0"                             #"0","1" or "0 1". If 1 it adds numactl -m 1 command

#####################################################################################################
# Define code - please edit
#####################################################################################################

bin="gpaw-python"
parameters="input.py"  #run parameters
testfolder="template" #folder where tests are stored
tests="carbon-nanotube"

#function for computing performance (perf) and execution time (time). Executed in run folder
function get_perf()
{
	time=$(grep SCF-cycle: output.txt | awk '{ print $2 }')
}

#application specific env variables

#####################################################################################################
# Load run environment (modules etc.)
#####################################################################################################
source /scratch/louhivuo/python-2016-10/load.sh

#####################################################################################################
# Actual benchmark loop, should be general for different applications
#####################################################################################################

#sniff knl details
hwloc_file=/var/run/hwloc/knl_memoryside_cache;
memMode=$(cat ${hwloc_file} | sed -n -e 's/^.*memory_mode: //p');
cache=$(cat ${hwloc_file} | sed -n -e 's/^.*cache_size: //p');
clusterMode=$( grep "cluster_mode:" ${hwloc_file} |sed -n -e 's/^.*cluster_mode: //p');



rootfolder=$(pwd)
if [ ! -e runs ]
then
    mkdir runs
fi
cd runs
runsfolder=$(pwd)

if [ ! -e  ${runsfolder}/performance.txt ]
then
    echo "#test memMode forcemcdram clusterMode I_MPI_PIN_ORDER KMP_AFFINITY processes threads ht time  performance" >  ${runsfolder}/performance.txt
fi


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


		for test in ${tests}
		do
		    for fm in  $forcemcdram
		    do
			#add mcdram mode
			if [ $fm -eq 1 ]
			then
			    if [ "$clusterMode" == "Quadrant" ]
			    then
				numactlcommand="numactl -m 1"
			    fi
			    if [ "$clusterMode" == "SNC4" ]
			    then
				numactlcommand="numactl -m 4,5,6,7"
			    fi
			    if [ "$clusterMode" == "SNC2" ]
			    then
				numactlcommand="numactl -m 2,3"
			    fi
			else
			    numactlcommand=""
			fi

			dir="${test}_${memMode}_mcdram-${fm}_${clusterMode}_mpo-${impo}_ka-${taff}_p${processes}_t${threads}_ht${ht}"
			echo $dir
			if [ -e $dir ]
			then
			    if [ -e ${dir}_old ]
			    then
				rm -rf ${dir}_old
			    fi
			    mv $dir ${dir}_old
			    echo "Moving existing folder $dir to ${dir}_old (overwriting if it already exists)"
			fi
			mkdir $dir
			cd $dir
			#link all input files
			ln -s ${rootfolder}/${testfolder}/${test}/* .

			if [ "$mpilibrary" == "openmpi" ]
			then
			    if [ $processes -ne 64 ]; then
				echo  "mpirun -cpus-per-proc $cpusperproc  -np $processes  ${numactlcommand} ${bin} $parameters"
				mpirun -cpus-per-proc $cpusperproc  -np $processes  ${numactlcommand} ${bin} $parameters 2> errors.txt > out.txt

			    else
				echo "mpirun --bind-to core  -np $processes ${numactlcommand} ${bin} $parameters"
				mpirun --bind-to core  -np $processes ${numactlcommand} ${bin} $parameters 2> errors.txt > out.txt
			    fi
			fi
			if [ "$mpilibrary" == "intel" ]
			then
			    echo "mpirun -np $processes ${numactlcommand} ${bin} $parameters"
			    mpirun -np $processes ${numactlcommand} ${bin} $parameters 2> errors.txt > out.txt
			fi

			#execute function to get perf
			get_perf
			cd ${runsfolder}

			#tot-mflups mflups time
			echo $test $memMode $fm $clusterMode $I_MPI_PIN_ORDER $KMP_AFFINITY $processes $threads $ht $time
			echo $test $memMode $fm $clusterMode $I_MPI_PIN_ORDER $KMP_AFFINITY $processes $threads $ht $time >> ${runsfolder}/performance.txt
		    done
		done
	    done
	done
    done
done


