%% ------------------------------------------------------------------------
% Author  : Armed Tusha
% Institution : University of Notre Dame
% Date        : August 1, 2025
% ------------------------------------------------------------------------

%--------------------------------------------------------------------------
% Introduction : 5G-NR, Transmission, Reception, Channel Estimation, PMI
% Precoding (SVD, PMI)
% -------------------------------------------------------------------------

%% IMPORTANT: code might have issues with channel parameters and release of channels

clear all, close all, clc;

%% ------------------------------------------------------------------------
% Simulation Parameters
% -------------------------------------------------------------------------

noSlotsSim                        = 2;         % Number of slots per transmission, min = 1, keep max =< 100.
ModOrder                          = "64QAM";    % Modulation order QPSK, 16QAM, 64QAM, 256QAM
SNRdB                             = [0];  % SNR in dB, you can input a range too, and have the results for all [0:5:20], etc.
pmiPrecoding                      = 1;          % If 1 PMI precoder, else SVD
perfectEstimation                 = false;      % Perfect synchronization and channel estimation
numIter                           = 1e2         % Number of iterations for this link configuration, number of channels is noSlotsSim * numIter

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

codeRate  = 948/1024;                            % This is the code rate, can be changed, 3GPP doc. has more conf.
%codeRate  = 797/1024;
%codeRate  = 711/1024;


% -------------------------------------------------------------------------
% DL-SCH encoder and decoder objects
% -------------------------------------------------------------------------
encodeDLSCH                       = nrDLSCH;
encodeDLSCH.MultipleHARQProcesses = true;
encodeDLSCH.TargetCodeRate        = codeRate;

% Create DLSCH decoder object
decodeDLSCH                       = nrDLSCHDecoder;
decodeDLSCH.MultipleHARQProcesses = true;
decodeDLSCH.TargetCodeRate        = codeRate;
decodeDLSCH.LDPCDecodingAlgorithm = "Normalized min-sum";
decodeDLSCH.MaximumLDPCIterationCount = 6;

harqEntity = HARQEntity(0:NHARQProcesses-1,rvSeq,pdsch.NumCodewords);

% -------------------------------------------------------------------------
% CSI-RS Configuration
% -------------------------------------------------------------------------
% Create a CSI-RS configuration object representing a non-zero-power CSI-RS
% used for PMI estimation (NZP-CSI-RS)

csirs                       = nrCSIRSConfig;
csirs.CSIRSType             = {'nzp','nzp','nzp'};   % Preamble type, chan. est.
csirs.RowNumber             = [4 4 4];
csirs.NumRB                 = 52;
csirs.RBOffset              = 0;
csirs.CSIRSPeriod           = [4 0];
csirs.SymbolLocations       = {0, 0, 0};
csirs.SubcarrierLocations   = {0, 4, 8};
csirs.Density = {'one','one','one'};

% -------------------------------------------------------------------------
% Configure CSI reporting configuration parameters.
% -------------------------------------------------------------------------
reportConfig.NStartBWP      = 0;                      % Configure the size of the bandwidth part (BWP)
reportConfig.NSizeBWP       = 52;                     % start of the BWP relative to common resource block 0 (CRB 0)
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
reportConfig.NumberOfBeams  = 2;                       % Applicable only when CodebookType is 'Type2'
reportConfig.SubbandAmplitude = false;                 % Applicable only when CodebookType is 'Type2'
reportConfig.PhaseAlphabetSize = 4;                    % Applicable only when CodebookType is 'Type2'
reportConfig.ParameterCombination = 2;                 % Applicable only when CodebookType is 'eType2'
reportConfig.NumberOfPMISubbandsPerCQISubband = 2;     % Applicable only when CodebookType is 'eType2'


% -------------------------------------------------------------------------
% Channel Configuration
% -------------------------------------------------------------------------
nTxAnts = csirs.NumCSIRSPorts(1);                      % Number of transmit antennas (physical)
nRxAnts = 1;                                           % Number of receive antennas (physical)

csirsPorts = csirs.NumCSIRSPorts(1);                   % Number of CSI-RS ports, logical antennas

% Get CDM lengths corresponding to configured CSI-RS resources
cdmLengths = getCDMLengths(csirs);

% Initialize the practical timing offset as zero, used for practical synchronization.
offsetPractical = 0;

totSlotsBinaryVec = zeros(1,carrier.NFrame*carrier.SlotsPerFrame);    % It is of length totSlots.

% Set RNG state for repeatability
rng('default');


% -------------------------------------------------------------------------
% Monte Carlo Simulator starts after here.
% -------------------------------------------------------------------------
inter_snr   = [];
for msnr = 1:numIter;
    msnr
    ber_snr = [];

    for isi  = 1:length(SNRdB)
        ber_slot = [];
        for nslot = 0:noSlotsSim-1

            % * Create a channel object.
            channel                     = nrTDLChannel;
            channel.DelayProfile        = "TDL-C";
            channel.NumTransmitAntennas = nTxAnts;
            channel.NumReceiveAntennas  = nRxAnts;
            channel.MaximumDopplerShift = 50;
            channel.DelaySpread         = 300e-9;
            chInfo                      = info(channel);

            channel.DelaySpread         = 0;
            chInfo.MaximumChannelDelay  = 0;
            maxChDelay                  = chInfo.MaximumChannelDelay;
            chInfo.AveragePathGains     = zeros(1,length(chInfo.AveragePathGains));
            chInfo.PathDelays           = zeros(1,length(chInfo.AveragePathGains));


            ofdmInfo           = nrOFDMInfo(carrier);
            channel.SampleRate = ofdmInfo.SampleRate;

            % Initial timing offset
            offset = 0;

            estChannelGrid     = getInitialChannelEstimate(channel,carrier);
            newPrecodingWeight = getPrecodingMatrix(pdsch.PRBSet,pdsch.NumLayers,estChannelGrid);

            % Create carrier resource grid for one slot
            csirsSlotGrid = nrResourceGrid(carrier,csirsPorts);

            % Update slot number in carrier configuration object
            carrier.NSlot = nslot;

            % Generate CSI-RS indices and symbols
            csirsInd = nrCSIRSIndices(carrier,csirs);
            csirsSym = nrCSIRS(carrier,csirs);

            % Map CSI-RS to slot grid
            csirsSlotGrid(csirsInd) = csirsSym;

            % Map CSI-RS ports to transmit antennas
            wtx        = eye(csirsPorts,nTxAnts);
            txGrid     = reshape(reshape(csirsSlotGrid,[],csirsPorts)*wtx,size(csirsSlotGrid,1),size(csirsSlotGrid,2),nTxAnts);

            % Perform OFDM modulation to generate time-domain waveform
            txWaveform = nrOFDMModulate(carrier,txGrid);

            txWaveform = [txWaveform; zeros(maxChDelay,size(txWaveform,2))]; %#ok<AGROW>

            % Transmit waveform through channel
            [rxWaveform,pathGains,sampleTimes] = channel(txWaveform);

            % Generate and add AWGN to received waveform
            SNR        = 10.^(SNRdB(isi)/10);                                             % Linear SNR value
            sigma      = 1/(sqrt(2.0*nRxAnts*double(ofdmInfo.Nfft)*SNR));               % Noise standard deviation
            noise      = sigma*complex(randn(size(rxWaveform)),randn(size(rxWaveform)));
            rxWaveform = rxWaveform + noise;

            [t,mag] = nrTimingEstimate(carrier,rxWaveform,csirsInd,csirsSym);
            offsetPractical = hSkipWeakTimingOffset(offsetPractical,t,mag);

            % Get path filters
            pathFilters = getPathFilters(channel);
            % Perform perfect timing estimation
            offsetPerfect = nrPerfectTimingEstimate(pathGains,pathFilters);

            % Perform time-domain offset correction for practical and
            % perfect timing estimation scenarios
            rxWaveformPractical = rxWaveform(1+offsetPractical:end,:);
            rxWaveformPerfect   = rxWaveform(1+offsetPerfect:end,:);

            % Perform OFDM demodulation on previously synchronized waveforms
            rxGridPractical     = nrOFDMDemodulate(carrier,rxWaveformPractical);
            rxGridPerfect       = nrOFDMDemodulate(carrier,rxWaveformPerfect);

            % Append zeros when the timing synchronization results in an incomplete
            % slot
            symbPerSlot         = carrier.SymbolsPerSlot;
            K                   = size(rxGridPractical,1);
            LPractical = size(rxGridPractical,2);
            LPerfect = size(rxGridPerfect,2);
            if LPractical < symbPerSlot
                rxGridPractical = cat(2,rxGridPractical,zeros(K,symbPerSlot-LPractical,nRxAnts));
            end
            if LPerfect < symbPerSlot
                rxGridPerfect = cat(2,rxGridPerfect,zeros(K,symbPerSlot-LPerfect,nRxAnts));
            end
            rxGridPractical = rxGridPractical(:,1:symbPerSlot,:);
            rxGridPerfect = rxGridPerfect(:,1:symbPerSlot,:);

            % Consider only the NZP-CSI-RS symbols and indices for channel estimation
            nzpCSIRSSym = csirsSym(csirsSym ~= 0);
            nzpCSIRSInd = csirsInd(csirsSym ~= 0);

            % Calculate practical channel estimate. Use a time-averaging window
            % that covers all the transmitted CSI-RS symbols.
            [PracticalHest,nVarPractical] = nrChannelEstimate(carrier,rxGridPractical, ...
                nzpCSIRSInd,nzpCSIRSSym,'CDMLengths',cdmLengths,'AveragingWindow',[0 5]);

            % Perform perfect channel estimation
            PerfectHest = nrPerfectChannelEstimate(carrier,pathGains,pathFilters,offsetPerfect,sampleTimes);

            % Get perfect noise estimate value from noise realization
            noiseGrid = nrOFDMDemodulate(carrier,noise(1+offsetPerfect:end,:));
            nVarPerfect = var(noiseGrid(:));
            if ~isempty(nzpCSIRSInd)
                % Set the totSlotsBinaryVec value corresponding to the slot
                % index where NZP-CSI-RS is present to 1
                totSlotsBinaryVec(nslot+1) = 1;

                % Calculate the RI value using practical channel estimate
                numLayersPractical = hRISelect(carrier,csirs,reportConfig,PracticalHest,nVarPractical,'MaxSE');
                numLayersPractical = 1;

                % Calculate CQI and PMI values using practical channel estimate
                [cqiPractical,pmiPractical,cqiInfoPractical,pmiInfoPractical] = hCQISelect(carrier,csirs, ...
                    reportConfig,numLayersPractical,PracticalHest,nVarPractical);
                numCodeWordsPr = size(cqiPractical,2);
                numSBs = size(cqiPractical,1);

                % Store CQI, PMI, RI, and subband SINR values of each slot for the
                riPracticalPerSlot(1,nslot+1) = numLayersPractical; %#ok<SAGROW>
                cqiPracticalPerSlot(:,:,nslot+1) = [cqiPractical NaN(numSBs,2-numCodeWordsPr)]; %#ok<SAGROW>
                pmiPracticalPerSlot(nslot+1) = pmiPractical;
                subbandCQIPractical(:,:,nslot+1) = [cqiInfoPractical.SubbandCQI NaN(numSBs,2-numCodeWordsPr)]; %#ok<SAGROW>
                SINRPerSubbandPerCWPractical(:,:,nslot+1) = [cqiInfoPractical.SINRPerSubbandPerCW NaN(numSBs,2-numCodeWordsPr)]; %#ok<SAGROW>

                % Calculate the RI value using perfect channel estimate
                numLayersPerfect = hRISelect(carrier,csirs,reportConfig,PerfectHest,nVarPerfect,'MaxSE');

                % Calculate CQI and PMI values using perfect channel estimate
                [cqiPerfect,pmiPerfect,cqiInfoPerfect,pmiInfoPerfect] = hCQISelect(carrier,csirs, ...
                    reportConfig,numLayersPerfect,PerfectHest,nVarPerfect);
                numCodeWordsPe = size(cqiPerfect,2);

                % Store CQI, PMI, RI, and subband SINR values of each slot for the
                riPerfectPerSlot(1,nslot+1) = numLayersPerfect; %#ok<SAGROW>
                cqiPerfectPerSlot(:,:,nslot+1) = [cqiPerfect NaN(numSBs,2-numCodeWordsPe)]; %#ok<SAGROW>
                subbandCQIPerfect(:,:,nslot+1) = [cqiInfoPerfect.SubbandCQI NaN(numSBs,2-numCodeWordsPe)]; %#ok<SAGROW>
                pmiPerfectPerSlot(nslot+1) = pmiPerfect;
                SINRPerSubbandPerCWPerfect(:,:,nslot+1) = [cqiInfoPerfect.SINRPerSubbandPerCW NaN(numSBs,2-numCodeWordsPe)]; %#ok<SAGROW>
            end

            % Generate PDSCH indices info, which is needed to calculate the transport
            [pdschIndices,pdschInfo] = nrPDSCHIndices(carrier,pdsch);

            % Calculate transport block sizes
            Xoh_PDSCH = 0;
            trBlkSizes = nrTBS(pdsch.Modulation,pdsch.NumLayers,numel(pdsch.PRBSet),pdschInfo.NREPerPRB,codeRate,Xoh_PDSCH);
            % HARQ Processing *(Buffer Management)*
            % Get new transport blocks and flush decoder soft buffer, as required
            for cwIdx = 1:pdsch.NumCodewords
                if harqEntity.NewData(cwIdx)
                    % Create and store a new transport block for transmission
                    trBlk = randi([0 1],trBlkSizes(cwIdx),1);
                    setTransportBlock(encodeDLSCH,trBlk,cwIdx-1,harqEntity.HARQProcessID);

                    % If the previous RV sequence ends without successful
                    % decoding, flush the soft buffer
                    if harqEntity.SequenceTimeout(cwIdx)
                        resetSoftBuffer(decodeDLSCH,cwIdx-1,harqEntity.HARQProcessID);
                    end
                end
            end
            % DL-SCH Encoding
            % Encode the transport blocks.

            codedTrBlock = encodeDLSCH(pdsch.Modulation,pdsch.NumLayers,pdschInfo.G,harqEntity.RedundancyVersion,harqEntity.HARQProcessID);
            % PDSCH Modulation and MIMO Precoding
            pdschSymbols = nrPDSCH(carrier,pdsch,codedTrBlock);

            % ---------------------------------------------------------------------
            % Precoding Section
            % ---------------------------------------------------------------------
            if pmiPrecoding == 0
                % SVD precoding
                precodingWeights = newPrecodingWeight;
            else
                % PMI precoding
                precodingWeights = (pmiInfoPractical.W).';
            end
            % ---------------------------------------------------------------------
            pdschSymbolsPrecoded = pdschSymbols*precodingWeights;

            dmrsSymbols = nrPDSCHDMRS(carrier,pdsch);
            dmrsIndices = nrPDSCHDMRSIndices(carrier,pdsch);

            pdschGrid = nrResourceGrid(carrier,nTxAnts);

            [~,pdschAntIndices] = nrExtractResources(pdschIndices,pdschGrid);
            pdschGrid(pdschAntIndices) = pdschSymbolsPrecoded;

            % PDSCH DM-RS precoding and mapping
            for p = 1:size(dmrsSymbols,2)
                [~,dmrsAntIndices] = nrExtractResources(dmrsIndices(:,p),pdschGrid);
                pdschGrid(dmrsAntIndices) = pdschGrid(dmrsAntIndices) + dmrsSymbols(:,p)*precodingWeights(p,:);
            end

            [txWaveform,ofdmInfo] = nrOFDMModulate(carrier,pdschGrid);

            txWaveform = [txWaveform; zeros(maxChDelay,size(txWaveform,2))];


            [rxWaveform,pathGains,sampleTimes] = channel(txWaveform);

            noise = generateAWGN(SNRdB(isi),nRxAnts,ofdmInfo.Nfft,size(rxWaveform));
            rxWaveform = rxWaveform + noise;
            if perfectEstimation
                % Get path filters for perfect timing estimation
                pathFilters = getPathFilters(channel);
                [offset,mag] = nrPerfectTimingEstimate(pathGains,pathFilters);
            else
                [t,mag] = nrTimingEstimate(carrier,rxWaveform,dmrsIndices,dmrsSymbols);
                offset = hSkipWeakTimingOffset(offset,t,mag);
                % Display a warning if the estimated timing offset exceeds the
                % maximum channel delay
                if offset > maxChDelay
                    warning(['Estimated timing offset (%d) is greater than the maximum channel delay (%d).' ...
                        ' This will result in a decoding failure. This may be caused by low SNR,' ...
                        ' or not enough DM-RS symbols to synchronize successfully.'],offset,maxChDelay);
                end
            end
            rxWaveform = rxWaveform(1+offset:end,:);
            % OFDM-demodulate the synchronized signal.

            % Perform OFDM demodulation on the received data t
            rxGrid = nrOFDMDemodulate(carrier,rxWaveform);

            [K,L,R] = size(rxGrid);
            if (L < carrier.SymbolsPerSlot)
                rxGrid = cat(2,rxGrid,zeros(K,carrier.SymbolsPerSlot-L,R));
            end

            % Perform perfect or practical channel estimation.
            if perfectEstimation
                % Perform perfect channel estimation between transmit and receive
                % antennas.
                estChGridAnts = nrPerfectChannelEstimate(carrier,pathGains,pathFilters,offset,sampleTimes);

                % Get perfect noise estimate (from noise realization)
                noiseGrid = nrOFDMDemodulate(carrier,noise(1+offset:end ,:));
                noiseEst = var(noiseGrid(:));

                % Get precoding matrix for next slot
                newPrecodingWeight = getPrecodingMatrix(pdsch.PRBSet,pdsch.NumLayers,estChGridAnts);

                % Apply precoding to estChGridAnts. The resulting estimate is for
                % the channel estimate between layers and receive antennas.
                estChGridLayers = precodeChannelEstimate(estChGridAnts,precodingWeights.');
            else
                % Perform practical channel estimation between layers and receive
                % antennas.
                [estChGridLayers,noiseEst] = nrChannelEstimate(carrier,rxGrid,dmrsIndices,dmrsSymbols,'CDMLengths',pdsch.DMRS.CDMLengths);

                % Remove precoding from estChannelGrid before precoding
                % matrix calculation
                estChGridAnts = precodeChannelEstimate(estChGridLayers,conj(precodingWeights));

                % Get precoding matrix for next slot
                newPrecodingWeight = getPrecodingMatrix(pdsch.PRBSet,pdsch.NumLayers,estChGridAnts);
            end

            [pdschRx,pdschHest] = nrExtractResources(pdschIndices,rxGrid,estChGridLayers);
            [pdschEq,csi]       = nrEqualizeMMSE(pdschRx,pdschHest,noiseEst);
            [dlschLLRs,rxSymbols] = nrPDSCHDecode(carrier,pdsch,pdschEq,noiseEst);

            % Scale the soft bits or log-likelihood ratios (LLRs) by the CSI. This scaling
            % applies a larger weight to the symbols in the REs with better channel conditions.

            % Scale LLRs by CSI
            csi = nrLayerDemap(csi);                                    % CSI layer demapping
            for cwIdx = 1:pdsch.NumCodewords
                Qm = length(dlschLLRs{cwIdx})/length(rxSymbols{cwIdx}); % Bits per symbol
                csi{cwIdx} = repmat(csi{cwIdx}.',Qm,1);                 % Expand by each bit per symbol
                dlschLLRs{cwIdx} = dlschLLRs{cwIdx} .* csi{cwIdx}(:);   % Scale
            end

            % DL-SCH Decoding
            decodeDLSCH.TransportBlockLength = trBlkSizes;
            [decbits,blkerr] = decodeDLSCH(dlschLLRs,pdsch.Modulation,pdsch.NumLayers, ...
                harqEntity.RedundancyVersion,harqEntity.HARQProcessID);

            [numErr, ber] = biterr(trBlk, decbits);

            ber_slot      = [ber_slot ber];
            statusReport = updateAndAdvance(harqEntity,blkerr,trBlkSizes,pdschInfo.G);

        end
        ber_snr = [ber_snr mean(ber_slot)];
    end
    inter_snr  = [inter_snr ; ber_snr];
end

%% ------------------------------------------------------------------------
% Simulation Results
% -------------------------------------------------------------------------
figure
semilogy(SNRdB, mean(inter_snr), '-o', 'LineWidth', 2);
xlabel('SNR (dB)'); 
ylabel('BER'); 
grid on;
title(sprintf('BER vs SNR (%d iterations, %d slots)', numIter, noSlotsSim));
legend('Optimized Simulation');

%% *References*
% [1] 3GPP TS 38.214. "NR; Physical layer procedures for data." _3rd Generation
% Partnership Project; Technical Specification Group Radio Access Network_.

%% *Local Functions*
% This example uses these local functions to validate the CSI-RS configuration
% object and to plot the computed CQI, PMI, and RI values.

function validateCSIRSConfig(carrier,csirs,nTxAnts)
%   Validates the CSI-RS configuration, given the carrier specific
%   configuration object, CSI-RS configuration object, and the number of
%   transmit antennas.

% Validate the number of CSI-RS ports
if ~isscalar(unique(csirs.NumCSIRSPorts))
    error('nr5g:InvalidCSIRSPorts', ...
        'All the CSI-RS resources must be configured to have the same number of CSI-RS ports.');
end

% Validate the CDM lengths
if ~iscell(csirs.CDMType)
    cdmType = {csirs.CDMType};
else
    cdmType = csirs.CDMType;
end
if (~all(strcmpi(cdmType,cdmType{1})))
    error('nr5g:InvalidCSIRSCDMTypes', ...
        'All the CSI-RS resources must be configured to have the same CDM lengths.');
end
if nTxAnts ~= csirs.NumCSIRSPorts(1)
    error('nr5g:InvalidNumTxAnts',['Number of transmit antennas (' num2str(nTxAnts) ...
        ') must be equal to the number of CSI-RS ports (' num2str(csirs.NumCSIRSPorts(1)) ').']);
end

% Check for the overlap between the CSI-RS indices
csirsInd = nrCSIRSIndices(carrier,csirs,"OutputResourceFormat",'cell');
numRes = numel(csirsInd);
csirsIndAll = cell(1,numRes);
ratioVal = csirs.NumCSIRSPorts(1)/prod(getCDMLengths(csirs));
for resIdx = 1:numRes
    if ~isempty(csirsInd{resIdx})
        grid = nrResourceGrid(carrier,csirs.NumCSIRSPorts(1));
        [~,tempInd] = nrExtractResources(csirsInd{resIdx},grid);
        if numel(tempInd)/numel(csirsInd{resIdx}) ~= ratioVal
            error('nr5g:OverlappedCSIRSREsSingleResource',['CSI-RS indices of resource ' ...
                num2str(resIdx) ' must be unique. Try changing the symbol or subcarrier locations.']);
        end
        csirsIndAll{resIdx} = tempInd(:);
        for idx = 1:resIdx-1
            overlappedInd = ismember(csirsIndAll{idx},csirsIndAll{resIdx});
            if any(overlappedInd)
                error('nr5g:OverlappedCSIRSREsMultipleResources',['The resource elements of the ' ...
                    'configured CSI-RS resources must not overlap. Try changing the symbol or ' ...
                    'subcarrier locations of CSI-RS resource ' num2str(idx) ' and resource ' num2str(resIdx) '.']);
            end
        end
    end
end
end

function cdmLengths = getCDMLengths(csirs)
%   Returns the CDM lengths, given the CSI-RS configuration object.

CDMType = csirs.CDMType;
if ~iscell(csirs.CDMType)
    CDMType = {csirs.CDMType};
end
CDMTypeOpts = {'noCDM','fd-CDM2','CDM4','CDM8'};
CDMLengthOpts = {[1 1],[2 1],[2 2],[2 4]};
cdmLengths = CDMLengthOpts{strcmpi(CDMTypeOpts,CDMType{1})};
end

function [cqiPracticalPerSlot,subbandCQIPractical,pmiPracticalPerSlot,SINRPerSubbandPerCWPractical,cqiPerfectPerSlot, ...
    subbandCQIPerfect,pmiPerfectPerSlot,SINRPerSubbandPerCWPerfect,riPracticalPerSlot,riPerfectPerSlot] = fillInactiveSlots(cqiPracticalPerSlot, ...
    subbandCQIPractical,pmiPracticalPerSlot,SINRPerSubbandPerCWPractical,cqiPerfectPerSlot,subbandCQIPerfect,pmiPerfectPerSlot, ...
    SINRPerSubbandPerCWPerfect,riPracticalPerSlot,riPerfectPerSlot,reportConfig,totSlotsBinaryVec,activeSlots)
%   Returns the CQI, PMI, and RI related variables filled with NaNs in the
%   slots where NZP-CSI-RS is not present according to the codebook type from
%   the report configuration structure. Note that the CQI, PMI, and RI
%   variables are returned as empty if there are no NZP-CSI-RS resources,
%   that is, no active slots in the entire simulation duration.

% Compute the indices of the slots and the number of slots in which
% NZP-CSI-RS is not present
inactiveSlotIdx = ~totSlotsBinaryVec;
numInactiveSlots = nnz(inactiveSlotIdx);

if ~isempty(activeSlots)
    numCQISBs = size(cqiPracticalPerSlot,1);

    % Get the codebook type
    codebookType = 'Type1SinglePanel';
    if isfield(reportConfig,'CodebookType')
        codebookType = validatestring(reportConfig.CodebookType,{'Type1SinglePanel','Type1MultiPanel','Type2','eType2'},'fillInactiveSlots','CodebookType field');
    end

    % Fill the CQI, PMI, and RI variables with NaNs in the slots where NZP-CSI-RS is
    % not present
    cqiPracticalPerSlot(:,:,inactiveSlotIdx) = NaN(numCQISBs,2,numInactiveSlots);
    subbandCQIPractical(:,:,inactiveSlotIdx) = NaN(numCQISBs,2,numInactiveSlots);
    SINRPerSubbandPerCWPractical(:,:,inactiveSlotIdx) = NaN(numCQISBs,2,numInactiveSlots);
    cqiPerfectPerSlot(:,:,inactiveSlotIdx) = NaN(numCQISBs,2,numInactiveSlots);
    subbandCQIPerfect(:,:,inactiveSlotIdx) = NaN(numCQISBs,2,numInactiveSlots);
    SINRPerSubbandPerCWPerfect(:,:,inactiveSlotIdx) = NaN(numCQISBs,2,numInactiveSlots);
    riPracticalPerSlot(inactiveSlotIdx) = NaN;
    riPerfectPerSlot(inactiveSlotIdx) = NaN;

    numi1Indices = 3;
    numi2Indices = 1;
    if strcmpi(codebookType,'Type1MultiPanel')
        numi1Indices = 6;
        numi2Indices = 3;
    end
    numPMISBs = size(pmiPerfectPerSlot(activeSlots(1)).i2,2);
    [pmiPerfectPerSlot(inactiveSlotIdx),pmiPracticalPerSlot(inactiveSlotIdx)] = deal(struct('i1',NaN(1,numi1Indices),'i2',NaN(numi2Indices,numPMISBs)));
end
end

function plotWidebandCQIAndSINR(cqiPracticalPerSlot,cqiPerfectPerSlot,SINRPerSubbandPerCWPractical,SINRPerSubbandPerCWPerfect,activeSlotNum)
%   Plots the wideband SINR and wideband CQI values for each codeword
%   across all specified active slots (1-based) (in which the CQI is
%   reported as other than NaN) for practical and perfect channel
%   estimation cases.

% Check if there are no slots in which NZP-CSI-RS is present
if isempty(activeSlotNum)
    disp('No CQI data to plot, because there are no slots in which NZP-CSI-RS is present.');
    return;
end
cqiPracticalPerCW = permute(cqiPracticalPerSlot(1,:,:),[1 3 2]);
cqiPerfectPerCW = permute(cqiPerfectPerSlot(1,:,:),[1 3 2]);
SINRPerCWPractical = permute(SINRPerSubbandPerCWPractical(1,:,:),[1 3 2]);
SINRPerCWPerfect = permute(SINRPerSubbandPerCWPerfect(1,:,:),[1 3 2]);

% Extract wideband CQI indices for slots where NZP-CSI-RS is present
cqiPracticalPerCWActiveSlots = cqiPracticalPerCW(1,activeSlotNum,:);
cqiPerfectPerCWActiveSlots = cqiPerfectPerCW(1,activeSlotNum,:);
widebandSINRPractical = 10*log10(SINRPerCWPractical(1,activeSlotNum,:));
widebandSINRPerfect = 10*log10(SINRPerCWPerfect(1,activeSlotNum,:));

if isempty(reshape(cqiPracticalPerCWActiveSlots(:,:,1),1,[]))
    disp('No CQI data to plot, because all CQI values are NaNs.');
    return;
end

figure();
plotWBCQISINR(widebandSINRPerfect,widebandSINRPractical,211,activeSlotNum,'SINR');
plotWBCQISINR(cqiPerfectPerCWActiveSlots,cqiPracticalPerCWActiveSlots,212,activeSlotNum,'CQI');
end

function plotWBCQISINR(perfectVals,practicalVals,subplotIdx,activeSlotNum,inpText)
%   Plots the wideband SINR and wideband CQI values for each codeword
%   across all specified active slots (1-based) (in which the CQI is
%   reported as other than NaN) for practical and perfect channel
%   estimation cases.

subplot(subplotIdx)
plot(perfectVals(:,:,1),'r-o');
hold on;
plot(practicalVals(:,:,1),'b-*');
if ~all(isnan(perfectVals(:,:,2))) % Two codewords
    hold on;
    plot(perfectVals(:,:,2),'r:s');
    hold on;
    plot(practicalVals(:,:,2),'b:d');
    title(['Wideband ' inpText ' Values for Codeword 1&2']);
    legend({'Codeword 1:Perfect channel est.','Codeword 1:Practical channel est.','Codeword 2:Perfect channel est.','Codeword 2:Practical channel est.'});
else
    title(['Wideband ' inpText ' Values for Codeword 1']);
    legend({'Codeword 1:Perfect channel est.','Codeword 1:Practical channel est.'});
end
xlabel('Slots');
if strcmpi(inpText,'SINR')
    units = ' in dB';
else
    units = '';
end
ylabel(['Wideband ' inpText ' Values' units]);
xticks(1:size(perfectVals,2));
xTickLables = num2cell(activeSlotNum(:)-1);
xticklabels(xTickLables);
[lowerBound,upperBound] = bounds([practicalVals(:);perfectVals(:)]);
ylim([lowerBound-1 upperBound+3.5]);
end

function plotSubbandCQIAndSINR(subbandCQIPractical,subbandCQIPerfect,SINRPerCWPractical,SINRPerCWPerfect,activeSlotNum,nslot)
%   Plots the SINR and CQI values for each codeword across all the subbands
%   for practical and perfect channel estimation cases for the given slot
%   number (0-based) among all specified active slots (1-based). The
%   function does not plot the values if CQIMode is 'Wideband' or if the
%   CQI and SINR values are all NaNs in the given slot.

% Check if there are no slots in which NZP-CSI-RS is present
if isempty(activeSlotNum)
    disp('No CQI data to plot, because there are no slots in which NZP-CSI-RS is present.');
    return;
end
numSubbands = size(subbandCQIPractical,1);
if numSubbands > 1 && ~any(nslot+1 == activeSlotNum) % Check if the CQI values are reported in the specified slot
    disp(['For the specified slot (' num2str(nslot) '), CQI values are not reported. Please choose another slot number.']);
    return;
end

% Plot subband CQI values
if numSubbands > 1 % Subband mode
    subbandCQIPerCWPractical = subbandCQIPractical(2:end,:,nslot+1);
    subbandCQIPerCWPerfect = subbandCQIPerfect(2:end,:,nslot+1);
    subbandSINRPerCWPractical = 10*log10(SINRPerCWPractical(2:end,:,nslot+1));
    subbandSINRPerCWPerfect = 10*log10(SINRPerCWPerfect(2:end,:,nslot+1));
    figure();
    plotSBCQISINR(subbandSINRPerCWPerfect,subbandSINRPerCWPractical,numSubbands,211,nslot,'SINR')
    plotSBCQISINR(subbandCQIPerCWPerfect,subbandCQIPerCWPractical,numSubbands,212,nslot,'CQI');
end
end

function plotSBCQISINR(perfectVals,practicalVals,numSubbands,subplotIdx,nslot,inpText)
%   Plots the SINR and CQI values for each codeword across all the subbands
%   for practical and perfect channel estimation cases for the given slot
%   number (0-based). The function does not plot the values if CQIMode is
%   'Wideband' or if the CQI and SINR values are all NaNs in the given
%   slot.

subplot(subplotIdx)
plot(perfectVals(:,1),'ro-');
hold on;
plot(practicalVals(:,1),'b*-');
if ~all(isnan(perfectVals(:,2))) % Two codewords
    hold on;
    plot(perfectVals(:,2),'rs:');
    hold on;
    plot(practicalVals(:,2),'bd:');
    legend({'Codeword 1:Perfect channel est.','Codeword 1:Practical channel est.','Codeword 2:Perfect channel est.','Codeword 2:Practical channel est.'});
    title(['Estimated Subband ' inpText ' Values for Codeword 1&2 in Slot ' num2str(nslot)]);
else % Single codeword
    legend({'Codeword 1:Perfect channel est.','Codeword 1:Practical channel est.'});
    title(['Estimated Subband ' inpText ' Values for Codeword 1 in Slot ' num2str(nslot)]);
end

if strcmpi(inpText,'SINR')
    units = ' in dB';
else
    units = '';
end
xlabel('Subbands');
ylabel(['Subband ' inpText ' Values' units]);
xticks(1:numSubbands);
xTickLables = num2cell(1:numSubbands);
xticklabels(xTickLables);
xlim([0 numSubbands+1]);
[lowerBound,upperBound] = bounds([perfectVals(:);practicalVals(:)]);
ylim([lowerBound-1 upperBound+3.5]);
end

function plotType1PMIAndRI(pmiPracticalPerSlot,pmiPerfectPerSlot,riPracticalPerSlot,riPerfectPerSlot,activeSlotNum,nslot)
%   Plots the RI and PMI i1 indices across all specified active slots
%   (1-based), for practical and perfect channel estimation scenarios. The
%   function also plots the i2 indices of practical and perfect channel
%   estimation scenarios across all specified active slots when the PMI
%   mode is 'Wideband' or plots i2 indices across all the subbands for the
%   specified slot number (0-based) when the PMI mode is 'Subband'.

% Check if there are no slots in which NZP-CSI-RS is present
if isempty(activeSlotNum)
    disp('No PMI and RI data to plot, because there are no slots in which NZP-CSI-RS is present.');
    return;
end

numi1Indices = numel(pmiPracticalPerSlot(activeSlotNum(1)).i1);
if numi1Indices == 6
    codebookType = 'Type1MultiPanel';
else
    codebookType = 'Type1SinglePanel';
end

% Extract wideband PMI indices (i1 values) for slots where NZP-CSI-RS
% is present
i1PerfectValsActiveSlots = reshape([pmiPerfectPerSlot(activeSlotNum).i1],numi1Indices,[])';
i1PracticalValsActiveSlots = reshape([pmiPracticalPerSlot(activeSlotNum).i1],numi1Indices,[])';

if isempty(i1PerfectValsActiveSlots)
    disp('No PMI and RI data to plot, because all PMI and RI values are NaNs.');
    return;
end

figure;
% Plot RI
plotRI(riPracticalPerSlot,riPerfectPerSlot,activeSlotNum,411);

% Extract and plot i11 indices
i11PerfectVals = i1PerfectValsActiveSlots(:,1);
i11PracticalVals = i1PracticalValsActiveSlots(:,1);
plotIxxIndices(i11PerfectVals,i11PracticalVals,activeSlotNum,412,'i11');

% Extract and plot i12 indices
i12PerfectVals = i1PerfectValsActiveSlots(:,2);
i12PracticalVals = i1PracticalValsActiveSlots(:,2);
plotIxxIndices(i12PerfectVals,i12PracticalVals,activeSlotNum,413,'i12');

% Extract and plot i13 indices
i13PerfectVals = i1PerfectValsActiveSlots(:,3);
i13PracticalVals = i1PracticalValsActiveSlots(:,3);
plotIxxIndices(i13PerfectVals,i13PracticalVals,activeSlotNum,414,'i13');

% Plot the i141, i142 and i143 indices in type I multi-panel case
if strcmpi(codebookType,'Type1MultiPanel')
    figure()
    % Extract and plot i141 indices
    i141PerfectVals = i1PerfectValsActiveSlots(:,4);
    i141PracticalVals = i1PracticalValsActiveSlots(:,4);
    plotIxxIndices(i141PerfectVals,i141PracticalVals,activeSlotNum,311,'i141');

    % Extract and plot i142 indices
    i142PerfectVals = i1PerfectValsActiveSlots(:,5);
    i142PracticalVals = i1PracticalValsActiveSlots(:,5);
    plotIxxIndices(i142PerfectVals,i142PracticalVals,activeSlotNum,312,'i142');

    % Extract and plot i143 indices
    i143PerfectVals = i1PerfectValsActiveSlots(:,6);
    i143PracticalVals = i1PracticalValsActiveSlots(:,6);
    plotIxxIndices(i143PerfectVals,i143PracticalVals,activeSlotNum,313,'i143');
end

% Get the number of subbands
numSubbands = size(pmiPracticalPerSlot(activeSlotNum(1)).i2,2);
% Get the number of i2 indices according to codebook type
numi2Indices = 1;
if strcmpi(codebookType,'Type1MultiPanel')
    numi2Indices = 3;
end

% Get number of active slots
numActiveSlots = numel(activeSlotNum);
% Extract i2 values
i2PerfectVals = reshape([pmiPerfectPerSlot(activeSlotNum).i2],[numSubbands,numi2Indices,numActiveSlots]);     % Of size numActiveSlots-by-numi2Indices-numSubbands
i2PracticalVals = reshape([pmiPracticalPerSlot(activeSlotNum).i2],[numSubbands,numi2Indices,numActiveSlots]); % Of size numActiveSlots-by-numi2Indices-numSubbands

% Plot i2 values
if numSubbands == 1 % Wideband mode
    figure;

    % In type I single-panel case, there is only one i2 index. The
    % first column of i2PerfectVals and i2PracticalVals corresponds to
    % i2 index. In type I multi-panel case, the i2 values are a set of
    % three indices i20, i21, and i22. Each column of i2PerfectVals and
    % i2PracticalVals correspond to i20, i21, and i22 indices. Extract
    % and plot the respective index values
    if strcmpi(codebookType,'Type1SinglePanel')
        % Extract and plot i2 values in each slot
        i2PerfectVals = reshape(i2PerfectVals(:,1,:),[],numActiveSlots).';
        i2PracticalVals = reshape(i2PracticalVals(:,1,:),[],numActiveSlots).';
        plotIxxIndices(i2PerfectVals,i2PracticalVals,activeSlotNum,111,'i2');
    else
        % Extract and plot i20 values in each slot
        i20PerfectVals = reshape(i2PerfectVals(:,1,:),[],numActiveSlots).';
        i20PracticalVals = reshape(i2PracticalVals(:,1,:),[],numActiveSlots).';
        plotIxxIndices(i20PerfectVals,i20PracticalVals,activeSlotNum,311,'i20');

        % Extract and plot i21 values in each slot
        i21PerfectVals = reshape(i2PerfectVals(:,2,:),[],numActiveSlots).';
        i21PracticalVals = reshape(i2PracticalVals(:,2,:),[],numActiveSlots).';
        plotIxxIndices(i21PerfectVals,i21PracticalVals,activeSlotNum,312,'i21');

        % Extract and plot i22 values in each slot
        i22PerfectVals = reshape(i2PerfectVals(:,3,:),[],numActiveSlots).';
        i22PracticalVals = reshape(i2PracticalVals(:,3,:),[],numActiveSlots).';
        plotIxxIndices(i22PerfectVals,i22PracticalVals,activeSlotNum,313,'i22');
    end
else % Subband mode
    if any(nslot+1 == activeSlotNum)

        % In subband mode, plot the PMI i2 indices corresponding to the
        % specified slot number
        figure;

        if strcmpi(codebookType,'Type1SinglePanel')
            % Extract and plot i2 values
            pmiSBi2Perfect = pmiPerfectPerSlot(nslot+1).i2(1,:);
            pmiSBi2Practical = pmiPracticalPerSlot(nslot+1).i2(1,:);
            plotI2xIndices_SB(pmiSBi2Perfect,pmiSBi2Practical,numSubbands,nslot,111,'i2');
        else
            % Extract and plot i20 values
            pmiSBi20Perfect = pmiPerfectPerSlot(nslot+1).i2(1,:);
            pmiSBi20Practical = pmiPracticalPerSlot(nslot+1).i2(1,:);
            plotI2xIndices_SB(pmiSBi20Perfect,pmiSBi20Practical,numSubbands,nslot,311,'i20');

            % Extract and plot i21 values
            pmiSBi21Perfect = pmiPerfectPerSlot(nslot+1).i2(2,:);
            pmiSBi21Practical = pmiPracticalPerSlot(nslot+1).i2(2,:);
            plotI2xIndices_SB(pmiSBi21Perfect,pmiSBi21Practical,numSubbands,nslot,312,'i21');

            % Extract and plot i22 values
            pmiSBi22Perfect = pmiPerfectPerSlot(nslot+1).i2(3,:);
            pmiSBi22Practical = pmiPracticalPerSlot(nslot+1).i2(3,:);
            plotI2xIndices_SB(pmiSBi22Perfect,pmiSBi22Practical,numSubbands,nslot,313,'i22');
        end
    else
        disp(['For the specified slot (' num2str(nslot) '), PMI i2 indices are not reported. Please choose another slot number.'])
    end
end
end

function plotType2PMIAndRI(pmiPracticalPerSlot,pmiPerfectPerSlot,riPracticalPerSlot,riPerfectPerSlot,panelDims,numBeams,activeSlotNum,nslot)
%   Plots the grid of beams by highlighting the beams that are used for the
%   precoding matrix generation for the specified slot number (0-based),
%   for practical and perfect channel estimation scenarios.

% Check if there are no slots in which NZP-CSI-RS is present
if isempty(activeSlotNum)
    disp('No PMI and RI data to plot, because there are no slots in which NZP-CSI-RS is present.');
    return;
end
plotRI(riPracticalPerSlot,riPerfectPerSlot,activeSlotNum,111);
if ~any(nslot+1 == activeSlotNum)
    disp(['For the specified slot (' num2str(nslot) '), PMI values are not reported. Please choose another slot number.']);
else
    pmiPractical = pmiPracticalPerSlot(nslot+1);
    pmiPerfect = pmiPerfectPerSlot(nslot+1);
    figure();
    plotType2GridOfBeams(pmiPractical,panelDims,numBeams,'Practical Channel Estimation Scenario',1);
    hold on;
    plotType2GridOfBeams(pmiPerfect,panelDims,numBeams,'Perfect Channel Estimation Scenario',2);
end
end

function plotRI(riPracticalPerSlot,riPerfectPerSlot,activeSlotNum,subplotIndex)
%   Plots the RI values across all specified active slots (1-based), for
%   practical and perfect channel estimation scenarios.

% Get number of active slots
numActiveSlots = numel(activeSlotNum);

% Extract RI values for slots where NZP-CSI-RS is present
RIPerfectValsActiveSlots = riPerfectPerSlot(activeSlotNum)';
RIPracticalValsActiveSlots = riPracticalPerSlot(activeSlotNum)';

if isempty(RIPerfectValsActiveSlots)
    disp('No RI data to plot, because all RI values are NaNs.');
    return;
end

figure;
subplot(subplotIndex);
plot(RIPerfectValsActiveSlots,'r-o');
hold on;
plot(RIPracticalValsActiveSlots,'b-*');
xlabel('Slots')
ylabel('RI Values');
xticks(1:numActiveSlots);
xTickLables = num2cell(activeSlotNum(:)-1);
xticklabels(xTickLables);
[~,upperBound] = bounds([RIPerfectValsActiveSlots; RIPracticalValsActiveSlots]);
xlim([0 numActiveSlots+8]);
ylim([0 upperBound+1]);
yticks(0:upperBound+1);
title('RI Values')
legend({'Perfect channel est.','Practical channel est.'});
end

function plotType2GridOfBeams(PMISet,panelDims,numBeams,chEstType,subplotNum)
%   Plots the grid of beams by highlighting the beams that are used for the
%   type II codebook based precoding matrix generation.

N1 = panelDims(1);
N2 = panelDims(2);
% Get the oversampling factors
O1 = 4;
O2 = 1 + 3*(N2 ~= 1);

% Extract q1, q2 values
qSet = PMISet.i1(1:2);
q1 = qSet(1)-1;
q2 = qSet(2)-1;

% Extract i12 value
i12 = PMISet.i1(3);
s = 0;
% Find the n1, n2 values for all the beams, as defined in TS 38.214
% Section 5.2.2.2.3
n1_i12 = zeros(1,numBeams);
n2_i12 = zeros(1,numBeams);
for beamIdxI = 0:numBeams-1
    i12minussVal = i12 - s;
    xValues = numBeams-1-beamIdxI:N1*N2-1-beamIdxI;
    CValues = zeros(numel(xValues),1);
    for xIdx = 1:numel(xValues)
        if xValues(xIdx) >= numBeams-beamIdxI
            CValues(xIdx) = nchoosek(xValues(xIdx),numBeams-beamIdxI);
        end
    end
    indices = i12minussVal >= CValues;
    maxIdx = find(indices,1,'last');
    xValue = xValues(maxIdx);
    ei = CValues(maxIdx);
    s = s+ei;
    ni = N1*N2 - 1 - xValue;
    n1_i12(beamIdxI+1) = mod(ni,N1);
    n2_i12(beamIdxI+1) = (ni-n1_i12(beamIdxI+1))/N1;
end
m1 = O1*(0:N1-1) + q1;
m2 = O2*(0:N2-1) + q2;

% Calculate the indices of orthogonal basis set which corresponds to
% the reported i12 value
m1_LBeams = O1*(n1_i12) + q1;
m2_LBeams = O2*(n2_i12) + q2;
OrthogonalBeams = [repmat(m1,1,length(m2));reshape(repmat(m2,length(m1),1),1,[])]';

% Plot the grid of beams
numCirlcesInRow = N1*O1;
numCirlcesInCol = N2*O2;
subplot(2,1,subplotNum);
circleRadius = 1;
for colIdx = 0:numCirlcesInCol-1
    for rowIdx = 0:numCirlcesInRow-1
        p = nsidedpoly(1000, 'Center', [2*rowIdx 2*colIdx], 'Radius', circleRadius);
        if any(prod(OrthogonalBeams == [rowIdx colIdx],2))
            h2 = plot(p, 'FaceColor', 'w','EdgeColor','r','LineWidth',2.5);
            hold on;
            if any(prod([m1_LBeams' m2_LBeams'] == [rowIdx colIdx],2))
                h3 = plot(p, 'FaceColor', 'g','LineStyle','-.');
            end
        else
            h1 = plot(p, 'FaceColor', 'w');
        end
        hold on;
    end
end
rowLength = 2*circleRadius*O1;
colLength = 2*circleRadius*O2;
for n2 = 0:N2-1
    for n1 = 0:N1-1
        x1 = -1*circleRadius + rowLength*n1;
        x2 = x1 + rowLength;
        y1 = -1*circleRadius + colLength*n2;
        y2 = y1 + colLength;
        x = [x1, x2, x2, x1, x1];
        y = [y1, y1, y2, y2, y1];
        plot(x, y, 'b-', 'LineWidth', 2);
        hold on;
    end
end

xlabel('N1O1 beams');
ylabel('N2O2 beams');
axis equal;
set(gca,'xtick',[],'ytick',[]);
legend([h1 h2 h3],{'Oversampled DFT beams',['Orthogonal basis set with [q1 q2] = [' num2str(q1) ' ' num2str(q2) ']'],'Selected beam group'},'Location','northeast');
title(['Grid of Beams or DFT Vectors for ' chEstType]);
end

function plotIxxIndices(ixxPerfectVals,ixxPracticalVals,activeSlotNum,subplotInp,pmiIdxType)
%   Plots i11, i12, i13 indices in case of type I single-panel codebooks
%   and plots i141, i142, and i143 in case of type I multi-panel codebooks.

% Plot ixx values
subplot(subplotInp)
plot(ixxPerfectVals,'r-o');
hold on;
plot(ixxPracticalVals,'b-*');
xlabel('Slots')
ylabel([pmiIdxType ' Indices']);
% Get number of active slots
numActiveSlots = numel(activeSlotNum);
xticks(1:numActiveSlots);
xTickLables = num2cell(activeSlotNum(:)-1);
xticklabels(xTickLables);
[lowerBound,upperBound] = bounds([ixxPerfectVals; ixxPracticalVals]);
xlim([0 numActiveSlots+8]);
ylim([lowerBound-2 upperBound+2]);
title(['PMI: ' pmiIdxType ' Indices']);
legend({'Perfect channel est.','Practical channel est.'});
end

function plotI2xIndices_SB(pmiSBi2Perfect,pmiSBi2Practical,numSubbands,nslot,subplotInp,pmiIdxType)
%   Plots i2 indices in case of type I single-panel codebooks and plots
%   i20, i21, and i22 in case of type I multi-panel codebooks.

subplot(subplotInp)
plot(pmiSBi2Perfect,'r-o');
hold on;
plot(pmiSBi2Practical,'b-*');
title(['PMI: ' pmiIdxType ' Indices for All Subbands in Slot ' num2str(nslot)]);
xlabel('Subbands')
ylabel([pmiIdxType ' Indices']);
xticks(1:numSubbands);
xticklabels(num2cell(1:numSubbands));
[lowerBound,upperBound] = bounds([pmiSBi2Perfect pmiSBi2Practical]);
yticks(lowerBound:upperBound);
yticklabels(num2cell(lowerBound:upperBound));
xlim([0 numSubbands+1])
ylim([lowerBound-1 upperBound+1]);
legend({'Perfect channel est.','Practical channel est.'});
end

function noise = generateAWGN(SNRdB,nRxAnts,Nfft,sizeRxWaveform)
% Generate AWGN for a given value of SNR in dB (SNRDB), which is the
% receiver SNR per RE and antenna, assuming the channel does
% not affect the power of the signal. NRXANTS is the number of receive
% antennas. NFFT is the FFT size used in OFDM demodulation. SIZERXWAVEFORM
% is the size of the receive waveform used to calculate the size of the
% noise matrix.

% Normalize noise power by the IFFT size used in OFDM modulation, as
% the OFDM modulator applies this normalization to the transmitted
% waveform. Also normalize by the number of receive antennas, as the
% channel model applies this normalization to the received waveform by
% default. The SNR is defined per RE for each receive antenna (TS
% 38.101-4).
SNR = 10^(SNRdB/10); % Calculate linear noise gain
N0 = 1/sqrt(2.0*nRxAnts*double(Nfft)*SNR);
noise = N0*complex(randn(sizeRxWaveform),randn(sizeRxWaveform));
end

function wtx = getPrecodingMatrix(PRBSet,NLayers,hestGrid)
% Calculate precoding matrix given an allocation and a channel estimate

% Allocated subcarrier indices
allocSc = (1:12)' + 12*PRBSet(:).';
allocSc = allocSc(:);

% Average channel estimate
[~,~,R,P] = size(hestGrid);
estAllocGrid = hestGrid(allocSc,:,:,:);
Hest = permute(mean(reshape(estAllocGrid,[],R,P)),[2 3 1]);

% SVD decomposition
[~,~,V] = svd(Hest);

wtx = V(:,1:NLayers).';
wtx = wtx/sqrt(NLayers); % Normalize by NLayers
end

function estChannelGrid = getInitialChannelEstimate(channel,carrier)
% Obtain an initial channel estimate for calculating the precoding matrix.
% This function assumes a perfect channel estimate

% Clone of the channel
chClone = channel.clone();
chClone.release();

% No filtering needed to get channel path gains
chClone.ChannelFiltering = false;

% Get channel path gains
[pathGains,sampleTimes] = chClone();

% Perfect timing synchronization
pathFilters = getPathFilters(chClone);
offset = nrPerfectTimingEstimate(pathGains,pathFilters);

% Perfect channel estimate
estChannelGrid = nrPerfectChannelEstimate(carrier,pathGains,pathFilters,offset,sampleTimes);
end

function refPoints = getConstellationRefPoints(mod)
% Calculate the reference constellation points for a given modulation
% scheme.
switch mod
    case "QPSK"
        nPts = 4;
    case "16QAM"
        nPts = 16;
    case "64QAM"
        nPts = 64;
    case "256QAM"
        nPts = 256;
end
binaryValues = int2bit(0:nPts-1,log2(nPts));
refPoints = nrSymbolModulate(binaryValues(:),mod);
end

function estChannelGrid = precodeChannelEstimate(estChannelGrid,W)
% Apply precoding matrix W to the last dimension of the channel estimate.

% Linearize 4-D matrix and reshape after multiplication
K = size(estChannelGrid,1);
L = size(estChannelGrid,2);
R = size(estChannelGrid,3);
estChannelGrid = reshape(estChannelGrid,K*L*R,[]);
estChannelGrid = estChannelGrid*W;
estChannelGrid = reshape(estChannelGrid,K,L,R,[]);

end

% -------------------------------------------------------------------------
% _Copyright 2021-2023 The MathWorks, Inc._ and midfied by Armed Tusha
% -------------------------------------------------------------------------