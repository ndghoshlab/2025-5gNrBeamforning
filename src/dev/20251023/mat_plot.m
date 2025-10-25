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

