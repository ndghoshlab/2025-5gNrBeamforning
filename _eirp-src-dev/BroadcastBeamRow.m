function [BroadBeamElemActivationRow,ShownElemActivIndexingRow] = BroadcastBeamRow(arrayTx,Mat,SubArraySize,ArrayRows,Polarization)
arrayNumElements = getNumElements(arrayTx);
TxElementInactive = zeros(arrayNumElements,1);

NumElementsColumn = SubArraySize(1)*ArrayRows*Polarization;

ARows      = zeros(arrayNumElements,1);
ARowsMat   = reshape(ARows,NumElementsColumn,[]);

ARowsMat(Mat,:) = 1;
ARowsMatFinal = reshape(ARowsMat,[],1);

BroadBeamElemActivationRow = ARowsMatFinal; 
ShownElemActivIndexingRow = ARowsMat;
end