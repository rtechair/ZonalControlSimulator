function [basecase, basecase_int] = updateRealPowerBatt(basecase, basecase_int, zone, instant)
% update the real power generation / consumption of the zone's batteries at
% a given instant, in both the external and internal basecases
    arguments
        basecase struct
        basecase_int struct {mustBeInternalBasecase(basecase_int)}
        zone {mustBeA(zone, 'Zone')}
        instant (1,1) {mustBeInteger,mustBePositive}
    end
    mustBePositive(zone.N_iteration)
    % instant <= 1 + zone.N_iteration 
    mustBeLessThanOrEqual(instant, 1 + zone.N_iteration);
    
    newRealPower = zone.PB(:,instant);
    %TODO: handling when PB is computed, but there is no battOn, what
    %behiavor
    %to expect?
    
    basecase.gen(zone.BattOn_idx,2) = newRealPower;
    basecase_int.gen(zone.BattOn_int_idx,2) = newRealPower;
end