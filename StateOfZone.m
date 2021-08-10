classdef StateOfZone < handle
   
    properties
       powerBranchFlow  % Fij
       powerCurtailment % PC
       powerBattery     % PB
       energyBattery    % EB
       powerGeneration  % PG
       powerAvailable   % PA
    end        
    
    methods
        function obj = StateOfZone(numberOfBranches, numberOfGenerators, numberOfBatteries)
            obj.powerBranchFlow = zeros(numberOfBranches, 1);
            obj.powerCurtailment = zeros(numberOfGenerators, 1);
            obj.powerBattery = zeros(numberOfBatteries, 1);
            obj.energyBattery = zeros(numberOfBatteries, 1);
            obj.powerGeneration = zeros(numberOfGenerators, 1);
            obj.powerAvailable = zeros(numberOfGenerators, 1);
        end
        
        function setPowerBranchFlow(obj, newValue)
            obj.powerBranchFlow = newValue;
        end
        
        function updatePowerBranchFlow(obj, electricalGrid, branchIdx)
            obj.powerBranchFlow = electricalGrid.getPowerBranchFlow(branchIdx);
        end
        
    end
end