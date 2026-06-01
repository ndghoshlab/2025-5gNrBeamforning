This repo contains codes and results for the 5g-nr beamforming project. The folder descriptions are as follows:
- `/results`: contains results data
- `/src/GenerateEirp`: EIRP pattern generation and antenna array configuration for 5G-NR beamforming.
- `/src/AnalyseEirp`: BER performance analysis and PMI-based beamforming simulations for link-level 5G-NR PDSCH transmission.
- `/src/RtMatlab`: Ray tracing channel modeling using MATLAB for 5G-NR beamforming.
- `/src/RtSionna`: ray tracing simulations using NVIDIA Sionna for 5G-NR beamforming.

Authors:
- Joshua Roy Palathinkal (jpalthi@nd.edu)
- Armed Tusha (armedtusha@gmail.com)

Major Changelogs (newer first):
- Implemented s-PMI algo
- Removed implementation of multiple slots due to bug causing `nrOFDMModulate()` to fail ([link](https://github.com/armedtusha/5gNrBeamforningSim/issues/2))