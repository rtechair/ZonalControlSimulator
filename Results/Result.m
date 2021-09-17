classdef Result < handle
   
    properties (SetAccess = protected)
        % State
        powerBranchFlow         % Fij
        powerCurtailment        % PC
        powerBattery            % PB
        energyBattery           % EB
        powerGeneration         % PG
        powerAvailable          % PA
        
        % Control
        controlCurtailment      % DeltaPC
        controlBattery          % DeltaPB
        
        % Disturbance
        disturbanceTransit      % DeltaPT
        disturbanceGeneration   % DeltaPG
        disturbanceAvailable    % DeltaPA
        
        step             % k
        
        branchFlowLimit  % maxFij
    end
    
    properties ( SetAccess = immutable)
        zoneName
        controlCycle
        numberOfIterations
        
        numberOfBuses
        numberOfBranches
        numberOfGen
        numberOfBatt
                    
        maxPowerGeneration
        
        busId
        branchIdx
        genOnIdx
        battOnIdx
        
        delayCurt
        delayBatt
        delayTimeSeries2Zone
        delayController2Zone
        delayZone2Controller
    end
    
    methods
        
        function obj = Result(zoneName, durationSimulation, controlCycle, ...
                numberOfBuses, numberOfBranches, numberOfGenerators, numberOfBatteries, ...
                maxPowerGeneration, branchFlowLimit, busId, branchIdx, genOnIdx, battOnIdx, delayCurt, delayBatt, ...
                delayTimeSeries2Zone, delayController2Zone, delayZone2Controller)
            obj.zoneName = zoneName;
            obj.numberOfIterations = floor(durationSimulation / controlCycle);
            obj.numberOfBuses = numberOfBuses;
            obj.numberOfBranches = numberOfBranches;
            obj.numberOfGen = numberOfGenerators;
            obj.numberOfBatt = numberOfBatteries;
            
            obj.maxPowerGeneration = maxPowerGeneration;
            obj.branchFlowLimit = branchFlowLimit;
            obj.controlCycle = controlCycle;
            
            obj.busId = busId;
            obj.branchIdx = branchIdx;
            obj.genOnIdx = genOnIdx;
            obj.battOnIdx = battOnIdx;
            
            obj.delayCurt = delayCurt;
            obj.delayBatt = delayBatt;
            
            obj.delayTimeSeries2Zone = delayTimeSeries2Zone;
            obj.delayController2Zone = delayController2Zone;
            obj.delayZone2Controller = delayZone2Controller;
            
            obj.step = 0; % 0, i.e. initialization before the actual simulation
            
            % State
            obj.powerBranchFlow = zeros(numberOfBranches, obj.numberOfIterations + 1);
            obj.powerCurtailment = zeros(numberOfGenerators, obj.numberOfIterations + 1);
            obj.powerBattery = zeros(numberOfBatteries, obj.numberOfIterations + 1);
            obj.energyBattery = zeros(numberOfBatteries, obj.numberOfIterations + 1);
            obj.powerGeneration = zeros(numberOfGenerators, obj.numberOfIterations + 1);
            obj.powerAvailable = zeros(numberOfGenerators, obj.numberOfIterations + 1);
            
            % Control
            obj.controlCurtailment = zeros(numberOfGenerators, obj.numberOfIterations);
            obj.controlBattery = zeros(numberOfBatteries, obj.numberOfIterations);
            
            % Disturbance 
            obj.disturbanceTransit = zeros(numberOfBuses, obj.numberOfIterations);
            obj.disturbanceGeneration = zeros(numberOfGenerators, obj.numberOfIterations);
            obj.disturbanceAvailable = zeros(numberOfGenerators, obj.numberOfIterations);
        end
        
        
        function saveState(obj, powerBranchFlow, powerCurtailment, powerBattery, ...
                energyBattery, powerGeneration, powerAvailable)
            obj.powerBranchFlow(:, obj.step + 1) = powerBranchFlow;
            obj.powerCurtailment(:, obj.step + 1) = powerCurtailment;
            obj.powerBattery(:, obj.step + 1) = powerBattery;
            obj.energyBattery(:, obj.step + 1) = energyBattery;
            obj.powerGeneration(:, obj.step + 1) = powerGeneration;
            obj.powerAvailable(:, obj.step + 1) = powerAvailable;
        end
        
        function saveControl(obj, controlCurt, controlBatt)
            obj.controlCurtailment(:, obj.step) = controlCurt;
            obj.controlBattery(:, obj.step) = controlBatt;
        end
        
        function saveDisturbance(obj, transit, generation, available)
            obj.disturbanceTransit(:, obj.step) = transit;
            obj.disturbanceGeneration(:, obj.step) = generation;
            obj.disturbanceAvailable(:, obj.step) = available;
        end
        
        function prepareForNextStep(obj)
            obj.step = obj.step + 1;
        end
 
    end
    
end