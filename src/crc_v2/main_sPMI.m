clear, clc;

%% sim params
ModOrderList = ["16QAM","64QAM","256QAM"];
pmiPrecoding = "s-PMI";
SNRdB_16QAM = [-5:1:10];
SNRdB_64QAM = [0:1:15];
SNRdB_256QAM = [5:1:20];

s_pmi_filename = 'N1_4_N2_4_Layer_2_El_Ref_Bel_10.mat';

MaximumDopplerShift = 0;
DelaySpread = 300e-9;

perfTx = false;
perfRx = true; % TODO: need to verify when perfRx = false

nLayers = 2;

numIter = 1e0;

%% carrier config
carrier = nrCarrierConfig;
carrier.SubcarrierSpacing = 30;
carrier.NFrame = 1;
carrier.NSlot = 0; % Slot number within the frame

%% pdsch_base config
pdsch_base = nrPDSCHConfig;
pdsch_base.NumLayers = nLayers;
pdsch_base.PRBSet = 0:carrier.NSizeGrid-1; % Full band allocation
pdsch_base.DMRS.DMRSAdditionalPosition = 1;
pdsch_base.DMRS.DMRSConfigurationType = 1;
pdsch_base.DMRS.DMRSLength = 2;

%% harq and coding rate
NHARQProcesses = 16; % Number of parallel HARQ processes
rvSeq = [0]; % Close the retransmission
if pdsch_base.NumCodewords == 1
    codeRate = 490/1024;
else
    codeRate = [490 490]./1024;
end

% DL-SCH encoder
encodeDLSCH_template = nrDLSCH;
encodeDLSCH_template.MultipleHARQProcesses = true;
encodeDLSCH_template.TargetCodeRate = codeRate;

% DLSCH decoder
decodeDLSCH_template = nrDLSCHDecoder;
decodeDLSCH_template.MultipleHARQProcesses = true;
decodeDLSCH_template.TargetCodeRate = codeRate;
decodeDLSCH_template.LDPCDecodingAlgorithm = "Normalized min-sum";
decodeDLSCH_template.MaximumLDPCIterationCount = 8;

%% csr-rs config
% 32-port CSI-RS resource (Row 16)
csirs = nrCSIRSConfig;
csirs.CSIRSType = {'nzp'};
csirs.RowNumber = 16; % 32 ports
csirs.NumRB = 52;
csirs.RBOffset = 0;
csirs.CSIRSPeriod = [4 0];
% Row 16 requires 2 subcarrier and 2 symbol locations
csirs.SubcarrierLocations = {[0 2 4 6]};  % 4 valid kᵢ values
csirs.SymbolLocations = {[7 9]}; % 2 OFDM symbols
csirs.Density = {'one'};

%% report configuration
reportConfig.CodebookType = 'Type1SinglePanel';
reportConfig.PanelDimensions = [4 4]; % 2 × (4×4) = 32 ports
reportConfig.NStartBWP = 0;
reportConfig.NSizeBWP = 52;
reportConfig.CQITable = 'table1';
reportConfig.CQIMode = 'Wideband';
reportConfig.PMIMode = 'Wideband';
reportConfig.CodebookMode = 1;
reportConfig.CodebookSubsetRestriction = [];
reportConfig.i2Restriction = [];
reportConfig.OverSamplingFactors = [4 4];

%% more params
nTxAnts = csirs.NumCSIRSPorts;
nRxAnts = 4;
csirsPorts = csirs.NumCSIRSPorts; % Number of CSI-RS ports (logical antennas)

% s-PMI matrix generation
fprintf('Loading s-PMI data from: %s\n', s_pmi_filename);
data = load(s_pmi_filename);
if ~isempty(data)
    fprintf('Data loaded successfully from: %s\n', s_pmi_filename);
else
    error('Failed to load data from: %s', s_pmi_filename);
end
[i2_length, i11_length, i12_length, i13_length, W_PMI] = getPMIType1SinglePanelCodebook(reportConfig,nLayers);
NumAllPMImatricies = NumberPMImatricies(W_PMI);
for pmi = 1:NumAllPMImatricies
    [Weight_PMI_Layer ~] = Get_Any_PMI_Matrix(W_PMI,pmi); % Select pmi-th PMI matrix from the table given nLayers
    Array_weight_PMI(:,:,pmi) = Weight_PMI_Layer;
end
% New PMI indicies
Array_weight_PMI = Array_weight_PMI(:,:,data.indicies_below_El_Ang_ref);
NumAllPMImatricies = size(Array_weight_PMI,3);

% Get CDM lengths corresponding to configured CSI-RS resources
cdmLengths = getCDMLengths(csirs);

% OPTIMIZATION: Precompute OFDM info once (moved outside all loops)
ofdmInfo = nrOFDMInfo(carrier);

% Set RNG state for repeatability
rng('default');

%% Storage for results
numModOrders = length(ModOrderList);

avgBER_all = cell(numModOrders, 1);
totalSlotErrors_all = cell(numModOrders, 1);
avgBitErrorsPerSlot_all = cell(numModOrders, 1);
SNRdB_all = cell(numModOrders, 1);
combinationLabels = cell(numModOrders, 1);
%%% Use the following code to access the BER metrics:
% % Get metrics for 16QAM (modIdx=1) at SNR index 5
% modIdx = 1;
% snrIdx = 5;
% metadata = SaveMetadata_all{modIdx};

% snr_value = metadata.SNRdB(snrIdx);  % e.g., 5 dB
% ber = avgBER_all{modIdx}(snrIdx);    % Average BER at this SNR
% slot_errors = totalSlotErrors_all{modIdx}(snrIdx);  % Total errors
% avg_bit_errors = avgBitErrorsPerSlot_all{modIdx}(snrIdx);  % Avg bit errors

% fprintf('Modulation: %s, SNR: %.1f dB\n', metadata.ModOrder, snr_value);
% fprintf('BER: %.4e, Slot Errors: %d/%d, Avg Bit Errors: %.2f\n', ...
%     ber, slot_errors, metadata.numIter, avg_bit_errors);

SavePMIperfect_all = cell(numModOrders, 1);
SavePMIpractical_all = cell(numModOrders, 1);
SaveSVDperfect_all = cell(numModOrders, 1);
SaveSVDpractical_all = cell(numModOrders, 1);
Save_sPMI_all = cell(numModOrders, 1);
SaveMetadata_all = cell(numModOrders, 1);
%%% Use the following code to access the precodingVector metadata:
% % Access data for a specific modulation (e.g., modIdx=1 for 16QAM)
% modIdx = 1;
% metadata = SaveMetadata_all{modIdx};
% fprintf('Modulation: %s, Precoding: %s\n', metadata.ModOrder, metadata.precodingLabel);
%
% % Access precoding matrix for iteration 100, SNR index 5
% iter = 100;
% snrIdx = 5;
% pmi_perfect = SavePMIperfect_all{modIdx}{iter, snrIdx};  % nLayers × nTxAnts complex matrix
% snr_value = metadata.SNRdB(snrIdx);  % Actual SNR value in dB

%% recording start time
startTime = datetime('now');
fprintf('\nSimulation started at %s\n', datestr(startTime,'yyyy-mm-dd HH:MM:SS'));

% Base filenames for .mat and .txt
saveFileBase = sprintf('results_%s', datestr(startTime,'yyyymmdd_HHMMSS'));
saveFile = [saveFileBase '.mat'];
saveFileTxt = [saveFileBase '.txt'];

% Start diary
try
    diary(saveFileTxt);
    diary on;
    fprintf('Diary started. Logging command-window output to: %s\n', saveFileTxt);
catch ME
    fprintf('WARNING: Could not start diary logging: %s\n', ME.message);
end

%% Printing simulation configuration
fprintf('\n================ Simulation Configuration ================\n');
fprintf('Number of iterations (slots) per link configuration: %d\n', numIter);
fprintf('Modulation Orders: %s\n', strjoin(ModOrderList, ', '));
fprintf('PMI Precoding: select-PMI (subset)\n');
fprintf('SNR Ranges (dB):\n');
fprintf('  16QAM: %s\n', mat2str(SNRdB_16QAM));
fprintf('  64QAM: %s\n', mat2str(SNRdB_64QAM));
fprintf('  256QAM: %s\n', mat2str(SNRdB_256QAM));
fprintf('MaximumDopplerShift: %.1f Hz\n', MaximumDopplerShift);
fprintf('DelaySpread: %.3f ns\n', DelaySpread*1e9);
fprintf('Perfect TX: [%s]\n', string(perfTx));
fprintf('Perfect RX: [%s]\n', string(perfRx));
fprintf('Panel Dimensions: [%d x %d]\n', reportConfig.PanelDimensions(1), reportConfig.PanelDimensions(2));
fprintf('Number of CSI-RS Ports: %d\n', csirsPorts);
fprintf('Number of Layers: %d\n', nLayers);
fprintf('Number of Transmit Antennas: %d\n', nTxAnts);
fprintf('Number of Receive Antennas: %d\n', nRxAnts);
fprintf('Coding Rate: [%s]\n', strjoin(string(codeRate), ', '));

%% simulations for all combinations
for modIdx = 1:numModOrders
    ModOrder = ModOrderList(modIdx);
    
    if ModOrder == "16QAM"
        SNRdB = SNRdB_16QAM;
    elseif ModOrder == "64QAM"
        SNRdB = SNRdB_64QAM;
    elseif ModOrder == "256QAM"
        SNRdB = SNRdB_256QAM;
    else
        error('Unknown modulation order: %s', ModOrder);
    end
    
    numSNR = length(SNRdB);
    
    SNRdB_all{modIdx} = SNRdB;
    
    precodingLabel = "s-PMI";
    combinationLabels{modIdx} = sprintf('%s-%s', ModOrder, precodingLabel);
    
    fprintf('\n========================================================================\n');
    fprintf('Running Simulation %d/%d: %s with %s Precoding\n', modIdx, numModOrders, ModOrder, precodingLabel);
    fprintf('SNR range: %.1f to %.1f dB\n', min(SNRdB), max(SNRdB));
    fprintf('========================================================================\n');
    
    pdsch = pdsch_base;
    pdsch.Modulation = ModOrder;
    
    fprintf('Starting simulation with %d slots (iterations)...\n', numIter);
    inter_snr = zeros(numIter, numSNR);
    slot_bit_errors = zeros(numIter, numSNR);
    slot_error_flag = zeros(numIter, numSNR);
    
    SavePMIperfect = cell(numIter, numSNR);
    SavePMIpractical = cell(numIter, numSNR);
    SaveSVDperfect = cell(numIter, numSNR);
    SaveSVDpractical = cell(numIter, numSNR);
    Save_sPMI = cell(numIter, numSNR);

    tic;

    parfor iterIdx = 1:numIter
        encodeDLSCH = clone(encodeDLSCH_template);
        decodeDLSCH = clone(decodeDLSCH_template);
        harqEntity = HARQEntity(0:NHARQProcesses-1, rvSeq, pdsch.NumCodewords);
        
        localCarrier = carrier;
        % localCarrier.NSlot = 0; % already done in carrier config
        
        offsetPractical = 0;
                
        trBlk = [];

        % Initialize temporary variables to avoid parfor warnings
        closestPMI = [];
        precodingWeights = [];
        
        ber_snr = zeros(1, numSNR);
        bitErrors_snr = zeros(1, numSNR);
        slotError_snr = zeros(1, numSNR);

        for snrIdx = 1:numSNR
            channel = nrTDLChannel;
            channel.DelayProfile = "TDL-C";
            channel.NumTransmitAntennas = nTxAnts;
            channel.NumReceiveAntennas  = nRxAnts;
            channel.MaximumDopplerShift = MaximumDopplerShift;
            channel.DelaySpread = DelaySpread;

            % TODO: chInfo params doesn't change even after release()
            chInfo = info(channel);
            maxChDelay = chInfo.MaximumChannelDelay;

            release(channel);
            channel.Seed = randi(1e6);
            
            channel.SampleRate = ofdmInfo.SampleRate;
            
            % Initial timing offset
            offset = 0;

            % % Get initial channel estimate and precoding matrix from pdsch
            % estChannelGrid        = getInitialChannelEstimate(channel, localCarrier);
            % newPrecodingWeight = getPrecodingMatrix(pdsch.PRBSet, pdsch.NumLayers, estChannelGrid);
            
            % Create carrier resource grid for one slot
            csirsSlotGrid = nrResourceGrid(localCarrier, csirsPorts);

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
            txWaveform_csirs = nrOFDMModulate(localCarrier, txGrid);
            txWaveform_csirs = [txWaveform_csirs; zeros(maxChDelay, size(txWaveform_csirs, 2))];

            % Transmit through channel
            [rxWaveform_csirs, pathGains, sampleTimes] = channel(txWaveform_csirs);

            % Add AWGN
            SNR = 10^(SNRdB(snrIdx) / 10);
            sigma = 1 / sqrt(2.0 * nRxAnts * double(ofdmInfo.Nfft) * SNR);
            noise = sigma * complex(randn(size(rxWaveform_csirs)), randn(size(rxWaveform_csirs)));
            rxWaveform_csirs = rxWaveform_csirs + noise;

            % Timing estimation
            [t, mag] = nrTimingEstimate(localCarrier, rxWaveform_csirs, csirsInd, csirsSym);
            offsetPractical = hSkipWeakTimingOffset(offsetPractical, t, mag);

            % Path filters and perfect timing
            pathFilters = getPathFilters(channel);
            offsetPerfect = nrPerfectTimingEstimate(pathGains, pathFilters);

            % Time-domain offset correction
            rxWaveformPractical_csirs = rxWaveform_csirs(1 + offsetPractical:end,:);
            rxWaveformPerfect_csirs = rxWaveform_csirs(1 + offsetPerfect:end,:);

            % OFDM demodulation
            rxGridPractical_csirs = nrOFDMDemodulate(localCarrier, rxWaveformPractical_csirs);
            rxGridPerfect_csirs = nrOFDMDemodulate(localCarrier, rxWaveformPerfect_csirs);

            % Zero-padding for incomplete slots
            symbPerSlot = localCarrier.SymbolsPerSlot;
            K = size(rxGridPractical_csirs, 1);
            LPractical = size(rxGridPractical_csirs, 2);
            LPerfect = size(rxGridPerfect_csirs, 2);

            if LPractical < symbPerSlot
                rxGridPractical_csirs = cat(2, rxGridPractical_csirs, zeros(K, symbPerSlot - LPractical, nRxAnts));
            end
            if LPerfect < symbPerSlot
                rxGridPerfect_csirs = cat(2, rxGridPerfect_csirs, zeros(K, symbPerSlot - LPerfect, nRxAnts));
            end

            rxGridPractical_csirs = rxGridPractical_csirs(:, 1:symbPerSlot, :);
            rxGridPerfect_csirs = rxGridPerfect_csirs(:, 1:symbPerSlot, :);

            % Extract NZP-CSI-RS symbols and indices
            nzpCSIRSSym = csirsSym(csirsSym ~= 0);
            nzpCSIRSInd = csirsInd(csirsSym ~= 0);

            % Practical channel estimate
            [PracticalHest_csirs, nVarPractical_csirs] = nrChannelEstimate(localCarrier, rxGridPractical_csirs, ...
                nzpCSIRSInd, nzpCSIRSSym, 'CDMLengths', cdmLengths, 'AveragingWindow', [0 5]);
            
            % Perfect channel and noise estimate
            PerfectHest = nrPerfectChannelEstimate(localCarrier, pathGains, pathFilters, offsetPerfect, sampleTimes);
            noiseGrid = nrOFDMDemodulate(localCarrier, noise(1 + offsetPerfect:end, :));
            nVarPerfect = var(noiseGrid(:));
            
            % Calculate CQI and PMI values using perfect channel estimate
            [cqiPerfect,pmiPerfect,cqiInfoPerfect,pmiInfoPerfect_csirs] = hCQISelect(localCarrier,csirs, ...
                reportConfig,pdsch.NumLayers,PerfectHest,nVarPerfect);

            [~, pmiPractical, ~, pmiInfoPractical_csirs] = hCQISelect(localCarrier, csirs, ...
                reportConfig, pdsch.NumLayers, PracticalHest_csirs, nVarPractical_csirs);

            SVDPertfChan = getPrecodingMatrix(pdsch.PRBSet, pdsch.NumLayers, PerfectHest);
            SVDNotPerfChan = getPrecodingMatrix(pdsch.PRBSet, pdsch.NumLayers, PracticalHest_csirs);

            % s-PMI: selecting closest PMI matrix
            if perfTx
                comparePMI = pmiInfoPerfect_csirs.W;
            else
                comparePMI = pmiInfoPractical_csirs.W;
            end
            dist = zeros(1, NumAllPMImatricies); % Preallocate distance vector
            %% Compute distances for all PMI candidates
            for ivec = 1:NumAllPMImatricies
                candidateWeights = Array_weight_PMI(:,:,ivec);
                diffMat = comparePMI - candidateWeights; % Element-wise difference
                dist(ivec) = norm(diffMat(:)); % Euclidean distance
            end
            %% Find the closest PMI
            [minDist, bestIndex] = min(dist); % Index of closest PMI
            % TODO: for future work, can save minDist for analysis
            closestPMI = Array_weight_PMI(:,:,bestIndex); % Retrieve corresponding matrix

            precodingWeights = closestPMI.';

            SavePMIperfect{iterIdx, snrIdx} = (pmiInfoPerfect_csirs.W).';
            SavePMIpractical{iterIdx, snrIdx} = (pmiInfoPractical_csirs.W).';
            SaveSVDperfect{iterIdx, snrIdx} = SVDPertfChan;
            SaveSVDpractical{iterIdx, snrIdx} = SVDNotPerfChan;
            Save_sPMI{iterIdx, snrIdx} = closestPMI.';

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

            % PDSCH Precoding
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
            if perfRx
                pathFilters = getPathFilters(channel);
                offset = nrPerfectTimingEstimate(pathGains, pathFilters);
            else
                [t, mag] = nrTimingEstimate(localCarrier, rxWaveform, dmrsIndices, dmrsSymbols);
                offset = hSkipWeakTimingOffset(offset, t, mag);
            end

            rxWaveform = rxWaveform(1 + offset:end, :);

            % OFDM demodulation
            rxGrid = nrOFDMDemodulate(localCarrier,rxWaveform);

            [K, L, R] = size(rxGrid);
            if L < localCarrier.SymbolsPerSlot
                rxGrid = cat(2, rxGrid, zeros(K, localCarrier.SymbolsPerSlot - L, R));
            end

            % Rx Channel estimation
            if perfRx
                estChGridAnts = nrPerfectChannelEstimate(localCarrier, pathGains, pathFilters, offset, sampleTimes);
                noiseGrid = nrOFDMDemodulate(localCarrier, noise(1 + offset:end, :));
                noiseEst = var(noiseGrid(:));
                % newPrecodingWeight = getPrecodingMatrix(pdsch.PRBSet, pdsch.NumLayers, estChGridAnts);
                estChGridLayers = precodeChannelEstimate(estChGridAnts, precodingWeights.');
            else
                %% TODO: need to verify when perfRx = false
                [estChGridLayers, noiseEst] = nrChannelEstimate(localCarrier, rxGrid, dmrsIndices, ...
                    dmrsSymbols, 'CDMLengths', pdsch.DMRS.CDMLengths);
                estChGridAnts = precodeChannelEstimate(estChGridLayers, conj(precodingWeights));
                % newPrecodingWeight = getPrecodingMatrix(pdsch.PRBSet, pdsch.NumLayers, estChGridAnts);
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

            % Calculate BER
            [numBitErrors, ber] = biterr(trBlk, decbits);
            
            ber_snr(snrIdx) = ber;
            bitErrors_snr(snrIdx) = numBitErrors;
            slotError_snr(snrIdx) = double(numBitErrors > 0);
            
            % Update HARQ entity
            updateAndAdvance(harqEntity, blkerr, trBlkSizes, pdschInfo.G);
        end

        inter_snr(iterIdx, :) = ber_snr;
        slot_bit_errors(iterIdx, :) = bitErrors_snr;
        slot_error_flag(iterIdx, :) = slotError_snr;
        
    end
    
    elapsedTime = toc;
    fprintf('\nSimulation completed in %.2f seconds (%.2f minutes) for combination %s\n', elapsedTime, elapsedTime/60, combinationLabels{modIdx});
    fprintf('Average time per iteration: %.4f seconds\n', elapsedTime/numIter);
    
    totalSlotErrors_perSNR = sum(slot_error_flag, 1);
    avgBER_perSNR = mean(inter_snr, 1);
    avgBitErrorsPerSlot_perSNR = mean(slot_bit_errors, 1);
    
    avgBER_all{modIdx} = avgBER_perSNR;
    totalSlotErrors_all{modIdx} = totalSlotErrors_perSNR;
    avgBitErrorsPerSlot_all{modIdx} = avgBitErrorsPerSlot_perSNR;
    
    SavePMIperfect_all{modIdx} = SavePMIperfect;
    SavePMIpractical_all{modIdx} = SavePMIpractical;
    SaveSVDperfect_all{modIdx} = SaveSVDperfect;
    SaveSVDpractical_all{modIdx} = SaveSVDpractical;
    Save_sPMI_all{modIdx} = Save_sPMI;
    
    SaveMetadata_all{modIdx} = struct('ModOrder', ModOrder, 'SNRdB', SNRdB, ...
        'numIter', numIter, 'numSNR', numSNR, 'nLayers', nLayers);
    
    fprintf('\n========================================\n');
    fprintf('Summary Statistics for %s:\n', combinationLabels{modIdx});
    fprintf('========================================\n');
    fprintf('%-10s %-15s %-20s %-20s\n', 'SNR (dB)', 'BER', 'Avg Bit Err/Slot', 'Slot Errors');
    fprintf('%-10s %-15s %-20s %-20s\n', '--------', '---', '----------------', '-----------');
    for idx = 1:numSNR
        fprintf('%-10.1f %-15.4e %-20.2f %-20d\n', ...
            SNRdB(idx), avgBER_perSNR(idx), avgBitErrorsPerSlot_perSNR(idx), totalSlotErrors_perSNR(idx));
    end
end

endTime = datetime('now');
fprintf('\nSimulation ended at %s\n', datestr(endTime,'yyyy-mm-dd HH:MM:SS'));
totalElapsed = endTime - startTime;
fprintf('Total elapsed time: %s\n', char(totalElapsed));

% TODO: need to work on logic to save select variables based on user choice
try
    save(saveFile, 'numIter', 'ModOrderList','pmiPrecoding', ...
        'SNRdB_16QAM','SNRdB_64QAM','SNRdB_256QAM', ...
        'MaximumDopplerShift','DelaySpread', 'perfTx','perfRx', ...
        'nLayers', 'nTxAnts', 'nRxAnts', 'csirsPorts', ...
        'codeRate', 'carrier', 'NHARQProcesses', 'encodeDLSCH_template', 'decodeDLSCH_template', ...
        'csirs','reportConfig','startTime','endTime', ...
        'avgBER_all','totalSlotErrors_all','avgBitErrorsPerSlot_all','SNRdB_all','combinationLabels', ...
        'Save_sPMI_all', 'SaveMetadata_all', ... % 'SavePMIperfect_all','SavePMIpractical_all','SaveSVDperfect_all','SaveSVDpractical_all',
        '-v7.3');
    fprintf('Results saved to: %s\n', saveFile);
catch ME
    fprintf('WARNING: Saving results failed: %s\n', ME.message);
end

% Stop diary logging
try
    diary off;
    fprintf('Diary stopped. Command window output saved to: %s\n', saveFileTxt);
catch ME
    fprintf('WARNING: Could not stop diary: %s\n', ME.message);
end

%% Helper functions

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
