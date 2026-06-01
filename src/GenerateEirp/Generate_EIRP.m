clear all; %close all; clc;

% Author's NAME : Armed Tusha
% Institution   : University of Notre Dame & NTIA
% Title         : 5G-NR simulation environment {1-Antenna Pattern, 2-SSB}
% Start Date    : June-1-2024

rng(211);                                           % Set RNG state for repeatability
%% %%%%%%%%%%%%%%%%%%%%% Simulation Parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%

% %%%%%%%%%%%%%% Precoder Matrix Indicator (PMI) patameters %%%%%%%%%%%%%%%
% [N1 N2 O1 O2]           = NumberLogicalPorts();      % Decide the number of Logical Ports
nLayers                   = 2;                         % Number of layers

% %%%%%%%%%%%%%%%%%%%%%%%% Antenna Element parameters %%%%%%%%%%%%%%%%%%%%%
CenterFreq              = 3.75e9;                      % Center frequency (Hz).
FreqBans                = [3.7 3.98]*1e9;              % Frequency range for the antenna element.
PropSpeed               = physconst('LightSpeed');     % Propagation speed.
lambda                  = PropSpeed/CenterFreq;          % Wavelength of center frequency.
HPBW_H                  = 90;                          % Half power beam width in the horizontal plane
HPBW_V                  = 65;                          % Half power beam width in the verrtical plane

AnElementGain           = 5.3;                         % Antenna element gain (dBi).
Polarization            = 2;

% %%%%%%%%%%%%%%%%%%%%%%%% AAS Configuration         %%%%%%%%%%%%%%%%%%%%%%%
AnElementSpacing_V      = 0.058;                     % Spacing between the antenna elements in the vertical plane (m).
AnElementSpacing_H      = 0.044;                     % Spacing between the antenna elements in the vertical plane (m).
%SubArraySpacing_V       = 0.174;                     % Spacing between the subarrays in the vertical plane (m).
%SubArraySpacing_H       = 0.044;

SubArraySize            = [2 3];                     % Number of antenna elements within a subarray.
ArraySize               = [4 4];                     % Number of subarray rows and columns within the array, respectively.
SubArraySpacing_V       = SubArraySize(1)*AnElementSpacing_V;                     % Spacing between the subarrays in the vertical plane (m).
SubArraySpacing_H       = SubArraySize(2)*AnElementSpacing_H;

% %%%%%%%%%%%%%%%%%%%%%%%%%% SSB parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
BroadBeamRow            = [1:4];
BroadBeamCol            = [2];

% Sectorization parameters
azSweepRangeSect        = [-90 , 90];                  % Total azimuth range for all SSBs corresponding to a sectorized cell
elSweepRangeSect        = [0 90];                      % Total elevation range for all SSBs corresponding to a sectorized cell

% # of SSB coarse beams and position
CoarseConfSSbeams       = [3 , 3 , 2];                 % Coarse configuration of SSB with a given sector
elSweepCoarseSSB        = [6 , 0 , -3];                % Elevation angle for each coarse of SSBs in a given plane

ElUpSam                 = 1; 
AzUpSam                 = 1;

% %%%%%%%%%%%%%%%%%%%%%%%%% Results and plots %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
AntElementProperties    = 0;                           % One (1) activates the plot function for antenna element.
SSBproperties           = 0; 
AntPanelProperties      = 0;                           % One (1) activates the plot function for subarray, antenna array and pattern

AnglePairAngle          = 0;
Ref_Elevation           = 0;

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

% All possible combinations of the SSB configurations
SSB_Active_Mat          = nchoosek([1:numSSbeams],numActiveSSBs);              % Each row shows a possible combination of k SSBs being active simultaneously

% Calculate the steering for each SSB 
[azSSB.sweepBW , azSSB.steerAngleMat , azSSB.steerAngle, elSSB.steerAngle , elSSB.steerAngleMat]  = azPlainSSBsteerAngle(azSweepRangeSect,CoarseConfSSbeams,elSweepCoarseSSB);

%% %%%%%%%%%%%%%%%%%%%%%%% Generation of SSB beam and PMI beam %%%%%%%%%%%%%%%%%%%%%%%%%
NumAntElements          = getNumElements(AntArrayTx);
ElementPossition        = getElementPosition(AntArrayTx).';

[SSBactiveAntEleInd SSBactiveAntEleIndMat] = SSBbeamWeightGeneration(BroadBeamCol,BroadBeamRow,SubArraySize,ArraySize,Polarization,NumAntElements);


%% %%%%%%%%%%%%%%%%%%%%%%%    Some displays     %%%%%%%%%%%%%%%%%%%%%%%%%%%%  
% Display the result for lambda
disp(['Carrier Frequency (GHz) = ', num2str(CenterFreq/1e9), 'meters']);
disp(['Wavelength (lambda) = ', num2str(lambda), ' meters']);

% ---------- summary information ----------
numElements = getNumElements(AntArrayTx);
fprintf('Center frequency: %.3f GHz\n', CenterFreq/1e9);
fprintf('Wavelength (lambda): %.4f m\n', lambda);
fprintf('Element spacing (V,H): %.3f m (%.2f lambda), %.3f m (%.2f lambda)\n', ...
    AnElementSpacing_V, AnElementSpacing_V/lambda, AnElementSpacing_H, AnElementSpacing_H/lambda);
fprintf('Polarization: %.4f \n', Polarization);
fprintf('Subarray spacing (V,H): %.3f m, %.3f m\n', SubArraySpacing_V, SubArraySpacing_H);
fprintf('Subarray size (V x H): %d x %d\n', SubArraySize(1), SubArraySize(2));
fprintf('Panel (array) size (V x H): %d x %d\n', ArraySize(1), ArraySize(2));
fprintf('Total number of elements: %d\n', numElements);

%% -----------------------
% Configureation Array & Subarray
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
        % Compute subarray ID (column-major numbering)
        saID     = (row-1)*ArraySize(2) + col;
        startIdx = (saID-1)*elementsPerSA + 1;
        endIdx   = startIdx + elementsPerSA - 1;
        SubarrayIndicesMat(1,:,saID) = startIdx:endIdx;
    end
end

%--- Example: Show all subarrays element indices ---
disp('All subarrays:');
for k = 1:numSubarrays
    fprintf('Subarray %d: ', k);
    disp(SubarrayIndicesMat(:,:,k));
end

%% -----------------------
% Fill the matrix
%% -----------------------
portID = 1;
for sa = 1:numSubarrays
    for pol = 1:Polarization
        startIdx = (sa-1)*elementsPerSA + (pol-1)*elementsPerPort + 1;
        endIdx   = startIdx + elementsPerPort - 1;      
        PortElementsMat(1,:,portID) = startIdx:endIdx;
        portID = portID + 1;
    end
end

%% -----------------------
% Example: display first 4 ports
%% -----------------------
for k = 1:min(32,totalPorts)
    fprintf('Port %d elements: ', k);
    disp(PortElementsMat(:,:,k));
end

%% Calculate the PMI matrix

panelConfigs = [2     2     4     3     6     4     8     4     6    12     4     8    16   % N1

1     2     1     2     1     2     1     3     2     1     4     2     1   % N2

4     4     4     4     4     4     4     4     4     4     4     4     4   % O1

1     4     1     4     1     4     1     4     4     1     4     4     1]; % O2

%for AllSen = [11]
%for AllSen = 1:size(panelConfigs,2)
AllSen = 11;
AllSen

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
%reportConfig.PRGSize                = [];
reportConfig.CodebookMode           = 1;
reportConfig.CodebookSubsetRestriction = [];
reportConfig.i2Restriction          = [];

reportConfig.PanelDimensions        = [N1 N2];
reportConfig.OverSamplingFactors    = [O1 O2];
[i2_length, i11_length, i12_length, i13_length, W_PMI] = getPMIType1SinglePanelCodebook(reportConfig,nLayers);


%% %%%%%%%%%%%%%%%%%%%%% Run Simulation (Monte Carlo) %%%%%%%%%%%%%%%%%%%%%%%%%

NumAllPMImatricies = NumberPMImatricies(W_PMI);
ContTempPMI = NumAllPMImatricies;


%% ================= PARFOR SAFE INITIALIZATION =================

% Make sure workers can see all files/functions
%addpath(genpath(pwd));

if isempty(gcp('nocreate'))
    parpool('local');
end


% Broadcast large read-only data to workers
AntArrayConst   = parallel.pool.Constant(AntArrayTx);
PortMapConst    = parallel.pool.Constant(PortElementsMat);
nLayersConst    = parallel.pool.Constant(nLayers);

NumEl = NumAntElements;
tp    = totalPorts;

% Preallocate outputs for slicing
nEl = length(-90:ElUpSam:90);
nAz = length(-180:AzUpSam:180);

Power_AzEl_PMI_Lin      = zeros(nEl,nAz,ContTempPMI);
Power_AzEl_SSB_PMI_Lin  = zeros(nEl,nAz,ContTempPMI);

AF_AzEl_PMI_eField      = zeros(nEl,nAz,ContTempPMI);
AF_AzEl_SSB_PMI_eField  = zeros(nEl,nAz,ContTempPMI);

%nLayers_loc = nLayers;

%numSSbeams = 1;
for iissb = 1:numSSbeams

    iissb 
    SSB_gNB_WT_AntArrayPanel    = SSB_SteerVecTx_Array(CenterFreq,[azSSB.steerAngleMat(iissb);elSSB.steerAngleMat(iissb)]);      % It steers toward azimuth and elevation angle, i.e., (Az,El).

    [EIRP_ElAz_SSB_dB AngleAxisAz_SSB AngleAxisEl_SSB] = pattern(SSB_AntArrayTx,CenterFreq,-180:AzUpSam:180,-90:ElUpSam:90,'CoordinateSystem','polar','Type','powerdB','Weights',SSB_gNB_WT_AntArrayPanel.*SSBactiveAntEleInd,'Normalize',true);

    [AF_ElAz_SSB_eField AngleAxisAz_SSB AngleAxisEl_SSB] = pattern(SSB_AntArrayTx,CenterFreq,-180:AzUpSam:180,-90:ElUpSam:90,'CoordinateSystem','polar','Type','efield','Weights',SSB_gNB_WT_AntArrayPanel.*SSBactiveAntEleInd,'Normalize',true);

    ResultElAz_SSB_Lin = 10.^(EIRP_ElAz_SSB_dB./10);

    %SteerConst      = parallel.pool.Constant(PMI_gNB_WT_AntArrayPanel);
    ResultSSBConst  = parallel.pool.Constant(ResultElAz_SSB_Lin);



for pmi = 1:ContTempPMI
%for pmi = 1:2


    AntArrayTx_loc = AntArrayConst.Value;
    %gNBT_loc       = SteerConst.Value;
    PortMap_loc    = PortMapConst.Value;
    SSB_Lin_loc    = ResultSSBConst.Value;
    nLayers_loc    = nLayersConst.Value;

    [PortMatricies, ~] = MapPanelPorts( ...
        AntArrayTx_loc,N1,N2,ArraySize,SubArraySize,Polarization);

    [Weight_PMI_Layer,~] = Get_Any_PMI_Matrix(W_PMI,pmi);

    WeightVector = zeros(NumEl,1);

    for p = 1:tp
        idx = PortMap_loc(1,:,p);
        WeightVector(idx) = Weight_PMI_Layer(p);

        z = zeros(NumEl,1);
        z(idx) = 1;
        PortMatricies{p} = z;
    end

    PMItoAnt = zeros(NumEl,1);

    PMItoAntennaEleMatrix_Layer = zeros(NumEl,nLayers_loc);
    for laylay = 1:nLayers_loc
        PMItoAntennaEleMatrix = zeros(NumEl,1);
        for ipi = 1:size(PortMatricies,2)
            PMItoAntennaEleMatrix  = PMItoAntennaEleMatrix + PortMatricies{ipi}.*Weight_PMI_Layer(ipi,laylay);
        end
        PMItoAntennaEleMatrix_Layer(:,laylay) = PMItoAntennaEleMatrix;
    end

    [pat_PMI_dB,~,~] = pattern( ...
        AntArrayTx_loc,CenterFreq,...
        -180:AzUpSam:180,...
        -90:ElUpSam:90,...
        'CoordinateSystem','polar',...
        'Type','powerdb',...
        'Weights',sum(PMItoAntennaEleMatrix_Layer,2),...
        'Normalize',PatternNormalization);

    [pat_PMI_eField,~,~] = pattern( ...
        AntArrayTx_loc,CenterFreq,...
        -180:AzUpSam:180,...
        -90:ElUpSam:90,...
        'CoordinateSystem','polar',...
        'Type','efield',...
        'Weights',sum(PMItoAntennaEleMatrix_Layer,2),...
        'Normalize',PatternNormalization);

    pat_PMI_Lin = 10.^(pat_PMI_dB./10);

    Power_AzEl_PMI_Lin(:,:,pmi)     = pat_PMI_Lin;
    Power_AzEl_SSB_PMI_Lin(:,:,pmi) = pat_PMI_Lin .* SSB_Lin_loc;

    AF_AzEl_PMI_eField(:,:,pmi)     = pat_PMI_eField;
    AF_AzEl_SSB_PMI_eField(:,:,pmi) = pat_PMI_eField .* AF_ElAz_SSB_eField;
end


%% %%%%%%%%%%%%%%%%% Save Files for studing purposes %%%%%%%%%%%%%%%%%%% %%

Power_AzEl_SSB_Lin                    = ResultElAz_SSB_Lin;

originalFolder = pwd;


folderPath = ['C:\Users\armed\Desktop\NTIA-Project-Codes\Save-Files'];
cd (folderPath);

save_matrix_to_here(Power_AzEl_PMI_Lin, N1, N2, nLayers,iissb)
save_matrix_to_here(Power_AzEl_SSB_PMI_Lin, N1, N2, nLayers,iissb)
save_matrix_to_here(Power_AzEl_SSB_Lin, N1, N2, nLayers,iissb)

save_matrix_to_here(AF_AzEl_PMI_eField, N1, N2, nLayers,iissb)
save_matrix_to_here(AF_AzEl_SSB_PMI_eField, N1, N2, nLayers,iissb)
save_matrix_to_here(AF_ElAz_SSB_eField, N1, N2, nLayers,iissb)



cd(originalFolder)

end



function [Output1 , Output2 , Output3 , Output4 , Output5]  = azPlainSSBsteerAngle(azSweepRangeSect,CoarseConfSSbeams,elSweepCoarseSSB)
azSSBeach.sweepBW         = [];
azSSBeach.steerAngleMat   = [];

elSSBeach.steerAngleMat = [];
for ii= 1:numel(CoarseConfSSbeams)

    % Azimuth work
    azSSBeach.sweepBW         = [azSSBeach.sweepBW diff(azSweepRangeSect)/CoarseConfSSbeams(ii)];                   % Scaning width for a given SSB in azimuth plane    
    temp  = [];
    for ixi = 1:CoarseConfSSbeams(ii)
        if ixi >1
            azSSBeach.sweepRange{ii,ixi}  = [(azSweepRangeSect(1)+(ixi-1)*azSSBeach.sweepBW(ii))+1,azSweepRangeSect(1)+ixi*azSSBeach.sweepBW(ii)];
        else
            azSSBeach.sweepRange{ii,ixi}  = [azSweepRangeSect(1)+(ixi-1)*azSSBeach.sweepBW(ii),azSweepRangeSect(1)+ixi*azSSBeach.sweepBW(ii)];
        end
        %azSSBeach.steerAngle{ii,ixi} = median(azSSBeach.sweepRange{ii,ixi});
        azSSBeach.steerAngleMat      = [azSSBeach.steerAngleMat median(azSSBeach.sweepRange{ii,ixi})];
        temp = [temp median(azSSBeach.sweepRange{ii,ixi})];
    end
    azSSBeach.steerAngle{ii,1} = temp;
    
    % Eleviation work
    elSSBeach.steerAngleMat = [elSSBeach.steerAngleMat elSweepCoarseSSB(ii)*ones(1,CoarseConfSSbeams(ii))];
    JustTemp = elSweepCoarseSSB(ii)*ones(1,CoarseConfSSbeams(ii));
    elSSBeach.steerAngle{ii,1} = elSweepCoarseSSB(ii)*ones(1,CoarseConfSSbeams(ii));

end
Output1           = azSSBeach.sweepBW;
Output2           = azSSBeach.steerAngleMat;
Output3           = azSSBeach.steerAngle;

Output4           = elSSBeach.steerAngle;
Output5           = elSSBeach.steerAngleMat;
end

function [SSBactiveAntEleInd,SSBactiveAntEleIndMat] = SSBbeamWeightGeneration(ColSize,RowSize,SubArraySize,ArraySize,Polarization,NumAntElements)
 
SSBactiveAntEleInd = zeros(NumAntElements,1);

 ADS = [];
 for ColIndex = ColSize;
     ADS = [ADS ; (ColIndex-1)*prod(SubArraySize)*Polarization*ArraySize(1) + 1 : ColIndex*prod(SubArraySize)*Polarization*ArraySize(1)];
 end

 rowADS = [];
 for RowIndex = RowSize;
     rowADS = [rowADS (RowIndex-1)*prod(SubArraySize)*Polarization + 1 : RowIndex*prod(SubArraySize)*Polarization];
 end
 ADS = ADS.';
 rowADS = rowADS.';
 SSBactiveAntElements = ADS(rowADS,:);
 SSBactiveAntEleInd(SSBactiveAntElements) = 1;
 SSBactiveAntEleIndMat = reshape(SSBactiveAntEleInd,prod(SubArraySize)*Polarization*ArraySize(1),[]);
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

