TODO: (increasing order of improtance):
- [x] ~~Need to merge `/src/crc_v2` with `/src/crc`:~~ moved `/src/crc` to `archive/20260601`, renamed `/src/crc_v2` to `/src/AnalyseEirp`.
- [ ] Verify why `release(channel)` isn't changing pathGain and pathDelay
- [ ] Issue with BER results for SVD when `perfChan`=false at -2dB SNR for 16-QAM and 10,11dB SNR for 256-QAM.
- [ ] Need to merge `perfTx` and `perfRx` into `perfChan`
- [ ] User-input option for different degrees of saving variables in `/src/crc`
- [x] ~~Implement algo for `perfRx=false`~~
- [x] ~~Need to implement single script to select between SVD, PMI and s-PMI algos~~ OMITTING