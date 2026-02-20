function OutPut = patternplot(AngelAxisAz_SSB,AngleAxisEl_SSB,ResultElAz_SSB_dB)
% Plot it manualy
[AZ_ssb, EL_ssb] = meshgrid(AngelAxisAz_SSB, AngleAxisEl_SSB); % Create grid for angles
R_ssb = 10 .^ (ResultElAz_SSB_dB / 50);  % Convert dB to linear scale
%R_ssb = db2mag(R_ssb);
%R_ssb = ResultElAz_SSB_dB ;  % Convert dB to linear scale

X_ssb = R_ssb .* cosd(EL_ssb) .* cosd(AZ_ssb);
Y_ssb = R_ssb .* cosd(EL_ssb) .* sind(AZ_ssb);
Z_ssb = R_ssb .* sind(EL_ssb);

% --- 6. Manual 3D Plot (Should Closely Match pattern()) ---
figure;
surf(X_ssb, Y_ssb, Z_ssb, ResultElAz_SSB_dB, 'EdgeColor', 'none'); % Color mapped to directivity
colormap(jet); shading interp;
colorbar;
xlabel('X'); ylabel('Y'); zlabel('Z');
title('Refined Manual 3D Radiation Pattern');
axis equal; grid on;

end