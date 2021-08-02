classdef TransmissionSimulator < handle
    
    properties
        SimulationSetting
        ZoneName
        NumberOfZones
    end
    
    
    methods
        function obj = TransmissionSimulator(filenameSimulation)
            obj.SimulationSetting = decodeJsonFile(filenameSimulation);
        end
        
        
        function setZoneName(obj)
           obj.ZoneName = struct2cell(obj.SimulationSetting.Zone); 
        end
        
        function setNumberOfZones(obj)
            obj.NumberOfZones = size(obj.ZoneName,1);
        end
    end
end