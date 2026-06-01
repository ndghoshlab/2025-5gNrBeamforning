This repo contains codes and results for the 5g-nr beamforming project. The folder descriptions are as follows:
- `/results`: contains results data
- `/src/GenerateEirp`: EIRP pattern generation and antenna array configuration for 5G-NR beamforming.
- `/src/AnalyseEirp`: BER performance analysis and PMI-based beamforming simulations for link-level 5G-NR PDSCH transmission.
- `/src/RtMatlab`: Ray tracing channel modeling using MATLAB for 5G-NR beamforming.
- `/src/RtSionna`: ray tracing simulations using NVIDIA Sionna for 5G-NR beamforming.

Authors:
- Joshua Roy Palathinkal (jpalthi@nd.edu)
- Armed Tusha (armedtusha@gmail.com)

TODO: (increasing order of improtance):
- [x] ~~Need to merge `/src/crc_v2` with `/src/crc`:~~ moved `/src/crc` to `archive/20260601`, renamed `/src/crc_v2` to `/src/AnalyseEirp`.
- [ ] Verify why `release(channel)` isn't changing pathGain and pathDelay
- [ ] Issue with BER results for SVD when `perfChan`=false at -2dB SNR for 16-QAM and 10,11dB SNR for 256-QAM.
- [ ] Need to merge `perfTx` and `perfRx` into `perfChan`
- [ ] User-input option for different degrees of saving variables in `/src/crc`
- [x] ~~Implement algo for `perfRx=false`~~
- [x] ~~Need to implement single script to select between SVD, PMI and s-PMI algos~~ OMITTING

Major Changelogs (newer first):
- Implemented s-PMI algo
- Removed implementation of multiple slots due to bug causing `nrOFDMModulate()` to fail ([link](https://github.com/armedtusha/5gNrBeamforningSim/issues/2))