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

SubArraySize            = 3;                         % Number of antenna elements within a subarray.
SubArrayRows            = 4;                         % Number of subarray rows within the array.
SubArrayCols            = 8;                         % Number of subarray colomuns within the array.
SubArraySpacing_V       = 0.174;                     % Spacing between the subarrays in the vertical plane (m).

% Sectorization parameters
azSweepRangeSect        = [-60 , 60];                % Total azimuth range for all SSBs corresponding to a sectorized cell
elSweepRangeSect        = [];                        % Total elevation range for all SSBs corresponding to a sectorized cell

% SSB information
CoarseConfSSbeams       = [3, 3, 2];                 % Coarse configuration of SSB with a given sector
elCoarseConfSSbeams     = [0,-3,-6];                 % Elevation angle for each coarse of SSBs in a given plane

% Power information
Pt                      =  61.07;                    % Transmitter Pannel gain in dBm
Gr                      =  0;                        % Receiver Pannel gain in dBm

MaxDistance             = 10^3;                      % Maximum distance between Tx and Rx

% Results and plots
PlotAntElement          = 1;                         % One (1) activates the plot function for antenna element.
PlotAntArray            = 1;                         % One (1) activates the plot function for subarray, antenna array and pattern.

%% %%%%%%%%%%%%%%%%%%%%%%%   Antenna Element   %%%%%%%%%%%%%%%%%%%%%%%%%%%%
antennaEleTx            = phased.NRAntennaElement('FrequencyRange',FreqBans,'Beamwidth',[HPBW_H HPBW_V],'PolarizationModel',2,'MaximumGain',AnElementGain);
%antenna                = phased.CrossedDipoleAntennaElement('FrequencyRange',FreqBans);
%antenna                = phased.OmnidirectionalMicrophoneElement('FrequencyRange',FreqBans,'BackBaffled',true);
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
SubarrayTx              = phased.ULA(SubArraySize,'ElementSpacing',AnElementSpacing_V,'Element',antennaEleTx,'ArrayAxis','z');

arrayTx                 = phased.ReplicatedSubarray('Subarray',SubarrayTx,'Layout','Rectangular','GridSize',[SubArrayRows SubArrayCols],...
    'GridSpacing',[SubArraySpacing_V , AnElementSpacing_H],'SubarraySteering','Phase');

if PlotAntArray == 1
    % Plot the subarray
    figure;
    viewArray(SubarrayTx,'Title','Subarray Having 3x1 Elements');

    % Plot the antenna array
    figure;
    viewArray(arrayTx,'Title','4x8 Subarrays');

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

SteerVecTx_Array        = phased.SteeringVector('SensorArray',arrayTx,'PropagationSpeed',c);

%% %%%%%%%%%%%%%%%%% SSB : Transmit-End Beam Sweeping   %%%%%%%%%%%%%%%%%%%%%%
% Based on the number of SS blocks in the burst and the sweep ranges specified, determine both the
% azimuth and elevation directions for the different beams. Then beamform the individual blocks
% within the burst to each of these directions.

numSSbeams                  = sum(CoarseConfSSbeams);                                % Number of SSB

azSSBeach.sweepBW         = [];
 azSSBeach.sweepAngleMat   = [];
for ii= 1:numel(CoarseConfSSbeams)
    azSSBeach.sweepBW         = [azSSBeach.sweepBW diff(azSweepRangeSect)/CoarseConfSSbeams(ii)];                   % Scaning width for a given SSB in azimuth plane

    for ixi = 1:CoarseConfSSbeams(ii)
        if ixi >1
            azSSBeach.sweepRange{ii,ixi}  = [(azSweepRangeSect(1)+(ixi-1)*azSSBeach.sweepBW(ii))+1,azSweepRangeSect(1)+ixi*azSSBeach.sweepBW(ii)];
        else
            azSSBeach.sweepRange{ii,ixi}  = [azSweepRangeSect(1)+(ixi-1)*azSSBeach.sweepBW(ii),azSweepRangeSect(1)+ixi*azSSBeach.sweepBW(ii)];
        end
        azSSBeach.sweepAngle{ii,ixi} = median(azSSBeach.sweepRange{ii,ixi});
        azSSBeach.sweepAngleMat      = [azSSBeach.sweepAngleMat azSSBeach.sweepAngle{ii,ixi}];
    end
end


%% %%%%%%%%%% Run Simulation (Monte Carlo) %%%%%%%%%%


MaxCoordinate       = [10:100:MaxDistance];                         % You can run the code for a given distance or multipe maximum distances; deffine the array [, , ,]
Iterations          = 10^1;                                         % Deffine the iteration number for the Monte Carlo method simulation

DirectivitySaveDist = [];
PrSaveDist          = [];
parfor iv = 1:length(MaxCoordinate)-1
%for iv = 1:length(MaxCoordinate)-1

    DirectivitySaveLoc         = [];
    PrSaveLoc                  = [];
    iv
for vi = 1:Iterations
    posTx                   = [0;0;30];                             % Transmit array position, [x;y;z], meters
    posRx                   = randi([1 MaxCoordinate(iv)],3,1);   % Receive array position, [x;y;z], meters
    % posRx                 = [500;600;300];                        % Receive array position for a fixed location [x;y;z], meters



    toRxRange               = rangeangle(posTx,posRx);
    spLoss                  = fspl(toRxRange,lambda);               % Free space path loss

    TxRxDistance            = sqrt((posRx(1)-posTx(1)).^2 + (posRx(2)-posTx(2)).^2 + (posRx(3)-posTx(3)).^2);   % Distnace between Tx and Rx 

    [azimuth,elevation,TxRxDistance]   = cart2sph(posRx(1)-posTx(1),posRx(2)-posTx(2),posRx(3)-posTx(3));       % Azimuth and Elevation between Tx and Rx coordinates

    %% Calculate Received Power
    
    Pr = Pt - spLoss;                                       % Received power at [x,y,z]

    %% Configure the azimuth and elevation beamwidths of SSB transmit beam

    AngleCheck              = [floor(rad2deg(azimuth)) , floor(rad2deg(elevation))];     % Select the angle pair of interest

    azSSB_SeepAngs          = azSSBeach.sweepAngleMat;
    elSSB_SeepAngs          = [elCoarseConfSSbeams(1)*ones(1,CoarseConfSSbeams(1)),elCoarseConfSSbeams(2)*ones(1,CoarseConfSSbeams(2)),elCoarseConfSSbeams(3)*ones(1,CoarseConfSSbeams(3))];


    %WT_SSB_Beam_Matrix      = [];
    DirectivitySaveSSB         = [];
    PrSaveSSB                  = [];
    for ii = 1:Iterations
        % NOTE: Generate the same number of steering angels as the SSB number.
        ActiveSSB           = randi([1 numSSbeams],1,1);

        txSteerAng_SSB      = [azSSB_SeepAngs(ActiveSSB);elSSB_SeepAngs(ActiveSSB)];

        % Generate weights for steered direction
        Tx_WT_SSB           = SteerVecTx_Array(prm.CenterFreq,txSteerAng_SSB);

        [ResultAzEl AngelAxisAzAll AngleAxisElAll] = pattern(arrayTx,prm.CenterFreq,-180:180,-90:90,'PropagationSpeed',c,'Weights',Tx_WT_SSB,'SteerAngle',txSteerAng_SSB,'CoordinateSystem','polar','Type','powerdB','Normalize',false);

        DirectivitySaveSSB  = [DirectivitySaveSSB;  ResultAzEl(find(AngleAxisElAll == AngleCheck(2)), find(AngelAxisAzAll == AngleCheck(1)))];

        % Calculate Received Power
        Pr                  = Pt + ResultAzEl(find(AngleAxisElAll == AngleCheck(2)), find(AngelAxisAzAll == AngleCheck(1))) + Gr - spLoss;        % Fee space model of propagation
        PrSaveSSB              = [PrSaveSSB Pr];

        %WT_SSB_Beam_Matrix  = [WT_SSB_Beam_Matrix, Tx_WT_SSB];                    % Each column refers to a weight factors for a single SSB beam
    end
    DirectivitySaveLoc      = [DirectivitySaveLoc DirectivitySaveSSB.'];
    PrSaveLoc               = [PrSaveLoc PrSaveSSB];
end
    DirectivitySaveDist     = [DirectivitySaveDist ; DirectivitySaveLoc];
    PrSaveDist              = [PrSaveDist ; PrSaveLoc];
end


%% %%%%%%%%%%%%%%%%%%%%%% Empirical CDF Grid Evaluation %%%%%%%%%%%%%%%%%%%%%%

figure;
for iiv = 1:length(MaxCoordinate)-1
    [CDFResults GenResults]             = cdfplot(PrSaveDist(iiv,:));
    set(CDFResults,'LineWidth',1,'DisplayName',strcat(' Md: ',int2str(GenResults.median),' (dBm)',' d: ',int2str(MaxCoordinate(iiv+1)),' (m)')); grid on;
    xlabel('Gain (dBm)'); ylabel('CDF');title(' ');%title(strcat('Distance',' ',int2str(MaxCoordinate(iiv)),' ','m'));
    fig = gcf; fig.Position = [500 300 420 360];
    set(gca,'TickLabelInterpreter','latex');
    legend(Location="best"); hold on 
end


figure;
[CDFResults GenResults]             = cdfplot(reshape(DirectivitySaveDist.',1,[]));
set(CDFResults,'LineWidth',1,'DisplayName',strcat(' Md: ',int2str(GenResults.median),' (dBi)')); grid on;
xlabel('Gain (dBi)'); ylabel('CDF');title(' ');%title(strcat('Distance',' ',int2str(MaxCoordinate(iiv)),' ','m'));
fig = gcf; fig.Position = [500 300 420 360];
set(gca,'TickLabelInterpreter','latex');
legend(Location="best"); hold on;


figure;
posTx                       = [0;0;30];                   % Transmit array position, [x;y;z], meters
posRx                       = [500;600;300];              % Receive array position, [x;y;z], meters

plot3(posTx(1),posTx(2),posTx(3), 'o'); grid on; hold on;
plot3(posRx(1),posRx(2),posRx(3),'r*'); axis([-600 600, -600 600, 0 600]);


