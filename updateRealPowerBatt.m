function [basecase, basecase_int] = updateRealPowerBatt(basecase, basecase_int, zone, instant)
% update the real power generation / consumption of the zone's batteries at
% a given instant, in both the external and internal basecases
    arguments
        basecase struct
        basecase_int struct {mustBeInternalBasecase(basecase_int)}
        zone {mustBeA(zone, 'Zone')}
        instant (1,1) {mustBeInteger,mustBePositive}
    end
    mustBePositive(zone.NumberIteration)
    % instant <= 1 + zone.NumberIteration 
    mustBeLessThanOrEqual(instant, 1 + zone.NumberIteration);
    
    newRealPower = zone.PB(:,instant);
    %TODO: handling when PB is computed, but there is no battOn, what
    %behiavor
    %to expect?
    
    basecase.gen(zone.BattOnIdx,2) = newRealPower;
    basecase_int.gen(zone.BattOnIntIdx,2) = newRealPower;
end