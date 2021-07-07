classdef (Abstract) Controller < handle
    
    properties (Abstract)
        % StateOfZone
        % DisturbanceTransit
        %{
        QueueCurtControlsNotYetApplied
        QueueBatteryControlsNotYetApplied
        %}
        % ControlOfZone
        %DelayBattery
        %DelayCurtailment
        
        % BranchFlowLimit
        
    end
    
    methods (Abstract)
        
        computeControl(stateOfZone, disturbanceTransit);
        
        getControl();
        
    end
    
end