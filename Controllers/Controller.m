classdef (Abstract) Controller < handle
% Act as an interface between the simulator and the future controllers

    methods (Abstract)
        
        computeControl;
        
        getControl;
        
        receiveState;
        
        receiveDisturbancePowerTransit;
        
    end
    
end