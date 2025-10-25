%% ------------------------------------------------------------------------
% Author  : Armed Tusha (Original), Joshua (Optimized/Modified)
% Institution : University of Notre Dame
% Date        : August 1, 2025 (Original), October 23, 2025 (Modified)
% ------------------------------------------------------------------------

%--------------------------------------------------------------------------
% Changelogs:
% - Initial version created by Armed Tusha, parfor added by Joshua. 
% - Packet Definition: 2 slots (noSlotsSim = 2)
% - Packet Error: At least one bit error across the 2 slots
% - Modified to test multiple ModOrder and pmiPrecoding combinations
% -------------------------------------------------------------------------

clear all, close all, clc;

%% ------------------------------------------------------------------------
% Simulation Parameters
% -------------------------------------------------------------------------

noSlotsSim                        = 2;         % Number of slots per packet (FIXED at 2)
ModOrderList                      = ["16QAM", "64QAM", "256QAM"];  % Modulation orders to test
pmiPrecodingList                  = [0, 1];    % 0 = SVD, 1 = PMI
SNRdB                             = [0:5:40];  % SNR in dB, you can input a range too, and have the results for all [0:5:20], etc.
perfectEstimation                 = false;     % Perfect synchronization and channel estimation
numIter                           = 1e2;       % Number of iterations (packets) for this link configuration

%% -------------------------------------------------------------------------
% Carrier Configuration
% -------------------------------------------------------------------------

carrier                   = nrCarrierConfig;    % 5G-NR Matlab Tool-box configuration
carrier.SubcarrierSpacing = 30;                 % Subcarrier spacing, unity kHz
carrier.NFrame            = 1;                  % Time domain signal, unity is 5G-NR number of frames

% -------------------------------------------------------------------------
% 3. PDSCH and DM-RS Configuration (BASE)
% -------------------------------------------------------------------------
pdsch_base                             = nrPDSCHConfig;
pdsch_base.NumLayers                   = 1;
pdsch_base.PRBSet                      = 0:carrier.NSizeGrid-1; % Full band allocation
pdsch_base.DMRS.DMRSAdditionalPosition = 1;
pdsch_base.DMRS.DMRSConfigurationType  = 1;
pdsch_base.DMRS.DMRSLength             = 2;

% -------------------------------------------------------------------------
% HARQ Configuration & Coding Rate
% -------------------------------------------------------------------------
NHARQProcesses                   = 16;           % Number of parallel HARQ processes
rvSeq                            = [0 2 3 1];
rvSeq                            = [0];          % Close the retransmission

% Coding rate
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
decodeDLSCH_template.MaximumLDPCIterationCount = 8;

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
% Storage for all results
% -------------------------------------------------------------------------
numSNR = length(SNRdB);
numModOrders = length(ModOrderList);
numPrecoding = length(pmiPrecodingList);
numCombinations = numModOrders * numPrecoding;

% Storage: avgBER_all(combination, SNR)
avgBER_all = zeros(numCombinations, numSNR);
totalPacketErrors_all = zeros(numCombinations, numSNR);
avgBitErrorsPerPacket_all = zeros(numCombinations, numSNR);
combinationLabels = cell(numCombinations, 1);

%% -------------------------------------------------------------------------
% Run simulations for all combinations
% -------------------------------------------------------------------------

combIdx = 0;
for modIdx = 1:numModOrders
    for pmiIdx = 1:numPrecoding
        combIdx = combIdx + 1;
        
        % Current configuration
        ModOrder = ModOrderList(modIdx);
        pmiPrecoding = pmiPrecodingList(pmiIdx);
        
        % Create label for this combination
        precodingLabel = "";
        if pmiPrecoding == 0
            precodingLabel = "SVD";
        else
            precodingLabel = "PMI";
        end
        combinationLabels{combIdx} = sprintf('%s-%s', ModOrder, precodingLabel);
        
        fprintf('\n========================================================================\n');
        fprintf('Running Simulation %d/%d: %s with %s Precoding\n', combIdx, numCombinations, ModOrder, precodingLabel);
        fprintf('========================================================================\n');
        
        % Configure PDSCH for this modulation order
        pdsch = pdsch_base;
        pdsch.Modulation = ModOrder;
        
        % Run simulation
        fprintf('Starting optimized simulation with %d packets (iterations)...\n', numIter);
        fprintf('Packet = %d slots, Packet error = at least 1 bit error in packet\n', noSlotsSim);
        fprintf('Using parallel processing (parfor) if Parallel Computing Toolbox available.\n\n');
        
        % OPTIMIZATION 1: Preallocate result matrices (no dynamic growth)
        inter_snr = zeros(numIter, numSNR);              % BER per iteration per SNR
        packet_bit_errors = zeros(numIter, numSNR);      % Bit errors per packet per SNR
        packet_error_flag = zeros(numIter, numSNR);      % Packet error flag (1 if error, 0 otherwise)
        
        % Create a parallel pool if not already created (optional - parfor will auto-create)
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
        
        % OPTIMIZATION 2: Use parfor for parallel iterations
        % Each worker gets its own encoder/decoder/HARQ entity
        parfor msnr = 1:numIter
            % OPTIMIZATION 3: Create local copies of stateful objects for each worker
            % This is necessary for parfor to avoid shared state
            encodeDLSCH = clone(encodeDLSCH_template);
            decodeDLSCH = clone(decodeDLSCH_template);
            harqEntity = HARQEntity(0:NHARQProcesses-1, rvSeq, pdsch.NumCodewords);
            
            % Local carrier object (to avoid broadcast variable issues)
            localCarrier = carrier;
            
            % Initialize practical timing offset for this iteration
            offsetPractical = 0;
            
            % OPTIMIZATION FIX: Initialize temporary variables to avoid parfor warnings
            pmiInfoPractical = struct(); % Initialize empty struct
            trBlk = []; % Initialize empty array
            
            % OPTIMIZATION 4: Preallocate per-iteration arrays
            ber_snr = zeros(1, numSNR);
            bitErrors_snr = zeros(1, numSNR);
            packetError_snr = zeros(1, numSNR);
            
            for isi = 1:numSNR
                % OPTIMIZATION 5: Preallocate slot arrays
                ber_slot = zeros(1, noSlotsSim);
                bitErrors_slot = zeros(1, noSlotsSim);
                totalBits_slot = zeros(1, noSlotsSim);
                
                for nslot = 0:noSlotsSim-1
                    % Create a channel object
                    channel = nrTDLChannel;
                    channel.DelayProfile = "TDL-C";
                    channel.NumTransmitAntennas = nTxAnts;
                    channel.NumReceiveAntennas = nRxAnts;
                    channel.MaximumDopplerShift = 50;
                    channel.DelaySpread = 30e-9;
                    
                    % Get channel info
                    chInfo = info(channel);
                    
                    % Zero delay configuration
                    channel.DelaySpread = 0;
                    maxChDelay = 0;
                    
                    % OPTIMIZATION 6: Use precomputed ofdmInfo
                    channel.SampleRate = ofdmInfo.SampleRate;
                    
                    % Initial timing offset
                    offset = 0;
                    
                    % Get initial channel estimate and precoding matrix
                    estChannelGrid = getInitialChannelEstimate(channel, localCarrier);
                    newPrecodingWeight = getPrecodingMatrix(pdsch.PRBSet, pdsch.NumLayers, estChannelGrid);
                    
                    % Create carrier resource grid for one slot
                    csirsSlotGrid = nrResourceGrid(localCarrier, csirsPorts);
                    
                    % Update slot number
                    localCarrier.NSlot = nslot;
                    
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
                    SNR = 10^(SNRdB(isi) / 10);
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
                    
                    % OPTIMIZATION 7: Simplified CSI computation (only when needed)
                    % Skip detailed CSI reporting arrays in optimized version to save memory/time
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
                    noise = generateAWGN(SNRdB(isi), nRxAnts, ofdmInfo.Nfft, size(rxWaveform));
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
                    
                    % Calculate BER and bit errors for this slot
                    [numBitErrors, ber] = biterr(trBlk, decbits);
                    numBits = length(trBlk);
                    
                    % OPTIMIZATION 8: Direct assignment instead of concatenation
                    ber_slot(nslot + 1) = ber;
                    bitErrors_slot(nslot + 1) = numBitErrors;
                    totalBits_slot(nslot + 1) = numBits;
                    
                    % Update HARQ
                    updateAndAdvance(harqEntity, blkerr, trBlkSizes, pdschInfo.G);
                end
                
                % OPTIMIZATION 9: Calculate packet-level metrics
                totalBitErrorsInPacket = sum(bitErrors_slot);
                totalBitsInPacket = sum(totalBits_slot);
                
                % Packet error flag: 1 if any bit errors in the packet, 0 otherwise
                packetErrorFlag = double(totalBitErrorsInPacket > 0);
                
                % Store results for this SNR
                ber_snr(isi) = mean(ber_slot);                      % Average BER across slots
                bitErrors_snr(isi) = totalBitErrorsInPacket;        % Total bit errors in packet
                packetError_snr(isi) = packetErrorFlag;             % Packet error indicator
            end
            
            % OPTIMIZATION 10: Store results directly in preallocated matrix
            inter_snr(msnr, :) = ber_snr;
            packet_bit_errors(msnr, :) = bitErrors_snr;
            packet_error_flag(msnr, :) = packetError_snr;
        end
        
        elapsedTime = toc;
        fprintf('\nSimulation completed in %.2f seconds (%.2f minutes)\n', elapsedTime, elapsedTime/60);
        fprintf('Average time per iteration: %.4f seconds\n', elapsedTime/numIter);
        
        % Compute Summary Statistics for this combination
        totalPacketErrors = sum(packet_error_flag, 1);
        avgBER = mean(inter_snr, 1);
        avgBitErrorsPerPacket = mean(packet_bit_errors, 1);
        
        % Store in global arrays
        avgBER_all(combIdx, :) = avgBER;
        totalPacketErrors_all(combIdx, :) = totalPacketErrors;
        avgBitErrorsPerPacket_all(combIdx, :) = avgBitErrorsPerPacket;
        
        % Display results for this combination
        fprintf('\n========================================\n');
        fprintf('Summary Statistics for %s:\n', combinationLabels{combIdx});
        fprintf('========================================\n');
        fprintf('%-10s %-15s %-20s %-20s\n', 'SNR (dB)', 'BER', 'Avg Bit Err/Pkt', 'Pkt Errors');
        fprintf('%-10s %-15s %-20s %-20s\n', '--------', '---', '---------------', '----------');
        for idx = 1:numSNR
            fprintf('%-10.1f %-15.4e %-20.2f %-20d\n', ...
                SNRdB(idx), avgBER(idx), avgBitErrorsPerPacket(idx), totalPacketErrors(idx));
        end
    end
end

%% ------------------------------------------------------------------------
% Combined Plot - BER vs SNR for All Combinations
% -------------------------------------------------------------------------
figure;

% Define colors and markers for different combinations
colors = lines(numCombinations);
markers = {'o', 's', 'd', '^', 'v', '>'};

for combIdx = 1:numCombinations
    semilogy(SNRdB, avgBER_all(combIdx, :), ...
        'LineWidth', 2, ...
        'Marker', markers{combIdx}, ...
        'MarkerSize', 8, ...
        'Color', colors(combIdx, :), ...
        'DisplayName', combinationLabels{combIdx});
    hold on;
end

grid on;
hold off;
xlabel('SNR (dB)', 'FontSize', 12, 'FontWeight', 'bold'); 
ylabel('BER', 'FontSize', 12, 'FontWeight', 'bold'); 
title(sprintf('BER vs SNR Comparison (%d packets, %d slots/packet)', numIter, noSlotsSim), ...
    'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 10);
set(gca, 'FontSize', 11);

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
