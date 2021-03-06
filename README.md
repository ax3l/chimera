# CHIMERA: a code for FEL and laser plasma simulations

by Igor A Andriyash (<igor.andriyash@gmail.com>)

CHIMERA is a relativistic electromagnetic particle-in-cell code, based on a quasi-cylindric pseudo-spectral analytical time domain (PSATD) Maxwell solver.

System requirements
- code runs under Linux or MacOS
- Fortran 90/95 compiler with OpenMP support (e.g. recent gfortran or ifort)
- Python with NumPy, SciPy; Additionally Matplotlib, Ipython and Jypyter are recommended
- FFTW3 (http://www.fftw.org), better to be compiled with the same compiler and "-fPIC" option enabled

To install CHIMERA
- clone the code folder into your working directory and add it to the PYTHONPATH
- Check that Makefile contains a correct address to FFTW3 /lib/ and /bin/
- compile the Fortran modules using 'make'command. 

To run CHIMERA in multiprocessor mode specify the OMP_NUM_THREADS variable. For more information see demo in ./doc/
