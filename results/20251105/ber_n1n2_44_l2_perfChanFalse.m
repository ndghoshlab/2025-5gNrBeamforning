% Extract data from simulation results (Perfect TX = false, Perfect RX = false)

% 16QAM-PMI (from new results)
SNRdB_16QAM_PMI = [0; 1; 2; 3; 4; 5; 6; 7; 8; 9; 10; 11; 12; 13; 14; 15];
BER_16QAM_PMI = [1.9296e-01; 1.6726e-01; 1.2692e-01; 6.3014e-02; 5.1804e-02; ...
    8.0395e-02; 4.0388e-02; 4.2311e-03; 4.6116e-05; 1.0967e-06; 0.0000e+00; ...
    0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00];
SlotErrors_16QAM_PMI = [10000; 10000; 10000; 9979; 9609; 9769; 9858; 6263; 501; 3; 0; 0; 0; 0; 0; 0];

% 16QAM-SVD (from new results)
SNRdB_16QAM_SVD = [-5; -4; -3; -2; -1; 0; 1; 2; 3; 4; 5; 6; 7; 8; 9; 10];
BER_16QAM_SVD = [2.1813e-01; 1.5704e-01; 1.0588e-01; 4.4390e-02; 8.5412e-02; ...
    7.2056e-02; 1.8498e-02; 4.5727e-04; 4.5696e-07; 0.0000e+00; 0.0000e+00; ...
    0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00];
SlotErrors_16QAM_SVD = [10000; 10000; 10000; 9978; 9913; 9999; 9535; 2702; 31; 0; 0; 0; 0; 0; 0; 0];

% 64QAM-PMI (from new results)
SNRdB_64QAM_PMI = [5; 6; 7; 8; 9; 10; 11; 12; 13; 14; 15; 16; 17; 18; 19; 20];
BER_64QAM_PMI = [1.7822e-01; 1.5289e-01; 1.1120e-01; 7.2983e-02; 6.0041e-02; ...
    4.7630e-02; 2.6208e-02; 4.7798e-03; 1.5255e-04; 3.1236e-07; 0.0000e+00; ...
    0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00];
SlotErrors_64QAM_PMI = [10000; 10000; 10000; 10000; 10000; 10000; 9893; 7305; 1296; 19; 0; 0; 0; 0; 0; 0];

% 64QAM-SVD (from new results)
SNRdB_64QAM_SVD = [0; 1; 2; 3; 4; 5; 6; 7; 8; 9; 10; 11; 12; 13; 14; 15];
BER_64QAM_SVD = [1.6847e-01; 1.3400e-01; 8.3249e-02; 6.3876e-02; 5.3466e-02; ...
    3.5806e-02; 8.8334e-03; 2.0462e-04; 7.5301e-08; 0.0000e+00; 0.0000e+00; ...
    0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00];
SlotErrors_64QAM_SVD = [10000; 10000; 10000; 10000; 10000; 10000; 9076; 1875; 7; 0; 0; 0; 0; 0; 0; 0];

% 256QAM-PMI (from new results)
SNRdB_256QAM_PMI = [10; 11; 12; 13; 14; 15; 16; 17; 18; 19; 20; 21; 22; 23; 24; 25];
BER_256QAM_PMI = [1.2767e-01; 1.0002e-01; 6.7212e-02; 4.5750e-02; 3.4747e-02; ...
    2.2845e-02; 8.8501e-03; 1.4451e-03; 9.8426e-05; 4.2352e-06; 3.4255e-07; ...
    6.8510e-08; 2.0761e-09; 2.0761e-09; 0.0000e+00; 0.0000e+00];
SlotErrors_256QAM_PMI = [10000; 10000; 10000; 10000; 10000; 9989; 9388; 5646; 1382; 164; 16; 4; 1; 1; 0; 0];

% 256QAM-SVD (from new results)
SNRdB_256QAM_SVD = [5; 6; 7; 8; 9; 10; 11; 12; 13; 14; 15; 16; 17; 18; 19; 20];
BER_256QAM_SVD = [1.0290e-01; 6.5374e-02; 4.4089e-02; 3.5248e-02; 2.2378e-02; ...
    5.8022e-03; 8.4194e-04; 4.0912e-03; 9.4026e-04; 7.3763e-06; 2.0761e-09; ...
    0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00];
SlotErrors_256QAM_SVD = [10000; 10000; 10000; 10000; 10000; 9348; 3291; 5187; 6268; 381; 1; 0; 0; 0; 0; 0];

% Apply threshold: set BER to zero if slot errors < 100
threshold = 100;

BER_16QAM_PMI(SlotErrors_16QAM_PMI < threshold) = 0;
BER_16QAM_SVD(SlotErrors_16QAM_SVD < threshold) = 0;
BER_64QAM_PMI(SlotErrors_64QAM_PMI < threshold) = 0;
BER_64QAM_SVD(SlotErrors_64QAM_SVD < threshold) = 0;
BER_256QAM_PMI(SlotErrors_256QAM_PMI < threshold) = 0;
BER_256QAM_SVD(SlotErrors_256QAM_SVD < threshold) = 0;

% Store in cell arrays
SNRdB_all = {SNRdB_16QAM_SVD, SNRdB_16QAM_PMI, ...
             SNRdB_64QAM_SVD, SNRdB_64QAM_PMI, ...
             SNRdB_256QAM_SVD, SNRdB_256QAM_PMI};
avgBER_all = {BER_16QAM_SVD, BER_16QAM_PMI, ...
              BER_64QAM_SVD, BER_64QAM_PMI, ...
              BER_256QAM_SVD, BER_256QAM_PMI};
SlotErrors_all = {SlotErrors_16QAM_SVD, SlotErrors_16QAM_PMI, ...
                  SlotErrors_64QAM_SVD, SlotErrors_64QAM_PMI, ...
                  SlotErrors_256QAM_SVD, SlotErrors_256QAM_PMI};

% Configuration
ModOrderList = [16, 64, 256];
precodingList = {'SVD', 'PMI'};
combinationLabels = {'16QAM-SVD', '16QAM-PMI', ...
                     '64QAM-SVD', '64QAM-PMI', ...
                     '256QAM-SVD', '256QAM-PMI'};
numIter = 10000;
noSlotsSim = 1;

% Plotting
figure;
numCombinations = length(ModOrderList) * length(precodingList);
modColors = lines(length(ModOrderList));
lineStyles = {'-', '--'};
markers = {'s', '^'};

for combIdx = 1:numCombinations
    modIdx = ceil(combIdx / length(precodingList));
    precodingIdx = mod(combIdx - 1, length(precodingList)) + 1;
    
    semilogy(SNRdB_all{combIdx}, avgBER_all{combIdx}, ... 
        'LineWidth', 2, ...
        'LineStyle', lineStyles{precodingIdx}, ...
        'Marker', markers{precodingIdx}, ...
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