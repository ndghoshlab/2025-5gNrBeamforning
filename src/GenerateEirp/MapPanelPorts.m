function [PortMatricies1 PortAntennaMap1] = MapPanelPorts(arrayTx,N1,N2,ArraySize,SubArraySize,Polarization)

SubArray_No_AntennaElements   = Polarization*prod(SubArraySize);
NumElementsColumn             = ArraySize(1)*SubArray_No_AntennaElements;

NumAntElements   = getNumElements(arrayTx);
NumAntPorts      = 2*N1*N2;
NumElePerPort    = NumAntElements/NumAntPorts;

for vi = 1:NumAntPorts
    Tempo = zeros(NumAntElements,1);
    Tempo((vi-1)*NumElePerPort +1:vi*NumElePerPort) = 1;
     PortMatricies1{vi} = Tempo;
     PortAntennaMap1{vi} = reshape(Tempo,NumElementsColumn,[]);
end
end