classdef TransmissionSimulation < handle
   
    properties
       grid
       simulationSetting
       zoneName
       numberOfZones
       zone
       
       duration
       start
       step
       currentTime
    end
   
    methods
        function obj = TransmissionSimulation(filenameSimulation)
            %% set elements
            obj.simulationSetting = decodeJsonFile(filenameSimulation);
            obj.duration = obj.simulationSetting.durationInSeconds;
            obj.step = obj.simulationSetting.windowInSeconds;
            obj.start = obj.step;
            
            obj.setZoneName();
            obj.setNumberOfZones();
            obj.setGrid();
            obj.setZone();
            
            obj.initialize();
            
            obj.runSimulation();
        end
        
        function runSimulation(obj)
            for time = obj.start:obj.step:obj.duration
                for i = 1:obj.numberOfZones
                    if obj.zone{i}.isToBeSimulated(time)
                        obj.zone{i}.simulate(); %TODO
                        obj.grid.updateBasecase(); %TODO
                    end
                end
                
                obj.grid.runPowerFlow()
                
                for i = 1:obj.numberOfZones
                    if obj.zone{i}.isToBeSimulated(time)
                        obj.zone{i}.updatePowerFlow(); %TODO
                        obj.zone{i}.saveResult(); %TODO
                        obj.zone{i}.prepareForNextStep()
                    end
                end
            end
        end
        
        function initialize(obj)
            obj.initializeZonePowerAvailable();
            obj.initializeZonePowerGeneration();
            
            obj.updateGridGeneration();
            obj.updateGridBatteryInjection();
            
            obj.updateGridPowerFlow();
            
            obj.updateZonePowerFlow();
            obj.updateZonePowerTransit();
            
            % do not compute disturbance transit initially, as there is not enough data
            obj.dropZoneOldestPowerTransit();
            obj.saveZoneState();
            obj.transmitDataZone2Controller();
            obj.prepareZoneForNextStep();
        end
        
        function setZoneName(obj)
            % the 'cell' data structure is used instead of 'matrix'.
            % A matrix merges char arrays into a single char array, which
            % would concatenate the zone names, which is not the desired behavior.
           obj.zoneName = struct2cell(obj.simulationSetting.Zone);
        end
        
        function setNumberOfZones(obj)
            obj.numberOfZones = size(obj.zoneName,1);
        end
        
        function setGrid(obj)
            obj.grid = ElectricalGrid(obj.simulationSetting.basecase);
        end
        
        function setZone(obj)
            obj.zone = cell(obj.numberOfZones,1);
            for i = 1:obj.numberOfZones
                name = obj.zoneName{i};
                obj.zone{i} = Zone(name, obj.grid, obj.duration);
            end
        end
        
        function initializeZonePowerAvailable(obj)
            for i = 1:obj.numberOfZones
               obj.zone{i}.initializePowerAvailable();
            end
        end
        
        function initializeZonePowerGeneration(obj)
           for i = 1:obj.numberOfZones
              obj.zone{i}.initializePowerGeneration();
           end
        end
        
        function updateGridGenerationForOneZone(obj, zoneNumber)
            genOnIdx = obj.zone{zoneNumber}.getGenOnIdx();
            powerGeneration = obj.zone{zoneNumber}.getPowerGeneration();
            obj.grid.updateGeneration(genOnIdx, powerGeneration);
        end
        
        function updateGridGeneration(obj)
            for i = 1:obj.numberOfZones
               obj.updateGridGenerationForOneZone(i); 
            end
        end
        
        function updateGridBatteryInjectionForOneZone(obj, zoneNumber)
            battOnIdx = obj.zone{zoneNumber}.getBattOnIdx;
            powerBattery = obj.zone{zoneNumber}.getPowerBattery;
            obj.grid.updateBattInjection(battOnIdx, powerBattery);
        end
        
        function updateGridBatteryInjection(obj)
           for i = 1:obj.numberOfZones
              obj.updateGridBatteryInjectionForOneZone(i);
           end
        end
        
        function updateGridPowerFlow(obj)
           obj.grid.runPowerFlow();
        end
        
        function updateZonePowerFlow(obj)
           for i = 1:obj.numberOfZones
               obj.zone{i}.updatePowerFlow(obj.grid);
           end
        end
        
        function updateZonePowerTransit(obj)
            for i = 1:obj.numberOfZones
                obj.zone{i}.updatePowerTransit(obj.grid);
            end
        end
        
        function dropZoneOldestPowerTransit(obj)
            for i = 1:obj.numberOfZones
                obj.zone{i}.dropOldestPowerTransit();
            end
        end
        
        function saveZoneState(obj)
            for i = 1:obj.numberOfZones
                obj.zone{i}.saveState();
            end
        end
        
        function transmitDataZone2Controller(obj)
            % Warning, this method transmits data for all zones, regardless
            % of their control cycles. Thus, be cautious
            for i = 1:obj.numberOfZones
                obj.zone{i}.transmitDataZone2Controller();
            end
        end
        
        function prepareZoneForNextStep(obj)
            % Warning, this method transmits data for all zones, regardless
            % of their control cycles. Thus, be cautious
            for i = 1:obj.numberOfZones
                obj.zone{i}.prepareForNextStep();
            end
        end
    end
end