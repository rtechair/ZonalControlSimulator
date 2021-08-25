classdef Zone < handle
% Zone is an aggregate class of the following objects:
% - the 3 telecommunications involved in the zone:
%        - zone->controller
%        - controller->zone
%        - time series->zone
% - the topology of the zone
% - the evolution of the zone over the time of the simulation
% - the time series which dictates what is the available power for the
% generators
% - the controller
% - the result of the simulation
% - other elements required for the simulation
%
% Column vectors are used instead of row vectors, e.g.
% busId, branchIdx, zoneEvolution's properties, etc.
% The reason is for consistency with column vectors obtained from Matpower
% functions [1].
% Hence, rows corresponds to elements, such as buses, branches, generators and
% batteries, while columns corresponds to time steps.
%  
% [1] https://matpower.org/docs/ref/


    properties (SetAccess = protected)
       name
       setting
       
       delayInIterations
       topology
       zoneEvolution
       
       telecomZone2Controller
       telecomController2Zone
       telecomTimeSeries2Zone
       
       controllerSetting
       controller
       timeSeries
       
       result
    end
    
    methods
        function obj = Zone(name, electricalGrid, duration)
            obj.name = name;
            obj.setSetting();
            obj.setDelayInIterations();
            obj.setTopology(electricalGrid);
            obj.setTimeSeries(duration);
            obj.setZoneEvolution();
            obj.setTelecom();
            obj.setResult(duration);
            obj.setControllerSetting();
            obj.setController();
        end
        
        function setSetting(obj)
            filename = obj.getFilename();
            obj.setting = ZoneSetting(filename);
        end
        
        function zoneFilename = getFilename(obj)
            zoneFilename = ['zone' obj.name '.json'];
        end
        
        function setDelayInIterations(obj)
            obj.delayInIterations = getDelayInIterations(obj.setting);
            
        end
        
        function setTopology(obj, electricalGrid)
           busId = obj.setting.getBusId();
           obj.topology = ZoneTopology(obj.name, busId, electricalGrid);
        end
        
        function setTimeSeries(obj, duration)
            obj.timeSeries = getTimeSeries(obj.setting, obj.topology, duration);
        end
        
        function setZoneEvolution(obj)
            obj.zoneEvolution = getZoneEvolution(obj.setting, obj.topology, obj.delayInIterations);
        end
        
        function setTelecom(obj)
            [obj.telecomTimeSeries2Zone, obj.telecomController2Zone, obj.telecomZone2Controller] = ...
                getTelecom(obj.topology, obj.delayInIterations);
        end
        
        function setResult(obj, duration)
            obj.result = getResult(obj.setting, obj.topology, obj.delayInIterations, duration, ...
                obj.name);
        end
        
        % WARNING: the following function is for the limiter,
        % it can not be used for other types of controllers.
        % Hence, it will be later modified TODO
        function limiterFilename = getLimiterFilename(obj)
            limiterFilename = ['limiter' obj.name '.json'];
        end
        
        function setControllerSetting(obj)
           obj.controllerSetting = decodeJsonFile(obj.getLimiterFilename());
        end
        
        % WARNING: actually this function sets a limiter as the controller
        % TODO: handle the case when it is not the limiter
        function setController(obj)
            branchFlowLimit = obj.setting.getBranchFlowLimit();
            numberOfBattOn = obj.topology.getNumberOfBattOn();
            increasingEchelon = obj.controllerSetting.IncreaseCurtPercentEchelon;
            decreasingEchelon = obj.controllerSetting.DecreaseCurtPercentEchelon;
            lowerThreshold = obj.controllerSetting.LowerThresholdPercent;
            upperThreshold = obj.controllerSetting.UpperThresholdPercent;
            
            delayCurt = obj.delayInIterations.getDelayCurt();
            maxPowerGeneration = obj.topology.getMaxPowerGeneration();
            
            obj.controller = Limiter(branchFlowLimit, numberOfBattOn, ...
                increasingEchelon, decreasingEchelon, lowerThreshold, upperThreshold, ...
                delayCurt, maxPowerGeneration);
        end
        
        function initializePowerAvailable(obj)
            obj.zoneEvolution.setInitialPowerAvailable(obj.timeSeries);
        end
        
        function initializePowerGeneration(obj)
           obj.zoneEvolution.setInitialPowerGeneration();
        end
        
        %{
        The zone sends to the controller all the information about its state,
        but only one disturbance: the power transiting through the buses.
        That is why the zone uses an object 'state' but not an object
        'Disturbance' to store the Power Transit.
        %}
        function updatePowerFlow(obj, electricalGrid)
            branchIdx = obj.topology.getBranchIdx();
            state = obj.zoneEvolution.getState();
            powerFlow = electricalGrid.getPowerFlow(branchIdx);
            state.setPowerFlow(powerFlow);
        end
        
        function updatePowerTransit(obj, electricalGrid)
            busId = obj.topology.getBusId();
            branchBorderIdx = obj.topology.getBranchBorderIdx();
            obj.zoneEvolution.updatePowerTransit(electricalGrid, busId, branchBorderIdx);
        end
        
        function updateGrid(obj,electricalGrid)
            obj.updateGridGeneration(electricalGrid);
            obj.updateGridBattInjection(electricalGrid);
        end
        
        function updateGridGeneration(obj, electricalGrid)
            genOnIdx = obj.topology.getGenOnIdx();
            state = obj.zoneEvolution.getState();
            powerGeneration = state.getPowerGeneration();
            electricalGrid.updateGeneration(genOnIdx, powerGeneration);
        end
        
        function updateGridBattInjection(obj, electricalGrid)
            battOnIdx = obj.topology.getBattOnIdx();
            state = obj.zoneEvolution.getState();
            powerBattery = state.getPowerBattery();
            electricalGrid.updateBattInjection(battOnIdx, powerBattery);
        end
        
        function dropOldestPowerTransit(obj)
            obj.zoneEvolution.dropOldestPowerTransit();
        end
        
        function saveState(obj)
            obj.zoneEvolution.saveState(obj.result);
        end
        
        function transmitDataController2Zone(obj)
            obj.telecomController2Zone.transmitData(obj.controller, obj.zoneEvolution);
        end
        
        function transmitDataTimeSeries2Zone(obj)
            obj.telecomTimeSeries2Zone.transmitData(obj.timeSeries, obj.zoneEvolution);
        end
        
        function transmitDataZone2Controller(obj)
            obj.telecomZone2Controller.transmitData(obj.zoneEvolution, obj.controller);
        end
        
        function prepareForNextStep(obj)
            obj.timeSeries.prepareForNextStep();
            obj.result.prepareForNextStep();
            
            obj.zoneEvolution.dropOldestPowerTransit();
            obj.zoneEvolution.dropOldestControl();
        end
        
        function boolean = isItTimeToUpdate(obj, currentTime, timeStep)
            previousTime = currentTime - timeStep;
            controlCycle = obj.setting.getcontrolCycleInSeconds();
            
            % Iterations are defined by the euclidian division:
            % time = iterations * controlCycle + remainder, with 0 <= remainder < controlCycle
            previousIteration = obj.getEuclideanQuotient(previousTime, controlCycle);
            currentIteration = obj.getEuclideanQuotient(currentTime, controlCycle);
            
            boolean = currentIteration > previousIteration;
        end
        
        % This method does not use the object, it is here to be close to its caller method
        function quotient = getEuclideanQuotient(obj, dividend, divisor)
            % dividend = divisor * quotient + remainder, with 0 <= remainder < quotient
            quotient = floor(dividend / divisor);
        end
        
        function simulate(obj)
            obj.controller.computeControl();
            obj.controller.saveControl(obj.result);
            obj.transmitDataController2Zone();
            obj.transmitDataTimeSeries2Zone();
            obj.zoneEvolution.computeDisturbancePowerGeneration();
            obj.zoneEvolution.updateState();
        end
        
        function update(obj, electricalGrid)
            obj.updatePowerFlow(electricalGrid);
            obj.updatePowerTransit(electricalGrid);
            obj.zoneEvolution.updateDisturbancePowerTransit();
            
            obj.transmitDataZone2Controller();
        end
        
        function saveResult(obj)
            obj.zoneEvolution.saveState(obj.result);
            obj.zoneEvolution.saveDisturbance(obj.result);
        end
        
        function plotTopology(obj, electricalGrid)
            obj.topology.plotLabeledGraph(electricalGrid);
        end
        
        function plotResult(obj, electricalGrid)
            obj.result.plotAbsoluteFlowBranch(electricalGrid);
            obj.result.plotControlAndDisturbanceGen(electricalGrid);
            obj.result.plotStateGen(electricalGrid);
            obj.result.plotDisturbanceTransit();
        end
        
        %% GETTER
        function object = getZoneEvolution(obj)
            object = obj.zoneEvolution;
        end
    end
end