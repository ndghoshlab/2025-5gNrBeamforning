% Extract data from simulation results for s-PMI-3dB and s-PMI-thres precoding
% perfChan = false

% ========== s-PMI-3dB Precoding (perfChan=false) ==========

% 16QAM-sPMI-3dB
SNRdB_16QAM_sPMI3dB = [0; 1; 2; 3; 4; 5; 6; 7; 8; 9; 10; 11; 12; 13; 14; 15];
BER_16QAM_sPMI3dB = [2.0418e-01; 1.8121e-01; 1.4796e-01; 9.6825e-02; 6.6279e-02; ...
    7.3025e-02; 5.3444e-02; 2.3943e-02; 8.7915e-03; 2.2948e-03; 3.8328e-04; ...
    2.5158e-05; 1.1383e-06; 0.0000e+00; 0.0000e+00; 0.0000e+00];
SlotErrors_16QAM_sPMI3dB = [10000; 10000; 10000; 9989; 9777; 9751; 9810; 7799; 3309; 1276; 373; 41; 9; 0; 0; 0];

% 64QAM-sPMI-3dB
SNRdB_64QAM_sPMI3dB = [5; 6; 7; 8; 9; 10; 11; 12; 13; 14; 15; 16; 17; 18; 19; 20];
BER_64QAM_sPMI3dB = [1.8223e-01; 1.6449e-01; 1.3291e-01; 9.6788e-02; 7.3749e-02; ...
    5.7413e-02; 3.8436e-02; 1.8397e-02; 7.4199e-03; 2.4526e-03; 5.8554e-04; ...
    1.0549e-04; 1.6075e-05; 2.6495e-07; 5.5779e-09; 3.0678e-08];
SlotErrors_64QAM_sPMI3dB = [10000; 10000; 10000; 10000; 10000; 10000; 9949; 8462; 4260; 1895; 707; 229; 47; 8; 1; 1];

% 256QAM-sPMI-3dB
SNRdB_256QAM_sPMI3dB = [10; 11; 12; 13; 14; 15; 16; 17; 18; 19; 20; 21; 22; 23; 24; 25];
BER_256QAM_sPMI3dB = [1.3987e-01; 1.1672e-01; 8.8821e-02; 6.4654e-02; 4.7537e-02; ...
    3.3231e-02; 1.9617e-02; 9.5351e-03; 4.3847e-03; 1.9094e-03; 8.2766e-04; ...
    2.8584e-04; 8.9782e-05; 2.8444e-05; 1.5762e-05; 1.7655e-05];
SlotErrors_256QAM_sPMI3dB = [10000; 10000; 10000; 10000; 10000; 9987; 9662; 7428; 4305; 2282; 1171; 562; 250; 129; 66; 46];

% ========== s-PMI-thres Precoding (perfChan=false) ==========

% 16QAM-sPMI-thres
SNRdB_16QAM_sPMIthres = [0; 1; 2; 3; 4; 5; 6; 7; 8; 9; 10; 11; 12; 13; 14; 15];
BER_16QAM_sPMIthres = [2.0125e-01; 1.7768e-01; 1.4237e-01; 8.7823e-02; 6.1470e-02; ...
    7.4438e-02; 5.1305e-02; 1.8875e-02; 5.3265e-03; 1.1863e-03; 1.7190e-04; ...
    1.5101e-05; 9.4300e-07; 0.0000e+00; 0.0000e+00; 0.0000e+00];
SlotErrors_16QAM_sPMIthres = [10000; 10000; 10000; 9987; 9746; 9748; 9810; 7453; 2605; 777; 187; 40; 7; 0; 0; 0];

% 64QAM-sPMI-thres
SNRdB_64QAM_sPMIthres = [5; 6; 7; 8; 9; 10; 11; 12; 13; 14; 15; 16; 17; 18; 19; 20];
BER_64QAM_sPMIthres = [1.8103e-01; 1.6213e-01; 1.2712e-01; 9.0045e-02; 6.9296e-02; ...
    5.4470e-02; 3.4667e-02; 1.4290e-02; 4.9108e-03; 1.5104e-03; 3.5105e-04; ...
    4.9378e-05; 2.2339e-06; 4.3228e-07; 0.0000e+00; 0.0000e+00];
SlotErrors_64QAM_sPMIthres = [10000; 10000; 10000; 10000; 10000; 10000; 9921; 8205; 3588; 1384; 420; 114; 17; 5; 0; 0];

% 256QAM-sPMI-thres
SNRdB_256QAM_sPMIthres = [10; 11; 12; 13; 14; 15; 16; 17; 18; 19; 20; 21; 22; 23; 24; 25];
BER_256QAM_sPMIthres = [1.3626e-01; 1.1229e-01; 8.3093e-02; 5.8691e-02; 4.3639e-02; ...
    3.0218e-02; 1.6562e-02; 7.2427e-03; 2.9600e-03; 1.1741e-03; 4.4058e-04; ...
    1.7907e-04; 6.7892e-05; 3.0666e-05; 1.5863e-05; 3.6207e-06];
SlotErrors_256QAM_sPMIthres = [10000; 10000; 10000; 10000; 10000; 9995; 9617; 7050; 3572; 1693; 754; 385; 163; 87; 33; 19];

% Apply threshold: set BER to zero if slot errors < 100
threshold = 100;

BER_16QAM_sPMI3dB(SlotErrors_16QAM_sPMI3dB < threshold) = 0;
BER_64QAM_sPMI3dB(SlotErrors_64QAM_sPMI3dB < threshold) = 0;
BER_256QAM_sPMI3dB(SlotErrors_256QAM_sPMI3dB < threshold) = 0;

BER_16QAM_sPMIthres(SlotErrors_16QAM_sPMIthres < threshold) = 0;
BER_64QAM_sPMIthres(SlotErrors_64QAM_sPMIthres < threshold) = 0;
BER_256QAM_sPMIthres(SlotErrors_256QAM_sPMIthres < threshold) = 0;

% Store in cell arrays
SNRdB_all = {SNRdB_16QAM_sPMI3dB, SNRdB_16QAM_sPMIthres, ...
             SNRdB_64QAM_sPMI3dB, SNRdB_64QAM_sPMIthres, ...
             SNRdB_256QAM_sPMI3dB, SNRdB_256QAM_sPMIthres};
avgBER_all = {BER_16QAM_sPMI3dB, BER_16QAM_sPMIthres, ...
              BER_64QAM_sPMI3dB, BER_64QAM_sPMIthres, ...
              BER_256QAM_sPMI3dB, BER_256QAM_sPMIthres};
SlotErrors_all = {SlotErrors_16QAM_sPMI3dB, SlotErrors_16QAM_sPMIthres, ...
                  SlotErrors_64QAM_sPMI3dB, SlotErrors_64QAM_sPMIthres, ...
                  SlotErrors_256QAM_sPMI3dB, SlotErrors_256QAM_sPMIthres};

% Configuration
ModOrderList = [16, 64, 256];
precodingList = {'s-PMI-3dB', 's-PMI-thres'};
combinationLabels = {'16QAM-sPMI-3dB', '16QAM-sPMI-thres', ...
                     '64QAM-sPMI-3dB', '64QAM-sPMI-thres', ...
                     '256QAM-sPMI-3dB', '256QAM-sPMI-thres'};
numIter = 10000;

% Plotting - Both s-PMI-3dB and s-PMI-thres on one figure
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
title(sprintf('BER vs SNR (%d slots, perfChan=False)', numIter), ...
    'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 10);
set(gca, 'FontSize', 11);
ylim([1e-9 1e0]);
xlim([0 25]);