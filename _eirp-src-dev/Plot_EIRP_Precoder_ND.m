clear all; %close all; clc;

% Author's NAME : Armed Tusha
% Institution   : University of Notre Dame & NTIA
% Title         : 5G-NR simulation environment {1-Antenna Pattern, 2-SSB}
% Start Date    : June-1-2024

rng(211);                                           % Set RNG state for repeatability
%% %%%%%%%%%%%%%%%%%%%%% Simulation Parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%

% %%%%%%%%%%%%%% Precoder Matrix Indicator (PMI) patameters %%%%%%%%%%%%%%%
% [N1 N2 O1 O2]           = NumberLogicalPorts();      % Decide the number of Logical Ports
nLayers                 = 1;                         % Number of layers

% %%%%%%%%%%%%%%%%%%%%%%%% Antenna Element parameters %%%%%%%%%%%%%%%%%%%%%
prm.CenterFreq          = 3.75e9;                    % Center frequency (Hz).
FreqBans                = [3.7 3.98]*1e9;            % Frequency range for the antenna element.
PropSpeed               = physconst('LightSpeed');   % Propagation speed.
lambda                  = PropSpeed/prm.CenterFreq;          % Wavelength of center frequency.
HPBW_H                  = 90;                        % Half power beam width in the horizontal plane
HPBW_V                  = 65;                        % Half power beam width in the verrtical plane

AnElementGain           = 5.3;                       % Antenna element gain (dBi).
Polarization            = 2;

%Antenna Pannel Design
% AnElementSpacing_V      = 0.5*lambda;              % Spacing between the antenna elements in the vertical plane (m).
% AnElementSpacing_H      = 0.5*lambda;              % Spacing between the antenna elements in the vertical plane (m).
% SubArraySpacing_V       = 3*AnElementSpacing_V;                   % Spacing between the subarrays in the vertical plane (m).
% SubArraySpacing_H       = 1*AnElementSpacing_H;
% SubArraySize            = [3 1];                   % Number of antenna elements within a subarray.                     
% ArraySize               = [4 8];                   % Number of subarray rows and columns within the array, respectively.

AnElementSpacing_V      = 0.058;                     % Spacing between the antenna elements in the vertical plane (m).
AnElementSpacing_H      = 0.044;                     % Spacing between the antenna elements in the vertical plane (m).
SubArraySpacing_V       = 0.174;                     % Spacing between the subarrays in the vertical plane (m).
SubArraySpacing_H       = 0.044;
SubArraySize            = [3 1];                     % Number of antenna elements within a subarray.
ArraySize               = [4 8];                     % Number of subarray rows and columns within the array, respectively.

% %%%%%%%%%%%%%%%%%%%%%%%%%% SSB parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
BroadBeamRow            = [7:12];
BroadBeamCol            = [5];
% Sectorization parameters
azSweepRangeSect        = [-60 , 60];                % Total azimuth range for all SSBs corresponding to a sectorized cell
elSweepRangeSect        = [0 90];                    % Total elevation range for all SSBs corresponding to a sectorized cell

% # of SSB coarse beams and position
CoarseConfSSbeams       = [3 , 3 , 2];               % Coarse configuration of SSB with a given sector
elSweepCoarseSSB        = [6 , 0 , -3];              % Elevation angle for each coarse of SSBs in a given plane

% Power information
Pt_dBm                  =  47;                       % Transmitter Pannel gain in dBm
Gr_dB                   =  0;                        % Receiver Pannel gain in dBm

ElUpSam                 = 1; 
AzUpSam                 = 1;

% %%%%%%%%%%%%%%%%%%%%%%%%% Results and plots %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
AntElementProperties    = 0;                         % One (1) activates the plot function for antenna element.
SSBproperties           = 0; 
AntPanelProperties      = 0;                         % One (1) activates the plot function for subarray, antenna array and pattern

AnglePairAngle          = 0;
Ref_Elevation           = 0;

PatternNormalization    = true;

%% %%%%%%%%%%%%%%%%%%%%%%%    Some displays     %%%%%%%%%%%%%%%%%%%%%%%%%%%%  
% Display the result for lambda
disp(['Carrier Frequency (GHz) = ', num2str(prm.CenterFreq/1e9), 'meters']);
disp(['Wavelength (lambda) = ', num2str(lambda), ' meters']);

%% %%%%%%%%%%%%%%%%%%%%%%%    Antenna Element   %%%%%%%%%%%%%%%%%%%%%%%%%%%%
antennaEleTx            = phased.NRAntennaElement('FrequencyRange',FreqBans,'Beamwidth',[HPBW_H HPBW_V],'PolarizationModel',Polarization,'MaximumGain',AnElementGain);
%antenna                = phased.CrossedDipoleAntennaElement('FrequencyRange',FreqBans);
%antennaEleTx            = phased.OmnidirectionalMicrophoneElement('FrequencyRange',FreqBans,'BackBaffled',false);
%antenna                = phased.IsotropicAntennaElement('FrequencyRange',FreqBans,'BackBaffled',false);

if AntElementProperties == 1
    % 3D plot of power for antenna element (dB).
    figure;
    pattern(antennaEleTx,prm.CenterFreq,-180:180,-90:90,'PropagationSpeed',PropSpeed,'CoordinateSystem','polar','Type','powerdB','ShowArray',true, 'Normalize',PatternNormalization);
    title('Antenna Element')

    % Plot of half power beam width in the horizontal plane.
    figure;
    beamwidth(antennaEleTx,prm.CenterFreq,'Cut','Azimuth');

    % Plot of half power beam width in the vertical plane.
    figure;
    beamwidth(antennaEleTx,prm.CenterFreq,'Cut','Elevation');

    % Calculate the transmit beam angles in azimuth and elevation for the antenna element respectively.
    azBWAntennaEleTx        = beamwidth(antennaEleTx,prm.CenterFreq,'Cut','Azimuth');
    elBWAntennaEleTx        = beamwidth(antennaEleTx,prm.CenterFreq,'Cut','Elevation');

    % Calculate the maximum power.
    [antennaPat,antennaAz,antennaEl] = pattern(antennaEleTx,prm.CenterFreq,-180:180,-90:90,'PropagationSpeed',PropSpeed,'CoordinateSystem','polar','Type','powerdB','Normalize',PatternNormalization);
    [Dim1 , Dim2]           = find(antennaPat == max(antennaPat,[],"all"));

    % 3D plot 
    patternplot(antennaAz,antennaEl,antennaPat)
    pattern10plot(antennaAz,antennaEl,antennaPat)

end

%% %%%%%%%%%%%%%%%%%%%%%%% Antenna Array pannel %%%%%%%%%%%%%%%%%%%%%%%%%

AntArrayTx                 = phased.NRRectangularPanelArray('ElementSet',repmat({antennaEleTx},1,Polarization),'Size',[SubArraySize , ArraySize(1), ArraySize(2)],...
    'Spacing',[AnElementSpacing_V,AnElementSpacing_H,SubArraySpacing_V,SubArraySpacing_H]);

SteerVecTx_Array         = phased.SteeringVector('SensorArray',AntArrayTx,'PropagationSpeed',PropSpeed,'IncludeElementResponse',true);

gNB_WT_AntArrayPanel     = SteerVecTx_Array(prm.CenterFreq,[0;0]);


%% %%%%%%%%%%%%%%%%%%%%%%% Generation of SSB beam and PMI beam %%%%%%%%%%%%%%%%%%%%%%%%%
[BroadBeamElemActivationCol,ShownElemActivIndexingCol] = BroadcastBeamCol(AntArrayTx,BroadBeamCol,SubArraySize,ArraySize(1),Polarization);

[BroadBeamElemActivationRow,ShownElemActivIndexingRow] = BroadcastBeamRow(AntArrayTx,BroadBeamRow,SubArraySize,ArraySize(1),Polarization);

% Generation of the SSB beam for the gNB

BroadBeamElemActivationSSB = BroadBeamElemActivationRow.*BroadBeamElemActivationCol;
ShownElemActivIndexingSSB  = ShownElemActivIndexingRow.*ShownElemActivIndexingCol;


[EIRP_ElAz_SSB_dB AngleAxisAz_SSB AngleAxisEl_SSB] = pattern(AntArrayTx,prm.CenterFreq,-180:AzUpSam:180,-90:ElUpSam:90,'CoordinateSystem','polar','Type','powerdB','Weights',BroadBeamElemActivationSSB.*gNB_WT_AntArrayPanel,'Normalize',true);

[EIRP_ElAz_PMI_dB AngleAxisAz_PMI AngleAxisEl_PMI] = pattern(AntArrayTx,prm.CenterFreq,-180:AzUpSam:180,-90:ElUpSam:90,'CoordinateSystem','polar','Type','powerdB','Weights',gNB_WT_AntArrayPanel,'Normalize',PatternNormalization);


if SSBproperties == 1
    figure;
    pattern(AntArrayTx,prm.CenterFreq,-180:AzUpSam:180,-90:ElUpSam:90,'CoordinateSystem','polar','Type','powerdB','Weights',BroadBeamElemActivationSSB,'Normalize',PatternNormalization);
    colormap("jet")
    patternplot(AngleAxisAz_SSB,AngleAxisEl_SSB,EIRP_ElAz_SSB_dB);
    figure;
    pattern(AntArrayTx,prm.CenterFreq,0,-90:ElUpSam:90,'CoordinateSystem','polar','Type','powerdB','Weights',BroadBeamElemActivationSSB,'Normalize',PatternNormalization);
    colormap("jet")
        figure;
    pattern(AntArrayTx,prm.CenterFreq,-180:AzUpSam:180,0,'CoordinateSystem','polar','Type','powerdB','Weights',BroadBeamElemActivationSSB,'Normalize',PatternNormalization);
    colormap("jet")
end

if AntPanelProperties == 1
    % Plot the antenna array
    figure;
    viewArray(AntArrayTx,'ShowIndex','All','ShowNormals',true, ...
        'ShowLocalCoordinates',true,'Orientation',[0;0;0], ...
        'ShowAnnotation',true)

    % Plot the antenna pattern
    figure;
    pattern(AntArrayTx,prm.CenterFreq,-180:AzUpSam:180,-90:ElUpSam:90,'PropagationSpeed',PropSpeed,'CoordinateSystem','polar','Type','powerdB','Normalize',PatternNormalization,'ShowArray',true);
    colormap("jet");

    % Plot the antenna pattern
    figure;
    pattern(AntArrayTx,prm.CenterFreq,-180:AzUpSam:180,-90:ElUpSam:90,'PropagationSpeed',PropSpeed,'CoordinateSystem','rectangular','Type','powerdB','Normalize',PatternNormalization);
    colormap("jet")

    % Plot the antenna pattern
    figure;
    pattern(AntArrayTx,prm.CenterFreq,0,-90:ElUpSam:90,'PropagationSpeed',PropSpeed,'CoordinateSystem','rectangular','Type','powerdB','Normalize',PatternNormalization);
    colormap("jet")

    figure;
    pattern(AntArrayTx,prm.CenterFreq,-180:AzUpSam:180,0,'PropagationSpeed',PropSpeed,'CoordinateSystem','rectangular','Type','powerdB','Normalize',PatternNormalization);
    colormap("jet")

    figure;
    pattern(AntArrayTx,prm.CenterFreq,'ShowArray',true,'Weights',gNB_WT_AntArrayPanel);

    %Plot of half power beam width in the horizontal plane.
    figure;
    beamwidth(AntArrayTx,prm.CenterFreq,'Cut','Azimuth');

    % Plot of half power beam width in the vertical plane.
    figure;
    beamwidth(AntArrayTx,prm.CenterFreq,'Cut','Elevation');
end


%% Design the map between the Antenna Ports and Antenna Elements to the Antenna Panel

NumAntElements   = getNumElements(AntArrayTx);
ElementPossition = getElementPosition(AntArrayTx).';

%% Calculate the PMI matrix

panelConfigs = [2     2     4     3     6     4     8     4     6    12     4     8    16   % N1

1     2     1     2     1     2     1     3     2     1     4     2     1   % N2

4     4     4     4     4     4     4     4     4     4     4     4     4   % O1

1     4     1     4     1     4     1     4     4     1     4     4     1]; % O2

%for AllSen = 1:size(panelConfigs,2)
for AllSen = [11]
AllSen

N1                                  = panelConfigs(1,AllSen);
N2                                  = panelConfigs(2,AllSen);
O1                                  = panelConfigs(3,AllSen);
O2                                  = panelConfigs(4,AllSen);

% PMI matrix parameters
reportConfig.NStartBWP              = 0;
reportConfig.NSizeBWP               = 52;
reportConfig.PanelDimensions        = [N1 N2];
reportConfig.CQIMode                = 'Wideband';
reportConfig.PMIMode                = 'Wideband';
reportConfig.SubbandSize            = 1;
reportConfig.PRGSize                = [];
reportConfig.CodebookMode           = 1;
reportConfig.CodebookSubsetRestriction = [];
reportConfig.i2Restriction          = [];

reportConfig.PanelDimensions        = [N1 N2];
reportConfig.OverSamplingFactors    = [O1 O2];
[i2_length, i11_length, i12_length, i13_length, W_PMI] = getPMIType1SinglePanelCodebook(reportConfig,nLayers);



[PortMatricies PortAntennaMap] = MapPanelPorts(AntArrayTx,N1,N2,ArraySize,SubArraySize,Polarization);

PortMatricies = fliplr(PortMatricies);

%% %%%%%%%%%%%%%%%%%%%%% Run Simulation (Monte Carlo) %%%%%%%%%%%%%%%%%%%%%%%%%

NumAllPMImatricies                  = NumberPMImatricies(W_PMI);

ContTempPMI                         = NumAllPMImatricies;

%% Get the PMI vector

for pmi = 1:ContTempPMI
    pmi 

    %[Weight_PMI_Layer idx_PMI] = Get_Rand_PMI_Matrix(W_PMI);           % Select a random PMI matrix from the table given nLayers
    [Weight_PMI_Layer idx_PMI]                          = Get_Any_PMI_Matrix(W_PMI,pmi);      % Select pmi-th PMI matrix from the table given nLayers

    % Map the antenna port weights to antenna elements
    [PMItoAntennaEleMatrixCechk PMI2AntEleMatrix]       = AntElementPMI(PortMatricies,Weight_PMI_Layer,nLayers,NumAntElements);

    % Antenna patern radiation considering PMI impact
    [ResultElAz_PMI_dB AngleAxisAz_PMI AngleAxisEl_PMI] = pattern(AntArrayTx,prm.CenterFreq,-180:AzUpSam:180,-90:ElUpSam:90,'CoordinateSystem','polar','Type','powerdb','Weights',gNB_WT_AntArrayPanel.*PMI2AntEleMatrix,'Normalize',PatternNormalization);

    ResultElAz_PMI_Lin               = 10.^(ResultElAz_PMI_dB./10);   % This is converted to watt scale
    
    ResultElAz_SSB_Lin               = 10.^(EIRP_ElAz_SSB_dB./10);    % This is converted to watt scale
    
    Enr_AzEl_PMI_Lin(:,:,pmi)        =  ResultElAz_PMI_Lin;                        % The result is in watt scale
    Enr_AzEl_SSB_PMI_Lin(:,:,pmi)    =  ResultElAz_PMI_Lin.*ResultElAz_SSB_Lin;    % The result is in watt scale
end

%% %%%%%%%%%%%%%%%%% Save Files for studing purposes %%%%%%%%%%%%%%%%%%% %%

folderPath = ['/home/ghoshlab1/Desktop/5GNRSimulator-EIRP/Run-ICC/EIRP-Results-L2'];

save_matrix_to_folder(Enr_AzEl_PMI_Lin,folderPath,N1,N2,nLayers);

save_matrix_to_folder(Enr_AzEl_SSB_PMI_Lin, folderPath,N1,N2,nLayers);

originalFolder = pwd;
cd(originalFolder)
end