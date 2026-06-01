function [Output1 Output2] = Get_Any_PMI_Matrix(W_PMI,PMI_mat_numb)

dims     = size(W_PMI);
numDims  = length(dims);
idx_PMI  = repmat({':'},1,numDims);

ComCheck = dims(3:end);
for iv = 1:length(ComCheck)
    ACAC{iv} = [1:ComCheck(iv)];
end

All_PMI_Matrix_Comb = table2array(combinations(ACAC{:}));

xcx = 1;
while xcx <= length(ComCheck)
    idx_PMI{2+xcx} = All_PMI_Matrix_Comb(PMI_mat_numb,xcx);
    xcx = xcx + 1;
end

%Weight_PMI_Layer   = W_PMI(:,:,6,1,1,1,1);
Output1   = W_PMI(idx_PMI{:});
Output2   = idx_PMI;
end