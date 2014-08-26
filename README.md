# Analysis pipeline that incorporates the new UPARSE clustering algorithm 
into QIIME workflow. 

This workflow is an attempt to test the UPARSE algorithm against existing an 
clustering workflow. Raw sequence files are not included in the 
github repo due to their size. 

Most commands are in the `makeUPARSE.sh` script, and this creates the 
directory architecture as it goes. 
With a ~10gb sequence file, this takes no more than an hour... Except

One final OTU table making command has to be run on a cluster 
(python script `uc2otutab.py`), thus the pbs script `makeUPARSEotus.sh`. 
