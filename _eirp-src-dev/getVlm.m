function vlm = getVlm(N1,N2,O1,O2,l,m)
%   VLM = getVlm(N1,N2,O1,O2,L,M) computes vlm vector according to
%   TS 38.214 Section 5.2.2.2.1 considering the panel configuration
%   [N1, N2], DFT oversampling factors [O1, O2], and vlm indices L and M.

um = exp(2*pi*1i*m*(0:N2-1)/(O2*N2));
ul = exp(2*pi*1i*l*(0:N1-1)/(O1*N1)).';
vlm =  reshape((ul.*um).',[],1);
end