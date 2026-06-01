function vbarlm = getVbarlm(N1,N2,O1,O2,l,m)
%   VBARLM = getVbarlm(N1,N2,O1,O2,L,M) computes vbarlm vector according to
%   TS 38.214 Section 5.2.2.2.1 considering the panel configuration
%   [N1, N2], DFT oversampling factors [O1, O2], and vbarlm indices L and M.

% Calculate vbarlm (DFT vector required to compute the precoding matrix)
um = exp(2*pi*1i*m*(0:N2-1)/(O2*N2));
ul = exp(2*pi*1i*l*(0:(N1/2)-1)/(O1*N1/2)).';
vbarlm = reshape((ul.*um).',[],1);
end