numCombinations = length(ModOrderList) * length(pmiPrecodingList);

% Filter combinations based on totalPacketErrors_all > 10% of numIter
threshold = 0.1 * numIter; % 10% of numIter
validCombinations = false(1, numCombinations);

for combIdx = 1:numCombinations
    % Check if any SNR point has totalPacketErrors > threshold
    if any(totalPacketErrors_all{combIdx} > threshold)
        validCombinations(combIdx) = true;
    end
end

% Plotting
modColors = lines(length(ModOrderList));
lineStyles = {'-', '--'};
markers = {'s', '^'};

for combIdx = 1:numCombinations
    % Only plot if this combination meets the criteria
    if validCombinations(combIdx)
        modIdx = ceil(combIdx / length(pmiPrecodingList));
        pmiIdx = mod(combIdx - 1, length(pmiPrecodingList)) + 1;
        
        % Filter data points where packet errors > threshold
        validPoints = totalPacketErrors_all{combIdx} > threshold;
        
        if any(validPoints)
            semilogy(SNRdB_all{combIdx}(validPoints), avgBER_all{combIdx}(validPoints), ... 
                'LineWidth', 2, ...
                'LineStyle', lineStyles{pmiIdx}, ...
                'Marker', markers{pmiIdx}, ...
                'MarkerSize', 6, ...
                'Color', modColors(modIdx, :), ...
                'DisplayName', combinationLabels{combIdx});
            hold on;
        end
    end
end
grid on;
hold off;
xlabel('SNR (dB)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('BER', 'FontSize', 12, 'FontWeight', 'bold');
title(sprintf('BER vs SNR Comparison (%d packets, %d slots/packet) - Pkt Err > 10%%', numIter, noSlotsSim), ...
    'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 10);
set(gca, 'FontSize', 11);
ylim([1e-5 1e0]);




% %%% Old version:
% numCombinations = length(ModOrderList) * length(pmiPrecodingList);
% modColors = lines(length(ModOrderList));
% lineStyles = {'-', '--'};
% markers = {'s', '^'};
% for combIdx = 1:numCombinations
%     modIdx = ceil(combIdx / length(pmiPrecodingList));
%     pmiIdx = mod(combIdx - 1, length(pmiPrecodingList)) + 1;
%     semilogy(SNRdB_all{combIdx}, avgBER_all{combIdx}, ... 
%         'LineWidth', 2, ...
%         'LineStyle', lineStyles{pmiIdx}, ...
%         'Marker', markers{pmiIdx}, ...
%         'MarkerSize', 6, ...
%         'Color', modColors(modIdx, :), ...
%         'DisplayName', combinationLabels{combIdx});
%     hold on;
% end
% grid on;
% hold off;
% xlabel('SNR (dB)', 'FontSize', 12, 'FontWeight', 'bold');
% ylabel('BER', 'FontSize', 12, 'FontWeight', 'bold');
% title(sprintf('BER vs SNR Comparison (%d packets, %d slots/packet)', numIter, noSlotsSim), ...
%     'FontSize', 14, 'FontWeight', 'bold');
% legend('Location', 'best', 'FontSize', 10);
% set(gca, 'FontSize', 11);
% ylim([1e-9 1e0]);