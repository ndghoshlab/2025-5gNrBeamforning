function save_matrix_to_folder(matrixData, folderPath, N1, N2, nLayer)
    % This function saves the matrixData into a .mat file in the specified folder
    % with the variable's name as the prefix, and appends N1 and N2 with 'N'.
    %
    % Inputs:
    %   matrixData - The matrix (or variable) you want to save
    %   folderPath - The folder where the new .mat file will be saved
    %   N1, N2 - Additional identifiers to append to the file name

    % Get the name of the variable passed to the function
    filePrefix = inputname(1);  % Get the name of the first input variable

    % Create the custom file prefix with "N" added before N1 and N2
    customPrefix = sprintf('%s_N1_%d_N2_%d_L_%d', filePrefix, N1, N2, nLayer);

    % Check if the folder exists, if not, create it
    if ~isfolder(folderPath)
        mkdir(folderPath);
        disp(['Folder created: ', folderPath]);
    end

    % Generate a unique filename based on the custom prefix, and N1_N2
    fileName = sprintf('%s.mat', customPrefix);

    % Create the full path to the new ".mat" file
    fullFilePath = fullfile(folderPath, fileName);

    % Save the matrixData to the .mat file
    save(fullFilePath, 'matrixData');

    % Display confirmation for the file created
    disp(['File saved successfully as: ', fullFilePath]);
end