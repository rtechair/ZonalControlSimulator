classdef mapBus_id2idx_idx2idTest < matlab.unittest.TestCase
    methods(Test)
        %% simple matpower cases from the documentation
        function case5(testCase)
            idx2id2idx('case5', testCase)
            id2idx2id('case5', testCase)
        end

        function case9(testCase)
            idx2id2idx('case9',testCase)
            id2idx2id('case9',testCase)
        end
        %% Rte instances, from the documentation
        function case1888rte(testCase)
            idx2id2idx('case1888rte',testCase)
            id2idx2id('case1888rte',testCase)
        end
        
        function case1951rte(testCase)
            idx2id2idx('case1951rte',testCase)
            id2idx2id('case1951rte',testCase)
        end
        
        function case2848rte(testCase)
            idx2id2idx('case2848rte',testCase)
            id2idx2id('case2848rte',testCase)
        end
        
        function case6468rte(testCase)
            idx2id2idx('case6468rte',testCase)
            id2idx2id('case6468rte',testCase)
        end
        
        function case6515rte(testCase)
            idx2id2idx('case6515rte',testCase)
            id2idx2id('case6515rte',testCase)
        end
        
        function case6468rte_zone1and2(testCase)
            idx2id2idx('case6468rte_zone1and2',testCase)
            id2idx2id('case6468rte_zone1and2',testCase)
        end
    end
end

function idx2id2idx(namecase, testCase)
    % Realize a double conversion bus_idx -> bus_id -> bus_idx, to check if
    % the mapping does a full circle
    [mapBus_id2idx, mapBus_idx2id, ~, bus_idx] = prepConversion(namecase);
    % conversion idx -> id -> idx
    actualConversion = mapBus_id2idx( mapBus_idx2id(bus_idx));
    testCase.verifyEqual(actualConversion, sparse(bus_idx));
end

function id2idx2id(namecase, testCase)
    % Realize a double conversion bus_id -> bus_idx -> bus_id, to check if
    % the mapping does a full circle
    [mapBus_id2idx, mapBus_idx2id, bus_id, ~] = prepConversion(namecase);
    % conversion id -> idx -> id
    actualConversion = mapBus_idx2id( mapBus_id2idx(bus_id));
    testCase.verifyEqual(actualConversion, bus_id);
    
end

function [mapBus_id2idx, mapBus_idx2id, bus_id, bus_idx] = prepConversion(namecase)
    basecase = loadcase(namecase);
    n_bus = size(basecase.bus,1);
    bus_id = basecase.bus(:,1);
    bus_idx = (1:n_bus)'; % column vector
    [mapBus_id2idx, mapBus_idx2id] = mapBus_id2idx_idx2id(basecase);
end