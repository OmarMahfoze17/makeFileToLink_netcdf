#=======================================================================
# Makefile for Imcompact3D
#=======================================================================

# Choose pre-processing options
#   -DSHM	   - enable shared-memory implementation
#   -DDOUBLE_PREC  - use double-precision
OPTIONS = -DDOUBLE_PREC

# Choose an FFT engine, available options are:
#   essl       - IBM Blue Gene ESSL Library
#   fftw3      - FFTW version 3.x
#   generic    - A general FFT algorithm (no 3rd-party library needed)
FFT= generic
FFTW3_INCLUDE = -I${MKLROOT}/include/fftw
FFTW3_LIB = -mkl -L${MKLROOT}/interfaces/fftw3xf -lfftw3xf_intel
# Paths to FFTW 3
#FFTW3_PATH=   # full path of FFTW installation if using fftw3 engine above
#FFTW3_INCLUDE = -I$(FFTW3_PATH)/include
#FFTW3_LIB = -L$(FFTW3_PATH)/lib -lfftw3 -lfftw3f

# Paths to ESSL
#ESSL_PATH=/bgsys/drivers/ppcfloor/comm/xl
#ESSL_INCLUDE =
#ESSL_LIB = -L$(ESSL_PATH)/lib -L/opt/ibmmath/lib64 -lesslbg

#NETCDFloc=/opt/software/libraries/netcdf/netcdf-4.2.1.1
#NETCDFfloc=/opt/software/libraries/netcdf/netcdf-4.2_hdf5_1.8.14
#NETCDFloc=/cineca/prod/opt/libraries/netcdf/4.4.1/intel--pe-xe-2017--binary
#NETCDFfloc=/home/om1014/PhD/INCOMPACT3D/TBL/cd815d03830b53e24c82-02db563c95dc4060eb847c2c93239738fa7b8924/netcdf-4.1.3

NETCDF_LIB=-L/home/om1014/PhD/INCOMPACT3D/TBL/NETCDF/netcdf-4.1.3/liblib -lnetcdf -lnetcdff -L/home/om1014/PhD/INCOMPACT3D/TBL/NETCDF/netcdf-4.1.3/f90 -lnetcdf -lnetcdff
NETCDF_INC=-I/home/om1014/PhD/INCOMPACT3D/TBL/NETCDF/netcdf-4.1.3/f90 -I/home/om1014/PhD/INCOMPACT3D/TBL/NETCDF/netcdf-4.1.3/include


NETCDFLIB= $(NETCDF_LIB) $(NETCDF_INC) 

# Specify Fortran and C compiler names and flags here
# Normally, use MPI wrappers rather than compilers themselves 
# Supply a Fortran pre-processing flag together with optimisation level flags
# Some examples are given below:

#FC =  
#OPTFC = 
#CC = 
#CFLAGS = 

# PGI
#FC = ftn
#OPTFC = -fast -O3 -Mpreprocess
#CC = cc
#CFLAGS = -O3

# PathScale
#FC = ftn
#OPTFC = -Ofast -cpp
#CC = cc
#CFLAGS = -O3

# GNU
#FC = mpif90
#OPTFC = -O3 -funroll-loops -ftree-vectorize -fcray-pointer -cpp
#CC = mpicc
#CFLAGS = -O3
#PLATFORM=gnu

# Intel
#FC = mpif90
#OPTFC = -g -debug -fpe0 -no-ftz -traceback -fp-stack-check -check uninit -check bounds -cpp -r8  
#OPTFC = -O2  -fpp -heap-arrays -implicitnone -pc64 -xW -axp -cm -w -vec_report0 -assume byterecl -mcmodel=medium -funroll-loops -safe-cray-ptr -cpp -extend-source -r8 $(NETCDFLIB)
#OPTFC = -g -debug -safe-cray-ptr -cpp -extend-source -fpe0 -traceback -check all
#CC = mpicc
#CFLAGS = -O2
#PLATFORM=intel


FC = mpif90
OPTFC = -O3 -funroll-loops -ftree-vectorize -fcray-pointer -cpp $(NETCDFLIB)
CC = mpicc
CFLAGS = -O3


#Blue Gene/Q : EDF R&D
#PREP=/bgsys/drivers/ppcfloor/comm/xl/bin/
#FC = $(PREP)mpixlf95_r
#OPTFC= -O3 -qsuffix=cpp=f90 -qinitauto -qautodbl=dbl4
#OPT_LK= -O3 -qinitauto -qautodbl=dbl4
#CFLAGS= -O3 -qinitauto -qautodbl=dbl4
#CC=$(PREP)mpixlc_r
#PLATFORM=bgq_xlf

# Cray
#FC = ftn
#OPTFC = -e Fm
#CC = cc
#CFLAGS = 

#-----------------------------------------------------------------------
# Normally no need to change anything below

# include PATH 
ifeq ($(FFT),generic)
  INC=
else ifeq ($(FFT),fftw3)
  INC=$(FFTW3_INCLUDE)
else ifeq ($(FFT),essl)
  INC=$(ESSL_INCLUDE)
endif

# library path
ifeq ($(FFT),generic)
   LIBFFT=
else ifeq ($(FFT),fftw3)
   LIBFFT=$(FFTW3_LIB)
endif

# List of source files
SRC = decomp_2d.f90 glassman.f90 fft_$(FFT).f90 module_param.f90 io.f90 variables.f90 poisson.f90 schemes.f90 implicit.f90 convdiff.f90 incompact3d.f90 navier.f90 derive.f90 parameters.f90 tools.f90 visu.f90 

#-----------------------------------------------------------------------
# Normally no need to change anything below

ifneq (,$(findstring DSHM,$(OPTIONS)))
SRC := FreeIPC.f90 $(SRC)  
OBJ =	$(SRC:.f90=.o) alloc_shm.o FreeIPC_c.o
else
OBJ =	$(SRC:.f90=.o)
endif	

OPTION=$(OPTIONS)
from:=-D
to:=-WF,-D
TMP=$(subst $(from),$(to),$(OPTIONS))
ifeq ($(PLATFORM),bgp_xlf)
   OPTION=$(TMP)
endif
ifeq ($(PLATFORM),bgq_xlf)
   OPTION=$(TMP)
endif

all: incompact3d

alloc_shm.o: alloc_shm.c
	$(CC) $(CFLAGS) -c $<

FreeIPC_c.o: FreeIPC_c.c
	$(CC) $(CFLAGS) -c $<

incompact3d : $(OBJ)
	$(FC) -O3 -o $@ $(OBJ) $(LIBFFT) $(NETCDFLIB)

%.o : %.f90
	$(FC) $(OPTFC) $(OPTION) $(INC) $(NETCDF_INC) -c $<

.PHONY: clean 
clean:
	rm -f *~ *.o *.mod incompact3d

.PHONY: realclean
realclean: clean
	rm -f *~ \#*\#
