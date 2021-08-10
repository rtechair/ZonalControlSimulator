classdef ZoneEvolution < handle
    
   
    properties
        state
        
        bufferQueueControlCurt
        bufferQueueControlBatt
        
        bufferQueuePowerTransit
        
        disturbanceTransit
        DisturbanceGeneration
        DisturbanceAvailable
    end
    
    properties (SetAccess = immutable)
       numberOfBuses
       numberOfGen
       numberOfBatt
       
       
       delayCurtSeconds
       delayBattSeconds
       controlCycle
       delayCurt
       delayBatt
       
       maxPowerGeneration
       
       %{
        From the paper 'Modeling the Partial Renewable Power Curtailment
        for Transmission Network Management', battConstPowerReduc corresponds to:
        T * C_n^B in the battery energy equation
        %}
       battConstPowerReduc
    end
    
    methods
       
        function obj = ZoneEvolution(numberOfBuses, numberOfBranches, numberOfGenerators, numberOfBatteries, ...
                delayCurtailmentInSeconds, delayBatteryInSeconds, controlCycle, ...
                maxGeneration, battConstPowerReduc)
            obj.numberOfBuses = numberOfBuses;
            obj.numberOfGen = numberOfGenerators;
            obj.numberOfBatt = numberOfBatteries;
            
            obj.delayCurtSeconds = delayCurtailmentInSeconds;
            obj.delayBattSeconds = delayBatteryInSeconds;
            obj.controlCycle = controlCycle;
            obj.delayCurt = ceil(delayCurtailmentInSeconds / controlCycle);
            obj.delayBatt = ceil(delayBatteryInSeconds / controlCycle);
            
            obj.maxPowerGeneration = maxGeneration;
            obj.battConstPowerReduc = battConstPowerReduc;
            
            % blank state
            obj.state = StateOfZone(numberOfBranches, numberOfGenerators, numberOfBatteries);
            
            
            % blank buffers
            obj.bufferQueueControlCurt = zeros(numberOfGenerators, obj.delayCurt);
            obj.bufferQueueControlBatt = zeros(numberOfBatteries, obj.delayBatt);
            
            obj.bufferQueuePowerTransit = zeros(obj.numberOfBuses,1);
            
            % blank transit disturbance
            obj.disturbanceTransit = zeros(numberOfBuses, 1);
            
        end
        
        function receiveTimeSeries(obj, disturbancePowerAvailable)
            obj.DisturbanceAvailable = disturbancePowerAvailable.getValue();
        end
        
        function receiveControl(obj, controlOfZone)
            obj.bufferQueueControlCurt(:,end+1) = controlOfZone.controlCurtailment;
            obj.bufferQueueControlBatt(:,end+1) = controlOfZone.controlBattery;
        end
        
        function dropOldestControl(obj)
            obj.bufferQueueControlCurt = obj.bufferQueueControlCurt(:, 2:end);
            obj.bufferQueueControlBatt = obj.bufferQueueControlBatt(:, 2:end);
        end
        
        function updatePowerTransit(obj, electricalGrid, zoneBusesId, branchBorderIdx)
            obj.bufferQueuePowerTransit(:,end+1) = ...
                electricalGrid.getPowerTransit(zoneBusesId, branchBorderIdx);
        end
                
        function updateDisturbanceTransit(obj)
            obj.disturbanceTransit = obj.bufferQueuePowerTransit(:,2) - obj.bufferQueuePowerTransit(:,1);
        end
        
        function dropOldestPowerTransit(obj)
            obj.bufferQueuePowerTransit = obj.bufferQueuePowerTransit(:, 2:end);
        end
        
        function saveState(obj, memory)
            memory.saveState(obj.state.powerBranchFlow, ...
                obj.state.powerCurtailment, ...
                obj.state.powerBattery,...
                obj.state.energyBattery,...
                obj.state.powerGeneration,...
                obj.state.powerAvailable);
        end
        
        function saveDisturbance(obj, memory)
            memory.saveDisturbance(obj.disturbanceTransit,...
                obj.DisturbanceGeneration,...
                obj.DisturbanceAvailable);
        end
        
        function object = getStateAndDistTransit(obj)
            object = StateAndDisturbanceTransit(obj.state, obj.disturbanceTransit);
        end
        
        function computeDisturbanceGeneration(obj)
            % DeltaPG = min(f,g)
            % with  f = PA    + DeltaPA - PG + DeltaPC(k - delayCurt)
            % and   g = maxPG - PC      - PG
            f = obj.state.powerAvailable ...
                + obj.DisturbanceAvailable ...
                - obj.state.powerGeneration ...
                + obj.bufferQueueControlCurt(:,1);
            g = obj.maxPowerGeneration...
                - obj.state.powerCurtailment...
                - obj.state.powerGeneration;
            obj.DisturbanceGeneration = min(f,g);
        end
        
        function updateState(obj)
            appliedControlCurt = obj.bufferQueueControlCurt(:,1);
            appliedControlBatt = obj.bufferQueueControlBatt(:, 1);
            
            % energyBattery requires powerBattery, thus the former must be
            % updated prior to the latter
            % EB += -cb * ( PB(k) + DeltaPB(k - delayBatt) )
            obj.state.energyBattery = obj.state.energyBattery ...
                - obj.battConstPowerReduc * ...
                ( obj.state.powerBattery + appliedControlBatt);
            
            % PA += DeltaPA
            obj.state.powerAvailable = obj.state.powerAvailable + obj.DisturbanceAvailable;
               
            % PG += DeltaPG(k) - DeltaPC(k - delayCurt)
            obj.state.powerGeneration = obj.state.powerGeneration ...
                + obj.DisturbanceGeneration ...
                - appliedControlCurt;
            
            % PC += DeltaPC(k - delayCurt)
            obj.state.powerCurtailment = obj.state.powerCurtailment + appliedControlCurt;
            
            % PB += DeltaPB(k - delayBatt)
            obj.state.powerBattery = obj.state.powerBattery - appliedControlBatt;
        end
        
        function setInitialPowerAvailable(obj, timeSeries)
           obj.state.powerAvailable = timeSeries.getInitialPowerAvailable(); 
        end
        
        function setInitialPowerGeneration(obj)
           obj.state.powerGeneration = min(obj.state.powerAvailable, obj.maxPowerGeneration); 
        end
    end
    
end