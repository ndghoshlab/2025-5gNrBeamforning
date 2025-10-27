% Script to print MATLAB version and all installed toolboxes with versions
% Created: October 25, 2025

fprintf('==========================================================\n');
fprintf('MATLAB VERSION INFORMATION\n');
fprintf('==========================================================\n\n');

% Get MATLAB version
v = ver('MATLAB');
fprintf('MATLAB Version: %s\n', v.Version);
fprintf('Release: %s\n', v.Release);
fprintf('Date: %s\n\n', v.Date);

% Get all installed products
fprintf('==========================================================\n');
fprintf('INSTALLED TOOLBOXES AND PRODUCTS\n');
fprintf('==========================================================\n\n');

% Get list of all installed products
installedProducts = ver;

% Print each toolbox/product with details
for i = 1:length(installedProducts)
    fprintf('%-40s\n', installedProducts(i).Name);
    fprintf('  Version: %-20s Release: %s\n', installedProducts(i).Version, installedProducts(i).Release);
    fprintf('  Date: %s\n', installedProducts(i).Date);
    fprintf('\n');
end

fprintf('==========================================================\n');
fprintf('Total number of installed products: %d\n', length(installedProducts));
fprintf('==========================================================\n\n');

% Additional system information
fprintf('==========================================================\n');
fprintf('SYSTEM INFORMATION\n');
fprintf('==========================================================\n\n');

% Computer type
fprintf('Computer: %s\n', computer);

% Java version (if available)
try
    javaVer = version('-java');
    fprintf('Java Version: %s\n', javaVer);
catch
    fprintf('Java Version: Not available\n');
end

% License information
try
    [~, username] = license('inuse');
    fprintf('License User: %s\n', username);
catch
    fprintf('License User: Information not available\n');
end

fprintf('\n==========================================================\n');
