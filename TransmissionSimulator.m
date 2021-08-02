classdef TransmissionSimulator < handle
    
    properties
        SimulationSetting
        
    end
    
    
    methods
        function obj = TransimissionSimulator(filenameSimulation)
            obj.SimulationSetting = decodeJsonFile(filenameSimulation);
        end
    end
end