classdef StateAndDisturbanceTransit < handle
    
   properties
      stateOfZone
      disturbancePowerInTransit
   end
    
   methods
       function obj = StateAndDisturbanceTransit(stateOfZone, disturbancePowerInTransit)
           obj.stateOfZone = stateOfZone;
           obj.disturbancePowerInTransit = disturbancePowerInTransit;
                       
       end
       
       function state = getStateOfZone(obj)
           state = obj.stateOfZone;
       end
       
       function distTransit = getDisturbanceTransit(obj)
           distTransit = obj.disturbancePowerInTransit;
       end
   end
end