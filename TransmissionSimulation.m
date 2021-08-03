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
    end
end