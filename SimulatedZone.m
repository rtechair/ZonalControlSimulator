classdef SimulatedZone < handle
    
   
    properties
        State
        %Control
        DisturbanceTransit
        DisturbanceGeneration
        DisturbanceAvailable
        BufferQueueControlCurt
        BufferQueueControlBatt
       
    end
    
    properties (SetAccess = immutable)
       NumberOfBuses
       NumberOfGen
       NumberOfBatt
       DelayCurt
       DelayBatt
       
       MaxPowerGeneration
       BattConstPowerReduc
    end
    
    methods
       
        function obj = SimulatedZone(numberOfBuses, numberOfGenerators, numberOfBatteries, ...
                numberOfBranches, delayCurtailment, delayBattery, maxGeneration, ...
                battConstPowerReduc)
            obj.NumberOfGen = numberOfGenerators;
            obj.NumberOfBatt = numberOfBatteries;
            obj.DelayCurt = delayCurtailment;
            obj.DelayBatt = delayBattery;
            obj.MaxPowerGeneration = maxGeneration;
            obj.BattConstPowerReduc = battConstPowerReduc;
            
            % blank state
            obj.State = StateOfZone(numberOfGenerators, numberOfBatteries, ...
                numberOfBranches);
            
            % blank transit disturbance
            obj.DisturbanceTransit = zeros(numberOfBuses, 1);
            
            % blank buffers control
            obj.BufferQueueControlCurt = zeros(numberOfGenerators, delayCurtailment);
            obj.BufferQueueControlBatt = zeros(numberOfBatteries, delayBattery);
            
            %TODO 
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
        
        
        function saveState(obj, memory)
            memory.saveState(obj.State.PowerBranchFlow, ...
                obj.State.PowerCurtailment, ...
                obj.State.PowerBattery,...
                obj.State.EnergyBattery,...
                obj.State.PowerGeneration,...
                obj.State.PowerAvailable);
        end
        
        function saveControl(obj, memory)
            lastControlCurt = obj.BufferQueueControlCurt(:,end);
            lastControlBatt = obj.BufferQueueControlBatt(:,end);
            memory.saveControl(lastControlCurt, lastControlBatt);
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
                + obj.BufferQueueControlCurt(:,end - obj.DelayCurt);
            g = obj.MaxPowerGeneration...
                - obj.State.PowerCurtailment...
                - obj.State.PowerGeneration;
            obj.DisturbanceGeneration = min(f,g);
        end
        
        function updateState(obj)
            appliedControlCurt = obj.BufferQueueControlCurt(:,end - obj.DelayCurt);
            appliedControlBatt = obj.BufferQueueControlBatt(:, end - obj.DelayBatt);
            
            % EnergyBattery requires PowerBattery, thus the former must be
            % updated prior to the latter
            % EB += -CB * ( PB(k) + DeltaPB(k - delayBatt) )
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
    end
    
end