function save_matrix_to_here( ...
    folderPath, ...
    matrixData, ...
    N1, N2, nLayers, numSSB)
% This function saves the matrixData into a .mat file in the specified folder
% with the variable's name and identifiers as the prefix.
%
% Inputs:
%   folderPath - The folder where the new .mat file will be saved
%   matrixData - The matrix (or variable) you want to save
%   N1, N2, nLayers, numSSB - Additional identifiers to append to file name prefix
    

varName = inputname(2);   % gets the name of the variable passed

% Create the filename with variable name and other identifiers as prefix
fileName = sprintf( ...
    '%s_N1_%d_N2_%d_L_%d_#SSB_%d.mat', ...
    varName, N1, N2, nLayers, numSSB);
fullFilePath = fullfile(folderPath, fileName);

% Save the matrixData to the .mat file
save(fullFilePath, 'matrixData');
end