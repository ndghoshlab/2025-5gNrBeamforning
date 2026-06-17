function save_matrix_to_here(matrixData, N1, N2, nLayers,numSSB)
% This function saves the matrixData into a .mat file in the specified folder
% with the variable's name as the prefix, and appends N1 and N2 with 'N'.
%
% Inputs:
%   matrixData - The matrix (or variable) you want to save
%   folderPath - The folder where the new .mat file will be saved
%   N1, N2 - Additional identifiers to append to the file name
    

varName = inputname(1);   % gets the name of the variable passed

% Create the custom file prefix with "N" added before N1 and N2
customPrefix = sprintf('%s_N1_%d_N2_%d_L_%d_#SSB_%d', varName, N1, N2, nLayers,numSSB)

% Generate a unique filename based on the custom prefix, and N1_N2
fileName = sprintf('%s.mat', customPrefix);

% Save the matrixData to the .mat file
save(fileName, 'matrixData');
end