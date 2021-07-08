classdef Zone < handle
    
    properties
       
       TopologicalZone
       SimulatedZone
       Telecom
       TimeSeries
       Controller
       Limiter

       TelecomTimeSeries2Zone
       TelecomController2Zone
       TelecomZone2Controller

       Memory

       SamplingTime
    end
    
    methods
        
        function obj = Zone(inputZone, inputLimiter, electricalGrid, filenameWind, ...
         branchFlowLimit, durationSimulation, delayTelecomTS2Z, delayTelecomC2Z, delayTelecomZ2C)
            obj.SamplingTime = inputZone.samplingTime;
            obj.TopologicalZone = TopologicalZone(inputZone.BusId, electricalGrid);

            obj.TimeSeries = DynamicTimeSeries(filenameWind, inputZone.StartTimeSeries, ...
                inputZone.SamplingTime, durationSimulation, inputZone.MaxGeneration, ...
                obj.TopologicalZone.NumberOfGen);

            obj.SimulatedZone = SimulatedZone(obj.TopologicalZone.NumberOfBuses,...
                obj.TopologicalZone.NumberOfGen, obj.TopologicalZone.NumberOfBatt, ...
                obj.TopologicalZone.NumberOfBranches, inputZone.DelayCurt, inputZone.DelayBatt,...
                inputZone.MaxGeneration, inputZone.BattConstPowerReduc);

            obj.Limiter = Limiter(branchFlowLimit, obj.TopologicalZone.NumberOfGen,...
                TopologicalZone.NumberOfBatt, inputLimiter.increasec\CurtPercentEchelon,...
                inputLimiter.decreaseCurtPercentEchelon, inputLimiter.lowerThresholdPercent, ...
                inputLimiter.upperThresholdPercent, inputZone.DelayCurt, inputZone.MaxGeneration);
            obj.Telecom = telecommunication;
            
            %% Telecom
            obj.TelecomTimeSeries2Zone = telecomTimeSeries2Zone(delayTelecomTS2Z, obj.TopologicalZone.NumberOfGen);
            
            obj.TelecomController2Zone = TelecomController2Zone(delayTelecomC2Z, obj.TopologicalZone.NumberOfGen, ...
                obj.TopologicalZone.NumberOfBatt);
            
            obj.TelecomZone2Controller = Telecomzone2Controller(delayTelecomZ2C, obj.TopologicalZone.NumberOfGen, ...
                obj.TopologicalZone.NumberOfBatt, obj.TopologicalZone.NumberOfBuses, obj.TopologicalZone.NumberOfBranches);

            %% Memory
            obj.Memory = Memory(durationSimulation, inputZone.SamplingTime, obj.TopologicalZone.NumberOfBuses, ...
                obj.TopologicalZone.NumberOfBranches, obj.TopologicalZone.NumberOfGen, obj.TopologicalZone.NumberOfBatt, ...
                    inputZone.MaxGeneration, obj.TopologicalZone.GenOnIdx, obj.TopologicalZone.BranchIdx, ...
                    inputZone.DelayCurt, inputZone.DelayBatt);
            
            
            
                
        end
        
        %% CHEATING below, need t obe later changed due to the direct access
        function initializePartialState(obj, inputZone)
            % set PA(0) directly
            obj.SimulatedZone.State.PowerAvailable = obj.TimeSeries.PowerAvailableState(:,1);
            obj.SimulatedZone.State.PowerGeneration = min( obj.TimeSeries.PowerAvailableState(:,1), ...
               inputZone.MaxGeneration);
        end
        
        function updateElectricalGrid(obj, electricalGrid)
            electricalGrid.updateGeneration(obj.TopologicalZone.GenOnIdx, obj.SimulatedZone.State.PowerGeneration);
            electricalGrid.updateBattInjection(obj.TopologyZone.BattOnIdx, obj.SimulatedZone.State.PowerBattery);
        end
        
        function updatePowerBranchFlow(obj, electricalGrid)
            obj.simulatedZone.State.updatePowerBranchFlow(obj.TopologyZone.BranchIdx, electricalGrid);
        end
        
        function saveState(obj)
           obj.SimulatedZone.saveState(obj.Memory); 
        end
        
    end
            
    
end
