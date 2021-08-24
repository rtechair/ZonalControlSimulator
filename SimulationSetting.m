classdef SimulationSetting < handle
% Read and interpret the JSON file into an object to get the parameters of the simulation.
% when the configuration of the JSON file is modified, the setters
% need to be modify as well to depict the changes.

    properties (SetAccess = protected)
        %% All settings are in the property 'settings'. The Setter methods
        %% extract the parameters into the other properties.        
        settings
        
        basecase
        duration
        window % i.e. the time step of the simulation
        zoneName
        numberOfZones
    end
    
    methods
        
        function obj = SimulationSetting(simulationFilename)
            obj.settings = decodeJsonFile(simulationFilename);
            
            obj.setBasecase();
            obj.setDuration();
            obj.setWindow();
            obj.setZoneName();
            obj.setNumberOfZones();
        end
        
        %% SETTER
        function setBasecase(obj)
            obj.basecase = obj.settings.basecase;
        end
        
        function setDuration(obj)
            obj.duration = obj.settings.durationInSeconds;
        end
        
        function setWindow(obj)
            obj.window = obj.settings.windowInSeconds;
        end
        
        function setZoneName(obj)
            % the 'cell' data structure is used instead of 'matrix'.
            % A matrix merges char arrays into a single char array, which
            % would concatenate the zone names, which is not the desired behavior.
           obj.zoneName = struct2cell(obj.settings.Zone);
        end
        
        function setNumberOfZones(obj)
            obj.numberOfZones = size(obj.zoneName,1);
        end
        
        %% GETTER
        function string = getBasecase(obj)
            string = obj.basecase;
        end
        
        function value = getDuration(obj)
            value = obj.duration;
        end
        
        function value = getWindow(obj)
            value = obj.window;
        end
        
        function cell = getZoneName(obj)
            cell = obj.zoneName;
        end
        
        function value = getNumberOfZones(obj)
            value = obj.numberOfZones;
        end
    end
end