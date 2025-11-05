% Extract data from simulation results (Perfect TX = false, Perfect RX = false)

% 16QAM-PMI (from results_20251105_105452.txt)
SNRdB_16QAM_PMI = [-5; -4; -3; -2; -1; 0; 1; 2; 3; 4; 5; 6; 7; 8; 9; 10];
BER_16QAM_PMI = [3.0033e-01; 2.7496e-01; 2.4842e-01; 2.3272e-01; 2.1775e-01; ...
    1.9046e-01; 1.6219e-01; 1.3330e-01; 6.1806e-02; 5.0440e-02; 8.2764e-02; ...
    3.1530e-02; 7.6437e-04; 0.0000e+00; 0.0000e+00; 0.0000e+00];

% 16QAM-SVD (from results_20251105_110430.txt)
SNRdB_16QAM_SVD = [-5; -4; -3; -2; -1; 0; 1; 2; 3; 4; 5; 6; 7; 8; 9; 10];
BER_16QAM_SVD = [1.9835e-01; 1.5182e-01; 1.1170e-01; 5.1732e-02; 7.1606e-02; ...
    6.5749e-02; 2.6620e-02; 3.3234e-05; 0.0000e+00; 0.0000e+00; 0.0000e+00; ...
    0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00];

% 16QAM-s-PMI (from results_20251105_113335.txt)
SNRdB_16QAM_sPMI = [0; 1; 2; 3; 4; 5; 6; 7; 8; 9; 10; 11; 12; 13; 14; 15];
BER_16QAM_sPMI = [1.9432e-01; 1.7757e-01; 1.3403e-01; 7.3658e-02; 9.0936e-02; ...
    7.2453e-02; 3.5597e-02; 7.4734e-03; 7.5607e-04; 0.0000e+00; 0.0000e+00; ...
    0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00];

% 64QAM-PMI (from results_20251105_105452.txt)
SNRdB_64QAM_PMI = [0; 1; 2; 3; 4; 5; 6; 7; 8; 9; 10; 11; 12; 13; 14; 15];
BER_64QAM_PMI = [2.3447e-01; 2.1939e-01; 2.0462e-01; 1.9157e-01; 1.8287e-01; ...
    1.7670e-01; 1.5222e-01; 1.1290e-01; 7.1430e-02; 5.8746e-02; 4.9808e-02; ...
    2.0942e-02; 6.7241e-03; 4.1834e-05; 0.0000e+00; 0.0000e+00];

% 64QAM-SVD (from results_20251105_110430.txt)
SNRdB_64QAM_SVD = [0; 1; 2; 3; 4; 5; 6; 7; 8; 9; 10; 11; 12; 13; 14; 15];
BER_64QAM_SVD = [1.7112e-01; 1.4272e-01; 8.4379e-02; 6.5543e-02; 5.3093e-02; ...
    3.3445e-02; 1.0467e-02; 1.3666e-04; 0.0000e+00; 0.0000e+00; 0.0000e+00; ...
    0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00];

% 64QAM-s-PMI (from results_20251105_113335.txt)
SNRdB_64QAM_sPMI = [5; 6; 7; 8; 9; 10; 11; 12; 13; 14; 15; 16; 17; 18; 19; 20];
BER_64QAM_sPMI = [1.7637e-01; 1.5482e-01; 1.1395e-01; 7.5343e-02; 5.9446e-02; ...
    4.4191e-02; 1.6558e-02; 3.3384e-03; 1.5339e-04; 0.0000e+00; 0.0000e+00; ...
    0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00];

% 256QAM-PMI (from results_20251105_105452.txt)
SNRdB_256QAM_PMI = [5; 6; 7; 8; 9; 10; 11; 12; 13; 14; 15; 16; 17; 18; 19; 20];
BER_256QAM_PMI = [2.0534e-01; 1.9204e-01; 1.7752e-01; 1.6125e-01; 1.4250e-01; ...
    1.3080e-01; 1.0879e-01; 7.6235e-02; 4.3284e-02; 3.6140e-02; 2.8050e-02; ...
    1.0393e-02; 2.5307e-03; 1.3910e-04; 0.0000e+00; 0.0000e+00];

% 256QAM-SVD (from results_20251105_110430.txt)
SNRdB_256QAM_SVD = [5; 6; 7; 8; 9; 10; 11; 12; 13; 14; 15; 16; 17; 18; 19; 20];
BER_256QAM_SVD = [9.8879e-02; 6.1070e-02; 4.5815e-02; 3.5059e-02; 1.7869e-02; ...
    4.9078e-03; 3.1141e-05; 2.8754e-03; 1.0920e-03; 0.0000e+00; 0.0000e+00; ...
    0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00];

% 256QAM-s-PMI (from results_20251105_113335.txt)
SNRdB_256QAM_sPMI = [10; 11; 12; 13; 14; 15; 16; 17; 18; 19; 20; 21; 22; 23; 24; 25];
BER_256QAM_sPMI = [1.2593e-01; 1.0092e-01; 6.5056e-02; 4.5848e-02; 3.4363e-02; ...
    2.0657e-02; 5.3459e-03; 9.5914e-04; 8.0967e-05; 4.1521e-06; 0.0000e+00; ...
    0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00];

% Store in cell arrays
SNRdB_all = {SNRdB_16QAM_SVD, SNRdB_16QAM_PMI, SNRdB_16QAM_sPMI, ...
             SNRdB_64QAM_SVD, SNRdB_64QAM_PMI, SNRdB_64QAM_sPMI, ...
             SNRdB_256QAM_SVD, SNRdB_256QAM_PMI, SNRdB_256QAM_sPMI};
avgBER_all = {BER_16QAM_SVD, BER_16QAM_PMI, BER_16QAM_sPMI, ...
              BER_64QAM_SVD, BER_64QAM_PMI, BER_64QAM_sPMI, ...
              BER_256QAM_SVD, BER_256QAM_PMI, BER_256QAM_sPMI};

% Configuration
ModOrderList = [16, 64, 256];
precodingList = {'SVD', 'PMI', 's-PMI'};
combinationLabels = {'16QAM-SVD', '16QAM-PMI', '16QAM-s-PMI', ...
                     '64QAM-SVD', '64QAM-PMI', '64QAM-s-PMI', ...
                     '256QAM-SVD', '256QAM-PMI', '256QAM-s-PMI'};
numIter = 10;
noSlotsSim = 1;

% Plotting
figure;
numCombinations = length(ModOrderList) * length(precodingList);
modColors = lines(length(ModOrderList));
lineStyles = {'-', '--', ':'};
markers = {'s', '^', 'o'};

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
title(sprintf('BER vs SNR (%d slots, perfTx=false, perfRx=false)', numIter), ...
    'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 10);
set(gca, 'FontSize', 11);
ylim([1e-9 1e0]);
xlim([-5 25]);