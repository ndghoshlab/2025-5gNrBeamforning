clear all; close all; clc;

% Author's NAME : Armed Tusha
% Institution   : University of Notre Dame & NTIA
% Title         : 5G-NR simulation environment {1-Antenna Pattern, 2-SSB}
% Date          : June-1-2024

rng(211);                                           % Set RNG state for repeatability
%% %%%%%%%%%%%%%%%%%%%%% Simulation Parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Antenna panel parameters
prm.CenterFreq          = 3.75e9;                    % Center frequency (Hz).
FreqBans                = [3.7 3.98]*1e9;            % Frequency range for the antenna element.
c                       = physconst('LightSpeed');   % Propagation speed.
lambda                  = c/prm.CenterFreq;          % Wavelength of center frequency.
HPBW_H                  = 90;                        % Half power beam width in the horizontal plane
HPBW_V                  = 65;                        % Half power beam width in the verrtical plane
AnElementSpacing_V      = 0.058;                     % Spacing between the antenna elements in the vertical plane (m).
AnElementSpacing_H      = 0.044;                     % Spacing between the antenna elements in the vertical plane (m).

AnElementGain           = 5.3;                       % Antenna element gain (dBi).

SubArraySize            = [3 1];                     % Number of antenna elements within a subarray.
SubArrayRows            = 4;                         % Number of subarray rows within the array.
SubArrayCols            = 8;                         % Number of subarray colomuns within the array.
SubArraySpacing_V       = 0.174;                     % Spacing between the subarrays in the vertical plane (m).
SubArraySpacing_H       = 0.044;

% Sectorization parameters
azSweepRangeSect        = [-60 , 60];                % Total azimuth range for all SSBs corresponding to a sectorized cell
elSweepRangeSect        = [0 90];                        % Total elevation range for all SSBs corresponding to a sectorized cell

% SSB information
CoarseConfSSbeams       = [3 , 3 , 2];                 % Coarse configuration of SSB with a given sector
elSweepCoarseSSB        = [6 , 0 , -3];                 % Elevation angle for each coarse of SSBs in a given plane

% Power information
Pt_dBm                  =  47;                       % Transmitter Pannel gain in dBm
Gr_dB                   =  0;                        % Receiver Pannel gain in dBm

% Results and plots
PlotAntElement          = 0;                         % One (1) activates the plot function for antenna element.
PlotAntArray            = 0;                         % One (1) activates the plot function for subarray, antenna array and pattern

%% %%%%%%%%%%%%%%%%%%%%%%%    Some displays     %%%%%%%%%%%%%%%%%%%%%%%%%%%%  
% Display the result for lambda
disp(['Carrier Frequency (GHz) = ', num2str(prm.CenterFreq/1e9), ' meters']);
disp(['Wavelength (lambda) = ', num2str(lambda), ' meters']);

%% %%%%%%%%%%%%%%%%%%%%%%%    Antenna Element   %%%%%%%%%%%%%%%%%%%%%%%%%%%%
antennaEleTx            = phased.NRAntennaElement('FrequencyRange',FreqBans,'Beamwidth',[HPBW_H HPBW_V],'PolarizationModel',2,'MaximumGain',AnElementGain);
%antenna                = phased.CrossedDipoleAntennaElement('FrequencyRange',FreqBans);
%antennaEleTx            = phased.OmnidirectionalMicrophoneElement('FrequencyRange',FreqBans,'BackBaffled',false);
%antenna                = phased.IsotropicAntennaElement('FrequencyRange',FreqBans,'BackBaffled',false);


% Calculate the transmit beam angles in azimuth and elevation for the antenna element respectively.
azBWAntennaEleTx        = beamwidth(antennaEleTx,prm.CenterFreq,'Cut','Azimuth');
elBWAntennaEleTx        = beamwidth(antennaEleTx,prm.CenterFreq,'Cut','Elevation');

if PlotAntElement == 1
    % 3D plot of power for antenna element (dB).
    %figure;
    %pattern(antennaEleTx,prm.CenterFreq,-180:180,-90:90,'PropagationSpeed',c,'CoordinateSystem','polar','Type','powerdB','ShowArray',true, 'Normalize',false);
    %title('Antenna Element')

    % 3D plot of directivity for antenna element (dBi).
    figure;
    pattern(antennaEleTx,prm.CenterFreq,-180:180,-90:90,'PropagationSpeed',c,'CoordinateSystem','polar','Type','directivity','ShowArray',true);
    title('Antenna Element')

    % Plot of half power beam width in the horizontal plane.
    figure;
    beamwidth(antennaEleTx,prm.CenterFreq,'Cut','Azimuth');

    % Plot of half power beam width in the vertical plane.
    figure;
    beamwidth(antennaEleTx,prm.CenterFreq,'Cut','Elevation');
end

% Calculate the maximum power.
[antennaPat,antennaAz,antennaEl] = pattern(antennaEleTx,prm.CenterFreq,-180:180,-90:90,'PropagationSpeed',c,'CoordinateSystem','polar','Type','powerdB','Normalize',false);
[Dim1 , Dim2]           = find(antennaPat == max(antennaPat,[],"all"));

%% %%%%%%%%%%%%%%%%%%%%%%% Antenna Array (pannel) %%%%%%%%%%%%%%%%%%%%%%%%%
% SubarrayTx              = phased.ULA(3,'ElementSpacing',AnElementSpacing_V,'Element',antennaEleTx,'ArrayAxis','z');
%
% arrayTx1                 = phased.ReplicatedSubarray('Subarray',SubarrayTx,'Layout','Rectangular','GridSize',[SubArrayRows SubArrayCols],'GridSpacing',[SubArraySpacing_V , AnElementSpacing_H],'SubarraySteering','Phase');
% figure
% viewArray(arrayTx1)
% figure;
% pattern(arrayTx1,prm.CenterFreq);


% arrayTx                 = phased.NRRectangularPanelArray('ElementSet',repmat({antennaEleTx},1,2),'Size',[SubArrayRows, SubArrayCols,SubArraySize],...
%     'Spacing',[AnElementSpacing_V,AnElementSpacing_H,2*SubArraySpacing_V,SubArraySpacing_H],'EnablePanelSubarray',true);
arrayTx                 = phased.NRRectangularPanelArray('ElementSet',repmat({antennaEleTx},1,2),'Size',[SubArraySize , SubArrayRows, SubArrayCols],...
    'Spacing',[AnElementSpacing_V,AnElementSpacing_H,SubArraySpacing_V,SubArraySpacing_H]);
%pattern(arrayTx1,prm.CenterFreq,'ElementWeights',ones(3,64));
% figure;
% pattern(arrayTx,prm.CenterFreq);
%figure
%viewArray(arrayTx)


if PlotAntArray == 1
    % Plot the subarray
    figure;
    viewArray(SubarrayTx,'Title','Subarray');

    % Plot the antenna array
    figure;
    viewArray(arrayTx,'Title','Panel');

    % Plot the antenna pattern
    figure;
    pattern(arrayTx,prm.CenterFreq,-180:180,-90:90,'PropagationSpeed',c,'CoordinateSystem','polar','Type','powerdB','Normalize',false,'ShowArray',true);

    % Plot of half power beam width in the horizontal plane.
    figure;
    beamwidth(arrayTx,prm.CenterFreq,'Cut','Azimuth');

    % Plot of half power beam width in the vertical plane.
    figure;
    beamwidth(arrayTx,prm.CenterFreq,'Cut','Elevation');
end

%% %%%% Evaluating transmit-side steering weights of the antenna array %%%%

%SteerVecTx_Array        = phased.SteeringVector('SensorArray',arrayTx,'PropagationSpeed',c);
SteerVecTx_Array         = phased.SteeringVector('SensorArray',arrayTx,'PropagationSpeed',c,'IncludeElementResponse',true);


%% %%%%%%%%%%%%%%%%% SSB : Transmit-End Beam Sweeping   %%%%%%%%%%%%%%%%%%%%%%
% Based on the number of SS blocks in the burst and the sweep ranges specified, determine both the
% azimuth and elevation directions for the different beams. Then beamform the individual blocks
% within the burst to each of these directions.

numSSbeams                  = sum(CoarseConfSSbeams);                                % Number of SSB


%% Calculate the steering for each SSB 
[azSSB.sweepBW , azSSB.steerAngleMat , azSSB.steerAngle, elSSB.steerAngle , elSSB.steerAngleMat]  = azPlainSSBsteerAngle(azSweepRangeSect,CoarseConfSSbeams,elSweepCoarseSSB);


%% Design the map between the Antenna Ports and Antenna Elements to the Antenna Panel

NumAntElements   = getNumElements(arrayTx);
ElementPossition = getElementPosition(arrayTx).';

% Create an array of weights (initially all ones)
weights = ones(NumAntElements, 1);

numActiveAntElements      = NumAntElements/numSSbeams;

ActiveAntElementIndx      = [];
for ia=1:numSSbeams
    ActiveAntElementIndx  = [ActiveAntElementIndx ; numActiveAntElements*(ia-1)+1:numActiveAntElements*ia];
end

SubArray_No_AntennaElements   = 2*prod(SubArraySize);
numActiveAntElements_Row      = SubArrayRows*SubArray_No_AntennaElements;

for subcol = 1:SubArrayCols
    ReshapeElePoss{subcol} = ElementPossition(numActiveAntElements_Row*(subcol-1)+1:numActiveAntElements_Row*subcol,:);
end


ColElementSingle   = SubArrayRows*SubArraySize(1,1);

for subcol = 1:SubArrayCols
    IndexCol  = [24*(subcol-1)+1:24*subcol];
    ReIndexCol = reshape(IndexCol,[ColElementSingle,2]);
    ReIndexCol = [ReIndexCol(:,1),flip(ReIndexCol(:,2))];

    IndexRow = [];
    for subrow = 1:SubArrayRows
        TempMatrix = zeros(NumAntElements,1);
        CSIRSPortIndex{subrow,subcol} = ReIndexCol(3*(subrow-1)+1:3*subrow,:);
        TempMatrix(reshape(ReIndexCol(3*(subrow-1)+1:3*subrow,:),[1,SubArray_No_AntennaElements])) = 1;
        CSIRSPortWeightMatrix{subrow,subcol} = TempMatrix;
        WeightDipol        = find(TempMatrix == 1);
        CSIRSPortWeightIndexMatrixPol1        = WeightDipol(1:3);
        CSIRSPortWeightIndexMatrixPol2        = WeightDipol(4:6);
        CSIRSPortWeightIndexMatrixPol{subrow,subcol,1} = CSIRSPortWeightIndexMatrixPol1;
        CSIRSPortWeightIndexMatrixPol{subrow,subcol,2} = CSIRSPortWeightIndexMatrixPol2;
    end
end


%% Calculate the PMI matrix

% Supported panel configurations and oversampling factors, as defined in TS 38.214 Table 5.2.2.2.1-2

panelConfigs = [2     2     4     3     6     4     8     4     6    12     4     8    16   % N1

1     2     1     2     1     2     1     3     2     1     4     2     1   % N2

4     4     4     4     4     4     4     4     4     4     4     4     4   % O1

1     4     1     4     1     4     1     4     4     1     4     4     1]; % O2


% Find avaliable options for the number of Antenna Ports
AntPortOpt = panelConfigs(1,:).*panelConfigs(2,:)*2;
disp(['The avaliable options for the number of Antenna Ports are:']);
AntPortOpt

% The avaliable (N1,N2) pairs are as 
N1N2Pairs  = panelConfigs(1:2,:);
for viv = 1:size(N1N2Pairs,2)
    N1N2PairsArr{viv} = N1N2Pairs(:,viv).';
end
disp(['The avaliable (N1,N2) pairs are as:']);
N1N2PairsArr
% of (N1, N2) pair for a given number of ports

FindN1N2 = input('Enter the location of the desired (N1,N2) pair: ');


%FindN1N2 = randi([1,size(panelConfigs,2)],1,1);
%FindN1N2 = 13;

% Panel dimensions in terms of antenna ports
N1       = panelConfigs(1,FindN1N2); 
N2       = panelConfigs(2,FindN1N2); 

% Number of layers
nLayers = 2;

% PMI matrix parameters
reportConfig.NStartBWP          = 0;
reportConfig.NSizeBWP           = 52;
reportConfig.PanelDimensions = [N1 N2];
reportConfig.CQIMode            = 'Wideband';
reportConfig.PMIMode            = 'Wideband';
reportConfig.SubbandSize        = 1;
reportConfig.PRGSize            = [];
reportConfig.CodebookMode       = 2;
reportConfig.CodebookSubsetRestriction = [];
reportConfig.i2Restriction      = [];


configIdx = find(panelConfigs(1,:) == N1 & panelConfigs(2,:) == N2,1);
% Extract the oversampling factors

O1                                  = panelConfigs(3,configIdx);
O2                                  = panelConfigs(4,configIdx);
reportConfig.PanelDimensions        = [N1 N2];
reportConfig.OverSamplingFactors    = [O1 O2];
[i2_length, i11_length, i12_length, i13_length, W_PMI] = getPMIType1SinglePanelCodebook(reportConfig,nLayers);


%% %%%%%%%%%%%%%%%%%%%%% Run Simulation (Monte Carlo) %%%%%%%%%%%%%%%%%%%%%%%%%
numActiveSSBs       = 1;

ContTempPMI         = 5;
% All possible combinations of the SSB configurations
SSB_Active_Mat      = nchoosek([1:numSSbeams],numActiveSSBs);              % Each row shows a possible combination of k SSBs being active simultaneously


%Pt_dB               = Pt_dBm - 30;                                         % Power in dB
Pt_watts            = 10^((Pt_dBm - 30)/10);                                       % Power in Watt 

EIRP_AzEl_Sum_Mat    = [];
EIRP_PhiTheta_Sum_Mat= [];

% Active all the possible combiantions for k (numActiveSSBs) SSBs being simultaneously
% active
for SSBcomb = 1:size(SSB_Active_Mat,1)
    SSBcomb

    % NOTE: Generate the same number of steering angels as the SSB number.
    %ActiveSSB           = randi([1 numSSbeams],1,numActiveSSBs);
    ActiveSSB           = SSB_Active_Mat(SSBcomb,:);

    for inssbcomb = 1:size(ActiveSSB,2)
        txSteerAng_SSB      = [azSSB.steerAngleMat(ActiveSSB(inssbcomb));elSSB.steerAngleMat(ActiveSSB(inssbcomb))];

        % Generate weights for steered direction
        gNB_WT_SSB          = SteerVecTx_Array(prm.CenterFreq,txSteerAng_SSB);

        [ResultElAz_SSB_dB AngelAxisAzAll_SSB AngleAxisElAll_SSB] = pattern(arrayTx,prm.CenterFreq,-180:180,-90:90,'CoordinateSystem','rectangular','PropagationSpeed',c,'Type','powerdb','Weights',gNB_WT_SSB,'Normalize',true);

        ResultElAz_SSB           = 10.^(ResultElAz_SSB_dB./10);                    % Convert to linear domain
        
        % Calculate Received Power per SSB
        EIRP_AzEl_Sum_All_SSB(:,:,(SSBcomb-1)*size(ActiveSSB,2)+inssbcomb)        = Pt_watts*ResultElAz_SSB;

        %% Get the PMI vector
        
        %for ssbpmi = 1:prod(size(W_PMI))
        
        for ssbpmi = 1:ContTempPMI

            ssbpmi
            [Weight_PMI_Layer idx_PMI] = Get_Rand_PMI_Matrix(W_PMI);           % Select a random PMI matrix from the table given nLayers

            [FinalMatrix] = MapPMI2AntennaPorts(Weight_PMI_Layer,CSIRSPortWeightMatrix,nLayers,CSIRSPortWeightIndexMatrixPol);
            [ResultAzEl_SSB_PMI_dB AngelAxisPhiAll_SSB AngleAxisThetaAll_SSB] = pattern(arrayTx,prm.CenterFreq,-180:180,-90:90,'CoordinateSystem','polar','PropagationSpeed',c,'Type','powerdb','Weights',gNB_WT_SSB.*FinalMatrix,'Normalize',true);

            ResultAzEl_SSB_PMI       = 10.^(ResultAzEl_SSB_PMI_dB./10);    % This is converted to watt scale 

            EIRP_AzEl_Sum_all_SSBcomb_all_PMI(:,:,(inssbcomb-1)*ContTempPMI+ssbpmi)    =  Pt_watts/nLayers*ResultAzEl_SSB_PMI; % The result is in watt scale
        end
        EIRP_AzEl_Sum_all_SSB_all_PMI_Cell{SSBcomb} = EIRP_AzEl_Sum_all_SSBcomb_all_PMI;
    end
end

% [ElAzPlaneEl , ElAzPlaneAz]                   = find(ResultElAz_dB == max(ResultElAz_dB,[],"all"));
% [PhiThetaPlaneTheta , PhiThetaPlanePhi]       = find(ResultPhiTheta_dB == max(ResultPhiTheta_dB,[],"all"));

% figure;
% H=surf(AngelAxisAzAll_SSB,AngleAxisElAll_SSB,ResultElAz_SSB_dB);
% H.LineStyle = 'none';
% H.FaceAlpha = 1; hold on;


%% Generate the for all SSBs only 

EIRP_AzEl_all_SSB_dB     = 10*log10(mean(EIRP_AzEl_Sum_All_SSB,3));

ElAxis = [];
AzAxis = [];
SSBcombPower = [];
for iii = 1:size(EIRP_AzEl_all_SSB_dB,1)
    for ici = 1:size(EIRP_AzEl_all_SSB_dB,2)
        ElAxis = [ElAxis ; iii];
        AzAxis = [AzAxis ; ici];
        SSBcombPower = [SSBcombPower ; EIRP_AzEl_all_SSB_dB(iii,ici)];
    end
end

figure
patternCustom(flipud(SSBcombPower),(ElAxis),AzAxis);

%% Generate the plots per SSB combination fixed and all PMIs

for SSBcomb = 1:size(SSB_Active_Mat)
    EIRP_AzEl_fixed_SSB_all_PMI_dB = 10*log10(mean(EIRP_AzEl_Sum_all_SSB_all_PMI_Cell{SSBcomb},3));

    Fixed_SSBcomb_PMI_Power = [];
    for iii = 1:size(EIRP_AzEl_fixed_SSB_all_PMI_dB,1)
        for ici = 1:size(EIRP_AzEl_fixed_SSB_all_PMI_dB,2)

            Fixed_SSBcomb_PMI_Power = [Fixed_SSBcomb_PMI_Power ; EIRP_AzEl_fixed_SSB_all_PMI_dB(iii,ici)];
        end
    end
    EIRP_AzEl_fixed_all_SSB_all_PMI(:,:,SSBcomb) = mean(EIRP_AzEl_Sum_all_SSB_all_PMI_Cell{SSBcomb},3);
    figure
    patternCustom(flipud(Fixed_SSBcomb_PMI_Power),ElAxis,AzAxis);
end

%% Generate the code for all SSBs and PMIs 
All_it  = mean(EIRP_AzEl_fixed_all_SSB_all_PMI,3);           % This power is in watts

EIRP_AzEl_fixed_all_SSB_all_PMI_db     = 10*log10(mean(EIRP_AzEl_fixed_all_SSB_all_PMI,3));

all_SSBcomb_all_PMI_Power = [];
for iii = 1:size(EIRP_AzEl_fixed_all_SSB_all_PMI_db,1)
    for ici = 1:size(EIRP_AzEl_fixed_all_SSB_all_PMI_db,2)
        all_SSBcomb_all_PMI_Power = [all_SSBcomb_all_PMI_Power ; EIRP_AzEl_fixed_all_SSB_all_PMI_db(iii,ici)];
    end
end

figure
patternCustom(flipud(all_SSBcomb_all_PMI_Power),(ElAxis),AzAxis);

%% Calculate the received energy at any given point in space [x, y, z] (unity of distance is in meters)

X_Dim = [-100:20:100];
Y_Dim = [-100:20:100];
Z_Dim = [-100:20:100];

DimSSB  = 1;

for ix = 1:size(X_Dim,2)
    for iy = 1:size(Y_Dim,2)
        for iz = 1:size(Z_Dim,2)

            posRefPOINT         = [X_Dim(ix); Y_Dim(iy); Z_Dim(iz)];
            posgNB              = [0;0;0];                                     % Transmit array position, [x;y;z], meters

            % Calculate the distance between the gNB and any point in space [x,y,z] 
            %gNB_RefP_Distance       = sqrt((posRefPOINT(1)-posgNB(1)).^2 + (posRefPOINT(2)-posgNB(2)).^2 + (posRefPOINT(3)-posgNB(3)).^2);   % Distnace between Tx and Rx

            [RefPOINTazimuth,RefPOINTelevation,gNB_RefP_Distance]   = cart2sph(posRefPOINT(1)-posgNB(1),posRefPOINT(2)-posgNB(2),posRefPOINT(3)-posgNB(3));       % Azimuth and Elevation between Tx and Rx coordinates

            RefPOINT_AngleCheck     = [floor(rad2deg(RefPOINTazimuth)) , floor(rad2deg(RefPOINTelevation))];                                            % Select the angle pair of interest

            %% Calculate Received Power

            TempPower           = All_it(find(AngleAxisElAll_SSB == RefPOINT_AngleCheck(2)), find(AngelAxisAzAll_SSB == RefPOINT_AngleCheck(1)),DimSSB)            % Received power (Friis equation)
            
            % Calculate the received power at [x,y,z] coordinate
            Pr_at_XYZ(ix,iy,iz) = (TempPower*lambda^2) ./ (4*pi*gNB_RefP_Distance).^2;        % Fee space model of propagation, and this power calculation is in watts

            % Display the result
            %fprintf('Received Power at %.2f meters: %.2f dBm\n', r, Pr);
        end
    end
end

Pr_at_XYZ_dBm = 10*log10(Pr_at_XYZ*1000);                                   % This calculation is in mili-watts

figure;
for ix = 1:size(X_Dim,2)
    for iy = 1:size(Y_Dim,2)
        for iz = 1:size(Z_Dim,2)
            x = X_Dim(ix);  % Random x values
            y = Y_Dim(iy);  % Random y values
            z = Z_Dim(iz);  % Random z values
            value = Pr_at_XYZ_dBm(ix,6,iz);  % Scalar values (can be temperature, intensity, etc.)
            scatter3(x, y, z, 10, value, 'filled','MarkerFaceColor','flat');  hold on % 3D scatter plot
        end
    end
end
colorbar;  % Colorbar to show value scale
colormap(jet);

title('3D Heatmap of Scalar Values');
xlabel('X');
ylabel('Y');
zlabel('Z');
% Optional: Adjust axis limits for better visualization
axis equal;  % Equal scaling for x, y, and z axes
xlim([-120 120]);
ylim([-120 120]);
zlim([-120 120]);


% figure;
% for iiv = 1:size(UE_EleAngle,2)
%     [CDFResults GenResults]             = cdfplot(XYZ_Coord_Save(iiv,:));
%     set(CDFResults,'LineWidth',1,'DisplayName',strcat(' Md: ',int2str(GenResults.median),' (dBm)',' [Az, El, R]:',', [',int2str(ForPlot(:,iiv).'),']')); grid on;
%     xlabel('Gain (dBm)'); ylabel('CDF');title(' ');%title(strcat('Distance',' ',int2str(MaxCoordinate(iiv)),' ','m'));
%     fig = gcf; fig.Position = [500 300 420 360];
%     set(gca,'TickLabelInterpreter','latex');
%     legend(Location="best"); hold on
% end


% figure;
% [CDFResults GenResults]             = cdfplot(PrSaveSSB);
% set(CDFResults,'LineWidth',1,'DisplayName',strcat(' Md: ',int2str(GenResults.median),' (dBm)')); grid on;
% xlabel('Gain (dBm)'); ylabel('CDF');title(' ');%title(strcat('Distance',' ',int2str(MaxCoordinate(iiv)),' ','m'));
% fig = gcf; fig.Position = [500 300 420 360];
% set(gca,'TickLabelInterpreter','latex');
% legend(Location="best"); hold on
%
%
% figure;
% [CDFResults GenResults]             = cdfplot(DirectivitySaveSSB);
% set(CDFResults,'LineWidth',1,'DisplayName',strcat(' Md: ',int2str(GenResults.median),' (dBm)')); grid on;
% xlabel('Gain (dBm)'); ylabel('CDF');title(' ');%title(strcat('Distance',' ',int2str(MaxCoordinate(iiv)),' ','m'));
% fig = gcf; fig.Position = [500 300 420 360];
% set(gca,'TickLabelInterpreter','latex');
% legend(Location="best"); hold on


%% %%%%%%%%%%%%%%%%%%%%%%% This is the section of used fuctions for the simulation %%%%%%%%%%%%%%%%%%%%%%%%%%%

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


function [Output1 Output2 Output3] = Get_Rand_PMI_Matrix(W_PMI)

dims     = size(W_PMI);
numDims  = length(dims);
idx_PMI  = repmat({':'},1,numDims);

ComCheck = dims(3:end);
for iv = 1:length(ComCheck)
    ACAC{iv} = [1:ComCheck(iv)];
end

All_PMI_Matrix_Comb = table2array(combinations(ACAC{:}));

random_PMI = randi([1, size(All_PMI_Matrix_Comb,1)], 1, 1);

xcx = 1;
while xcx <= length(ComCheck)
    idx_PMI{2+xcx} = All_PMI_Matrix_Comb(random_PMI,xcx);
    xcx = xcx + 1;
end

%Weight_PMI_Layer   = W_PMI(:,:,6,1,1,1,1);
Output1   = W_PMI(idx_PMI{:});
Output2   = idx_PMI;
Output3   = All_PMI_Matrix_Comb;
end


function [Output1] = MapPMI2AntennaPorts(Weight_PMI_Layer,CSIRSPortWeightMatrix,nLayers,CSIRSPortWeightIndexMatrixPol)
if nLayers == 1;
    FinalMatrix  = zeros(192,1);
    ixi          = 1;
    NoCSIRSports = 32;
    for csi2 = 1:size(CSIRSPortWeightMatrix,2)
        for csi1 = 1:size(CSIRSPortWeightMatrix,1)
            FinalMatrix = FinalMatrix + CSIRSPortWeightMatrix{csi1,csi2}*Weight_PMI_Layer(ixi,:);
            ixi  = ixi + 1;
        end
    end

else
    FinalMatrix  = zeros(192,1);
    ixi          = 1;
    NoCSIRSports = 32;
    for csi2 = 1:size(CSIRSPortWeightMatrix,2)
        for csi1 = 1:size(CSIRSPortWeightMatrix,1)
            CheckMat = CSIRSPortWeightMatrix{csi1,csi2};
            CheckMat(CSIRSPortWeightIndexMatrixPol{csi1,csi2,1}) = CheckMat(CSIRSPortWeightIndexMatrixPol{csi1,csi2,1})*Weight_PMI_Layer(ixi,1);
            CheckMat(CSIRSPortWeightIndexMatrixPol{csi1,csi2,2}) = CheckMat(CSIRSPortWeightIndexMatrixPol{csi1,csi2,2})*Weight_PMI_Layer(ixi,2);
            FinalMatrix  = FinalMatrix + CheckMat;
            ixi  = ixi + 1;
        end
    end

end
Output1 = FinalMatrix;
end

function [x, y, z] = azimuth_elevation_to_xyz(elevation, azimuth, r)
% Convert elevation and azimuth angles to radians
elevation = deg2rad(elevation); % Elevation angle in radians
azimuth = deg2rad(azimuth);     % Azimuth angle in radians

% Compute the Cartesian coordinates
x = r * cos(elevation) * sin(azimuth);
y = r * sin(elevation) * sin(azimuth);
z = r * cos(elevation);
end


function [i2_length, i11_length, i12_length, i13_length,  codebook] = getPMIType1SinglePanelCodebook(reportConfig,nLayers)
%   CODEBOOK = getPMIType1SinglePanelCodebook(REPORTCONFIG,NLAYERS) returns
%   a codebook CODEBOOK containing type I single-panel precoding matrices,
%   as defined in TS 38.214 Tables 5.2.2.2.1-1 to 5.2.2.2.1-12 by
%   considering these inputs:
%
%   REPORTCONFIG is a CSI reporting configuration structure with these
%   fields:
%   PanelDimensions            - Antenna panel configuration as a
%                                two-element vector ([N1 N2]). It is
%                                not applicable for CSI-RS ports less
%                                than or equal to 2
%   OverSamplingFactors        - DFT oversampling factors corresponding to
%                                the panel configuration
%   CodebookMode               - Codebook mode. Applicable only when the
%                                number of MIMO layers is 1 or 2 and
%                                number of CSI-RS ports is greater than 2
%   CodebookSubsetRestriction  - Binary vector for vlm or vbarlm restriction
%   i2Restriction              - Binary vector for i2 restriction
%
%   NLAYERS      - Number of transmission layers
%
%   CODEBOOK     - Multidimensional array containing unrestricted type I
%                  single-panel precoding matrices. It is of size
%                  Pcsirs-by-nLayers-by-i2Length-by-i11Length-by-i12Length-by-i13Length
%
%   Note that the restricted precoding matrices are returned as all zeros.
i2_length                 =[];
i13_length                =[];
i11_length                =[];
i12_length                =[];

panelDimensions           = reportConfig.PanelDimensions;
codebookMode              = reportConfig.CodebookMode;
codebookSubsetRestriction = reportConfig.CodebookSubsetRestriction;
i2Restriction             = reportConfig.i2Restriction;

% Create a function handle to compute the co-phasing factor value
% according to TS 38.214 Section 5.2.2.2.1, considering the co-phasing
% factor index
phi = @(x)exp(1i*pi*x/2);

% Get the number of CSI-RS ports using the panel dimensions
Pcsirs = 2*panelDimensions(1)*panelDimensions(2);
if Pcsirs == 2
    % Codebooks for 1-layer and 2-layer CSI reporting using antenna
    % ports 3000 to 3001, as defined in TS 38.214 Table 5.2.2.2.1-1
    if nLayers == 1
        codebook(:,:,1) = 1/sqrt(2).*[1; 1];
        codebook(:,:,2) = 1/sqrt(2).*[1; 1i];
        codebook(:,:,3) = 1/sqrt(2).*[1; -1];
        codebook(:,:,4) = 1/sqrt(2).*[1; -1i];
        restrictedIndices = find(~codebookSubsetRestriction);
        restrictedIndices = restrictedIndices(restrictedIndices <= 4);
        if ~isempty(restrictedIndices)
            restrictedSet = logical(sum(restrictedIndices == [1;2;3;4],2));
            codebook(:,:,restrictedSet) = 0;
        end
    elseif nLayers == 2
        codebook(:,:,1) = 1/2*[1 1;1 -1];
        codebook(:,:,2) = 1/2*[1 1; 1i -1i];
        restrictedIndices = find(~codebookSubsetRestriction);
        restrictedIndices = restrictedIndices(restrictedIndices > 4);
        if ~isempty(restrictedIndices)
            restrictedSet = logical(sum(restrictedIndices == [5;6],2));
            codebook(:,:,restrictedSet) = 0;
        end
    end
elseif Pcsirs > 2

    N1 = panelDimensions(1);
    N2 = panelDimensions(2);
    O1 = reportConfig.OverSamplingFactors(1);
    O2 = reportConfig.OverSamplingFactors(2);
    % Select the codebook based on the number of layers, panel
    % configuration, and the codebook mode

    switch nLayers
        case 1 % Number of layers is 1
            % Codebooks for 1-layer CSI reporting using antenna ports
            % 3000 to 2999+P_CSIRS, as defined in TS 38.214 Table
            % 5.2.2.2.1-5
            if codebookMode == 1
                i11_length = N1*O1;
                i12_length = N2*O2;
                i2_length  = 4;
                codebook   = zeros(Pcsirs,nLayers,i2_length,i11_length,i12_length);
                % Loop over all the values of i11, i12, and i2
                for i11 = 0:i11_length-1
                    for i12 = 0:i12_length-1
                        for i2 = 0:i2_length-1
                            l = i11;
                            m = i12;
                            n = i2;
                            bitIndex = N2*O2*l+m;
                            [lmRestricted,i2Restricted] = isRestricted(codebookSubsetRestriction,bitIndex,i2,i2Restriction);
                            if ~(lmRestricted || i2Restricted)
                                vlm = getVlm(N1,N2,O1,O2,l,m);
                                phi_n = phi(n);
                                codebook(:,:,i2+1,i11+1,i12+1) = (1/sqrt(Pcsirs))*[vlm ;...
                                    phi_n*vlm];
                            end
                        end
                    end
                end
            else % codebookMode == 2
                i11_length = N1*O1/2;
                i12_length = N2*O2/2;
                if N2 == 1
                    i12_length = 1;
                end
                i2_length = 16;
                codebook = zeros(Pcsirs,nLayers,i2_length,i11_length,i12_length);
                % Loop over all the values of i11, i12, and i2
                for i11 = 0:i11_length-1
                    for i12 = 0:i12_length-1
                        for i2 = 0:i2_length-1
                            floor_i2by4 = floor(i2/4);
                            if N2 == 1
                                l = 2*i11 + floor_i2by4;
                                m = 0;
                            else % N2 > 1
                                lmAddVals = [0 0; 1 0; 0 1;1 1];
                                l = 2*i11 + lmAddVals(floor_i2by4+1,1);
                                m = 2*i12 + lmAddVals(floor_i2by4+1,2);
                            end
                            n = mod(i2,4);
                            bitIndex = N2*O2*l+m;
                            [lmRestricted,i2Restricted] = isRestricted(codebookSubsetRestriction,bitIndex,i2,i2Restriction);
                            if ~(lmRestricted || i2Restricted)
                                vlm = getVlm(N1,N2,O1,O2,l,m);
                                phi_n = phi(n);
                                codebook(:,:,i2+1,i11+1,i12+1) = (1/sqrt(Pcsirs))*[vlm;...
                                    phi_n*vlm];
                            end
                        end
                    end
                end
            end

        case 2 % Number of layers is 2
            % Codebooks for 2-layer CSI reporting using antenna ports
            % 3000 to 2999+P_CSIRS, as defined in TS 38.214 Table
            % 5.2.2.2.1-6

            % Compute i13 parameter range and corresponding k1 and k2,
            % as defined in TS 38.214 Table 5.2.2.2.1-3
            if (N1 > N2) && (N2 > 1)
                i13_length = 4;
                k1 = [0 O1 0 2*O1];
                k2 = [0 0 O2 0];
            elseif N1 == N2
                i13_length = 4;
                k1 = [0 O1 0 O1];
                k2 = [0 0 O2 O2];
            elseif (N1 == 2) && (N2 == 1)
                i13_length = 2;
                k1 = O1*(0:1);
                k2 = [0 0];
            else
                i13_length = 4;
                k1 = O1*(0:3);
                k2 = [0 0 0 0] ;
            end

            if codebookMode == 1 % This is Table 5.2.2.2.1-6
                i11_length = N1*O1;
                i12_length = N2*O2;
                i2_length  =  2;
                codebook   = zeros(Pcsirs,nLayers,i2_length,i11_length,i12_length,i13_length);
                % Loop over all the values of i11, i12, i13, and i2
                for i11 = 0:i11_length-1
                    for i12 = 0:i12_length-1
                        for i13 = 0:i13_length-1
                            for i2 = 0:i2_length-1 % Here we need to calculate W^(2) formula ...
                                l = i11;
                                m = i12;
                                n = i2;
                                lPrime = i11+k1(i13+1);
                                mPrime = i12+k2(i13+1);
                                bitIndex = N2*O2*l+m;
                                [lmRestricted,i2Restricted] = isRestricted(codebookSubsetRestriction,bitIndex,i2,i2Restriction);
                                if ~(lmRestricted || i2Restricted)
                                    vlm = getVlm(N1,N2,O1,O2,l,m);
                                    vlPrime_mPrime = getVlm(N1,N2,O1,O2,lPrime,mPrime);
                                    phi_n = phi(n);
                                    codebook(:,:,i2+1,i11+1,i12+1,i13+1) = ...
                                        (1/sqrt(2*Pcsirs))*[vlm        vlPrime_mPrime;...
                                        phi_n*vlm  -phi_n*vlPrime_mPrime];
                                end
                            end
                        end
                    end
                end
            else % codebookMode == 2
                i11_length = N1*O1/2;
                if N2 == 1
                    i12_length = 1;
                else
                    i12_length = N2*O2/2;
                end
                i2_length = 8;
                codebook = zeros(Pcsirs,nLayers,i2_length,i11_length,i12_length,i13_length);
                % Loop over all the values of i11, i12, i13, and i2
                for i11 = 0:i11_length-1
                    for i12 = 0:i12_length-1
                        for i13 = 0:i13_length-1
                            for i2 = 0:i2_length-1
                                floor_i2by2 = floor(i2/2);
                                if N2 == 1
                                    l = 2*i11 + floor_i2by2;
                                    lPrime = 2*i11 + floor_i2by2 + k1(i13+1);
                                    m = 0;
                                    mPrime = 0;
                                else % N2 > 1
                                    lmAddVals = [0 0; 1 0; 0 1;1 1];
                                    l = 2*i11 + lmAddVals(floor_i2by2+1,1);
                                    lPrime =  2*i11 + k1(i13+1) + lmAddVals(floor_i2by2+1,1);
                                    m = 2*i12 + lmAddVals(floor_i2by2+1,2);
                                    mPrime =  2*i12 + k2(i13+1) + lmAddVals(floor_i2by2+1,2);
                                end
                                n = mod(i2,2);
                                bitIndex = N2*O2*l+m;
                                [lmRestricted,i2Restricted] = isRestricted(codebookSubsetRestriction,bitIndex,i2,i2Restriction);
                                if ~(lmRestricted || i2Restricted)
                                    vlm = getVlm(N1,N2,O1,O2,l,m);
                                    vlPrime_mPrime = getVlm(N1,N2,O1,O2,lPrime,mPrime);
                                    phi_n = phi(n);
                                    codebook(:,:,i2+1,i11+1,i12+1,i13+1) = ...
                                        (1/sqrt(2*Pcsirs))*[vlm        vlPrime_mPrime;...
                                        phi_n*vlm  -phi_n*vlPrime_mPrime];
                                end
                            end
                        end
                    end
                end
            end

        case {3,4} % Number of layers is 3 or 4
            if (Pcsirs < 16)
                % For the number of CSI-RS ports less than 16, compute
                % i13 parameter range, corresponding k1 and k2,
                % according to TS 38.214 Table 5.2.2.2.1-4
                if (N1 == 2) && (N2 == 1)
                    i13_length = 1;
                    k1 = O1;
                    k2 = 0;
                elseif (N1 == 4) && (N2 == 1)
                    i13_length = 3;
                    k1 = O1*(1:3);
                    k2 = [0 0 0];
                elseif (N1 == 6) && (N2 == 1)
                    i13_length = 4;
                    k1 = O1*(1:4);
                    k2 = [0 0 0 0];
                elseif (N1 == 2) && (N2 == 2)
                    i13_length = 3;
                    k1 = [O1 0 O1];
                    k2 = [0 O2 O2];
                elseif (N1 == 3) && (N2 == 2)
                    i13_length = 4;
                    k1 = [O1 0 O1 2*O1];
                    k2 = [0 O2 O2 0];
                end

                % For 3 and 4 layers the procedure for computation of W
                % is same, other than the dimensions of W. Compute W
                % for either case accordingly
                i11_length = N1*O1;
                i12_length = N2*O2;
                i2_length = 2;
                codebook = zeros(Pcsirs,nLayers,i2_length,i11_length,i12_length,i13_length);
                % Loop over all the values of i11, i12, i13, and i2
                for i11 = 0:i11_length-1
                    for i12 = 0:i12_length-1
                        for i13 = 0:i13_length-1
                            for i2 = 0:i2_length-1
                                l = i11;
                                lPrime = i11+k1(i13+1);
                                m = i12;
                                mPrime = i12+k2(i13+1);
                                n = i2;
                                bitIndex = N2*O2*l+m;
                                [lmRestricted,i2Restricted] = isRestricted(codebookSubsetRestriction,bitIndex,i2,i2Restriction);
                                if ~(lmRestricted || i2Restricted)
                                    vlm = getVlm(N1,N2,O1,O2,l,m);
                                    vlPrime_mPrime = getVlm(N1,N2,O1,O2,lPrime,mPrime);
                                    phi_n = phi(n);
                                    phi_vlm = phi_n*vlm;
                                    phi_vlPrime_mPrime = phi_n*vlPrime_mPrime;
                                    if nLayers == 3
                                        % Codebook for 3-layer CSI
                                        % reporting using antenna ports
                                        % 3000 to 2999+P_CSIRS, as
                                        % defined in TS 38.214 Table
                                        % 5.2.2.2.1-7
                                        codebook(:,:,i2+1,i11+1,i12+1,i13+1) = ...
                                            (1/sqrt(3*Pcsirs))*[vlm      vlPrime_mPrime      vlm;...
                                            phi_vlm  phi_vlPrime_mPrime  -phi_vlm];
                                    else
                                        % Codebook for 4-layer CSI
                                        % reporting using antenna ports
                                        % 3000 to 2999+P_CSIRS, as
                                        % defined in TS 38.214 Table
                                        % 5.2.2.2.1-8
                                        codebook(:,:,i2+1,i11+1,i12+1,i13+1) = ...
                                            (1/sqrt(4*Pcsirs))*[vlm      vlPrime_mPrime      vlm       vlPrime_mPrime;...
                                            phi_vlm  phi_vlPrime_mPrime  -phi_vlm  -phi_vlPrime_mPrime];
                                    end
                                end
                            end
                        end
                    end
                end
            else % Number of CSI-RS ports is greater than or equal to 16
                i11_length = N1*O1/2;
                i12_length = N2*O2;
                i13_length = 4;
                i2_length = 2;
                codebook = zeros(Pcsirs,nLayers,i2_length,i11_length,i12_length,i13_length);
                % Loop over all the values of i11, i12, i13, and i2
                for i11 = 0:i11_length-1
                    for i12 = 0:i12_length-1
                        for i13 = 0:i13_length-1
                            for i2 = 0:i2_length-1
                                theta = exp(1i*pi*i13/4);
                                l = i11;
                                m = i12;
                                n = i2;
                                phi_n = phi(n);
                                bitValues = [mod(N2*O2*(2*l-1)+m,N1*O1*N2*O2), N2*O2*(2*l)+m, N2*O2*(2*l+1)+m];
                                [lmRestricted,i2Restricted] = isRestricted(codebookSubsetRestriction,bitValues,i2,i2Restriction);
                                if ~(lmRestricted || i2Restricted)
                                    vbarlm = getVbarlm(N1,N2,O1,O2,l,m);
                                    theta_vbarlm = theta*vbarlm;
                                    phi_vbarlm = phi_n*vbarlm;
                                    phi_theta_vbarlm = phi_n*theta*vbarlm;
                                    if nLayers == 3
                                        % Codebook for 3-layer CSI
                                        % reporting using antenna ports
                                        % 3000 to 2999+P_CSIRS, as
                                        % defined in TS 38.214 Table
                                        % 5.2.2.2.1-7
                                        codebook(:,:,i2+1,i11+1,i12+1,i13+1) = ...
                                            (1/sqrt(3*Pcsirs))*[vbarlm            vbarlm             vbarlm;...
                                            theta_vbarlm      -theta_vbarlm      theta_vbarlm;...
                                            phi_vbarlm        phi_vbarlm         -phi_vbarlm;...
                                            phi_theta_vbarlm  -phi_theta_vbarlm  -phi_theta_vbarlm];
                                    else
                                        % Codebook for 4-layer CSI
                                        % reporting using antenna ports
                                        % 3000 to 2999+P_CSIRS, as
                                        % defined in TS 38.214 Table
                                        % 5.2.2.2.1-8
                                        codebook(:,:,i2+1,i11+1,i12+1,i13+1) = ...
                                            (1/sqrt(4*Pcsirs))*[vbarlm            vbarlm             vbarlm             vbarlm;...
                                            theta_vbarlm      -theta_vbarlm      theta_vbarlm       -theta_vbarlm;...
                                            phi_vbarlm        phi_vbarlm         -phi_vbarlm        -phi_vbarlm;...
                                            phi_theta_vbarlm  -phi_theta_vbarlm  -phi_theta_vbarlm  phi_theta_vbarlm];
                                    end
                                end
                            end
                        end
                    end
                end
            end

        case {5,6} % Number of layers is 5 or 6
            i11_length = N1*O1;
            if N2 == 1
                i12_length = 1;
            else % N2 > 1
                i12_length = N2*O2;
            end
            i2_length = 2;
            codebook = zeros(Pcsirs,nLayers,i2_length,i11_length,i12_length);
            % Loop over all the values of i11, i12, and i2
            for i11 = 0:i11_length-1
                for i12 = 0:i12_length-1
                    for i2 = 0:i2_length-1
                        if N2 == 1
                            l = i11;
                            lPrime = i11+O1;
                            l_dPrime = i11+2*O1;
                            m = 0;
                            mPrime = 0;
                            m_dPrime = 0;
                        else % N2 > 1
                            l = i11;
                            lPrime = i11+O1;
                            l_dPrime = i11+O1;
                            m = i12;
                            mPrime = i12;
                            m_dPrime = i12+O2;
                        end
                        n = i2;
                        bitIndex = N2*O2*l+m;
                        [lmRestricted,i2Restricted] = isRestricted(codebookSubsetRestriction,bitIndex,i2,i2Restriction);
                        if ~(lmRestricted || i2Restricted)
                            vlm = getVlm(N1,N2,O1,O2,l,m);
                            vlPrime_mPrime = getVlm(N1,N2,O1,O2,lPrime,mPrime);
                            vlDPrime_mDPrime = getVlm(N1,N2,O1,O2,l_dPrime,m_dPrime);
                            phi_n = phi(n);
                            phi_vlm = phi_n*vlm;
                            phi_vlPrime_mPrime = phi_n*vlPrime_mPrime;
                            if nLayers == 5
                                % Codebook for 5-layer CSI reporting
                                % using antenna ports 3000 to
                                % 2999+P_CSIRS, as defined in TS 38.214
                                % Table 5.2.2.2.1-9
                                codebook(:,:,i2+1,i11+1,i12+1) = ...
                                    1/(sqrt(5*Pcsirs))*[vlm       vlm        vlPrime_mPrime   vlPrime_mPrime    vlDPrime_mDPrime;...
                                    phi_vlm   -phi_vlm   vlPrime_mPrime   -vlPrime_mPrime   vlDPrime_mDPrime];
                            else
                                % Codebook for 6-layer CSI reporting
                                % using antenna ports 3000 to
                                % 2999+P_CSIRS, as defined in TS 38.214
                                % Table 5.2.2.2.1-10
                                codebook(:,:,i2+1,i11+1,i12+1) = ...
                                    1/(sqrt(6*Pcsirs))*[vlm       vlm        vlPrime_mPrime       vlPrime_mPrime        vlDPrime_mDPrime   vlDPrime_mDPrime;...
                                    phi_vlm   -phi_vlm   phi_vlPrime_mPrime   -phi_vlPrime_mPrime   vlDPrime_mDPrime   -vlDPrime_mDPrime];
                            end
                        end
                    end
                end
            end

        case{7,8} % Number of layers is 7 or 8
            if N2 == 1
                i12_length = 1;
                if N1 == 4
                    i11_length = N1*O1/2;
                else % N1 > 4
                    i11_length = N1*O1;
                end
            else % N2 > 1
                i11_length = N1*O1;
                if (N1 == 2 && N2 == 2) || (N1 > 2 && N2 > 2)
                    i12_length = N2*O2;
                else % (N1 > 2 && N2 == 2)
                    i12_length = N2*O2/2;
                end
            end
            i2_length = 2;
            codebook = zeros(Pcsirs,nLayers,i2_length,i11_length,i12_length);
            % Loop over all the values of i11, i12, and i2
            for i11 = 0:i11_length-1
                for i12 = 0:i12_length-1
                    for i2 = 0:i2_length-1
                        if N2 == 1
                            l = i11;
                            lPrime = i11+O1;
                            l_dPrime = i11+2*O1;
                            l_tPrime = i11+3*O1;
                            m = 0;
                            mPrime = 0;
                            m_dPrime = 0;
                            m_tPrime = 0;
                        else % N2 > 1
                            l = i11;
                            lPrime = i11+O1;
                            l_dPrime = i11;
                            l_tPrime = i11+O1;
                            m = i12;
                            mPrime = i12;
                            m_dPrime = i12+O2;
                            m_tPrime = i12+O2;
                        end
                        n = i2;
                        bitIndex = N2*O2*l+m;
                        [lmRestricted,i2Restricted] = isRestricted(codebookSubsetRestriction,bitIndex,i2,i2Restriction);
                        if ~(lmRestricted || i2Restricted)
                            vlm = getVlm(N1,N2,O1,O2,l,m);
                            vlPrime_mPrime = getVlm(N1,N2,O1,O2,lPrime,mPrime);
                            vlDPrime_mDPrime = getVlm(N1,N2,O1,O2,l_dPrime,m_dPrime);
                            vlTPrime_mTPrime = getVlm(N1,N2,O1,O2,l_tPrime,m_tPrime);
                            phi_n = phi(n);
                            phi_vlm = phi_n*vlm;
                            phi_vlPrime_mPrime = phi_n*vlPrime_mPrime;
                            if nLayers == 7
                                % Codebook for 7-layer CSI reporting
                                % using antenna ports 3000 to
                                % 2999+P_CSIRS, as defined in TS 38.214
                                % Table 5.2.2.2.1-11
                                codebook(:,:,i2+1,i11+1,i12+1) = ...
                                    1/(sqrt(7*Pcsirs))*[vlm       vlm        vlPrime_mPrime       vlDPrime_mDPrime   vlDPrime_mDPrime    vlTPrime_mTPrime   vlTPrime_mTPrime;...
                                    phi_vlm   -phi_vlm   phi_vlPrime_mPrime   vlDPrime_mDPrime   -vlDPrime_mDPrime   vlTPrime_mTPrime   -vlTPrime_mTPrime];
                            else
                                % Codebook for 8-layer CSI reporting
                                % using antenna ports 3000 to
                                % 2999+P_CSIRS, as defined in TS 38.214
                                % Table 5.2.2.2.1-12
                                codebook(:,:,i2+1,i11+1,i12+1) = ...
                                    1/(sqrt(8*Pcsirs))*[vlm       vlm        vlPrime_mPrime       vlPrime_mPrime        vlDPrime_mDPrime   vlDPrime_mDPrime    vlTPrime_mTPrime   vlTPrime_mTPrime;...
                                    phi_vlm   -phi_vlm   phi_vlPrime_mPrime   -phi_vlPrime_mPrime   vlDPrime_mDPrime   -vlDPrime_mDPrime   vlTPrime_mTPrime   -vlTPrime_mTPrime];
                            end
                        end
                    end
                end
            end
    end
end
end



%%  ******************************************************
function [vlmRestricted,i2Restricted] = isRestricted(codebookSubsetRestriction,bitIndex,n,i2Restriction)
%   [VLMRESTRICTED,I2RESTRICTED] = isRestricted(CODEBOOKSUBSETRESTRICTION,BITINDEX,N,I2RESTRICTION)
%   returns the status of vlm or vbarlm restriction and i2 restriction for
%   a codebook index set, as defined in TS 38.214 Section 5.2.2.2.1 by
%   considering these inputs:
%
%   CODEBOOKSUBSETRESTRICTION - Binary vector for vlm or vbarlm restriction
%   BITINDEX                  - Bit index or indices (0-based) associated
%                               with all the precoding matrices based on
%                               vlm or vbarlm
%   N                         - Co-phasing factor index
%   I2RESTRICTION             - Binary vector for i2 restriction

% Get the restricted index positions from the codebookSubsetRestriction
% binary vector
restrictedIdx = reshape(find(~codebookSubsetRestriction)-1,1,[]);
vlmRestricted = false;
if any(sum(restrictedIdx == bitIndex(:),2))
    vlmRestricted = true;
end

restrictedi2List = find(~i2Restriction)-1;
i2Restricted = false;
% Update the i2Restricted flag, if the precoding matrices based on vlm
% or vbarlm are restricted
if any(restrictedi2List == n)
    i2Restricted = true;
end
end


function vlm = getVlm(N1,N2,O1,O2,l,m)
%   VLM = getVlm(N1,N2,O1,O2,L,M) computes vlm vector according to
%   TS 38.214 Section 5.2.2.2.1 considering the panel configuration
%   [N1, N2], DFT oversampling factors [O1, O2], and vlm indices L and M.

um = exp(2*pi*1i*m*(0:N2-1)/(O2*N2));
ul = exp(2*pi*1i*l*(0:N1-1)/(O1*N1)).';
vlm =  reshape((ul.*um).',[],1);
end