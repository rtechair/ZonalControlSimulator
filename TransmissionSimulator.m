classdef TransmissionSimulator < handle
    
    properties
        SimulationSetting
        ZoneName
    end
    
    
    methods
        function obj = TransmissionSimulator(filenameSimulation)
            obj.SimulationSetting = decodeJsonFile(filenameSimulation);
        end
        
        
        function setZoneName(obj)
           obj.ZoneName = struct2cell(obj.SimulationSetting.Zone); 
        end
    end
end