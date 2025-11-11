% Extract data from simulation results for s-PMI-3dB and s-PMI-thres precoding

% ========== s-PMI-3dB Precoding ==========

% 16QAM-sPMI-3dB
SNRdB_16QAM_sPMI3dB = [-5; -4; -3; -2; -1; 0; 1; 2; 3; 4; 5; 6; 7; 8; 9; 10];
BER_16QAM_sPMI3dB = [2.8061e-01; 2.6290e-01; 2.4487e-01; 2.2645e-01; 2.0609e-01; ...
    1.8345e-01; 1.5261e-01; 9.6417e-02; 3.6177e-02; 1.0837e-02; 1.8791e-03; ...
    1.4000e-04; 4.1750e-06; 0.0000e+00; 0.0000e+00; 0.0000e+00];
SlotErrors_16QAM_sPMI3dB = [10000; 10000; 10000; 10000; 10000; 10000; 10000; 9899; 6977; 2655; 813; 133; 11; 0; 0; 0];

% 64QAM-sPMI-3dB
SNRdB_64QAM_sPMI3dB = [0; 1; 2; 3; 4; 5; 6; 7; 8; 9; 10; 11; 12; 13; 14; 15];
BER_64QAM_sPMI3dB = [2.3156e-01; 2.1521e-01; 1.9932e-01; 1.8239e-01; 1.6260e-01; ...
    1.3671e-01; 9.0729e-02; 3.6188e-02; 1.1790e-02; 2.4683e-03; 2.6336e-04; ...
    1.3811e-05; 0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00];
SlotErrors_64QAM_sPMI3dB = [10000; 10000; 10000; 10000; 10000; 10000; 9947; 7899; 3152; 1102; 258; 19; 0; 0; 0; 0];

% 256QAM-sPMI-3dB
SNRdB_256QAM_sPMI3dB = [5; 6; 7; 8; 9; 10; 11; 12; 13; 14; 15; 16; 17; 18; 19; 20];
BER_256QAM_sPMI3dB = [1.7730e-01; 1.6293e-01; 1.4794e-01; 1.3051e-01; 1.0432e-01; ...
    6.1353e-02; 2.4214e-02; 7.6812e-03; 1.3603e-03; 1.2948e-04; 5.1217e-06; ...
    2.8442e-07; 0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00];
SlotErrors_256QAM_sPMI3dB = [10000; 10000; 10000; 10000; 10000; 9914; 7303; 2978; 978; 239; 24; 1; 0; 0; 0; 0];

% ========== s-PMI-thres Precoding ==========

% 16QAM-sPMI-thres
SNRdB_16QAM_sPMIthres = [-5; -4; -3; -2; -1; 0; 1; 2; 3; 4; 5; 6; 7; 8; 9; 10];
BER_16QAM_sPMIthres = [2.7826e-01; 2.6043e-01; 2.4242e-01; 2.2364e-01; 2.0299e-01; ...
    1.7988e-01; 1.4691e-01; 8.6643e-02; 2.6318e-02; 6.4500e-03; 1.0496e-03; ...
    7.8980e-05; 1.5163e-06; 0.0000e+00; 0.0000e+00; 0.0000e+00];
SlotErrors_16QAM_sPMIthres = [10000; 10000; 10000; 10000; 10000; 10000; 10000; 9894; 6505; 1917; 470; 74; 8; 0; 0; 0];

% 64QAM-sPMI-thres
SNRdB_64QAM_sPMIthres = [0; 1; 2; 3; 4; 5; 6; 7; 8; 9; 10; 11; 12; 13; 14; 15];
BER_64QAM_sPMIthres = [2.2893e-01; 2.1284e-01; 1.9656e-01; 1.7963e-01; 1.5955e-01; ...
    1.3217e-01; 8.2988e-02; 2.7984e-02; 6.6792e-03; 1.3759e-03; 1.3963e-04; ...
    9.9425e-06; 0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00];
SlotErrors_64QAM_sPMIthres = [10000; 10000; 10000; 10000; 10000; 10000; 9942; 7563; 2412; 705; 128; 7; 0; 0; 0; 0];

% 256QAM-sPMI-thres
SNRdB_256QAM_sPMIthres = [5; 6; 7; 8; 9; 10; 11; 12; 13; 14; 15; 16; 17; 18; 19; 20];
BER_256QAM_sPMIthres = [1.7454e-01; 1.6072e-01; 1.4566e-01; 1.2741e-01; 9.9939e-02; ...
    5.3830e-02; 1.7350e-02; 4.4604e-03; 8.3633e-04; 8.7396e-05; 6.4711e-06; ...
    0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00; 0.0000e+00];
SlotErrors_256QAM_sPMIthres = [10000; 10000; 10000; 10000; 10000; 9897; 6876; 2171; 633; 112; 12; 0; 0; 0; 0; 0];

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
title(sprintf('BER vs SNR (%d slots, perfChan=True)', numIter), ...
    'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 10);
set(gca, 'FontSize', 11);
ylim([1e-9 1e0]);
xlim([-5 20]);