clear
clc

SNRdB = 0:5:25;

% % Load PMI results
% pmi_mod4 = load('Results/simPMI_snrY_nslot2_mod4_niter250e2.mat');
% pmi_mod4 = mean(pmi_mod4.inter_snr);

pmi_mod16 = load('Results/simPMI_snrY_nslot2_mod16_niter250e2.mat');
pmi_mod16 = mean(pmi_mod16.inter_snr);

pmi_mod64 = [0.310724679830433,0.234299815930388,0.137534751227131,0.040258231816153,0.009097825747434,0.003189116465863];

pmi_mod256 = load('Results/simPMI_snrY_nslot2_mod256_niter250e2.mat');
pmi_mod256 = mean(pmi_mod256.inter_snr);

% % Load SVD results
% svd_mod4 = load('Results/simSVD_snrY_nslot2_mod4_niter250e2.mat');
% svd_mod4 = mean(svd_mod4.inter_snr);

svd_mod16 = load('Results/simSVD_snrY_nslot2_mod16_niter250e2.mat');
svd_mod16 = mean(svd_mod16.inter_snr);

svd_mod64 = load('Results/simSVD_snrY_nslot2_mod64_niter250e2.mat');
svd_mod64 = mean(svd_mod64.inter_snr);

svd_mod256 = load('Results/simSVD_snrY_nslot2_mod256_niter250e2.mat');
svd_mod256 = mean(svd_mod256.inter_snr);

figure
% semilogy(SNRdB,pmi_mod4,'-sg','LineWidth',1.5)
semilogy(SNRdB,pmi_mod16,'-or','LineWidth',1.5)
hold on
semilogy(SNRdB,pmi_mod64,'-^m','LineWidth',1.5)
semilogy(SNRdB,pmi_mod256,'-dk','LineWidth',1.5)
% semilogy(SNRdB,svd_mod4,'--sg','LineWidth',1.5)
semilogy(SNRdB,svd_mod16,'--or','LineWidth',1.5)
semilogy(SNRdB,svd_mod64,'--^m','LineWidth',1.5)
semilogy(SNRdB,svd_mod256,'--dk','LineWidth',1.5)
grid on
xlabel('SNR (dB)')
ylabel('BER')
legend('PMI 16-QAM','PMI 64-QAM','PMI 256-QAM','SVD 16-QAM','SVD 64-QAM','SVD 256-QAM','Location','SouthWest')
title('nSlot = 2, nIter = 25000')
set(gca, 'FontSize',15)