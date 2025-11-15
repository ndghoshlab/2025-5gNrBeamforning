This repo contains codes and results for the 5g-nr beamforming project. The folder descriptions are as follows:
- `/results`: contains results data
- `/src/stable`: contains stable code 
- `/src/dev`: contains latest dev code
- `/src/old`: contains codes shared prior to 2025 March
- `/src/crc`: contains codes to run in Notre Dame's CRC (high performance computing resource)
- `/src/crc_v2`: Version 2 for `/src/crc`

Authors:
- Joshua Roy Palathinkal (jpalthi@nd.edu)
- Armed Tusha (atusha@nd.edu)

TODO: (increasing order of improtance):
- [ ] Need to merge `/src/crc_v2` with `/src/crc`
- [ ] Verify why `release(channel)` isn't changing pathGain and pathDelay
- [ ] Issue with BER results for SVD when `perfChan`=false at -2dB SNR for 16-QAM and 10,11dB SNR for 256-QAM.
- [ ] Need to merge `perfTx` and `perfRx` into `perfChan`
- [ ] User-input option for different degrees of saving variables in `/src/crc`
- [x] ~~Implement algo for `perfRx=false`~~
- [x] ~~Need to implement single script to select between SVD, PMI and s-PMI algos~~ OMITTING

Major Changelogs (newer first):
- Implemented s-PMI algo
- Removed implementation of multiple slots due to bug causing `nrOFDMModulate()` to fail ([link](https://github.com/armedtusha/5gNrBeamforningSim/issues/2))
