classdef TransmissionSimulation < handle
   
    properties
       grid
       simulationSetting
       zoneName
       numberOfZones
       zones
       
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
            obj.setZones();
            
            obj.initialize();
            
            obj.runSimulation();
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
        
        function setZones(obj)
            obj.zones = cell(obj.numberOfZones,1);
            for i = 1:obj.numberOfZones
                name = obj.zoneName{i};
                obj.zones{i} = Zone(name, obj.grid, obj.duration);
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
            
            obj.saveZoneState();
            obj.transmitDataZone2Controller();
            
            obj.dropZoneOldestPowerTransit();
            obj.prepareZoneForNextStep();
        end
        
        function runSimulation(obj)
            for time = obj.start:obj.step:obj.duration
                for i = 1:obj.numberOfZones
                    if obj.zones{i}.isToBeSimulated(time)
                        obj.zones{i}.simulate(); %TODO
                        obj.grid.updateBasecase(); %TODO
                    end
                end
                
                obj.grid.runPowerFlow()
                
                for i = 1:obj.numberOfZones
                    if obj.zones{i}.isToBeSimulated(time)
                        obj.zones{i}.updatePowerFlow(); %TODO
                        obj.zones{i}.saveResult(); %TODO
                        obj.zones{i}.prepareForNextStep()
                    end
                end
            end
        end
        
        function initializeZonePowerAvailable(obj)
            for i = 1:obj.numberOfZones
               obj.zones{i}.initializePowerAvailable();
            end
        end
        
        function initializeZonePowerGeneration(obj)
           for i = 1:obj.numberOfZones
              obj.zones{i}.initializePowerGeneration();
           end
        end
        
        function updateGridGenerationForOneZone(obj, zoneNumber)
            genOnIdx = obj.zones{zoneNumber}.getGenOnIdx();
            powerGeneration = obj.zones{zoneNumber}.getPowerGeneration();
            obj.grid.updateGeneration(genOnIdx, powerGeneration);
        end
        
        function updateGridGeneration(obj)
            for i = 1:obj.numberOfZones
               obj.updateGridGenerationForOneZone(i); 
            end
        end
        
        function updateGridBatteryInjectionForOneZone(obj, zoneNumber)
            battOnIdx = obj.zones{zoneNumber}.getBattOnIdx;
            powerBattery = obj.zones{zoneNumber}.getPowerBattery;
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
               obj.zones{i}.updatePowerFlow(obj.grid);
           end
        end
        
        function updateZonePowerTransit(obj)
            for i = 1:obj.numberOfZones
                obj.zones{i}.updatePowerTransit(obj.grid);
            end
        end
        
        function dropZoneOldestPowerTransit(obj)
            for i = 1:obj.numberOfZones
                obj.zones{i}.dropOldestPowerTransit();
            end
        end
        
        function saveZoneState(obj)
            for i = 1:obj.numberOfZones
                obj.zones{i}.saveState();
            end
        end
        
        function transmitDataZone2Controller(obj)
            % Warning, this method transmits data for all zones, regardless
            % of their control cycles. Thus, be cautious
            for i = 1:obj.numberOfZones
                obj.zones{i}.transmitDataZone2Controller();
            end
        end
        
        function prepareZoneForNextStep(obj)
            % Warning, this method transmits data for all zones, regardless
            % of their control cycles. Thus, be cautious
            for i = 1:obj.numberOfZones
                obj.zones{i}.prepareForNextStep();
            end
        end
    end
end