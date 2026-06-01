function [vlmRestricted,i2Restricted] = isRestricted(codebookSubsetRestriction,bitIndex,n,i2Restriction)
%   [VLMRESTRICTED,I2RESTRICTED] = isRestricted(CODEBOOKSUBSETRESTRICTION,BITINDEX,N,I2RESTRICTION)
%   returns the status of vlm or vbarlm restriction and i2 restriction for
%   a codebook index set, as defined in TS 38.214 Section 5.2.2.2.1 by
%   considering these inputs:
%
%   CODEBOOKSUBSETRESTRICTION - Binary vector for vlm or vbarlm restriction
%   BITINDEX                  - Bit index or indices (0-based) associated
%                               with all the precoding matrices based on
%                               vlm or vbarlm
%   N                         - Co-phasing factor index
%   I2RESTRICTION             - Binary vector for i2 restriction

% Get the restricted index positions from the codebookSubsetRestriction
% binary vector
restrictedIdx = reshape(find(~codebookSubsetRestriction)-1,1,[]);
vlmRestricted = false;
if any(sum(restrictedIdx == bitIndex(:),2))
    vlmRestricted = true;
end

restrictedi2List = find(~i2Restriction)-1;
i2Restricted = false;
% Update the i2Restricted flag, if the precoding matrices based on vlm
% or vbarlm are restricted
if any(restrictedi2List == n)
    i2Restricted = true;
end
end