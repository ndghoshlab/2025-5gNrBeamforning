classdef nrCQITables  < comm.internal.ConfigBase
    %nrCQITables CQI lookup tables
    %   CQITables = nrCQITables creates a channel quality indicator (CQI)
    %   lookup tables object that contains the 4-bit CQI tables, as defined
    %   in TS 38.214 Section 5.2.2.1
    %
    %   nrCQITables constant properties:
    %
    %   CQITable1 - Table containing the 4-bit CQI Table,
    %               corresponding to TS 38.214 Table 5.2.2.1-2
    %   CQITable2 - Table containing the 4-bit CQI Table 2,
    %               corresponding to TS 38.214 Table 5.2.2.1-3
    %   CQITable3 - Table containing the 4-bit CQI Table 3,
    %               corresponding to TS 38.214 Table 5.2.2.1-4
    %   CQITable4 - Table containing the 4-bit CQI Table 4,
    %               corresponding to TS 38.214 Table 5.2.2.1-5
    %
    %   The columns in each table are CQIIndex, Modulation, Qm,
    %   TargetCodeRate, and SpectralEfficiency. A table value NaN
    %   corresponds to the "out of range" value from the technical
    %   specification.
    %
    %   Example 1: 
    %   % Create an nrCQITables object, get the code rate from a CQI
    %   % index.
    %
    %   iCQI = 1; 
    %   cqiTables = nrCQITables;
    %   cqiTableOne = cqiTables.CQITable1;
    %   tcr = cqiTableOne.TargetCodeRate(cqiTableOne.CQIIndex == iCQI);
    %
    %   See also nrPDSCHMCSTables, nrPUSCHMCSTables.

    %   Copyright 2023 The MathWorks, Inc.

    %#codegen 

    % Read-only properties  
    properties (SetAccess=private)
        %CQITable1 - 4-bit CQI table, corresponding to TS 38.214 Table 5.2.2.1-2
        %   The table contains a column Qm for the number of bits per
        %   modulation symbol in addition to the columns from the
        %   specification. The TargetCodeRate column contains the
        %   fractional target code rates, which are obtained by dividing
        %   the target code rate values from the specification by 1024.
        CQITable1;

        %CQITable2 - CQI table 2, corresponding to TS 38.214 Table 5.2.2.1-3
        %   The table contains a column Qm for the number of bits per
        %   modulation symbol in addition to the columns from the
        %   specification. The TargetCodeRate column contains the
        %   fractional target code rates, which are obtained by dividing
        %   the target code rate values from the specification by 1024.
        CQITable2;

        %CQITable3 - CQI table 3, corresponding to TS 38.214 Table 5.2.2.1-4
        %   The table contains a column Qm for the number of bits per
        %   modulation symbol in addition to the columns from the
        %   specification. The TargetCodeRate column contains the
        %   fractional target code rates, which are obtained by dividing
        %   the target code rate values from the specification by 1024.
        CQITable3;

        %CQITable4 - CQI table 4, corresponding to TS 38.214 Table 5.2.2.1-5
        %   The table contains a column Qm for the number of bits per
        %   modulation symbol in addition to the columns from the
        %   specification. The TargetCodeRate column contains the
        %   fractional target code rates, which are obtained by dividing
        %   the target code rate values from the specification by 1024.
        CQITable4;
    end

    methods
        % Constructor
        function obj = nrCQITables()
            % CQI Table 1 - TS 38.214 Table 5.2.2.1-2
            obj.CQITable1 = table(...
                [0; 1; 2; 3; 4; 5; 6; 7; 8; 9; 10; 11; 12; 13; 14; 15], ...
                {'Out of Range'; 'QPSK'; 'QPSK'; 'QPSK'; 'QPSK'; 'QPSK'; 'QPSK'; '16QAM'; '16QAM'; '16QAM'; '64QAM'; '64QAM'; '64QAM'; '64QAM'; '64QAM'; '64QAM'}, ...
                [NaN; 2; 2; 2; 2; 2; 2; 4; 4; 4; 6; 6; 6; 6; 6; 6], ...
                [NaN; 0.076172; 0.11719; 0.18848; 0.30078; 0.43848; 0.58789; 0.36914; 0.47852; 0.60156; 0.45508; 0.55371; 0.65039; 0.75391; 0.85254; 0.92578], ...
                [NaN; 0.1523; 0.2344; 0.377; 0.6016; 0.877; 1.1758; 1.4766; 1.9141; 2.4063; 2.7305; 3.3223; 3.9023; 4.5234; 5.1152; 5.5547], ...
                'VariableNames', {'CQIIndex', 'Modulation', 'Qm', 'TargetCodeRate', 'SpectralEfficiency'});
            
            % CQI Table 2 - TS 38.214 Table 5.2.2.1-3
            obj.CQITable2 = table(...
                [0; 1; 2; 3; 4; 5; 6; 7; 8; 9; 10; 11; 12; 13; 14; 15], ...
                {'Out of Range'; 'QPSK'; 'QPSK'; 'QPSK'; '16QAM'; '16QAM'; '16QAM'; '64QAM'; '64QAM'; '64QAM'; '64QAM'; '64QAM'; '256QAM'; '256QAM'; '256QAM'; '256QAM'}, ...
                [NaN; 2; 2; 2; 4; 4; 4; 6; 6; 6; 6; 6; 8; 8; 8; 8], ...
                [NaN; 0.076172; 0.18848; 0.43848; 0.36914; 0.47852; 0.60156; 0.45508; 0.55371; 0.65039; 0.75391; 0.85254; 0.69434; 0.77832; 0.86426; 0.92578], ...
                [NaN; 0.1523; 0.377; 0.877; 1.4766; 1.9141; 2.4063; 2.7305; 3.3223; 3.9023; 4.5234; 5.1152; 5.5547; 6.2266; 6.9141; 7.4063], ...
                'VariableNames', {'CQIIndex', 'Modulation', 'Qm', 'TargetCodeRate', 'SpectralEfficiency'});
            
            % CQI Table 3 - TS 38.214 Table 5.2.2.1-4
            obj.CQITable3 = table(...
                [0; 1; 2; 3; 4; 5; 6; 7; 8; 9; 10; 11; 12; 13; 14; 15], ...
                {'Out of Range'; 'QPSK'; 'QPSK'; 'QPSK'; 'QPSK'; 'QPSK'; 'QPSK'; 'QPSK'; 'QPSK'; '16QAM'; '16QAM'; '16QAM'; '64QAM'; '64QAM'; '64QAM'; '64QAM'}, ...
                [NaN; 2; 2; 2; 2; 2; 2; 2; 2; 4; 4; 4; 6; 6; 6; 6], ...
                [NaN; 0.029297; 0.048828; 0.076172; 0.11719; 0.18848; 0.30078; 0.43848; 0.58789; 0.36914; 0.47852; 0.60156; 0.45508; 0.55371; 0.65039; 0.75391], ...
                [NaN; 0.0586; 0.0977; 0.1523; 0.2344; 0.377; 0.6016; 0.877; 1.1758; 1.4766; 1.9141; 2.4063; 2.7305; 3.3223; 3.9023; 4.5234], ...
                'VariableNames', {'CQIIndex', 'Modulation', 'Qm', 'TargetCodeRate', 'SpectralEfficiency'});
            
            % CQI Table 4 - TS 38.214 Table 5.2.2.1-5
            obj.CQITable4 = table(...
                [0; 1; 2; 3; 4; 5; 6; 7; 8; 9; 10; 11; 12; 13; 14; 15], ...
                {'Out of Range'; 'QPSK'; 'QPSK'; 'QPSK'; '16QAM'; '16QAM'; '64QAM'; '64QAM'; '64QAM'; '64QAM'; '256QAM'; '256QAM'; '256QAM'; '256QAM'; '1024QAM'; '1024QAM'}, ...
                [NaN; 2; 2; 2; 4; 4; 6; 6; 6; 6; 8; 8; 8; 8; 10; 10], ...
                [NaN; 0.076172; 0.18848; 0.43848; 0.36914; 0.60156; 0.55371; 0.65039; 0.75391; 0.85254; 0.69434; 0.77832; 0.86426; 0.92578; 0.83301; 0.92578], ...
                [NaN; 0.1523; 0.377; 0.877; 1.4766; 2.4063; 3.3223; 3.9023; 4.5234; 5.1152; 5.5547; 6.2266; 6.9141; 7.4063; 8.3301; 9.2578], ...
                'VariableNames', {'CQIIndex', 'Modulation', 'Qm', 'TargetCodeRate', 'SpectralEfficiency'});
        end
   end
    
end