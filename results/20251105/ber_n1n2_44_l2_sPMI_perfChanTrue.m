% Extract data from simulation results for SVD and PMI precoding

% ========== SVD Precoding ==========

% 16QAM-SVD
SNRdB_16QAM_SVD = [-5; -4; -3; -2; -1; 0; 1; 2; 3; 4; 5; 6; 7; 8; 9; 10];
BER_16QAM_SVD = [1.6718e-01; 1.2847e-01; 4.9512e-02; 2.8776e-03; 2.2941e-04; ...
    1.3727e-04; 3.1618e-05; 1.1432e-05; 6.2313e-08; 0.0000e+00; 0.0000e+00; ...
    0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00];
SlotErrors_16QAM_SVD = [10000; 10000; 9786; 3803; 70; 9; 5; 4; 1; 0; 0; 0; 0; 0; 0; 0];

% 64QAM-SVD
SNRdB_64QAM_SVD = [0; 1; 2; 3; 4; 5; 6; 7; 8; 9; 10; 11; 12; 13; 14; 15];
BER_64QAM_SVD = [1.1284e-01; 4.6894e-02; 2.9650e-03; 8.1713e-05; 1.1334e-04; ...
    3.7723e-05; 2.8341e-05; 0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00; ...
    0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00];
SlotErrors_64QAM_SVD = [10000; 9870; 4670; 110; 8; 6; 9; 0; 0; 0; 0; 0; 0; 0; 0; 0];

% 256QAM-SVD
SNRdB_256QAM_SVD = [0; 1; 2; 3; 4; 5; 6; 7; 8; 9; 10; 11; 12; 13; 14; 15];
BER_256QAM_SVD = [1.6489e-01; 1.5061e-01; 1.3474e-01; 1.1382e-01; 7.8373e-02; ...
    2.2444e-02; 8.7300e-04; 1.3217e-04; 6.6615e-05; 1.5662e-05; 1.6727e-05; ...
    6.2282e-08; 0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00];
SlotErrors_256QAM_SVD = [10000; 10000; 10000; 10000; 10000; 9648; 3211; 71; 8; 7; 9; 1; 0; 0; 0; 0];

% ========== PMI Precoding ==========

% 16QAM-PMI
SNRdB_16QAM_PMI = [-5; -4; -3; -2; -1; 0; 1; 2; 3; 4; 5; 6; 7; 8; 9; 10];
BER_16QAM_PMI = [2.7199e-01; 2.5411e-01; 2.3548e-01; 2.1634e-01; 1.9528e-01; ...
    1.7046e-01; 1.3409e-01; 6.0255e-02; 3.6878e-03; 1.1112e-05; 0.0000e+00; ...
    0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00];
SlotErrors_16QAM_PMI = [10000; 10000; 10000; 10000; 10000; 10000; 9999; 9818; 4952; 76; 0; 0; 0; 0; 0; 0];

% 64QAM-PMI
SNRdB_64QAM_PMI = [0; 1; 2; 3; 4; 5; 6; 7; 8; 9; 10; 11; 12; 13; 14; 15];
BER_64QAM_PMI = [2.2254e-01; 2.0644e-01; 1.9000e-01; 1.7235e-01; 1.5140e-01; ...
    1.2009e-01; 5.9862e-02; 5.2763e-03; 1.7361e-05; 0.0000e+00; 0.0000e+00; ...
    0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00];
SlotErrors_64QAM_PMI = [10000; 10000; 10000; 10000; 10000; 10000; 9926; 6368; 247; 0; 0; 0; 0; 0; 0; 0];

% 256QAM-PMI
SNRdB_256QAM_PMI = [5; 6; 7; 8; 9; 10; 11; 12; 13; 14; 15; 16; 17; 18; 19; 20];
BER_256QAM_PMI = [1.6885e-01; 1.5444e-01; 1.3897e-01; 1.1930e-01; 8.7803e-02; ...
    3.3197e-02; 1.7836e-03; 2.3958e-06; 0.0000e+00; 0.0000e+00; 0.0000e+00; ...
    0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00];
SlotErrors_256QAM_PMI = [10000; 10000; 10000; 10000; 10000; 9832; 5372; 148; 0; 0; 0; 0; 0; 0; 0; 0];

% Apply threshold: set BER to zero if slot errors < 100
threshold = 100;

BER_16QAM_SVD(SlotErrors_16QAM_SVD < threshold) = 0;
BER_64QAM_SVD(SlotErrors_64QAM_SVD < threshold) = 0;
BER_256QAM_SVD(SlotErrors_256QAM_SVD < threshold) = 0;

BER_16QAM_PMI(SlotErrors_16QAM_PMI < threshold) = 0;
BER_64QAM_PMI(SlotErrors_64QAM_PMI < threshold) = 0;
BER_256QAM_PMI(SlotErrors_256QAM_PMI < threshold) = 0;

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

% Plotting - Both SVD and PMI on one figure
figure;
numCombinations = length(ModOrderList) * length(precodingList);
modColors = lines(length(ModOrderList));
lineStyles = {'-', '--'};
markers = {'o', 's', '^'};

for combIdx = 1:numCombinations
    modIdx = ceil(combIdx / length(precodingList));
    precodingIdx = mod(combIdx - 1, length(precodingList)) + 1;
    
    semilogy(SNRdB_all{combIdx}, avgBER_all{combIdx}, ... 
        'LineWidth', 2, ...
        'LineStyle', lineStyles{precodingIdx}, ...
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
title(sprintf('BER vs SNR (%d slots, perfChan=True)', numIter), ...
    'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 10);
set(gca, 'FontSize', 11);
ylim([1e-9 1e0]);
xlim([-5 20]);