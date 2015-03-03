# Personal config for Ada SPARK 2014

### BUILDING SETTINGS ###
# Use FPU by default
USE_FPU = 1

# Sources
VPATH += wrappers/src
INCLUDES += -Iwrappers/interface

ADA_LIB_DIR = bin/lib
ADA_LIB = libspark.a
ADA_LIB_FLAGS = -L$(ADA_LIB_DIR) -lspark

WRAPPER_OBJ = FreeRTOS_wrapper.o

# Project file used to build the Ada library
ADA_PROJECT_FILE = ada_spark/cf_spark.gpr

# Programs to be run on the Ada part
ADA_BUILDER = gprbuild
ADA_PROVER = gnatprove

# Ada flags
ADA_PROVER_FLAGS = -XMODE=Analyze
