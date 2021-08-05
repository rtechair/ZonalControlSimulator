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
            obj.simulationSetting = decodeJsonFile(filenameSimulation);
            obj.duration = obj.simulationSetting.durationInSeconds;
            obj.step = obj.simulationSetting.windowInSeconds;
            obj.start = obj.step;
            
            obj.setZoneName();
            obj.setNumberOfZones();
            obj.setGrid();
            obj.setZone();
            
            obj.initialize();
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
            for k = 1:obj.numberOfZones
                name = obj.zoneName{k};
                duration = obj.simulationSetting.durationInSeconds;
                obj.zone{k} = Zone(name, obj.grid, duration);
            end
        end
        
        function initializeZonePowerAvailable(obj)
            for zoneNumber = 1:obj.numberOfZones
               obj.zone{zoneNumber}.initializePowerAvailable();
            end
        end
        
        function initializeZonePowerGeneration(obj)
           for zoneNumber = 1:obj.numberOfZones
              obj.zone{zoneNumber}.initializePowerGeneration();
           end
        end
        
        function updateGridGenerationForOneZone(obj, zoneNumber)
            genOnIdx = obj.zone{zoneNumber}.getGenOnIdx();
            powerGeneration = obj.zone{zoneNumber}.getPowerGeneration();
            obj.grid.updateGeneration(genOnIdx, powerGeneration);
        end
        
        function updateGridGeneration(obj)
            for zoneNumber = 1:obj.numberOfZones
               obj.updateGridGenerationForOneZone(zoneNumber); 
            end
        end
        
        function updateGridBatteryInjectionForOneZone(obj, zoneNumber)
            battOnIdx = obj.zone{zoneNumber}.getBattOnIdx;
            powerBattery = obj.zone{zoneNumber}.getPowerBattery;
            obj.grid.updateBattInjection(battOnIdx, powerBattery);
        end
        
        function updateGridBatteryInjection(obj)
           for zoneNumber = 1:obj.numberOfZones
              obj.updateGridBatteryInjectionForOneZone(zoneNumber);
           end
        end
        
        function updateGridPowerFlow(obj)
           obj.grid.runPowerFlow();
        end
        
        function updateZonePowerFlow(obj)
           for zoneNumber = 1:obj.numberOfZones
               obj.zone{zoneNumber}.updatePowerFlow(obj.grid);
           end
        end
        
        function updateZonePowerTransit(obj)
            for zoneNumber = 1:obj.numberOfZones
                obj.zone{zoneNumber}.updatePowerTransit(obj.grid);
            end
        end
        
        function dropZoneOldestPowerTransit(obj)
            for zoneNumber = 1:obj.numberOfZones
                obj.zone{zoneNumber}.dropOldestPowerTransit();
            end
        end
        
        function saveZoneState(obj)
            for zoneNumber = 1:obj.numberOfZones
                obj.zone{zoneNumber}.saveState();
            end
        end
        
        function transmitDataZone2Controller(obj)
            % Warning, this method transmits data for all zones, regardless
            % of their control cycles. Thus, be cautious
            for zoneNumber = 1:obj.numberOfZones
                obj.zone{zoneNumber}.transmitDataZone2Controller();
            end
        end
        
        function prepareZoneForNextStep(obj)
            % Warning, this method transmits data for all zones, regardless
            % of their control cycles. Thus, be cautious
            for zoneNumber = 1:obj.numberOfZones
                obj.zone{zoneNumber}.prepareForNextStep();
            end
        end
    end
end