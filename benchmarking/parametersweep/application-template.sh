
#####################################################################################################
# Define code - please edit
#####################################################################################################
bin=$(pwd)"/app"                # Binary name (with absolute path)
parameters="-a -b"              # Run parameters
testfolder=$(pwd)"/tests"       # Folder where tests are stored (absolute path)
tests="small medium large"      # Name of test folders within testfolder (multiple allowes)

#Function get_perf() for computing performance (perf) and execution time
#(time). Executed in run folder
function get_perf()
{
    time=$(grep "Performance" profile.txt  |gawk '{printf $2}')
    perf=$(grep "Performance" profile.txt  |gawk '{printf $3}')
}

#application specific env variables
export A=b

