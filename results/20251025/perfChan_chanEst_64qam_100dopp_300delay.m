% Extract data from simulation results

% Channel Estimation (Practical) - 64QAM-SVD
SNRdB_64QAM_SVD_ChanEst = [10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 34]';
BER_64QAM_SVD_ChanEst = [6.2866e-02; 2.4398e-02; 8.2126e-03; 3.0360e-03; 9.9177e-04; ...
    2.9080e-04; 1.2043e-04; 1.9695e-04; 8.7098e-05; 4.7496e-05; ...
    4.1137e-05; 4.8249e-06; 1.1145e-04];

% Channel Estimation (Practical) - 64QAM-PMI
SNRdB_64QAM_PMI_ChanEst = [10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 34]';
BER_64QAM_PMI_ChanEst = [1.3828e-01; 9.0215e-02; 5.6524e-02; 3.0755e-02; 1.6570e-02; ...
    7.8565e-03; 5.9775e-03; 4.2783e-03; 2.5007e-03; 2.0928e-03; ...
    2.0581e-03; 2.6599e-03; 2.2542e-03];

% Perfect Channel - 64QAM-SVD
SNRdB_64QAM_SVD_PerfChan = [10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 34]';
BER_64QAM_SVD_PerfChan = [2.4833e-02; 5.4309e-03; 8.9017e-04; 1.4558e-05; 2.7889e-07; ...
    0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00; ...
    0.0000e+00; 0.0000e+00; 1.1348e-04];

% Perfect Channel - 64QAM-PMI
SNRdB_64QAM_PMI_PerfChan = [10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 34]';
BER_64QAM_PMI_PerfChan = [9.0959e-02; 4.6555e-02; 1.8580e-02; 4.5705e-03; 1.2166e-03; ...
    2.7025e-05; 0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00; ...
    0.0000e+00; 0.0000e+00; 0.0000e+00];

% Store in cell arrays
SNRdB_all = {SNRdB_64QAM_SVD_ChanEst, SNRdB_64QAM_PMI_ChanEst, ...
             SNRdB_64QAM_SVD_PerfChan, SNRdB_64QAM_PMI_PerfChan};
avgBER_all = {BER_64QAM_SVD_ChanEst, BER_64QAM_PMI_ChanEst, ...
              BER_64QAM_SVD_PerfChan, BER_64QAM_PMI_PerfChan};

% Configuration
ModOrderList = [64, 64]; % ChanEst and PerfChan
pmiPrecodingList = [false, true]; % SVD, PMI
combinationLabels = {'64QAM-SVD (EstChan)', '64QAM-PMI (EstChan)', ...
                     '64QAM-SVD (PerfChan)', '64QAM-PMI (PerfChan)'};
numIter = 1000;
noSlotsSim = 2;

% Plotting
numCombinations = length(ModOrderList) * length(pmiPrecodingList);
modColors = lines(length(ModOrderList));
lineStyles = {'-', '--'};
markers = {'s', '^'};
for combIdx = 1:numCombinations
    modIdx = ceil(combIdx / length(pmiPrecodingList));
    pmiIdx = mod(combIdx - 1, length(pmiPrecodingList)) + 1;
    semilogy(SNRdB_all{combIdx}, avgBER_all{combIdx}, ... 
        'LineWidth', 2, ...
        'LineStyle', lineStyles{pmiIdx}, ...
        'Marker', markers{pmiIdx}, ...
        'MarkerSize', 6, ...
        'Color', modColors(modIdx, :), ...
        'DisplayName', combinationLabels{combIdx});
    hold on;
end
grid on;
hold off;
xlabel('SNR (dB)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('BER', 'FontSize', 12, 'FontWeight', 'bold');
title(sprintf('BER vs SNR Comparison (%d packets, %d slots/packet)', numIter, noSlotsSim), ...
    'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 10);
set(gca, 'FontSize', 11);
ylim([1e-9 1e0]);