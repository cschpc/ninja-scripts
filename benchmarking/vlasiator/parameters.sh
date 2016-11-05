#####################################################################################################
# Run parameters - please edit
#####################################################################################################

range_hyperthreads="4 2 1"
range_processes="1 2 4 8 16 32 64"
range_i_mpi_pin_order="compact"
range_kmp_affinity="compact scatter balanced"
mpilibrary="openmpi"                          #openmpi or intel
forcemcdram="0 1"                             #"0","1" or "0 1". If 1 it adds numactl -m 1 command 

