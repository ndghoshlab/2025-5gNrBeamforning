This repo contains codes and results for the 5g-nr beamforming project. The folder descriptions are as follows:
- `/results`: contains results data
- `/src/stable`: contains stable code 
- `/src/dev`: contains latest dev code
- `/src/old`: contains codes shared prior to 2025 March
- `/src/crc`: contains codes to run in Notre Dame's CRC (high performance computing resource)
- `/src/crc_v2`: Version 2 for `/src/crc`

Authors:
- Armed Tusha (atusha@nd.edu)
- Joshua Roy Palathinkal (jpalthi@nd.edu)

TODO:
- Need to merge `/src/crc_v2` with `/src/crc`
- Need to implement single script to select between SVD, PMI and s-PMI algos
- Verify why `release(channel)` isn't changing pathGain and pathDelay
- Implement algo for `perfRx=false`

Major Changelogs:
- Removed implementation of multiple slots due to bug causing `nrOFDMModulate()` to fail ([link](https://github.com/armedtusha/5gNrBeamforningSim/issues/2))
- Implemented s-PMI algo
- User-input option for different degrees of saving variables in `/src/crc`