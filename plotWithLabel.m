function P = plotWithLabel(graphStatic, basecase, busId, genOnIdx, battOnIdx)
% plot the static graph given as input while modifying the legend
% 3 modifications in the plot:
% - buses in busId are red
% - buses with a generator display 'Gen' next to their id
% - buses with a battery display 'Batt' next to their id
% INPUT
% - graphStatic

    % unique to remove redundancy as several generators can be on a same bus
    busWithGenOn = unique(basecase.gen(genOnIdx,1));
    busWithBattOn = unique(basecase.gen(battOnIdx,1)); % a battery is considered as a generator with negative min Power
    
    isBusWithGenOn = ismember(busId, busWithGenOn);
    isBusWithBattOn = ismember(busId, busWithBattOn);
    
    figureGraph = figure('Name', 'Graph of the zone with its border',...
        'NumberTitle', 'off', 'WindowState', 'maximize');
    P = plot(graphStatic);
    %% Configurate basic properties
    % Node
    P.NodeColor = 'k'; % k = black
    P.NodeFontSize = 16;
    P.MarkerSize = 12; % node size
    % Edge
    P.EdgeColor = 'k';
    P.LineWidth = 3;
    P.EdgeLabelColor = 'k';
    
    % display each bus in busId in red
    % highlight(P, string(busId), 'NodeColor','r')
    % zone1_bus = [1445 2076 2135 2745 4720 10000]';
    % highlight(P, string(zone1_bus), 'NodeColor','r')
    % zone2_bus = [2506 4169 4546 4710 4875 4915]';
    %highlight(P, string(zone2_bus), 'NodeColor','r')
    
    % for each bus, show a text displaying: bus id, if there is a
    % generator and if there is a battery
    for bus = 1: size(busId,1)
        % default texts:
        textGen = '';
        textBatt = '';
        
        % show there is a generator on the bus
        if isBusWithGenOn(bus)
            textGen = ' Gen ';
        end
        % show there is a battery on the bus
        if isBusWithBattOn(bus)
            textBatt = ' Batt ';
        end
        
        % label to display
        textNode = [num2str(busId(bus,1)), textGen, textBatt];
        labelnode(P, string(busId(bus,1)), textNode);
    end    
end

% https://www.mathworks.com/help/matlab/math/label-graph-nodes-and-edges.html
% https://www.mathworks.com/help/matlab/math/graph-plotting-and-customization.html
% https://www.mathworks.com/help/matlab/ref/matlab.graphics.chart.primitive.graphplot.html
% https://www.mathworks.com/help/matlab/ref/graph.plot.html#namevaluepairarguments