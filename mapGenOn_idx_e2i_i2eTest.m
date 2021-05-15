classdef mapGenOn_idx_e2i_i2eTest < matlab.unittest.TestCase
   methods (Test)
       function case1888rte(testCase)
           mapGenOn_idx_e2i = prepConversion('case1888rte');
           genOn_selection = [140 200 240 298];
           actualConversion = mapGenOn_idx_e2i(genOn_selection);
           expectedConversion = sparse([135 194 234 291]');
           testCase.verifyEqual(actualConversion, expectedConversion);            
       end
       
       function case1888rteGenOff(testCase)
           mapGenOn_idx_e2i = prepConversion('case1888rte');
           genOff_selection = [7 33 38 136];
           actualConversion = mapGenOn_idx_e2i(genOff_selection);
           expectedConversion = sparse(zeros(4,1)); % All zero sparse: 4x1
           testCase.verifyEqual(actualConversion, expectedConversion);
       end
           
           
   end
end

function mapGenOn_idx_e2i = prepConversion(namecase)
   basecase = loadcase(namecase);
   basecase_int = ext2int(basecase);
   [mapGenOn_idx_e2i, ~] = mapGenOn_idx_e2i_i2e(basecase_int);
end

   