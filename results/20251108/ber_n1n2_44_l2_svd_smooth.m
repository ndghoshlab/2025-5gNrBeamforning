% Extract data for 16QAM-SVD

% 16QAM-SVD (10,000 iterations)
SNRdB_16QAM_SVD_10k = [-5:5]';
BER_16QAM_SVD_10k = [2.1936e-01; 1.5672e-01; 1.0663e-01; 4.3391e-02; 8.5234e-02; ...
    7.1387e-02; 1.8440e-02; 4.5090e-04; 1.8278e-07; 0.0000e+00; 0.0000e+00];

% 16QAM-SVD (50,000 iterations)
SNRdB_16QAM_SVD_50k = [-5:5]';
BER_16QAM_SVD_50k = [2.1879e-01; 1.5679e-01; 1.0654e-01; 4.3991e-02; 8.4929e-02; ...
    7.1495e-02; 1.8421e-02; 4.4417e-04; 3.6142e-07; 0.0000e+00; 0.0000e+00];

% Extract data for 256QAM-SVD

% 256QAM-SVD (10,000 iterations)
SNRdB_256QAM_SVD_10k = [5:15]';
BER_256QAM_SVD_10k = [1.0294e-01; 6.5168e-02; 4.4013e-02; 3.5230e-02; 2.2378e-02; ...
    5.8614e-03; 7.8791e-04; 4.1434e-03; 9.4202e-04; 8.1444e-06; 0.0000e+00];

% 256QAM-SVD (50,000 iterations)
SNRdB_256QAM_SVD_50k = [5:15]';
BER_256QAM_SVD_50k = [1.0289e-01; 6.5285e-02; 4.4067e-02; 3.5237e-02; 2.2428e-02; ...
    5.8050e-03; 7.9279e-04; 4.1675e-03; 9.2217e-04; 7.2633e-06; 8.3043e-10];

% Simulation parameters
numIter_10k = 10000;
numIter_50k = 50000;
noSlotsSim = 1;

% Plotting
figure;

% 16QAM-SVD curves
semilogy(SNRdB_16QAM_SVD_10k, BER_16QAM_SVD_10k, ...
    'LineWidth', 2, 'LineStyle', '-', 'Marker', 's', 'MarkerSize', 6, ...
    'Color', [0 0.4470 0.7410], 'DisplayName', '16QAM-SVD (10k slots)');

hold on;

semilogy(SNRdB_16QAM_SVD_50k, BER_16QAM_SVD_50k, ...
    'LineWidth', 2, 'LineStyle', '--', 'Marker', 'o', 'MarkerSize', 6, ...
    'Color', [0 0.4470 0.7410], 'DisplayName', '16QAM-SVD (50k slots)');

% 256QAM-SVD curves
semilogy(SNRdB_256QAM_SVD_10k, BER_256QAM_SVD_10k, ...
    'LineWidth', 2, 'LineStyle', '-', 'Marker', '^', 'MarkerSize', 6, ...
    'Color', [0.8500 0.3250 0.0980], 'DisplayName', '256QAM-SVD (10k slots)');

semilogy(SNRdB_256QAM_SVD_50k, BER_256QAM_SVD_50k, ...
    'LineWidth', 2, 'LineStyle', '--', 'Marker', 'd', 'MarkerSize', 6, ...
    'Color', [0.8500 0.3250 0.0980], 'DisplayName', '256QAM-SVD (50k slots)');

grid on;
hold off;
xlabel('SNR (dB)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('BER', 'FontSize', 12, 'FontWeight', 'bold');
title('BER vs SNR: 16QAM & 256QAM with SVD Precoding', ...
    'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 10);
set(gca, 'FontSize', 11);
ylim([1e-10 1e0]);
xlim([-6 16]);