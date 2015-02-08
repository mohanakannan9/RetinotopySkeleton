# HCPretinotopyanalysis

History of major code changes:
- 2015/02/07 - Version 1.0.

## CONTENTS

Contents:
- ExampleInvocation.sh - example script for invoking the analysis
- MATLAB - This folder contains MATLAB source code
  - analyzePRF_chpc.m - a version of analyzePRF.m specifically adapted for HCP use on CHPC
  - CHPCsubmit.m - utility for submitting jobs to CHPC
  - CHPCwait.m - utility for waiting for jobs to complete on CHPC
  - RetinotopyAnalysis.m - entry point for the MATLAB processing
  - utilities - various MATLAB utility functions, including MatlabCIFTI
- mcc - This folder contains various files related to the compiled MATLAB code and the CHPC setup
  - compilescript.m - a script that compiles the necessary MATLAB functions
  - fitnonlinearmodel and
    run_fitnonlinearmodel.sh - compiled version of fitnonlinearmodel.m
  - RetinotopyAnalysis and
    run_RetinotopyAnalysis.sh - compiled version of RetinotopyAnalysis.m
  - matlabsge.sh - a shell script used by CHPC jobs in order to invoke MATLAB
- README.md - this file
- RetinotopyAnalysis.sh - top-level analysis script

There are several external dependencies:
1. Connectome Workbench. This is required by MatlabCIFTI. It is required that
   the command-line utility "wb_command" is accessible from the shell.
2. analyzePRF (http://github.com/kendrickkay/analyzePRF/). This is the MATLAB toolbox
   that actually analyzes the data. We use tagged version 1.2. If you wish to
   compile the MATLAB functions yourself, you will need to download this toolbox.

Note that the files in the MATLAB directory are not actually used during the
analysis. This is because the processing relies on compiled MATLAB code (as contained
in the mcc directory). 

Installation and setup issues:
1. The CHPC jobs write .o and .e files to ~/sgeoutput
2. It is assumed that the mcc directory is installed in the home directory (~/)
3. It is assumed that a dummy CIFTI file is available at ~/dummy.dtseries.nii
4. It is assumed that scratch space is available at /scratch/<userid>/

The code workflow is as follows:
1.   RetinotopyAnalysis.sh
     [this is the top-level script that is called by the user. 
      this script generates a .txt file that is really a MATLAB
      script that defines some input variables.]
2. -> run_RetinotopyAnalysis.sh
     [this is a compiled version of RetinotopyAnalysis.m.]
     [this function accepts the location of the .txt file created in the previous step,
      evaluates the file, prepares inputs, calls analyzePRF_chpc.m with these inputs, 
      takes the outputs, massages these outputs, and writes them to CIFTI files.]
3. -> analyzePRF_chpc.m
     [this does the real work, and is an alternative version of analyzePRF.m.]
     [note that this function encodes a lot of specific details about the CHPC setup.]
