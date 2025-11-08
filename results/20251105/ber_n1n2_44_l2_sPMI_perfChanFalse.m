% Extract data from simulation results for s-PMI (Perfect TX = false, Perfect RX = false)

% ========== phi < 10 degrees ==========

% 16QAM-s-PMI (phi < 10 degrees)
SNRdB_16QAM_sPMI_10deg = [0; 1; 2; 3; 4; 5; 6; 7; 8; 9; 10; 11; 12; 13; 14; 15];
BER_16QAM_sPMI_10deg = [1.9428e-01; 1.6886e-01; 1.2962e-01; 6.7455e-02; 5.2594e-02; ...
    7.8868e-02; 4.3060e-02; 6.7831e-03; 5.4394e-04; 0.0000e+00; 0.0000e+00; ...
    0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00];
SlotErrors_16QAM_sPMI_10deg = [10000; 10000; 10000; 9983; 9626; 9762; 9852; 6513; 892; 74; 3; 0; 0; 0; 0; 0];

% 64QAM-s-PMI (phi < 10 degrees)
SNRdB_64QAM_sPMI_10deg = [5; 6; 7; 8; 9; 10; 11; 12; 13; 14; 15; 16; 17; 18; 19; 20];
BER_64QAM_sPMI_10deg = [1.7855e-01; 1.5440e-01; 1.1388e-01; 7.5719e-02; 6.1173e-02; ...
    4.8549e-02; 2.7891e-02; 6.2754e-03; 6.7756e-04; 0.0000e+00; 0.0000e+00; ...
    0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00];
SlotErrors_64QAM_sPMI_10deg = [10000; 10000; 10000; 10000; 10000; 10000; 9908; 7469; 1708; 165; 24; 3; 0; 0; 0; 0];

% 256QAM-s-PMI (phi < 10 degrees)
SNRdB_256QAM_sPMI_10deg = [10; 11; 12; 13; 14; 15; 16; 17; 18; 19; 20; 21; 22; 23; 24; 25];
BER_256QAM_sPMI_10deg = [1.2904e-01; 1.0211e-01; 7.0091e-02; 4.7844e-02; 3.5839e-02; ...
    2.3878e-02; 9.9072e-03; 2.2947e-03; 4.0797e-04; 0.0000e+00; 0.0000e+00; ...
    0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00];
SlotErrors_256QAM_sPMI_10deg = [10000; 10000; 10000; 10000; 10000; 9983; 9424; 5950; 1799; 382; 85; 27; 9; 2; 2; 0];

% ========== phi < 5 degrees ==========

% 16QAM-s-PMI (phi < 5 degrees)
SNRdB_16QAM_sPMI_5deg = [0; 1; 2; 3; 4; 5; 6; 7; 8; 9; 10; 11; 12; 13; 14; 15];
BER_16QAM_sPMI_5deg = [2.0049e-01; 1.7662e-01; 1.4097e-01; 8.6128e-02; 6.1206e-02; ...
    7.4698e-02; 4.9631e-02; 1.7834e-02; 5.6545e-03; 1.4628e-03; 0.0000e+00; ...
    0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00];
SlotErrors_16QAM_sPMI_5deg = [10000; 10000; 10000; 9988; 9715; 9749; 9829; 7357; 2435; 817; 247; 32; 5; 0; 0; 0];

% 64QAM-s-PMI (phi < 5 degrees)
SNRdB_64QAM_sPMI_5deg = [5; 6; 7; 8; 9; 10; 11; 12; 13; 14; 15; 16; 17; 18; 19; 20];
BER_64QAM_sPMI_5deg = [1.8094e-01; 1.6091e-01; 1.2619e-01; 8.9699e-02; 6.9489e-02; ...
    5.4141e-02; 3.4546e-02; 1.4387e-02; 4.8997e-03; 1.5500e-03; 4.2936e-04; ...
    0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00];
SlotErrors_64QAM_sPMI_5deg = [10000; 10000; 10000; 10000; 10000; 10000; 9937; 8154; 3397; 1252; 477; 120; 22; 0; 2; 1];

% 256QAM-s-PMI (phi < 5 degrees)
SNRdB_256QAM_sPMI_5deg = [10; 11; 12; 13; 14; 15; 16; 17; 18; 19; 20; 21; 22; 23; 24; 25];
BER_256QAM_sPMI_5deg = [1.3582e-01; 1.1154e-01; 8.1425e-02; 5.8849e-02; 4.3773e-02; ...
    2.9874e-02; 1.6122e-02; 6.8680e-03; 2.9450e-03; 1.3119e-03; 5.0810e-04; ...
    1.5763e-04; 0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00];
SlotErrors_256QAM_sPMI_5deg = [10000; 10000; 10000; 10000; 10000; 9992; 9540; 6779; 3330; 1557; 775; 372; 187; 89; 35; 24];

% Apply threshold: set BER to zero if slot errors < 100
threshold = 100;

BER_16QAM_sPMI_10deg(SlotErrors_16QAM_sPMI_10deg < threshold) = 0;
BER_64QAM_sPMI_10deg(SlotErrors_64QAM_sPMI_10deg < threshold) = 0;
BER_256QAM_sPMI_10deg(SlotErrors_256QAM_sPMI_10deg < threshold) = 0;

BER_16QAM_sPMI_5deg(SlotErrors_16QAM_sPMI_5deg < threshold) = 0;
BER_64QAM_sPMI_5deg(SlotErrors_64QAM_sPMI_5deg < threshold) = 0;
BER_256QAM_sPMI_5deg(SlotErrors_256QAM_sPMI_5deg < threshold) = 0;

% Store in cell arrays
SNRdB_all = {SNRdB_16QAM_sPMI_10deg, SNRdB_16QAM_sPMI_5deg, ...
             SNRdB_64QAM_sPMI_10deg, SNRdB_64QAM_sPMI_5deg, ...
             SNRdB_256QAM_sPMI_10deg, SNRdB_256QAM_sPMI_5deg};
avgBER_all = {BER_16QAM_sPMI_10deg, BER_16QAM_sPMI_5deg, ...
              BER_64QAM_sPMI_10deg, BER_64QAM_sPMI_5deg, ...
              BER_256QAM_sPMI_10deg, BER_256QAM_sPMI_5deg};
SlotErrors_all = {SlotErrors_16QAM_sPMI_10deg, SlotErrors_16QAM_sPMI_5deg, ...
                  SlotErrors_64QAM_sPMI_10deg, SlotErrors_64QAM_sPMI_5deg, ...
                  SlotErrors_256QAM_sPMI_10deg, SlotErrors_256QAM_sPMI_5deg};

% Configuration
ModOrderList = [16, 64, 256];
phiList = {'\phi<10°', '\phi<5°'};
combinationLabels = {'16QAM-s-PMI (\phi<10°)', '16QAM-s-PMI (\phi<5°)', ...
                     '64QAM-s-PMI (\phi<10°)', '64QAM-s-PMI (\phi<5°)', ...
                     '256QAM-s-PMI (\phi<10°)', '256QAM-s-PMI (\phi<5°)'};
numIter = 10000;

% Plotting - Both phi thresholds on one figure
figure;
numCombinations = length(ModOrderList) * length(phiList);
modColors = lines(length(ModOrderList));
lineStyles = {'-', '--'};
markers = {'o', 's', '^'};

for combIdx = 1:numCombinations
    modIdx = ceil(combIdx / length(phiList));
    phiIdx = mod(combIdx - 1, length(phiList)) + 1;
    
    semilogy(SNRdB_all{combIdx}, avgBER_all{combIdx}, ... 
        'LineWidth', 2, ...
        'LineStyle', lineStyles{phiIdx}, ...
        'Marker', markers{modIdx}, ...
        'MarkerSize', 6, ...
        'Color', modColors(modIdx, :), ...
        'DisplayName', combinationLabels{combIdx});
    hold on;
end

grid on;
hold off;
xlabel('SNR (dB)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('BER', 'FontSize', 12, 'FontWeight', 'bold');
title(sprintf('BER vs SNR (%d slots, perfChan=False)', numIter), ...
    'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 10);
set(gca, 'FontSize', 11);
ylim([1e-9 1e0]);
xlim([-5 25]);