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
                obj.zone{k} = Zone(name, obj.grid);
            end
        end
        
    end
end