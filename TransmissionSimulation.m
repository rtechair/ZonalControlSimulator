classdef TransmissionSimulation < handle
   
    properties
       grid
       simulationSetting
       zoneName
       zone
    end
   
    methods 
        function obj = TransmissionSimulation(filenameSimulation)
            obj.simulationSetting = decodeJsonFile(filenameSimulation);
        end
    end
end