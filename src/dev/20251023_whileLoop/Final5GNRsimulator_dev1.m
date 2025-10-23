%% ------------------------------------------------------------------------
% Author  : Armed Tusha (Original), Joshua (Optimized/Simplified)
% Institution : University of Notre Dame
% Date        : August 1, 2025 (Original), October 23, 2025 (Dev)
% ------------------------------------------------------------------------

%--------------------------------------------------------------------------
% Changelogs:
% - Initial version created by Armed Tusha
% - Introduced parfor for parallel processing, and other optimizations to
%   accomodate parallel execution.
% - Removed capability to simulation multiple slots.
% - Incorporated target bit error based simulation stopping criteria.
% -------------------------------------------------------------------------

clear all, close all, clc;

%% ------------------------------------------------------------------------
% Simulation Parameters
% -------------------------------------------------------------------------

ModOrder                          = "256QAM";    % Modulation order QPSK, 16QAM, 64QAM, 256QAM
SNRdB                             = [0:5:40];  % SNR in dB, you can input a range too, and have the results for all [0:5:20], etc.
pmiPrecoding                      = 0;          % If 1 PMI precoder, else SVD
perfectEstimation                 = false;      % Perfect synchronization and channel estimation
maxBitErrors                      = 100;        % Target number of bit errors per SNR point
maxIter                           = 1e6;        % Maximum iterations per SNR (safety limit)

%% -------------------------------------------------------------------------
% Carrier Configuration
% -------------------------------------------------------------------------

carrier                   = nrCarrierConfig;    % 5G-NR Matlab Tool-box configuration
carrier.SubcarrierSpacing = 30;                 % Subcarrier spacing, unity kHz
carrier.NFrame            = 1;                  % Time domain signal, unity is 5G-NR number of frames

% -------------------------------------------------------------------------
% 3. PDSCH and DM-RS Configuration
% -------------------------------------------------------------------------
pdsch                             = nrPDSCHConfig;
pdsch.Modulation                  = ModOrder;
pdsch.NumLayers                   = 1;
pdsch.PRBSet                      = 0:carrier.NSizeGrid-1; % Full band allocation
pdsch.DMRS.DMRSAdditionalPosition = 1;
pdsch.DMRS.DMRSConfigurationType  = 1;
pdsch.DMRS.DMRSLength             = 2;

% -------------------------------------------------------------------------
% HARQ Configuration & Coding Rate
% -------------------------------------------------------------------------
NHARQProcesses                   = 16;           % Number of parallel HARQ processes
rvSeq                            = [0 2 3 1];
rvSeq                            = [0];          % Close the retransmission

% Coding rate
if pdsch.NumCodewords == 1
    codeRate = 490/1024;
else
    codeRate = [490 490]./1024;
end

codeRate  = 948/1024;                            % This is the code rate

% -------------------------------------------------------------------------
% DL-SCH encoder and decoder objects (TEMPLATE - will be cloned per worker)
% -------------------------------------------------------------------------
encodeDLSCH_template                       = nrDLSCH;
encodeDLSCH_template.MultipleHARQProcesses = true;
encodeDLSCH_template.TargetCodeRate        = codeRate;

% Create DLSCH decoder object (TEMPLATE)
decodeDLSCH_template                       = nrDLSCHDecoder;
decodeDLSCH_template.MultipleHARQProcesses = true;
decodeDLSCH_template.TargetCodeRate        = codeRate;
decodeDLSCH_template.LDPCDecodingAlgorithm = "Normalized min-sum";
decodeDLSCH_template.MaximumLDPCIterationCount = 6;

% -------------------------------------------------------------------------
% CSI-RS Configuration
% -------------------------------------------------------------------------
csirs                       = nrCSIRSConfig;
csirs.CSIRSType             = {'nzp','nzp','nzp'};
csirs.RowNumber             = [4 4 4];
csirs.NumRB                 = 52;
csirs.RBOffset              = 0;
csirs.CSIRSPeriod           = [4 0];
csirs.SymbolLocations       = {0, 0, 0};
csirs.SubcarrierLocations   = {0, 4, 8};
csirs.Density               = {'one','one','one'};

% -------------------------------------------------------------------------
% Configure CSI reporting configuration parameters.
% -------------------------------------------------------------------------
reportConfig.NStartBWP      = 0;
reportConfig.NSizeBWP       = 52;
reportConfig.CQITable       = 'table1';
reportConfig.CodebookType   = 'Type1SinglePanel';
reportConfig.PanelDimensions = [2 1];
reportConfig.CQIMode        = 'Wideband';
reportConfig.PMIMode        = 'Wideband';
reportConfig.SubbandSize    = [];
reportConfig.PRGSize        = [];
reportConfig.CodebookMode   = 1;
reportConfig.CodebookSubsetRestriction = [];
reportConfig.i2Restriction  = [];
reportConfig.RIRestriction  = [];
reportConfig.NumberOfBeams  = 2;
reportConfig.SubbandAmplitude = false;
reportConfig.PhaseAlphabetSize = 4;
reportConfig.ParameterCombination = 2;
reportConfig.NumberOfPMISubbandsPerCQISubband = 2;

% -------------------------------------------------------------------------
% Channel Configuration
% -------------------------------------------------------------------------
nTxAnts = csirs.NumCSIRSPorts(1);    % Number of transmit antennas (physical)
nRxAnts = 1;                         % Number of receive antennas (physical)
csirsPorts = csirs.NumCSIRSPorts(1); % Number of CSI-RS ports, logical antennas

% Get CDM lengths corresponding to configured CSI-RS resources
cdmLengths = getCDMLengths(csirs);

% OPTIMIZATION: Precompute OFDM info once (moved outside all loops)
ofdmInfo = nrOFDMInfo(carrier);

% Set RNG state for repeatability
rng('default');

%% -------------------------------------------------------------------------
% OPTIMIZED Monte Carlo Simulator - Single Slot Version with Bit Error Target
% -------------------------------------------------------------------------
fprintf('Starting single-slot simulation with target of %d bit errors per SNR...\n', maxBitErrors);
fprintf('Maximum iterations per SNR: %d\n', maxIter);
fprintf('Using parallel processing (parfor) across SNR values\n\n');

% Preallocate result arrays
numSNR = length(SNRdB);
ber_results = zeros(1, numSNR);
totalBits_results = zeros(1, numSNR);
totalBitErrors_results = zeros(1, numSNR);
numIterations_results = zeros(1, numSNR);

% Create a parallel pool if not already created
try
    poolobj = gcp('nocreate');
    if isempty(poolobj)
        fprintf('No parallel pool found. Starting parallel pool...\n');
        poolobj = parpool;
    end
    fprintf('Using parallel pool with %d workers\n', poolobj.NumWorkers);
catch
    fprintf('Parallel Computing Toolbox not available. Using serial execution.\n');
end

tic; % Start timing

% Parallel loop through each SNR value
parfor snrIdx = 1:numSNR
    fprintf('\n========================================\n');
    fprintf('Processing SNR = %.1f dB (Worker)\n', SNRdB(snrIdx));
    fprintf('========================================\n');
    
    % Initialize counters for this SNR
    totalBitErrors = 0;
    totalBits = 0;
    iterCount = 0;
    
    % Create stateful objects for this SNR (local to each worker)
    encodeDLSCH = clone(encodeDLSCH_template);
    decodeDLSCH = clone(decodeDLSCH_template);
    harqEntity = HARQEntity(0:NHARQProcesses-1, rvSeq, pdsch.NumCodewords);
    
    % Local carrier object (each worker needs its own)
    localCarrier = carrier;
    
    % Initialize practical timing offset
    offsetPractical = 0;
    
    % Initialize temporary variables
    pmiInfoPractical = struct();
    trBlk = [];
    
    % While loop: continue until target bit errors reached or max iterations
    while totalBitErrors < maxBitErrors && iterCount < maxIter
        iterCount = iterCount + 1;
        
        % Create a channel object
        channel = nrTDLChannel;
        channel.DelayProfile = "TDL-C";
        channel.NumTransmitAntennas = nTxAnts;
        channel.NumReceiveAntennas = nRxAnts;
        channel.MaximumDopplerShift = 50;
        channel.DelaySpread = 300e-9;
        
        % Get channel info
        chInfo = info(channel);
        
        % Zero delay configuration
        channel.DelaySpread = 0;
        maxChDelay = 0;
        
        % Use precomputed ofdmInfo
        channel.SampleRate = ofdmInfo.SampleRate;
        
        % Initial timing offset
        offset = 0;
        
        % Get initial channel estimate and precoding matrix
        estChannelGrid = getInitialChannelEstimate(channel, localCarrier);
        newPrecodingWeight = getPrecodingMatrix(pdsch.PRBSet, pdsch.NumLayers, estChannelGrid);
        
        % Create carrier resource grid for one slot
        csirsSlotGrid = nrResourceGrid(localCarrier, csirsPorts);
        
        % Single slot - no loop needed
        localCarrier.NSlot = 0;
        
        % Generate CSI-RS indices and symbols
        csirsInd = nrCSIRSIndices(localCarrier, csirs);
        csirsSym = nrCSIRS(localCarrier, csirs);
        
        % Map CSI-RS to slot grid
        csirsSlotGrid(csirsInd) = csirsSym;
        
        % Map CSI-RS ports to transmit antennas
        wtx = eye(csirsPorts, nTxAnts);
        txGrid = reshape(reshape(csirsSlotGrid, [], csirsPorts) * wtx, ...
            size(csirsSlotGrid, 1), size(csirsSlotGrid, 2), nTxAnts);
        
        % Perform OFDM modulation
        txWaveform = nrOFDMModulate(localCarrier, txGrid);
        txWaveform = [txWaveform; zeros(maxChDelay, size(txWaveform, 2))];
        
        % Transmit through channel
        [rxWaveform, pathGains, sampleTimes] = channel(txWaveform);
        
        % Add AWGN
        SNR = 10^(SNRdB(snrIdx) / 10);
        sigma = 1 / sqrt(2.0 * nRxAnts * double(ofdmInfo.Nfft) * SNR);
        noise = sigma * complex(randn(size(rxWaveform)), randn(size(rxWaveform)));
        rxWaveform = rxWaveform + noise;
        
        % Timing estimation
        [t, mag] = nrTimingEstimate(localCarrier, rxWaveform, csirsInd, csirsSym);
        offsetPractical = hSkipWeakTimingOffset(offsetPractical, t, mag);
        
        % Path filters and perfect timing
        pathFilters = getPathFilters(channel);
        offsetPerfect = nrPerfectTimingEstimate(pathGains, pathFilters);
        
        % Time-domain offset correction
        rxWaveformPractical = rxWaveform(1 + offsetPractical:end, :);
        rxWaveformPerfect = rxWaveform(1 + offsetPerfect:end, :);
        
        % OFDM demodulation
        rxGridPractical = nrOFDMDemodulate(localCarrier, rxWaveformPractical);
        rxGridPerfect = nrOFDMDemodulate(localCarrier, rxWaveformPerfect);
        
        % Zero-padding for incomplete slots
        symbPerSlot = localCarrier.SymbolsPerSlot;
        K = size(rxGridPractical, 1);
        LPractical = size(rxGridPractical, 2);
        LPerfect = size(rxGridPerfect, 2);
        
        if LPractical < symbPerSlot
            rxGridPractical = cat(2, rxGridPractical, zeros(K, symbPerSlot - LPractical, nRxAnts));
        end
        if LPerfect < symbPerSlot
            rxGridPerfect = cat(2, rxGridPerfect, zeros(K, symbPerSlot - LPerfect, nRxAnts));
        end
        
        rxGridPractical = rxGridPractical(:, 1:symbPerSlot, :);
        rxGridPerfect = rxGridPerfect(:, 1:symbPerSlot, :);
        
        % Extract NZP-CSI-RS symbols and indices
        nzpCSIRSSym = csirsSym(csirsSym ~= 0);
        nzpCSIRSInd = csirsInd(csirsSym ~= 0);
        
        % Channel estimation
        [PracticalHest, nVarPractical] = nrChannelEstimate(localCarrier, rxGridPractical, ...
            nzpCSIRSInd, nzpCSIRSSym, 'CDMLengths', cdmLengths, 'AveragingWindow', [0 5]);
        
        PerfectHest = nrPerfectChannelEstimate(localCarrier, pathGains, pathFilters, offsetPerfect, sampleTimes);
        
        % Perfect noise estimate
        noiseGrid = nrOFDMDemodulate(localCarrier, noise(1 + offsetPerfect:end, :));
        nVarPerfect = var(noiseGrid(:));
        
        % Simplified CSI computation (only when needed)
        if ~isempty(nzpCSIRSInd)
            numLayersPractical = 1; % Fixed for this configuration
            
            % Only compute PMI info when using PMI precoding
            if pmiPrecoding == 1
                [~, pmiPractical, ~, pmiInfoPractical] = hCQISelect(localCarrier, csirs, ...
                    reportConfig, numLayersPractical, PracticalHest, nVarPractical);
            end
        end
        
        % Generate PDSCH indices
        [pdschIndices, pdschInfo] = nrPDSCHIndices(localCarrier, pdsch);
        
        % Calculate transport block sizes
        Xoh_PDSCH = 0;
        trBlkSizes = nrTBS(pdsch.Modulation, pdsch.NumLayers, numel(pdsch.PRBSet), ...
            pdschInfo.NREPerPRB, codeRate, Xoh_PDSCH);
        
        % HARQ processing
        for cwIdx = 1:pdsch.NumCodewords
            if harqEntity.NewData(cwIdx)
                trBlk = randi([0 1], trBlkSizes(cwIdx), 1);
                setTransportBlock(encodeDLSCH, trBlk, cwIdx - 1, harqEntity.HARQProcessID);
                
                if harqEntity.SequenceTimeout(cwIdx)
                    resetSoftBuffer(decodeDLSCH, cwIdx - 1, harqEntity.HARQProcessID);
                end
            end
        end
        
        % DL-SCH Encoding
        codedTrBlock = encodeDLSCH(pdsch.Modulation, pdsch.NumLayers, pdschInfo.G, ...
            harqEntity.RedundancyVersion, harqEntity.HARQProcessID);
        
        % PDSCH Modulation
        pdschSymbols = nrPDSCH(localCarrier, pdsch, codedTrBlock);
        
        % Precoding
        if pmiPrecoding == 0
            precodingWeights = newPrecodingWeight;
        else
            precodingWeights = (pmiInfoPractical.W).';
        end
        
        pdschSymbolsPrecoded = pdschSymbols * precodingWeights;
        
        % DM-RS generation
        dmrsSymbols = nrPDSCHDMRS(localCarrier, pdsch);
        dmrsIndices = nrPDSCHDMRSIndices(localCarrier, pdsch);
        
        % Resource grid mapping
        pdschGrid = nrResourceGrid(localCarrier, nTxAnts);
        [~, pdschAntIndices] = nrExtractResources(pdschIndices, pdschGrid);
        pdschGrid(pdschAntIndices) = pdschSymbolsPrecoded;
        
        % PDSCH DM-RS precoding and mapping
        for p = 1:size(dmrsSymbols, 2)
            [~, dmrsAntIndices] = nrExtractResources(dmrsIndices(:, p), pdschGrid);
            pdschGrid(dmrsAntIndices) = pdschGrid(dmrsAntIndices) + dmrsSymbols(:, p) * precodingWeights(p, :);
        end
        
        % OFDM modulation
        txWaveform = nrOFDMModulate(localCarrier, pdschGrid);
        txWaveform = [txWaveform; zeros(maxChDelay, size(txWaveform, 2))];
        
        % Channel transmission
        [rxWaveform, pathGains, sampleTimes] = channel(txWaveform);
        
        % Add noise
        noise = generateAWGN(SNRdB(snrIdx), nRxAnts, ofdmInfo.Nfft, size(rxWaveform));
        rxWaveform = rxWaveform + noise;
        
        % Timing estimation and synchronization
        if perfectEstimation
            pathFilters = getPathFilters(channel);
            offset = nrPerfectTimingEstimate(pathGains, pathFilters);
        else
            [t, mag] = nrTimingEstimate(localCarrier, rxWaveform, dmrsIndices, dmrsSymbols);
            offset = hSkipWeakTimingOffset(offset, t, mag);
        end
        
        rxWaveform = rxWaveform(1 + offset:end, :);
        
        % OFDM demodulation
        rxGrid = nrOFDMDemodulate(localCarrier, rxWaveform);
        
        [K, L, R] = size(rxGrid);
        if L < localCarrier.SymbolsPerSlot
            rxGrid = cat(2, rxGrid, zeros(K, localCarrier.SymbolsPerSlot - L, R));
        end
        
        % Channel estimation
        if perfectEstimation
            estChGridAnts = nrPerfectChannelEstimate(localCarrier, pathGains, pathFilters, offset, sampleTimes);
            noiseGrid = nrOFDMDemodulate(localCarrier, noise(1 + offset:end, :));
            noiseEst = var(noiseGrid(:));
            newPrecodingWeight = getPrecodingMatrix(pdsch.PRBSet, pdsch.NumLayers, estChGridAnts);
            estChGridLayers = precodeChannelEstimate(estChGridAnts, precodingWeights.');
        else
            [estChGridLayers, noiseEst] = nrChannelEstimate(localCarrier, rxGrid, dmrsIndices, ...
                dmrsSymbols, 'CDMLengths', pdsch.DMRS.CDMLengths);
            estChGridAnts = precodeChannelEstimate(estChGridLayers, conj(precodingWeights));
            newPrecodingWeight = getPrecodingMatrix(pdsch.PRBSet, pdsch.NumLayers, estChGridAnts);
        end
        
        % Equalization
        [pdschRx, pdschHest] = nrExtractResources(pdschIndices, rxGrid, estChGridLayers);
        [pdschEq, csi] = nrEqualizeMMSE(pdschRx, pdschHest, noiseEst);
        
        % PDSCH decoding
        [dlschLLRs, rxSymbols] = nrPDSCHDecode(localCarrier, pdsch, pdschEq, noiseEst);
        
        % Scale LLRs by CSI
        csi = nrLayerDemap(csi);
        for cwIdx = 1:pdsch.NumCodewords
            Qm = length(dlschLLRs{cwIdx}) / length(rxSymbols{cwIdx});
            csi{cwIdx} = repmat(csi{cwIdx}.', Qm, 1);
            dlschLLRs{cwIdx} = dlschLLRs{cwIdx} .* csi{cwIdx}(:);
        end
        
        % DL-SCH Decoding
        decodeDLSCH.TransportBlockLength = trBlkSizes;
        [decbits, blkerr] = decodeDLSCH(dlschLLRs, pdsch.Modulation, pdsch.NumLayers, ...
            harqEntity.RedundancyVersion, harqEntity.HARQProcessID);
        
        % Calculate bit errors for this iteration
        numBitErrors = sum(trBlk ~= decbits);
        numBits = length(trBlk);
        
        % Update totals
        totalBitErrors = totalBitErrors + numBitErrors;
        totalBits = totalBits + numBits;
        
        % Update HARQ
        updateAndAdvance(harqEntity, blkerr, trBlkSizes, pdschInfo.G);
        
        % Progress update every 100 iterations (less verbose in parallel)
        if mod(iterCount, 500) == 0
            currentBER = totalBitErrors / totalBits;
            fprintf('  [SNR %.1f dB] Iteration %d: Bit Errors = %d/%d, BER = %.4e\n', ...
                SNRdB(snrIdx), iterCount, totalBitErrors, maxBitErrors, currentBER);
        end
    end
    
    % Store results for this SNR (parallel-safe assignment)
    ber_results(snrIdx) = totalBitErrors / totalBits;
    totalBits_results(snrIdx) = totalBits;
    totalBitErrors_results(snrIdx) = totalBitErrors;
    numIterations_results(snrIdx) = iterCount;
    
    % Final report for this SNR
    fprintf('\n[SNR %.1f dB] completed:\n', SNRdB(snrIdx));
    fprintf('  Total iterations: %d\n', iterCount);
    fprintf('  Total bit errors: %d\n', totalBitErrors);
    fprintf('  Total bits: %d\n', totalBits);
    fprintf('  BER: %.4e\n', ber_results(snrIdx));
    
    if iterCount >= maxIter
        fprintf('  WARNING: Reached maximum iterations without achieving target bit errors\n');
    end
end

elapsedTime = toc;
fprintf('\n========================================\n');
fprintf('Simulation completed in %.2f seconds (%.2f minutes)\n', elapsedTime, elapsedTime/60);
fprintf('========================================\n\n');

% Display summary table
fprintf('Summary Results:\n');
fprintf('%-10s %-15s %-15s %-15s %-15s\n', 'SNR (dB)', 'Iterations', 'Bit Errors', 'Total Bits', 'BER');
fprintf('%-10s %-15s %-15s %-15s %-15s\n', '--------', '----------', '----------', '----------', '---');
for snrIdx = 1:numSNR
    fprintf('%-10.1f %-15d %-15d %-15d %-15.4e\n', ...
        SNRdB(snrIdx), numIterations_results(snrIdx), ...
        totalBitErrors_results(snrIdx), totalBits_results(snrIdx), ber_results(snrIdx));
end

%% ------------------------------------------------------------------------
% Simulation Results
% -------------------------------------------------------------------------
figure
semilogy(SNRdB, ber_results, '-o', 'LineWidth', 2);
xlabel('SNR (dB)'); 
ylabel('BER'); 
grid on;
title(sprintf('BER vs SNR (Target: %d bit errors per SNR)', maxBitErrors));
legend('Single Slot Simulation');

% Additional plot: Number of iterations per SNR
figure
plot(SNRdB, numIterations_results, '-s', 'LineWidth', 2);
xlabel('SNR (dB)'); 
ylabel('Number of Iterations'); 
grid on;
title('Iterations Required to Reach Target Bit Errors');
legend('Iteration Count');

%% *References*
% [1] 3GPP TS 38.214. "NR; Physical layer procedures for data."

%% *Local Functions*

function cdmLengths = getCDMLengths(csirs)
    CDMType = csirs.CDMType;
    if ~iscell(csirs.CDMType)
        CDMType = {csirs.CDMType};
    end
    CDMTypeOpts = {'noCDM','fd-CDM2','CDM4','CDM8'};
    CDMLengthOpts = {[1 1],[2 1],[2 2],[2 4]};
    cdmLengths = CDMLengthOpts{strcmpi(CDMTypeOpts,CDMType{1})};
end

function noise = generateAWGN(SNRdB, nRxAnts, Nfft, sizeRxWaveform)
    SNR = 10^(SNRdB / 10);
    N0 = 1 / sqrt(2.0 * nRxAnts * double(Nfft) * SNR);
    noise = N0 * complex(randn(sizeRxWaveform), randn(sizeRxWaveform));
end

function wtx = getPrecodingMatrix(PRBSet, NLayers, hestGrid)
    allocSc = (1:12)' + 12 * PRBSet(:).';
    allocSc = allocSc(:);
    [~, ~, R, P] = size(hestGrid);
    estAllocGrid = hestGrid(allocSc, :, :, :);
    Hest = permute(mean(reshape(estAllocGrid, [], R, P)), [2 3 1]);
    [~, ~, V] = svd(Hest);
    wtx = V(:, 1:NLayers).';
    wtx = wtx / sqrt(NLayers);
end

function estChannelGrid = getInitialChannelEstimate(channel, carrier)
    chClone = channel.clone();
    chClone.release();
    chClone.ChannelFiltering = false;
    [pathGains, sampleTimes] = chClone();
    pathFilters = getPathFilters(chClone);
    offset = nrPerfectTimingEstimate(pathGains, pathFilters);
    estChannelGrid = nrPerfectChannelEstimate(carrier, pathGains, pathFilters, offset, sampleTimes);
end

function estChannelGrid = precodeChannelEstimate(estChannelGrid, W)
    K = size(estChannelGrid, 1);
    L = size(estChannelGrid, 2);
    R = size(estChannelGrid, 3);
    estChannelGrid = reshape(estChannelGrid, K * L * R, []);
    estChannelGrid = estChannelGrid * W;
    estChannelGrid = reshape(estChannelGrid, K, L, R, []);
end
