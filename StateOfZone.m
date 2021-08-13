classdef StateOfZone < handle
   
    properties
       powerCurtailment % PC
       powerBattery     % PB
       energyBattery    % EB
       powerGeneration  % PG
    end
    
    properties (SetAccess = protected, GetAccess = protected)
       powerFlow        % Fij
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
        
        function value = getPowerFlow(obj)
            value = obj.powerFlow;
        end
        
        function value = getPowerAvailable(obj)
            value = obj.powerAvailable;
        end
        
        function setPowerFlow(obj, value)
            obj.powerFlow = value;
        end
        
        function setPowerAvailable(obj, value)
            obj.powerAvailable = value;
        end
        
    end
end