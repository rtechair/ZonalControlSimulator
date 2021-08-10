classdef SimulatedZone < handle
    
   
    properties
        State
        
        BufferQueueControlCurt
        BufferQueueControlBatt
        
        BufferQueuePowerTransit
        
        DisturbanceTransit
        DisturbanceGeneration
        DisturbanceAvailable
    end
    
    properties (SetAccess = immutable)
       NumberOfBuses
       NumberOfGen
       NumberOfBatt
       
       
       DelayCurtSeconds
       DelayBattSeconds
       ControlCycle
       DelayCurt
       DelayBatt
       
       MaxPowerGeneration
       
       %{
        From the paper 'Modeling the Partial Renewable Power Curtailment
        for Transmission Network Management', BattConstPowerReduc corresponds to:
        T * C_n^B in the battery energy equation
        %}
       BattConstPowerReduc
    end
    
    methods
       
        function obj = SimulatedZone(numberOfBuses, numberOfBranches, numberOfGenerators, numberOfBatteries, ...
                delayCurtailmentInSeconds, delayBatteryInSeconds, controlCycle, ...
                maxGeneration, battConstPowerReduc)
            obj.NumberOfBuses = numberOfBuses;
            obj.NumberOfGen = numberOfGenerators;
            obj.NumberOfBatt = numberOfBatteries;
            
            obj.DelayCurtSeconds = delayCurtailmentInSeconds;
            obj.DelayBattSeconds = delayBatteryInSeconds;
            obj.ControlCycle = controlCycle;
            obj.DelayCurt = ceil(delayCurtailmentInSeconds / controlCycle);
            obj.DelayBatt = ceil(delayBatteryInSeconds / controlCycle);
            
            obj.MaxPowerGeneration = maxGeneration;
            obj.BattConstPowerReduc = battConstPowerReduc;
            
            % blank state
            obj.State = StateOfZone(numberOfBranches, numberOfGenerators, numberOfBatteries);
            
            
            % blank buffers
            obj.BufferQueueControlCurt = zeros(numberOfGenerators, obj.DelayCurt);
            obj.BufferQueueControlBatt = zeros(numberOfBatteries, obj.DelayBatt);
            
            obj.BufferQueuePowerTransit = zeros(obj.NumberOfBuses,1);
            
            % blank transit disturbance
            obj.DisturbanceTransit = zeros(numberOfBuses, 1);
            
        end
        
        function receiveTimeSeries(obj, disturbancePowerAvailable)
            obj.DisturbanceAvailable = disturbancePowerAvailable.getValue();
        end
        
        function receiveControl(obj, controlOfZone)
            obj.BufferQueueControlCurt(:,end+1) = controlOfZone.ControlCurtailment;
            obj.BufferQueueControlBatt(:,end+1) = controlOfZone.ControlBattery;
        end
        
        function dropOldestControl(obj)
            obj.BufferQueueControlCurt = obj.BufferQueueControlCurt(:, 2:end);
            obj.BufferQueueControlBatt = obj.BufferQueueControlBatt(:, 2:end);
        end
        
        function updatePowerTransit(obj, electricalGrid, zoneBusesId, branchBorderIdx)
            obj.BufferQueuePowerTransit(:,end+1) = ...
                electricalGrid.getPowerTransit(zoneBusesId, branchBorderIdx);
        end
                
        function updateDisturbanceTransit(obj)
            obj.DisturbanceTransit = obj.BufferQueuePowerTransit(:,2) - obj.BufferQueuePowerTransit(:,1);
        end
        
        function dropOldestPowerTransit(obj)
            obj.BufferQueuePowerTransit = obj.BufferQueuePowerTransit(:, 2:end);
        end
        
        function saveState(obj, memory)
            memory.saveState(obj.State.PowerBranchFlow, ...
                obj.State.PowerCurtailment, ...
                obj.State.PowerBattery,...
                obj.State.EnergyBattery,...
                obj.State.PowerGeneration,...
                obj.State.PowerAvailable);
        end
        
        function saveDisturbance(obj, memory)
            memory.saveDisturbance(obj.DisturbanceTransit,...
                obj.DisturbanceGeneration,...
                obj.DisturbanceAvailable);
        end
        
        function object = getStateAndDistTransit(obj)
            object = StateAndDisturbanceTransit(obj.State, obj.DisturbanceTransit);
        end
        
        function computeDisturbanceGeneration(obj)
            % DeltaPG = min(f,g)
            % with  f = PA    + DeltaPA - PG + DeltaPC(k - delayCurt)
            % and   g = maxPG - PC      - PG
            f = obj.State.PowerAvailable ...
                + obj.DisturbanceAvailable ...
                - obj.State.PowerGeneration ...
                + obj.BufferQueueControlCurt(:,1);
            g = obj.MaxPowerGeneration...
                - obj.State.PowerCurtailment...
                - obj.State.PowerGeneration;
            obj.DisturbanceGeneration = min(f,g);
        end
        
        function updateState(obj)
            appliedControlCurt = obj.BufferQueueControlCurt(:,1);
            appliedControlBatt = obj.BufferQueueControlBatt(:, 1);
            
            % EnergyBattery requires PowerBattery, thus the former must be
            % updated prior to the latter
            % EB += -cb * ( PB(k) + DeltaPB(k - delayBatt) )
            obj.State.EnergyBattery = obj.State.EnergyBattery ...
                - obj.BattConstPowerReduc * ...
                ( obj.State.PowerBattery + appliedControlBatt);
            
            % PA += DeltaPA
            obj.State.PowerAvailable = obj.State.PowerAvailable + obj.DisturbanceAvailable;
               
            % PG += DeltaPG(k) - DeltaPC(k - delayCurt)
            obj.State.PowerGeneration = obj.State.PowerGeneration ...
                + obj.DisturbanceGeneration ...
                - appliedControlCurt;
            
            % PC += DeltaPC(k - delayCurt)
            obj.State.PowerCurtailment = obj.State.PowerCurtailment + appliedControlCurt;
            
            % PB += DeltaPB(k - delayBatt)
            obj.State.PowerBattery = obj.State.PowerBattery - appliedControlBatt;
        end
        
        function setInitialPowerAvailable(obj, timeSeries)
           obj.State.PowerAvailable = timeSeries.getInitialPowerAvailable(); 
        end
        
        function setInitialPowerGeneration(obj)
           obj.State.PowerGeneration = min(obj.State.PowerAvailable, obj.MaxPowerGeneration); 
        end
    end
    
end