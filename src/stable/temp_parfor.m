clear, clc;

fprintf('=== ROBUST DEMONSTRATION: parfor Order Problem ===\n\n');

%% Example 1: Your exact code pattern - WRONG
fprintf('1. YOUR CODE PATTERN (Appending inside parfor - WRONG):\n');
fprintf('   Running with random computation delays...\n\n');

SNRdB = 0:2:25;
numSNR = length(SNRdB);
numIter = 50; % More iterations to show mixing

% Initialize like your code
SVD_wrong = [];
PMI_wrong = [];

parfor msnr = 1:numIter
    for isi = 1:numSNR
        % Simulate varying computation time (like real channel sim)
        pause(rand * 1); % Random delay
        
        % Simulate weight computation (unique value = iter*1000 + SNR)
        weight_svd = msnr * 1000 + SNRdB(isi);
        weight_pmi = msnr * 1000 + SNRdB(isi) + 0.5;
        
        % THIS IS WRONG - Same as your code!
        SVD_wrong = [SVD_wrong; weight_svd]; %#ok<AGROW>
        PMI_wrong = [PMI_wrong; weight_pmi]; %#ok<AGROW>
    end
end

fprintf('   Results (first 20 SVD weights):\n');
if ~isempty(SVD_wrong)
    disp(SVD_wrong(1:min(20, length(SVD_wrong)))');
    
    % Check if order is preserved
    expected_order = [];
    for msnr = 1:numIter
        for isi = 1:numSNR
            expected_order = [expected_order; msnr * 1000 + SNRdB(isi)];
        end
    end
    
    if length(SVD_wrong) ~= length(expected_order)
        fprintf('   ✗ WRONG LENGTH: Expected %d, Got %d (LOST DATA!)\n', ...
            length(expected_order), length(SVD_wrong));
    elseif ~isequal(SVD_wrong, expected_order)
        fprintf('   ✗ ORDER MIXED UP! Results do NOT match expected sequence\n');
        fprintf('   ✗ Cannot determine which weight belongs to which SNR!\n');
    else
        fprintf('   ✓ Order preserved (got lucky with small problem)\n');
    end
else
    fprintf('   ✗ NO DATA COLLECTED! (Complete failure)\n');
end

%% Example 2: CORRECT approach using cell array
fprintf('\n2. CORRECT APPROACH (Cell array with indexing):\n\n');

% Preallocate cell arrays
SVD_correct = cell(numIter, numSNR);
PMI_correct = cell(numIter, numSNR);

parfor msnr = 1:numIter
    for isi = 1:numSNR
        % Simulate varying computation time
        pause(rand * 0.01);
        
        % Compute weights
        weight_svd = msnr * 1000 + SNRdB(isi);
        weight_pmi = msnr * 1000 + SNRdB(isi) + 0.5;
        
        % CORRECT: Direct assignment with both indices
        SVD_correct{msnr, isi} = weight_svd;
        PMI_correct{msnr, isi} = weight_pmi;
    end
end

fprintf('   Results organized by SNR:\n');
for isi = 1:min(3, numSNR)
    snr_weights = [SVD_correct{:, isi}];
    fprintf('   SNR = %2.0f dB (first 10): [%s ...]\n', ...
        SNRdB(isi), sprintf('%.0f ', snr_weights(1:min(10, length(snr_weights)))));
end

% Verify correctness
all_correct = true;
for msnr = 1:numIter
    for isi = 1:numSNR
        expected_val = msnr * 1000 + SNRdB(isi);
        if SVD_correct{msnr, isi} ~= expected_val
            all_correct = false;
            break;
        end
    end
end

if all_correct
    fprintf('   ✓ ALL values in correct positions!\n');
    fprintf('   ✓ Each SNR column contains all %d iterations\n', numIter);
else
    fprintf('   ✗ Some values incorrect\n');
end