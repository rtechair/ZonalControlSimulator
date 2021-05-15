function mustBusBeFromBasecase(bus_id, basecase)
% check all buses are present in the basecase, otherwise abrupt the program
    if ~all(ismember(bus_id, basecase.bus(:,1)))
        eidType = 'mustBusBeFromBasecase:busNotFromBasecase';
        msgType = 'bus_id must be full of buses id present in the basecase.';
        throwAsCaller(MException(eidType, msgType))
    end
end