clear
clc

% Config:
% noSlotsSim = 2; 
% ModOrder = 16/64/256-QAM;
% SNRdB = [0:5:40];
% pmiPrecoding = 0/1;
% perfectEstimation = false;
% numIter = 2.5e4;

SNRdB = 0:5:40;

% Load PMI results

pmi_mod16 = [0.277756102990033,0.158349794019934,0.040729513289037,...
            0.004203805647841,0.000258694352159,0.000059312292359,0,0,0];

pmi_mod64 = [0.310724679830433,0.234299815930388,0.137534751227131,...
            0.040258231816153,0.009097825747434,0.003189116465863,...
            0.002280727353860, 0.001873613342258, 0.001775335787595];

pmi_mod256 = [0.331674828015952,0.256578133100698,0.191426306081755,...
            0.110581066799601,0.048284806414091,0.02626070704553,0,0,0];

% Load SVD results

svd_mod16 = [0.156982230034722,0.077244378472222,0.000000919270833,0,0,0,0,0,0];

svd_mod64 = [0.266755555555556,0.187331859660865,0.063172662873717,...
            0.005153582106203,0.000391284024989,0.00008833556448,0,0,0];

svd_mod256 = [0.288323691425723,0.214564581256232,0.146645586573613,...
            0.047389281322699,0.00944893403124,0.003352180126288,...
            0.001730972914590, 0.001403668993021, 0.001113462113659];

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

