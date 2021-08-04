classdef TransmissionSimulation < handle
   
    properties
       grid
       simulationSetting
       zoneName
       numberOfZones
       zone
    end
   
    methods
        function obj = TransmissionSimulation(filenameSimulation)
            obj.simulationSetting = decodeJsonFile(filenameSimulation);
            obj.setZoneName();
            obj.setNumberOfZones();
            obj.setGrid();
            obj.setZone();
            obj.initializeSimulation();
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
        
        function initializeSimulation(obj)
            for z = 1:obj.numberOfZones
               obj.zone{z}.initializePowerAvailable();
               obj.zone{z}.initializePowerGeneration();
               
               genOnIdx = obj.zone{z}.getGenOnIdx();
               powerGeneration = obj.zone{z}.getPowerGeneration();
               obj.grid.updateGeneration(genOnIdx, powerGeneration);
               
               battOnIdx = obj.zone{z}.getBattOnIdx;
               powerBattery = obj.zone{z}.getPowerBattery;
               obj.grid.updateBattInjection(battOnIdx, powerBattery);
            end
        end
        
    end
end