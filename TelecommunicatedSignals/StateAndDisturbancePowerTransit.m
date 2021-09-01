classdef StateAndDisturbancePowerTransit < handle
% Wrapper class of an object STATE + a value DISTURBANCE POWER TRANSIT
% such that the telecommunication, from the zone to the controller,
% manipulates 1 object instead 1 object + 1 value.
   properties (SetAccess = protected, GetAccess = protected)
      stateOfZone
      disturbancePowerTransit
   end
    
   methods
       function obj = StateAndDisturbancePowerTransit(objectStateOfZone, valueDisturbancePowerTransit)
           obj.stateOfZone = objectStateOfZone;
           obj.disturbancePowerTransit = valueDisturbancePowerTransit;
       end
       
       function object = getStateOfZone(obj)
           object = obj.stateOfZone;
       end
       
       function value = getDisturbancePowerTransit(obj)
           value = obj.disturbancePowerTransit;
       end
   end
end