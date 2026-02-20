function [PMItoAntennaEleMatrixCechk PMItoAntennaEleMatrix] = AntElementPMI(PortMatricies,Weight_PMI_Layer_check,nLayers,NumAntElements)
PMItoAntennaEleMatrix = zeros(NumAntElements,1);
for laylay = 1:nLayers
    for ipi = 1:size(PortMatricies,2)
        PMItoAntennaEleMatrixCechk(:,:,ipi,laylay) = PortMatricies{ipi}.*Weight_PMI_Layer_check(ipi,laylay);
        PMItoAntennaEleMatrix  = PMItoAntennaEleMatrix + PortMatricies{ipi}.*Weight_PMI_Layer_check(ipi,laylay);
    end
end
end