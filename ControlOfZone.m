classdef ControlOfZone < handle
% Wrapper class of the 2 controls defined by the controller:
% the control of the generator curtailments
% the control of the battery injections
   properties (SetAccess = protected)
       controlCurtailment
       controlBattery
   end
   
   methods
       function obj = ControlOfZone(controlCurtailment, controlBattery)
           obj.controlCurtailment = controlCurtailment;
           obj.controlBattery = controlBattery;
       end
       
       function value = getControlCurtailment(obj)
           value = obj.controlCurtailment;
       end
       
       function value = getControlBattery(obj)
           value = obj.controlBattery;
       end
   end
   
end