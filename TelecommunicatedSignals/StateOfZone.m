classdef StateOfZone < handle
    
    properties (SetAccess = protected)
       powerFlow        % Fij
       powerCurtailment % PC
       powerBattery     % PB, if PB > 0, the battery is used. if PB < 0, the battery is recharged.
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
        
        %% Getter
        function value = getPowerFlow(obj)
            value = obj.powerFlow;
        end
        
        function value = getPowerCurtailment(obj)
            value = obj.powerCurtailment;
        end
        
        function value = getPowerBattery(obj)
            value = obj.powerBattery;
        end
        
        function value = getEnergyBattery(obj)
            value = obj.energyBattery;
        end
        
        function value = getPowerGeneration(obj)
            value = obj.powerGeneration;
        end
        
        function value = getPowerAvailable(obj)
            value = obj.powerAvailable;
        end
        
        %% Setter
        function setPowerFlow(obj, value)
            obj.powerFlow = value;
        end
        
        function setPowerCurtailment(obj, value)
            obj.powerCurtailment = value;
        end
        
        function setPowerBattery(obj, value)
            obj.powerBattery = value;
        end
        
        function setEnergyBattery(obj, value)
            obj.energyBattery = value;
        end
        
        function setPowerGeneration(obj, value)
            obj.powerGeneration = value;
        end
        
        function setPowerAvailable(obj, value)
            obj.powerAvailable = value;
        end
        
        %% Evolution
        function setInitialPowerGeneration(obj, maxPowerGeneration)
            obj.powerGeneration = min(obj.powerAvailable, ...
                maxPowerGeneration - obj.powerCurtailment);
        end
        
        function updateEnergyBattery(obj, controlBattery, battConstPowerReduc)
            % energyBattery requires powerBattery, thus the former must be
            % updated prior to the latter
            obj.energyBattery = obj.energyBattery ...
                - battConstPowerReduc * (obj.powerBattery + controlBattery);
        end
        
        function updatePowerAvailable(obj, disturbancePowerAvailable)
            obj.powerAvailable = obj.powerAvailable + disturbancePowerAvailable;
        end
        
        function updatePowerGeneration(obj, disturbancePowerGeneration, controlCurtailment)
            obj.powerGeneration = obj.powerGeneration ...
                + disturbancePowerGeneration - controlCurtailment;
        end
        
        function updatePowerCurtailment(obj, controlCurtailment)
            obj.powerCurtailment = obj.powerCurtailment + controlCurtailment;
        end
        
        function updatePowerBattery(obj, controlBattery)
            obj.powerBattery = obj.powerBattery + controlBattery;
        end
        
    end
end