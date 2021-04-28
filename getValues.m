function [valueArray] = getValues(mapObj,keyArray)
    % 'getValues' returns values of containers.Map object corresponding to
    % the keys array. Internally, it calls 'values' function which requires
    % keys as a cell array
    
    % Examples:
    % TODO
    arguments
        mapObj containers.Map
        keyArray
    end
    % Convert array to cell array, as 'values' function requires a cell array
    keySet = num2cell(keyArray);
    valueSet = values(mapObj, keySet);
    % Convert cell array to array
    valueArray = cell2mat(valueSet);
end