#!/bin/bash
ulimit -c unlimited

if [[  $# -ne 2 ]]
then
    echo "Usage $0 code-description.sh parameters.sh"
    exit
fi

source $1
source $2



#benchmark function
function set_default_values()

{
    taff=$default_kmp_affinity
    impo=$default_i_mpi_pin_order    
    ht=$default_hyperthreads
    processes=$default_processes
    fm=$default_forcemcdram


}
function run_benchmark() 
{
    cpusperproc=$(( 64 / $processes ))
    threads=$(( $ht * 64 / $processes ))
    
    echo "$processes processes, $ht ht, $threads threads"
    export OMP_NUM_THREADS=$threads		
    export KMP_HW_SUBSET=${ht}T
    export KMP_AFFINITY=$taff	
    export I_MPI_PIN_ORDER=$impo

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
    ln -s ${testfolder}/${test}/* .

    if [ "$mpilibrary" == "openmpi" ]
    then
	if [ $processes -ne 64 ]; then
	    echo  "mpirun -cpus-per-proc $cpusperproc -np $processes ${numactlcommand} ${bin} $parameters"
	    mpirun -cpus-per-proc $cpusperproc -np $processes ${numactlcommand} ${bin} $parameters 2> errors.txt > out.txt 
	    
	else
	    echo "mpirun --bind-to core  -np $processes ${numactlcommand} ${bin} $parameters "
	    mpirun --bind-to core  -np $processes ${numactlcommand} ${bin} $parameters  2> errors.txt > out.txt
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
    echo $test $memMode $fm $clusterMode $I_MPI_PIN_ORDER $KMP_AFFINITY $processes $threads $ht $time  $perf  
    echo $test $memMode $fm $clusterMode $I_MPI_PIN_ORDER $KMP_AFFINITY $processes $threads $ht $time  $perf >> ${runsfolder}/performance.txt

}



#sniff knl details
hwloc_file=/var/run/hwloc/knl_memoryside_cache;
memMode=$(cat ${hwloc_file} | sed -n -e 's/^.*memory_mode: //p');
cache=$(cat ${hwloc_file} | sed -n -e 's/^.*cache_size: //p');
clusterMode=$( grep "cluster_mode:" ${hwloc_file} |sed -n -e 's/^.*cluster_mode: //p');




#create run folder if it des not exist
rootfolder=$(pwd)
if [ ! -e runs ]
then
    mkdir runs
fi
cd runs
runsfolder=$(pwd)


#add header if it does not exist
if [ ! -e  ${runsfolder}/performance.txt ]
then
    echo "#test memMode forcemcdram clusterMode I_MPI_PIN_ORDER KMP_AFFINITY processes threads ht time  performance" >  ${runsfolder}/performance.txt
fi



for test in ${tests}
do
    set_default_values
    run_benchmark

    for taff in ${range_kmp_affinity}
    do
	if [ ! $taff == ${default_kmp_affinity} ]
	then
	    run_benchmark
	fi
    done
    
    for impo in ${range_i_mpi_pin_order}
    do
 	if [ ! $impo == ${default_i_mpi_pin_order} ]
	then
	    run_benchmark
	fi
    done
    
    for ht in ${range_hyperthreads}
    do
 	if [ $ht -ne ${default_hyperthreads} ]
	then
	    run_benchmark
	fi
    done

    
    for processes in ${range_processes}
    do
 	if [ $processes -ne ${default_processes} ]
	then
	    run_benchmark
	fi
    done

    
    for fm in  $range_forcemcdram 
    do
 	if [ $fm -ne $default_forcemcdram ]
	then
	    run_benchmark
	fi
    done
done 


    
