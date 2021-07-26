function [busId, maxPowerGeneration] = readZoneGenerator(jsonFilename)
    zone = jsonDecodeFile(jsonFilename);
    generator = zone.Generator;
    numberOfRows = size(generator,1);
    
    busId = zeros(numberOfRows,1);
    maxPowerGeneration = zeros(numberOfRows,1);
    for k = 1:numberOfRows
        busId(k) = generator{k}.bus;
        maxPowerGeneration(k) = generator{k}.maxPowerGeneration;
    end
end