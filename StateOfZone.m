classdef StateOfZone < handle
   
    properties
       PowerBranchFlow
       PowerCurtailment
       PowerBattery
       EnergyBattery
       PowerGeneration
       PowerAvailable
    end        
    
    methods
        function obj = StateOfZone(numberOfGenerators, numberOfBatteries, numberOfBranches)
            obj.PowerBranchFlow = zeros(numberOfBranches, 1);
            obj.PowerCurtailment = zeros(numberOfGenerators, 1);
            obj.PowerBattery = zeros(numberOfBatteries, 1);
            obj.EnergyBattery = zeros(numberOfBatteries, 1);
            obj.PowerGeneration = zeros(numberOfGenerators, 1);
            obj.PowerAvailable = zeros(numberOfGenerators, 1);
        end
        
        function setPowerBranchFlow(obj, newValue)
            obj.PowerBranchFlow = newValue;
        end
        
        function updatePowerBranchFlow(obj, branchIdx, electricalGrid)
            obj.PowerBranchFlow = electricalGrid.getPowerBranchFlow(branchIdx);
        end
        
    end
end