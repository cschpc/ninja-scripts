
#####################################################################################################
# Define code - please edit
#####################################################################################################
bin=$(pwd)"/vlasiator" # Binary name (with absolute path)
parameters="--run_config=magnetosphere.cfg"  #run parameters
testfolder=$(pwd)"/tests" #folder where tests are stored (absolute path)
tests="small medium large" #name of test folders within testfolder (multiple allowes)

#function for computing performance (perf) and execution time (time). Executed in run folder
function get_perf()
{
    perf=0
    for f in phiprof_*.txt
    do
	procs=$(grep "Set of identical timers has" $f |gawk '{printf $8}')
	temp=$(grep "Propagate   " $f  |gawk -v perf=$perf -v procs=$procs '{printf perf + procs * $21}')
	perf=$temp
    done
    time=$(grep "Propagate   " phiprof_0.txt  |gawk '{printf $11}')
	
}

#application specific env variables
export PHIPROF_PRINTS="full"
