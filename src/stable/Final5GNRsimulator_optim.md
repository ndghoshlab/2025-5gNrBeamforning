# 5G NR Simulator Change Report

### **CHANGE 1: Preallocated Result Arrays**
```matlab
% Before: Dynamic growth
inter_snr = [];
for msnr = 1:numIter
    inter_snr = [inter_snr ; ber_snr];  % Reallocates every iteration
end

% After: Preallocated
inter_snr = zeros(numIter, numSNR);
for msnr = 1:numIter
    inter_snr(msnr, :) = ber_snr;  % Direct indexing
end
```

### **CHANGE 2: Fixed parfor Temporary Variable Warnings**
```matlab
% Before: Runtime errors in parfor
parfor msnr = 1:numIter
    if condition
        pmiInfoPractical = hCQISelect(...);
    end
    weights = (pmiInfoPractical.W).';  % Error if condition false
end

% After: Initialize all temporaries
parfor msnr = 1:numIter
    pmiInfoPractical = struct();  % Safe initialization
    trBlk = [];
    % ... conditional assignment ...
end
```

### **CHANGE 3: Real-Time Progress with DataQueue**
```matlab
% Setup async progress reporting
D = parallel.pool.DataQueue;
afterEach(D, @(x) fprintf('Iteration %d/%d (%.1f%%) - SNR: %.1f dB, BER: %.2e\n', ...
    x.iter, numIter, 100*x.iter/numIter, x.snr, x.ber));

parfor msnr = 1:numIter
    if mod(msnr, progressStep) == 0
        send(D, struct('iter', msnr, 'snr', SNRdB(1), 'ber', ber_snr(1)));
    end
end
```

### **CHANGE 4: Cached OFDM Info**
```matlab
% Before: Redundant computation
for loops
    ofdmInfo = nrOFDMInfo(carrier);  % Called millions of times
end

% After: Compute once
ofdmInfo = nrOFDMInfo(carrier);  % Outside all loops
```

### **CHANGE 5: Parallel Processing**
```matlab
% Create template objects for cloning
encodeDLSCH_template = nrDLSCH;
decodeDLSCH_template = nrDLSCHDecoder;

parfor msnr = 1:numIter  % Parallel execution
    % Clone stateful objects per worker
    encodeDLSCH = clone(encodeDLSCH_template);
    decodeDLSCH = clone(decodeDLSCH_template);
    harqEntity = HARQEntity(0:NHARQProcesses-1, rvSeq, pdsch.NumCodewords);
    localCarrier = carrier;  % Local copy for safe modification
end
```

### **CHANGE 6: Reduced Console I/O**
```matlab
% Before: Console print every iteration
for msnr = 1:numIter
    msnr  % Slow I/O
end

% After: Progress via DataQueue (1% intervals)
progressStep = max(1, floor(numIter / 100));
```

### **CHANGE 7: Removed Unused CSI Arrays**
```matlab
% Eliminated unused diagnostic arrays:
% riPracticalPerSlot, cqiPracticalPerSlot, pmiPracticalPerSlot
% SINRPerSubbandPerCWPractical, etc.
```

### **CHANGE 8: Direct Assignment vs Concatenation**
```matlab
% Before: Concatenation
ber_slot = [];
ber_slot = [ber_slot ber];  % Reallocates

% After: Direct indexing
ber_slot = zeros(1, noSlotsSim);
ber_slot(nslot + 1) = ber;  % Direct assignment
```

### **CHANGE 9: Local Variables for parfor**
```matlab
parfor msnr = 1:numIter
    localCarrier = carrier;  % Safe to modify locally
    localCarrier.NSlot = nslot;
end
```

### **CHANGE 10: Cleanup Unused Outputs**
```matlab
[~, ber] = biterr(trBlk, decbits);  % Ignore unused numErr
```