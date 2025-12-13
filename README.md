This repository includes new developments with Bayesian Additive Regression Trees and extends the original OpenBT repository created by Matt Pratola (https://bitbucket.org/mpratola/openbt/src/master/). Such extensions include Bayesian Model Mixing and Bayesian Calibration. All of the Bayesian Tree code is written in C++. User interfaces constructed in R and Python allow one to easily run the software. The BART Model Mixing software has been implemented in the Taweret Python package in conjunction with the BAND collaboration.


Requirements for C++ Tools:
Eigen: eigen-3.4.0
Openmpi

JMRL Reproducible Example:
1. Install Eigen and Openmpi
2. Clone the Openbt repository and checkout to the rpath branch.
3. To reproduce the Taylor series mixing example, please run <.\JMLR\jml_mixing_examples.R>. To run the script, please change the working directory to the location of the openbt repository (line 5).


General steps for building using the automake scripts:

1. aclocal
2. libtoolize
3. automake --add-missing
4. autoconf
5. ./configure --with-mpi --with-silent
6. make clean
7. make

Note: In the odd case that the system does not update the Linux library cache,
you may need to run:

sudo ldconfig