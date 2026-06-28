%% Set Up the Scene
clc; clear all;
buildings = readgeotable("ND_1.osm",Layer="buildingparts"); 
    % read buildings Only, From the OpenStreetMap(OSM) file
    % Download any OSM file and keep it in the folder
uniqueMaterials = unique(buildings.Material); 
    % See how many materials is there 
materials = ["","brick","concrete","copper","glass","metal","plaster","stone"]; 
    %list of typical materials, empty string is used when no annotation is
    %present and matlab maps it to concrete
colors = ["magenta","blue","black","green","red","cyan","yellow","white"]; 
    % A color mapping for each materials.
dict = dictionary(materials,colors); 
    % Map to dictionary (materials - colors)
numBuildings = height(buildings); 
    % Total number of buildings 
for n = 1:numBuildings % Loop over to change color based on materials, Visualization purpose
    material = buildings.Material(n);
    buildings.Color(n) = dict(material);
end
viewer = siteviewer(Buildings=buildings); % View the site 
disp(viewer.Materials) % See the materials found and the ITU match
%% Transmitters and Receivers
carrierFreq = 3.75e9; c = physconst('LightSpeed'); lambda = c / carrierFreq; %Frequency
SCS = 30; NRB = 52; num_sc = NRB * 12; %Setting up frequency Grid and Channel BW

antenna1 = phased.NRAntennaElement(PolarizationAngle = 45); %Cross Polarized Antenna Elements
antenna2 = phased.NRAntennaElement(PolarizationAngle = -45); 

N1=4; N2=4; % TX Panel, N1 - Horizontal Ports, N2 - Vertical Ports
Nv=2; Nh=3; 
% Nh , Nv is the number of antenna elements in one subarray in horizontal and
% vert direction

tx_array = phased.NRRectangularPanelArray('ElementSet', {antenna1, antenna2}, ...
    'Size', [N1*Nv, N2*Nh, 1, 1], 'Spacing', [0.5*lambda, 0.5*lambda, 1, 1]); 
            % TX Antenna Panel,URA; We keep half wavelength spacing for now
rx_array = phased.NRRectangularPanelArray('ElementSet', {antenna1, antenna2}, ...
    'Size', [1, 2, 1, 1], 'Spacing', [0.5*lambda, 0.5*lambda, 1, 1]); 
            % RX ULA; We keep half wavelength spacing for now

Nt = getNumElements(tx_array); Nr = getNumElements(rx_array); %Total Tx and Rx Elements

gnb_lat  = 41.699200 ; gnb_lon= -86.233981 ;  gnb_alt = 10.0;  
    %TX Location From Map, Take it using cursor in Siteviewer
yaw_deg = +90 ; pitch_deg = -15; 
    % TX Orientation in azimuth and tilt

tx = txsite("Name", "gNB_Sector_1", ...  %gNB placement
    "Latitude", gnb_lat, ...
    "Longitude", gnb_lon, ...
    "AntennaHeight", gnb_alt, ...
    "AntennaAngle", [yaw_deg; pitch_deg], ...
    "Antenna", tx_array, ...
    "TransmitterFrequency", carrierFreq); 
        % carrier Frequency mentioned here at TX

show(tx); %show gNB
pattern(tx, carrierFreq,"Size", 50); % Show broadside beam for visualization

num_users = 100; % Num UE
radius_min = 10.0; radius_max = 250.0; % Distance Spread of UE
azimuth_spread = 60; elev_max = -5;  elev_min = -25; % Azimuth and Elevation Spread of UE

r = radius_min + (radius_max - radius_min) * rand(1, num_users); % Random Distance 
elev_offset = elev_min + (elev_max - elev_min) * rand(1, num_users); % Random Elev
az_offset = -azimuth_spread + (2 * azimuth_spread) * rand(1, num_users); % Random Azimuth wrt gNB
global_az = yaw_deg + az_offset; % Random azimuth wrt to coordinate placement

[x_meters, y_meters, z_meters] = sph2cart(deg2rad(global_az), deg2rad(elev_offset), r); % x,y,z

R = 6371000; % Convert x,y,z to latitude,longitude offset
lat_offset = (y_meters / R) * (180 / pi); 
lon_offset = (x_meters ./ (R * cos(gnb_lat * pi/180))) * (180 / pi); 

ue_lats = gnb_lat + lat_offset;
ue_lons = gnb_lon + lon_offset;
ue_alts = ones(1, num_users) * 1.5; 
    %ignore z_meters, keep all UE at same height/some prefixed distribution

ue_yaws = 360 * rand(1, num_users); % Random orientation in yaw by the UE
ue_pitches = zeros(1, num_users); % Assume holding the phone roughly level in tilt

rx = rxsite("Name", "UE", ... % UE Placement
    "Latitude", ue_lats, ...
    "Longitude", ue_lons, ...
    "AntennaHeight", ue_alts, ...
    "AntennaAngle", [ue_yaws; ue_pitches], ...
    "Antenna", rx_array);
show(rx); %Show UE

for i = 1:min([10,num_users]) %loop over num users if broadside beam of all UE is needed to see
    pattern(rx(i), carrierFreq,"Size",2); %Show UE Broadside beam for subset of UE
end
%% Ray Tracing
pm = propagationModel("raytracing", ...
    "Method", "sbr", 'AngularSeparation','low',...
    "MaxNumReflections", 3, ...
    "MaxNumDiffractions", 1,'UseGPU','auto'); % Set up propagation model

all_UE_rays = raytrace(tx, rx, pm, "Type", "pathloss"); % All Users rays 
%
for i = 1:min([2,num_users]) %loop over num users if all UE paths is to be seen
    if ~isempty(all_UE_rays{i})     % Check if the cell is empty
        plot(all_UE_rays{i});
    end
end
%% Get MIMO Channel for one random user
ofdmInfo = nrOFDMInfo(NRB, SCS); % Setting up CP info,Length,Sample rate etc
carrier = nrCarrierConfig("SubcarrierSpacing", SCS, "NSizeGrid", NRB); %Set up Carrier

userID = randi([1,num_users]); %random user
ue_rays = all_UE_rays{userID}; %That user rays
delays = [ue_rays.PropagationDelay]; % Path delays in seconds
path_losses = [ue_rays.PathLoss]; path_losses_lin = 10.^(-path_losses / 10); % Path losses
mean_delay = sum(path_losses_lin .* delays) / sum(path_losses_lin);
rms_delay_spread = sqrt(sum(path_losses_lin .* (delays - mean_delay).^2) / sum(path_losses_lin)); %T_d(RMS)

ch = comm.RayTracingChannel(ue_rays, tx, rx(userID)); %Channel Object
% needs rays , tx, rx objects (to know antenna types in tx,rx,freq of tx etc)

ch.SampleRate = ofdmInfo.SampleRate; %Channel Sample Rate
ch.MinimizePropagationDelay = true; %Set earliest path delay to 0
ch.ChannelFiltering = false; %doesn't accept input and only returns IR when called ch()
ch.ReceiverVirtualVelocity = [0;0;0]; %Rx Stationary
ch.NumSamples = 1; %Number of impulse responses
% (multiple of numSamplesPerSlot only necessary if rx velocity i.e. rx moving)
% If one slot it will extrapolate to 14 OFDM Symbol (OFDM Grid)
% If velocity given and numSamples=2*SlotSamples, then 28 symbols channel
ch.NormalizeImpulseResponses = false; %Not needed, do manual normalization
ch.NormalizeChannelOutputs = false; %Not needed, do manual normalization

cir = ch(); %get the baseband path gain a_bb (Timestep x numPaths x Nr x Nt) 
chInfo = ch.info();
pathFilters = chInfo.ChannelFilterCoefficients;

hest = nrPerfectChannelEstimate(carrier, cir, pathFilters.');
% Takes carrier, pathGains, pathFilters and calculates channel matrix
% from pathGains, pathFilters computes IR and then OFDM Demod with carrier info
% Returns N_sc x N_sym x Nr x Nt 
%{
surf(pow2db(abs(hest(:,:,1,1)).^2));
shading("flat");
xlabel("OFDM Symbols");ylabel("Subcarriers");zlabel("Magnitude Squared (dB)");
title("OFDM Channel Response Between First Tx and First Rx Antenna");
%}

H_static = squeeze(hest(:, 1, :, :)); % N_sc x Nr x Nt , Since static so same for N_sym

num_elements = num_sc * Nr * Nt;
energy_matlab = sum(abs(H_static(:)).^2);
scale_matlab = sqrt(num_elements / energy_matlab);
H_matlab_norm = H_static * scale_matlab; % To Normalize Frob_norm(H)= Nr x Nt x Nsc
%% Analytical Channel Extraction - This is much faster than Matlab's default
num_paths = length(ue_rays);

a_bb_raw = squeeze(cir); % cir [1, Paths, 192 Tx, 4 Rx] -> [Paths, 192 Tx, 4 Rx]
a_bb = permute(a_bb_raw, [1, 3, 2]); %Swap Tx and Rx dimensions -> [Paths, 4 Rx, 192 Tx]

raw_delays = [ue_rays.PropagationDelay]; % Raw Delay
tau = raw_delays - min(raw_delays); %Delay shifted to zero
f_k = (-(num_sc/2) : (num_sc/2 - 1)) * SCS * 1e3; % Shift(from f_c) Frequencies in Hz

%{ 
- This is for better understanding of what happens under the hood in
following block
H_k = complex(zeros(num_sc, 4, 192));
for k = 1:num_sc
    f = f_k(k);
    H_k = zeros(4, 192);
    for p = 1:num_paths
        phase_rotation = exp(-1j * 2 * pi * f * tau(p));
        H_k = H_k + squeeze(a_bb(p, :, :)) * phase_rotation;
    end
    H_static_theory(k, :, :) = H_k;
end 
%}

% The Upper for loop is optimized with batch matrix multiplication
phase_matrix = exp(-1j * 2 * pi * f_k(:) .* tau(:).');
a_bb_flat = reshape(a_bb, num_paths, []);
H_flat = phase_matrix * a_bb_flat;
H_static_theory = reshape(H_flat, num_sc, 4, 192);

energy_theory = sum(abs(H_static_theory(:)).^2);
scale_theory = sqrt(num_elements / energy_theory);
H_theory_norm = H_static_theory * scale_theory;
%% Verify Theory and Matlab Channel Estimate Match via plotting
nmse_mag_linear = mean((abs(H_matlab_norm(:)) - abs(H_theory_norm(:))).^2); 
% Calculate difference in magnitude (phase can be different due to Timing Offset)
disp(['Total Magnitude NMSE: ', num2str(10*log10(nmse_mag_linear), '%.2f'), ' dB']);

rx_idx = randi([1, Nr]); % Receive antenna i
tx_idx = randi([1, Nt]); % Transmit antenna j

pow_link_theory = abs(H_theory_norm(:, rx_idx, tx_idx)).^2;
pow_link_matlab = abs(H_matlab_norm(:, rx_idx, tx_idx)).^2;
% Single Link Power (|H_ij(k)|^2) 

num_links = Nr * Nt;
pow_total_theory = sum(abs(H_theory_norm).^2, [2, 3]) / num_links;
pow_total_matlab = sum(abs(H_matlab_norm).^2, [2, 3]) / num_links;
% Total MIMO Average Power per subcarrier

pow_link_theory_dB = 10 * log10(pow_link_theory);
pow_link_matlab_dB = 10 * log10(pow_link_matlab);
pow_total_theory_dB = 10 * log10(pow_total_theory);
pow_total_matlab_dB = 10 * log10(pow_total_matlab);
% Convert linear power to dB for visualization

figure('Name', 'Channel Variations vs Subcarriers', 'Color', 'w', 'Position', [100, 100, 900, 500]);
% Plotting all 4 curves on the same figure

plot(f_k / 1e6, pow_link_theory_dB, 'b-', 'LineWidth', 2); hold on;
plot(f_k / 1e6, pow_link_matlab_dB, 'r--', 'LineWidth', 2);
% Plot Single Link Variations (Blue/Red)

plot(f_k / 1e6, pow_total_theory_dB, 'g-', 'LineWidth', 3);
plot(f_k / 1e6, pow_total_matlab_dB, 'm--', 'LineWidth', 2);
% Plot Total MIMO Average Power (Green/Magenta)

yline(0, 'k:', 'Expected Average (0 dB)', 'LineWidth', 1.5, 'LabelHorizontalAlignment', 'left');
% Add a reference line for Unit Average Energy (0 dB)

title(sprintf('Frequency Response: Random Single Link vs Total MIMO Average'));
xlabel('Baseband Frequency (MHz)');
ylabel('Normalized Power (dB)');
legend(...
    sprintf('Theory: Link Tx %d \\rightarrow Rx %d', tx_idx, rx_idx), ...
    sprintf('MATLAB: Link Tx %d \\rightarrow Rx %d', tx_idx, rx_idx), ...
    'Theory: Total MIMO Average Power', ...
    'MATLAB: Total MIMO Average Power', ...
    'Location', 'best');
grid on;            
%% Static All users channel
% SCS = 30; NRB = 52; %Re initializing to be safe
num_sc = NRB * 12;
num_elements = num_sc * Nr * Nt; 

ofdmInfo = nrOFDMInfo(NRB, SCS); % Re Init
f_k = (-(num_sc/2) : (num_sc/2 - 1)) * SCS * 1e3; 
        %Needed for calculating subcarrier channel

tau_rms_all = zeros(num_users, 1); %Initialize
H_global_pages = complex(zeros(4, 192, num_users * num_sc)); %Initialize

for u = 1:num_users
    ue_rays = all_UE_rays{u}; %Take user u-s rays
    delays = [ue_rays.PropagationDelay]; %Calculate Td(RMS) for user u
    path_losses = [ue_rays.PathLoss]; 
    path_losses_lin = 10.^(-path_losses / 10);
    
    mean_delay = sum(path_losses_lin .* delays) / sum(path_losses_lin);
    tau_rms_all(u) = sqrt(sum(path_losses_lin .* (delays - mean_delay).^2) / sum(path_losses_lin));
    
    ch = comm.RayTracingChannel(ue_rays, tx, rx(u)); % Set up RTChannel to get baseband pathGains
    ch.SampleRate = ofdmInfo.SampleRate; 
    ch.MinimizePropagationDelay = true; 
    ch.ChannelFiltering = false; 
    ch.ReceiverVirtualVelocity = [0;0;0]; 
    ch.NumSamples = 1; 
    ch.NormalizeImpulseResponses = false; 
    ch.NormalizeChannelOutputs = false; 
    cir = ch();

    num_paths = length(ue_rays);
    a_bb_raw = reshape(cir, num_paths, Nt, Nr); 
    a_bb = permute(a_bb_raw, [1, 3, 2]); 

    tau = delays - min(delays);
    phase_matrix = exp(-1j * 2 * pi * f_k(:) .* tau(:).');
    a_bb_flat = reshape(a_bb, num_paths, []);              
    H_flat = phase_matrix * a_bb_flat;   %Combine a_bb to get H(k)'s                
 
    H_static_theory = reshape(H_flat, num_sc, Nr, Nt); % Normalize

    energy_theory = sum(abs(H_static_theory(:)).^2);
    scale_theory = sqrt(num_elements / energy_theory);
    H_theory_norm = H_static_theory * scale_theory;

    H_page = permute(H_theory_norm, [2, 3, 1]);

    idx_start = (u - 1) * num_sc + 1; %Put users num_sc channel one to one big matrix
    idx_end = u * num_sc;
    H_global_pages(:, :, idx_start:idx_end) = H_page;
end
%% Understand Channel condition
S_all = pagesvd(H_global_pages); %Calculate the singular values
sigmas = squeeze(S_all);
cond_dB = 10 * log10(sigmas(1, :) ./ sigmas(2, :)); %Rank-2 feasibility

% 1. Histogram of RMS Delay Spread
figure; subplot(1, 3, 1);
histogram(tau_rms_all * 1e9, 20, 'FaceColor', '#0072BD', 'EdgeColor', 'w'); 
title('RMS Delay Spread (\tau_{rms})');
xlabel('Delay (ns)');
ylabel('Number of Users');
grid on;

% 2. CDF of Singular Values
subplot(1, 3, 2);
hold on;
colors = {'#D95319', '#EDB120', '#7E2F8E', '#77AC30'};
for i = 1:4
    cdfplot(sigmas(i, :));
end
title('CDF of Singular Values');
xlabel('Singular Value Magnitude (\sigma)');
ylabel('ECDF');
legend('\sigma_1', '\sigma_2', '\sigma_3', '\sigma_4', 'Location', 'best');
grid on; 
set(findobj(gca, 'Type', 'Line'), 'LineWidth', 2); 
for i=1:4 % Clean up the cdfplot default formatting
    lines = findobj(gca, 'Type', 'Line'); 
    lines(5-i).Color = colors{i};
end

% 3. Histogram of Condition Number
subplot(1, 3, 3);
histogram(cond_dB, 50, 'FaceColor', '#A2142F', 'EdgeColor', 'w');
title('Condition Number (\sigma_1 / \sigma_2)');
xlabel('Condition Number (dB)');
ylabel('Occurrences (Users \times Subcarriers)');
grid on;
%% Converting Air channel to Logical Channel and saving the Static Channel
       % How matlab indexes NR-URA? 
       % column first (1-96/N1*Nh*N2*Nv) for pol 1 and, then column first (97/Nr*Nt+1 - 192/2*N1*Nh*N2*Nv) for pol 2
       % How matlab/3gpp wants logical ports to be indexed?
       % Column first (1-16/N1*N2) for pol 1 and, then column first (17/N1*N2+1 - 32/2*N1*N2) for pol 2
%posn = getElementPosition(tx_array); %Helper function
%viewArray(tx_array); %Helper function
%{ 
- Redefine if needed
N1=4; N2=4; % N1 - Horizontal Ports, N2 - Vertical Ports
Nv=2; Nh=3; 
    % Nh , Nv is the number of antenna elements in one subarray in horz and
    % vert direction
%} 
C_horz = kron(eye(N1), ones(Nh, 1)); % Shape: [12 x 4]
C_vert = kron(eye(N2), ones(Nv, 1)); % Shape: [8 x 4]
W_pol1 = kron(C_horz, C_vert); % Shape: [96 x 16]
W_pol1 = W_pol1 * (1 / sqrt(Nv*Nh));
W_analog = blkdiag(W_pol1, W_pol1); % Shape [192x32]

H_eff_pages = pagemtimes(H_global_pages, W_analog); % Shape: [4, 32, 62400]
H_eff_split = reshape(H_eff_pages, 4, 32, num_sc, num_users); % Shape: [4, 32, 624, 100]
%H_eff_users = permute(H_eff_split, [4, 3, 1, 2]); % Shape: [100, 624, 4, 32]

target_energy_eff = 4 * (2*N1*N2) * num_sc; 

for u = 1:num_users
    H_user_eff = H_eff_split(:, :, :, u); 
        % Extract user u's effective channel [4 x 32 x 624]
    current_energy = sum(abs(H_user_eff(:)).^2);
        % Calculate the analog-altered energy
    scale_factor = sqrt(target_energy_eff / current_energy);
            % Calculate the scaling factor to restore unit link power
    H_eff_split(:, :, :, u) = H_user_eff * scale_factor;
end

H_eff_users = permute(H_eff_split, [4, 3, 1, 2]); % Shape: [100, 624, 4, 32]
       % permutation to standard shape

save('UE_Channels_100.mat', 'H_eff_users'); 