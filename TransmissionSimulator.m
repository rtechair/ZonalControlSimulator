classdef TransmissionSimulator < handle
    
    properties
        SimulationSetting
        ZoneName
        NumberOfZones
        ZoneFilename
    end
    
    
    methods
        function obj = TransmissionSimulator(filenameSimulation)
            obj.SimulationSetting = decodeJsonFile(filenameSimulation);
        end
        
        
        function setZoneName(obj)
            % the 'cell' data structure is used instead of 'matrix'.
            % A matrix merges char arrays into a single char array, which
            % would concatenate the zone names, which is not the desired behavior.
           obj.ZoneName = struct2cell(obj.SimulationSetting.Zone); 
        end
        
        function setNumberOfZones(obj)
            obj.NumberOfZones = size(obj.ZoneName,1);
        end
        
        function setZoneFileName(obj)
           obj.ZoneFilename = cell(obj.NumberOfZones,1);
           for l = 1:obj.NumberOfZones
               obj.ZoneFilename{l} = ['zone' obj.ZoneName{l} '.json'];
           end
        end
    end
end