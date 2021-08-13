classdef StateOfZone < handle
   
    properties %(SetAccess = protected)
       powerFlow  % Fij
       powerCurtailment % PC
       powerBattery     % PB
       energyBattery    % EB
       powerGeneration  % PG
       powerAvailable   % PA
    end        
    
    methods
        function obj = StateOfZone(numberOfBranches, numberOfGenerators, numberOfBatteries)
            obj.powerFlow = zeros(numberOfBranches, 1);
            obj.powerCurtailment = zeros(numberOfGenerators, 1);
            obj.powerBattery = zeros(numberOfBatteries, 1);
            obj.energyBattery = zeros(numberOfBatteries, 1);
            obj.powerGeneration = zeros(numberOfGenerators, 1);
            obj.powerAvailable = zeros(numberOfGenerators, 1);
        end
        
        function setPowerFlow(obj, value)
            obj.powerFlow = value;
        end
        
        function setPowerAvailable(obj, value)
            obj.PowerAvailable = value;
        end
        
    end
end