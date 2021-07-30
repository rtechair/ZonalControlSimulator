classdef Result < handle
   
    properties
        % State
        PowerBranchFlow         % Fij
        PowerCurtailment        % PC
        PowerBattery            % PB
        EnergyBattery           % EB
        PowerGeneration         % PG
        PowerAvailable          % PA
        
        % Control
        ControlCurtailment      % DeltaPC
        ControlBattery          % DeltaPB
        
        % Disturbance
        DisturbanceTransit      % DeltaPT
        DisturbanceGeneration   % DeltaPG
        DisturbanceAvailable    % DeltaPA
        
        CurrentStep             % k
    end
    
    properties ( SetAccess = immutable)
        zoneName
        SamplingTime
        NumberOfIterations
        
        NumberOfBuses
        NumberOfBranches
        NumberOfGen
        NumberOfBatt
                    
        MaxPowerGeneration
        
        BusId
        BranchIdx
        GenOnIdx
        
        DelayCurt
        DelayBatt
        DelayTimeSeries2Zone
        DelayController2Zone
        DelayZone2Controller
    end
    
    methods
        
        function obj = Result(zoneName, durationSimulation, samplingTime, ...
                numberOfBuses, numberOfBranches, numberOfGenerators, numberOfBatteries, ...
                maxPowerGeneration, busId, branchIdx, genOnIdx, delayCurt, delayBatt, ...
                delayTimeSeries2Zone, delayController2Zone, delayZone2Controller)
            obj.zoneName = zoneName;
            obj.NumberOfIterations = floor(durationSimulation / samplingTime);
            obj.NumberOfBuses = numberOfBuses;
            obj.NumberOfBranches = numberOfBranches;
            obj.NumberOfGen = numberOfGenerators;
            obj.NumberOfBatt = numberOfBatteries;
            
            obj.MaxPowerGeneration = maxPowerGeneration;
            obj.SamplingTime = samplingTime;
            
            obj.BusId = busId;
            obj.BranchIdx = branchIdx;
            obj.GenOnIdx = genOnIdx;
            
            obj.DelayCurt = delayCurt;
            obj.DelayBatt = delayBatt;
            
            obj.DelayTimeSeries2Zone = delayTimeSeries2Zone;
            obj.DelayController2Zone = delayController2Zone;
            obj.DelayZone2Controller = delayZone2Controller;
            
            obj.CurrentStep = 0;
            
            % State
            obj.PowerBranchFlow = zeros(numberOfBranches, obj.NumberOfIterations + 1);
            obj.PowerCurtailment = zeros(numberOfGenerators, obj.NumberOfIterations + 1);
            obj.PowerBattery = zeros(numberOfBatteries, obj.NumberOfIterations + 1);
            obj.EnergyBattery = zeros(numberOfBatteries, obj.NumberOfIterations + 1);
            obj.PowerGeneration = zeros(numberOfGenerators, obj.NumberOfIterations + 1);
            obj.PowerAvailable = zeros(numberOfGenerators, obj.NumberOfIterations + 1);
            
            % Control
            obj.ControlCurtailment = zeros(numberOfGenerators, obj.NumberOfIterations);
            obj.ControlBattery = zeros(numberOfBatteries, obj.NumberOfIterations);
            
            % Disturbance 
            obj.DisturbanceTransit = zeros(numberOfBuses, obj.NumberOfIterations);
            obj.DisturbanceGeneration = zeros(numberOfGenerators, obj.NumberOfIterations);
            obj.DisturbanceAvailable = zeros(numberOfGenerators, obj.NumberOfIterations);
        end
        
        
        function saveState(obj, powerBranchFlow, powerCurtailment, powerBattery, ...
                energyBattery, powerGeneration, powerAvailable)
            obj.PowerBranchFlow(:, obj.CurrentStep + 1) = powerBranchFlow;
            obj.PowerCurtailment(:, obj.CurrentStep + 1) = powerCurtailment;
            obj.PowerBattery(:, obj.CurrentStep + 1) = powerBattery;
            obj.EnergyBattery(:, obj.CurrentStep + 1) = energyBattery;
            obj.PowerGeneration(:, obj.CurrentStep + 1) = powerGeneration;
            obj.PowerAvailable(:, obj.CurrentStep + 1) = powerAvailable;
        end
        
        function saveControl(obj, controlCurt, controlBatt)
            obj.ControlCurtailment(:, obj.CurrentStep) = controlCurt;
            obj.ControlBattery(:, obj.CurrentStep) = controlBatt;
        end
        
        function saveDisturbance(obj, transit, generation, available)
            obj.DisturbanceTransit(:, obj.CurrentStep) = transit;
            obj.DisturbanceGeneration(:, obj.CurrentStep) = generation;
            obj.DisturbanceAvailable(:, obj.CurrentStep) = available;
        end
        
        function prepareForNextStep(obj)
            obj.CurrentStep = obj.CurrentStep + 1;
        end
 
    end
    
end