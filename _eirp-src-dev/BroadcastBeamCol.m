function [BroadBeamElemActivation,ShownElemActivIndexing] = BroadcastBeamCol(arrayTx,Mat,SubArraySize,ArrayRows,Polarization)
arrayNumElements = getNumElements(arrayTx);
TxElementInactive = zeros(arrayNumElements,1);

NumElementsColumn = SubArraySize(1)*ArrayRows*Polarization;

for ii = 1:numel(Mat)
    indexing = (Mat(ii)-1)*NumElementsColumn+1:Mat(ii)*NumElementsColumn;
    TxElementInactive(indexing) = TxElementInactive(indexing) + 1;
end
BroadBeamElemActivation= TxElementInactive; 
ShownElemActivIndexing = reshape(TxElementInactive,NumElementsColumn,[]);
end