#####################################################################################################
# Run parameters - please edit
#####################################################################################################
range_hyperthreads="1 2 4"                    # Numbr of threads per core
range_processes="1 2 4 8 16 32 64"            # Number of processes (threads computed to fill cores)
range_i_mpi_pin_order="compact"               # I_MPI_PIN_ORDER values
range_kmp_affinity="compact scatter balanced" # KMP_AFFINITY values
mpilibrary="intel"                            # MPI library, openmpi or intel
forcemcdram="0 1"                             # Force allocations to mcdram in flat mode. "0","1" or "0 1". 
                                              # If 1 it adds numactl commands (supports Quadrant, SNC-2, SNC-4)

