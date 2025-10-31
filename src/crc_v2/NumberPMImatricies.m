function [Output1] = NumberPMImatricies(W_PMI)
% Calculate total number of PMI matricies
dims     = size(W_PMI);
numDims  = length(dims);
idx_PMI  = repmat({':'},1,numDims);

ComCheck = dims(3:end);
for iv = 1:length(ComCheck)
    ACAC{iv} = [1:ComCheck(iv)];
end
All_PMI_Matrix_Comb = table2array(combinations(ACAC{:}));

Output1 = size(All_PMI_Matrix_Comb,1);
end