clear all; %close all; clc;

% Author's NAME : Armed Tusha & Antigravity GPU Optimizer
% Institution   : University of Notre Dame & NTIA
% Title         : GPU-Accelerated 5G-NR simulation environment {1-Antenna Pattern, 2-SSB}
% Start Date    : June-1-2024

rng(211);             % Set RNG state for repeatability
testingMode = false;  % Enable testing mode to quickly run the script on a small number of variables

% Output folder path for further study
folderPath = fullfile(pwd, '../Save-Files');
disp(['Saving files to ', folderPath])
if ~exist(folderPath, 'dir')
    mkdir(folderPath)
end

%% %%%%%%%%%%%%%%%%%%%%% Simulation Parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%

% %%%%%%%%%%%%%% Precoder Matrix Indicator (PMI) patameters %%%%%%%%%%%%%%%
nLayers                   = 2;                         % Number of layers

% %%%%%%%%%%%%%%%%%%%%%%%% Antenna Element parameters %%%%%%%%%%%%%%%%%%%%%
CenterFreq              = 3.75e9;                      % Center frequency (Hz).
FreqBans                = [3.7, 3.98] * 1e9;           % Frequency range for the antenna element.
PropSpeed               = physconst('LightSpeed');     % Propagation speed.
lambda                  = PropSpeed / CenterFreq;      % Wavelength of center frequency.
HPBW_H                  = 90;                          % Half power beam width in the horizontal plane
HPBW_V                  = 65;                          % Half power beam width in the verrtical plane

AnElementGain           = 5.3;                         % Antenna element gain (dBi).
Polarization            = 2;

% %%%%%%%%%%%%%%%%%%%%%%%% AAS Configuration         %%%%%%%%%%%%%%%%%%%%%%%
AnElementSpacing_V      = 0.058;                     % Spacing between the antenna elements in the vertical plane (m).
AnElementSpacing_H      = 0.044;                     % Spacing between the antenna elements in the vertical plane (m).

SubArraySize            = [2, 3];                    % Number of antenna elements within a subarray.
ArraySize               = [4, 4];                    % Number of subarray rows and columns within the array, respectively.
SubArraySpacing_V       = SubArraySize(1)*AnElementSpacing_V;   % Spacing between the subarrays in the vertical plane (m).
SubArraySpacing_H       = SubArraySize(2)*AnElementSpacing_H;

% %%%%%%%%%%%%%%%%%%%%%%%%%% SSB parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
BroadBeamRow            = 1:4;
BroadBeamCol            = 2;

% Sectorization parameters
azSweepRangeSect        = [-90, 90];                  % Total azimuth range for all SSBs corresponding to a sectorized cell
elSweepRangeSect        = [0, 90];                    % Total elevation range for all SSBs corresponding to a sectorized cell

% # of SSB coarse beams and position
CoarseConfSSbeams       = [3, 3, 2];                 % Coarse configuration of SSB with a given sector
elSweepCoarseSSB        = [6, 0, -3];                % Elevation angle for each coarse of SSBs in a given plane

ElUpSam                 = 1; 
AzUpSam                 = 1;

PatternNormalization    = true;

%% %%%%%%%%%%%%%%%%%%%%%%%    Antenna Element   %%%%%%%%%%%%%%%%%%%%%%%%%%%%
antennaEleTx            = phased.NRAntennaElement('FrequencyRange',FreqBans,'Beamwidth',[HPBW_H HPBW_V],'PolarizationModel',Polarization,'MaximumGain',AnElementGain);

%% %%%%%%%%%%%%%%%%%%%%%%% Antenna Array pannel %%%%%%%%%%%%%%%%%%%%%%%%%
AntArrayTx              = phased.NRRectangularPanelArray('ElementSet',repmat({antennaEleTx},1,Polarization),'Size',[SubArraySize , ArraySize],...
    'Spacing',[AnElementSpacing_V,AnElementSpacing_H,SubArraySpacing_V,SubArraySpacing_H]);

SteerVecTx_Array        = phased.SteeringVector('SensorArray',AntArrayTx,'PropagationSpeed',PropSpeed,'IncludeElementResponse',true);

% %%%%%%%%%%%%%%%%%%%%%%% SSB Generation %%%%%%%%%%%%%%%%%%%%%%%%%%%%
SSB_AntArrayTx              = phased.NRRectangularPanelArray('ElementSet',repmat({antennaEleTx},1,Polarization),'Size',[SubArraySize , ArraySize],...
    'Spacing',[AnElementSpacing_V,AnElementSpacing_H,SubArraySpacing_V,SubArraySpacing_H]);

SSB_SteerVecTx_Array        = phased.SteeringVector('SensorArray',SSB_AntArrayTx,'PropagationSpeed',PropSpeed,'IncludeElementResponse',true);

numSSbeams              = sum(CoarseConfSSbeams);                                % Number of SSB

numActiveSSBs           = 8;

% Calculate the steering for each SSB 
[azSSB.sweepBW , azSSB.steerAngleMat , azSSB.steerAngle, elSSB.steerAngle , elSSB.steerAngleMat]  = azPlainSSBsteerAngle(azSweepRangeSect,CoarseConfSSbeams,elSweepCoarseSSB);

%% %%%%%%%%%%%%%%%%%%%%%%% Generation of SSB beam and PMI beam %%%%%%%%%%%%%%%%%%%%%%%%%
NumAntElements          = getNumElements(AntArrayTx);
ElementPossition        = getElementPosition(AntArrayTx).';

[SSBactiveAntEleInd, SSBactiveAntEleIndMat] = SSBbeamWeightGeneration( ...
    BroadBeamCol, BroadBeamRow, ...
    SubArraySize, ArraySize, ...
    Polarization, ...
    NumAntElements ...
);

% ---------- summary information ----------
numElements = getNumElements(AntArrayTx);
fprintf('Center frequency: %.3f GHz\n', CenterFreq/1e9);
fprintf('Wavelength (lambda): %.4f m\n', lambda);
fprintf('Total number of elements: %d\n', numElements);

%% -----------------------
% Configuration Array & Subarray
% -----------------------
numSubarrays    = prod(ArraySize);
elementsPerPort = prod(SubArraySize);        % elements per port
totalPorts      = numSubarrays * Polarization;
elementsPerSA   = prod(SubArraySize) * Polarization;  % 2*3*2 = 12

% --- Initialize matrix ---
SubarrayIndicesMat = zeros(1, elementsPerSA, numSubarrays);
PortElementsMat = zeros(1, elementsPerPort, totalPorts);

% --- Fill matrix ---
for row = 1:ArraySize(1)
    for col = 1:ArraySize(2)
        saID     = (row-1)*ArraySize(2) + col;
        startIdx = (saID-1)*elementsPerSA + 1;
        endIdx   = startIdx + elementsPerSA - 1;
        SubarrayIndicesMat(1,:,saID) = startIdx:endIdx;
    end
end

portID = 1;
for sa = 1:numSubarrays
    for pol = 1:Polarization
        startIdx = (sa-1)*elementsPerSA + (pol-1)*elementsPerPort + 1;
        endIdx   = startIdx + elementsPerPort - 1;      
        PortElementsMat(1,:,portID) = startIdx:endIdx;
        portID = portID + 1;
    end
end

%% Calculate the PMI matrix
panelConfigs = [
    2     2     4     3     6     4     8     4     6    12     4     8    16   % N1
    1     2     1     2     1     2     1     3     2     1     4     2     1   % N2
    4     4     4     4     4     4     4     4     4     4     4     4     4   % O1
    1     4     1     4     1     4     1     4     4     1     4     4     1   % O2
];

AllSen = 11;
N1                                  = panelConfigs(1,AllSen);
N2                                  = panelConfigs(2,AllSen);
O1                                  = panelConfigs(3,AllSen);
O2                                  = panelConfigs(4,AllSen);

% PMI matrix parameters
reportConfig.NStartBWP              = 0;
reportConfig.NSizeBWP               = 52;
reportConfig.PanelDimensions        = [N1 N2];
reportConfig.CQITable               = 'table1';
reportConfig.CQIMode                = 'Wideband';
reportConfig.PMIMode                = 'Wideband';
reportConfig.SubbandSize            = 1;
reportConfig.CodebookMode           = 1;
reportConfig.CodebookSubsetRestriction = [];
reportConfig.i2Restriction          = [];

reportConfig.PanelDimensions        = [N1 N2];
reportConfig.OverSamplingFactors    = [O1 O2];
[i2_length, i11_length, i12_length, i13_length, W_PMI] = getPMIType1SinglePanelCodebook(reportConfig,nLayers);

NumAllPMImatricies = NumberPMImatricies(W_PMI);
ContTempPMI = NumAllPMImatricies;

if testingMode
    numSSbeams = 1;
    ContTempPMI_Loop = 1;
else
    ContTempPMI_Loop = ContTempPMI;
end

%% ================= GPU PREPARATION =================
disp('Preparing GPU resources...')

% 1. Create evaluation grid on GPU (Double precision)
azGrid = -180:AzUpSam:180;
elGrid = -90:ElUpSam:90;
nAz = length(azGrid);
nEl = length(elGrid);

[AZ, EL] = meshgrid(deg2rad(azGrid), deg2rad(elGrid));
ux = cos(EL) .* cos(AZ);
uy = cos(EL) .* sin(AZ);
uz = sin(EL);
u_gpu = gpuArray(double([ux(:), uy(:), uz(:)].')); % 3 x NumDirections

% 2. Retrieve antenna element positions and move to GPU (Double precision)
pos_gpu = gpuArray(double(getElementPosition(AntArrayTx))); % 3 x NumElements

% 3. Pre-evaluate Single Element patterns (Power & E-Field) on CPU, then copy to GPU
[elemPat_dB, ~, ~] = pattern( ...
    antennaEleTx, ...
    CenterFreq, ...
    azGrid, ...
    elGrid, ...
    'CoordinateSystem', 'polar', ...
    'Type', 'powerdB' ...
);
elemPat_Lin_gpu = gpuArray(double(10.^(elemPat_dB ./ 10))); % NumDirections x 1

[elemEField, ~, ~] = pattern( ...
    antennaEleTx, ...
    CenterFreq, ...
    azGrid, ...
    elGrid, ...
    'CoordinateSystem', 'polar', ...
    'Type', 'efield' ...
);
elemEField_gpu = gpuArray(double(elemEField)); % NumDirections x 1

% 4. Compute Wave steering phase shifts for all elements (NumElements x NumDirections) on GPU
k = 2 * pi / lambda;
PhaseMat_gpu = exp(-1i * k * (pos_gpu.' * u_gpu));

% 5. Map Port matrices
[PortMatricies, ~] = MapPanelPorts( ...
    AntArrayTx, ...
    N1, N2, ...
    ArraySize, ...
    SubArraySize, ...
    Polarization ...
);

% Pack all PMI weights into a single CPU matrix (NumElements x ContTempPMI_Loop)
All_PMI_Weights_Pol1 = zeros(NumAntElements, ContTempPMI_Loop, 'double');
All_PMI_Weights_Pol2 = zeros(NumAntElements, ContTempPMI_Loop, 'double');

for pmi = 1:ContTempPMI_Loop
    [Weight_PMI_Layer, ~] = Get_Any_PMI_Matrix(W_PMI, pmi);
    
    PMItoAntennaEleMatrix_Layer = zeros(NumAntElements, nLayers, 'double');
    for laylay = 1:nLayers
        PMItoAntennaEleMatrix = zeros(NumAntElements, 1, 'double');
        for ipi = 1:size(PortMatricies, 2)
            PMItoAntennaEleMatrix = PMItoAntennaEleMatrix + ...
                PortMatricies{ipi} .* Weight_PMI_Layer(ipi, laylay);
        end
        PMItoAntennaEleMatrix_Layer(:, laylay) = PMItoAntennaEleMatrix;
    end
    total_weights = sum(PMItoAntennaEleMatrix_Layer, 2);
    
    % Separate weights by polarization (Odd ports -> Pol1, Even ports -> Pol2)
    weights_pol1 = zeros(NumAntElements, 1, 'double');
    weights_pol2 = zeros(NumAntElements, 1, 'double');
    for p = 1:totalPorts
        idx = PortElementsMat(1, :, p);
        if mod(p, 2) == 1
            weights_pol1(idx) = total_weights(idx);
        else
            weights_pol2(idx) = total_weights(idx);
        end
    end
    All_PMI_Weights_Pol1(:, pmi) = weights_pol1;
    All_PMI_Weights_Pol2(:, pmi) = weights_pol2;
end

% Move all PMI weights matrix to GPU (NumElements x ContTempPMI_Loop)
All_PMI_Weights_Pol1_gpu = gpuArray(All_PMI_Weights_Pol1);
All_PMI_Weights_Pol2_gpu = gpuArray(All_PMI_Weights_Pol2);

%% ================= RUN GPU SIMULATION =================
disp('Running calculations on GPU...')

for iissb = 1:numSSbeams
    display(['Generating SSB Idx: ', num2str(iissb)])
    
    % SSB Steering
    SSB_gNB_WT_AntArrayPanel = SSB_SteerVecTx_Array( ...
        CenterFreq, ...
        [azSSB.steerAngleMat(iissb); elSSB.steerAngleMat(iissb)] ...
    );
    SSB_Weights = SSB_gNB_WT_AntArrayPanel .* SSBactiveAntEleInd;
    
    % Separate SSB weights by polarization
    weights_ssb_pol1 = zeros(NumAntElements, 1, 'double');
    weights_ssb_pol2 = zeros(NumAntElements, 1, 'double');
    for p = 1:totalPorts
        idx = PortElementsMat(1, :, p);
        if mod(p, 2) == 1
            weights_ssb_pol1(idx) = SSB_Weights(idx);
        else
            weights_ssb_pol2(idx) = SSB_Weights(idx);
        end
    end
    SSB_Weights_Pol1_gpu = gpuArray(weights_ssb_pol1);
    SSB_Weights_Pol2_gpu = gpuArray(weights_ssb_pol2);
    
    % 1. Compute SSB Array Factors on GPU (1 x NumDirections)
    SSB_AF_Pol1_gpu = SSB_Weights_Pol1_gpu.' * PhaseMat_gpu;
    SSB_AF_Pol2_gpu = SSB_Weights_Pol2_gpu.' * PhaseMat_gpu;
    
    % 2. Apply Single Element Pattern
    SSB_Pat_Lin_gpu = (abs(SSB_AF_Pol1_gpu).^2 + abs(SSB_AF_Pol2_gpu).^2) .* elemPat_Lin_gpu(:).';
    SSB_EField_gpu = sqrt(abs(SSB_AF_Pol1_gpu).^2 + abs(SSB_AF_Pol2_gpu).^2) .* elemEField_gpu(:).';
    if PatternNormalization
        SSB_EField_gpu = SSB_EField_gpu / sqrt(max(SSB_Pat_Lin_gpu));
        SSB_Pat_Lin_gpu = SSB_Pat_Lin_gpu / max(SSB_Pat_Lin_gpu);
    end
    
    % 4. Batch compute array factors for ALL PMIs in one GPU operation
    % Size: (ContTempPMI_Loop x NumDirections)
    AF_PMI_Pol1_gpu = All_PMI_Weights_Pol1_gpu.' * PhaseMat_gpu;
    AF_PMI_Pol2_gpu = All_PMI_Weights_Pol2_gpu.' * PhaseMat_gpu;
    
    % 5. Apply element pattern on GPU
    Pat_PMI_Lin_gpu = (abs(AF_PMI_Pol1_gpu).^2 + abs(AF_PMI_Pol2_gpu).^2) .* repmat(elemPat_Lin_gpu(:).', ContTempPMI_Loop, 1);
    
    if PatternNormalization
        rowMax_gpu = max(Pat_PMI_Lin_gpu, [], 2);
        Pat_PMI_Lin_gpu = Pat_PMI_Lin_gpu ./ rowMax_gpu;
    else
        rowMax_gpu = ones(ContTempPMI_Loop, 1, 'double', 'gpuArray');
    end
    
    % 6. Combine PMI pattern with SSB pattern
    Pat_SSB_PMI_Lin_gpu = Pat_PMI_Lin_gpu .* repmat(SSB_Pat_Lin_gpu, ContTempPMI_Loop, 1);
    
    % 7. E-field evaluations on GPU (magnitude only - real matrix)
    EField_PMI_gpu = sqrt(abs(AF_PMI_Pol1_gpu).^2 + abs(AF_PMI_Pol2_gpu).^2) .* repmat(elemEField_gpu(:).', ContTempPMI_Loop, 1);
    if PatternNormalization
        EField_PMI_gpu = EField_PMI_gpu ./ sqrt(rowMax_gpu);
    end
    EField_SSB_PMI_gpu = EField_PMI_gpu .* repmat(SSB_EField_gpu, ContTempPMI_Loop, 1);
    
    % 8. Preallocate CPU outputs matching the CPU's full preallocation shape (ContTempPMI=2048)
    Power_AzEl_PMI_Lin      = zeros(nEl, nAz, ContTempPMI);
    Power_AzEl_SSB_PMI_Lin  = zeros(nEl, nAz, ContTempPMI);
    AF_AzEl_PMI_eField      = zeros(nEl, nAz, ContTempPMI);
    AF_AzEl_SSB_PMI_eField  = zeros(nEl, nAz, ContTempPMI);
    
    % Gather and assign to the first ContTempPMI_Loop slices
    Power_AzEl_PMI_Lin(:, :, 1:ContTempPMI_Loop)      = gather(reshape(Pat_PMI_Lin_gpu.', nEl, nAz, ContTempPMI_Loop));
    Power_AzEl_SSB_PMI_Lin(:, :, 1:ContTempPMI_Loop)  = gather(reshape(Pat_SSB_PMI_Lin_gpu.', nEl, nAz, ContTempPMI_Loop));
    Power_AzEl_SSB_Lin                                = gather(reshape(SSB_Pat_Lin_gpu.', nEl, nAz));
    
    AF_AzEl_PMI_eField(:, :, 1:ContTempPMI_Loop)      = gather(reshape(EField_PMI_gpu.', nEl, nAz, ContTempPMI_Loop));
    AF_AzEl_SSB_PMI_eField(:, :, 1:ContTempPMI_Loop)  = gather(reshape(EField_SSB_PMI_gpu.', nEl, nAz, ContTempPMI_Loop));
    AF_ElAz_SSB_eField                                = gather(reshape(SSB_EField_gpu.', nEl, nAz));
    
    % 9. Save Files
    save_matrix_to_here(folderPath, Power_AzEl_PMI_Lin, N1, N2, nLayers, iissb);
    save_matrix_to_here(folderPath, Power_AzEl_SSB_PMI_Lin, N1, N2, nLayers, iissb);
    save_matrix_to_here(folderPath, Power_AzEl_SSB_Lin, N1, N2, nLayers, iissb);
    
    save_matrix_to_here(folderPath, AF_AzEl_PMI_eField, N1, N2, nLayers, iissb);
    save_matrix_to_here(folderPath, AF_AzEl_SSB_PMI_eField, N1, N2, nLayers, iissb);
    save_matrix_to_here(folderPath, AF_ElAz_SSB_eField, N1, N2, nLayers, iissb);
end

disp('Simulation complete!')

%% %%%%%%%%%%%%%%%%%%%%%%%%%% HELPER FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ ...
    azSweepBW, ...
    azSteerAngleMat, ...
    azSteerAngle, ...
    elSteerAngle, ...
    elSteerAngleMat]  = azPlainSSBsteerAngle( ...
        azSweepRangeSect, ...
        CoarseConfSSbeams, ...
        elSweepCoarseSSB ...
    )

azSSBeach.sweepBW         = [];
azSSBeach.steerAngleMat   = [];

elSSBeach.steerAngleMat = [];
for ii= 1:numel(CoarseConfSSbeams)

    % Azimuth work
    azSSBeach.sweepBW         = [ ...
        azSSBeach.sweepBW diff(azSweepRangeSect) / CoarseConfSSbeams(ii) ...
    ];      % Scaning width for a given SSB in azimuth plane

    temp  = [];
    for ixi = 1:CoarseConfSSbeams(ii)
        if ixi > 1
            azSSBeach.sweepRange{ii, ixi}  = [ ...
                (azSweepRangeSect(1) + (ixi - 1) * azSSBeach.sweepBW(ii)) + 1, ...
                azSweepRangeSect(1) + ixi * azSSBeach.sweepBW(ii) ...
            ];
        else
            azSSBeach.sweepRange{ii, ixi}  = [ ...
                azSweepRangeSect(1) + (ixi - 1) * azSSBeach.sweepBW(ii), ...
                azSweepRangeSect(1) + ixi * azSSBeach.sweepBW(ii) ...
            ];
        end
        azSSBeach.steerAngleMat = [ ...
            azSSBeach.steerAngleMat, ...
            median(azSSBeach.sweepRange{ii, ixi}) ...
        ];
        temp = [temp, median(azSSBeach.sweepRange{ii, ixi})];
    end
    azSSBeach.steerAngle{ii, 1} = temp;
    
    % Eleviation work
    elSSBeach.steerAngleMat = [ ...
        elSSBeach.steerAngleMat, ...
        elSweepCoarseSSB(ii) * ones(1, CoarseConfSSbeams(ii)) ...
    ];
    JustTemp = elSweepCoarseSSB(ii) * ones(1, CoarseConfSSbeams(ii));
    elSSBeach.steerAngle{ii, 1} = elSweepCoarseSSB(ii) * ones(1, CoarseConfSSbeams(ii));

end

azSweepBW           = azSSBeach.sweepBW;
azSteerAngleMat     = azSSBeach.steerAngleMat;
azSteerAngle        = azSSBeach.steerAngle;

elSteerAngle        = elSSBeach.steerAngle;
elSteerAngleMat     = elSSBeach.steerAngleMat;

end

function [SSBactiveAntEleInd, SSBactiveAntEleIndMat] = SSBbeamWeightGeneration( ...
    ColSize, RowSize, ...
    SubArraySize, ArraySize, ...
    Polarization, ...
    NumAntElements ...
)

SSBactiveAntEleInd = zeros(NumAntElements, 1);

ADS = [];
for ColIndex = ColSize
    ADS = [ADS ; ...
        ((ColIndex - 1) * prod(SubArraySize) * Polarization * ArraySize(1) + 1 : ...
            ColIndex * prod(SubArraySize) * Polarization * ArraySize(1))
    ];
end

rowADS = [];
for RowIndex = RowSize
    rowADS = [rowADS, ...
        ((RowIndex - 1) * prod(SubArraySize) * Polarization + 1 : ...
            RowIndex * prod(SubArraySize) * Polarization) ...
    ];
end

ADS = ADS .';
rowADS = rowADS .';
SSBactiveAntElements = ADS(rowADS, :);
SSBactiveAntEleInd(SSBactiveAntElements) = 1;
SSBactiveAntEleIndMat = reshape( ...
    SSBactiveAntEleInd, ...
    prod(SubArraySize) * Polarization * ArraySize(1), []);

end

function varName = saveVarName(x)
    varName = inputname(1);   % gets the name of the variable passed
    disp(['Variable name is: ', varName]);

    % Save the name to a file
    fid = fopen('varName.txt','w');
    %fprintf(fid,'%s\n',varName);
    fclose(fid);
    varName = varName;
end
