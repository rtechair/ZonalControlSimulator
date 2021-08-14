classdef ZoneTopology < handle
    
    
    properties (SetAccess = protected, GetAccess = protected)
        name
        
        busId
        branchIdx
        genOnIdx % offline generators within the zone are not considered
        battOnIdx % offline batteries withing the zone are not considered
        
        busBorderId
        branchBorderIdx
        
        maxPowerGeneration
        
        numberOfBuses
        numberOfBranches
        numberOfGenOn
        numberOfBattOn
    end
    
    methods
        function obj = ZoneTopology(name, zoneBusId, electricalGrid)
            arguments
                name
                zoneBusId (:,1) {mustBeInteger}
                electricalGrid
            end
            obj.name = name;
            obj.busId = zoneBusId;
            
            obj.setBranchesInZoneAndInBorder(electricalGrid);
            obj.setBusBorderId(electricalGrid);
            
            obj.setGenOnIdx(electricalGrid);
            obj.setBattOnIdx(electricalGrid);
            
            obj.setMaxPowerGeneration(electricalGrid);
                        
            obj.setNumberOfElements();
        end
        
        function genOffIdx = getGenOffIdx(obj, electricalGrid)
            genOffIdx = electricalGrid.getGenOffIdx(obj.busId);
        end
         
        function battOffIdx = getBattOffIdx(obj, electricalGrid)
            battOffIdx = electricalGrid.getBattOffIdx(obj.busId);
        end
        
        function G = getGraphStatic(obj, electricalGrid)
            % Create the static graph of a zone defined by its branch indices in the
            % basecase.
        
            insideAndBorderBranches = [obj.branchIdx; obj.branchBorderIdx];
            [fromBus, toBus] = electricalGrid.getEndBuses(insideAndBorderBranches);
            %{
                %https://www.mathworks.com/help/matlab/ref/graph.html
                Matlab's Graph object cares about the value / id of nodes, it will print as many nodes as
                 the max id of nodes; e.g. if a node's number is 1000,
                then Matlab assumes this is the 1000th node and will plot 1000 nodes, even
                if it is the only node of the graph. Therefore, node's numbers are
                converted into strings to avoid this strange behavior.
            %}
            G = graph(string(fromBus), string(toBus)); 
        end
        
        function P = plotLabeledGraph(obj, electricalGrid)
            % plot the static graph given as input while modifying the legend
            % 3 modifications in the plot:
            % - buses in busId are red
            % - buses with a generator display 'Gen' next to their id
            % - buses with a battery display 'Batt' next to their id

            %{
                https://www.mathworks.com/help/matlab/math/label-graph-nodes-and-edges.html
                https://www.mathworks.com/help/matlab/math/graph-plotting-and-customization.html
                https://www.mathworks.com/help/matlab/ref/matlab.graphics.chart.primitive.graphplot.html
                https://www.mathworks.com/help/matlab/ref/graph.plot.html#namevaluepairarguments
            %}
            % unique to remove redundancy as several generators can be on a same bus
            busIdWithGenOn = electricalGrid.getBuses(obj.genOnIdx);
            busIdWithBattOn = electricalGrid.getBuses(obj.battOnIdx);
            
            isBusOfZoneWithGenOn = ismember(obj.busId, busIdWithGenOn);
            isBusOfZoneWithBattOn = ismember(obj.busId, busIdWithBattOn);
            
            figName = ['Zone ' obj.name ': red node = bus within zone, black node = bus at the border'];
            figure('name', figName, 'NumberTitle', 'off', 'WindowState', 'maximize');    
            graphStatic = obj.getGraphStatic(electricalGrid);
            P = plot(graphStatic);
            P = obj.configurePlot(P);
            
            % display in red color, each bus inside the zone
            highlight(P, string(obj.busId), 'NodeColor', 'r')
            
            % for each bus, show a text displaying: bus id, if there is a
            % generator and if there is a battery
            for bus = 1: size(obj.busId,1)
               % default texts:
               textGen = '';
               textBatt ='';
               
               % show there is a generator on the bus
               if isBusOfZoneWithGenOn(bus)
                   textGen = ' Gen ';
               end
               
               % show there is a battery on the bus
               if isBusOfZoneWithBattOn(bus)
                   textBatt = ' Batt ';
               end
               
               % label to display
               textNode = [num2str(obj.busId(bus, 1)), textGen, textBatt];
               labelnode(P, string(obj.busId(bus, 1)), textNode);
            end
            
        end
        
        function P = configurePlot(obj, P)
            % Node
            P.NodeColor = 'k'; % k = black
            P.NodeFontSize = 16;
            P.MarkerSize = 12; % node size
            % Edge
            P.EdgeColor = 'k';
            P.LineWidth = 3;
            P.EdgeLabelColor = 'k';
        end
        
    end
    
    methods (Access = protected)
       
        function setBranchesInZoneAndInBorder(obj, electricalGrid)
            [obj.branchIdx, obj.branchBorderIdx] = ...
                electricalGrid.getInnerAndBorderBranchIdx(obj.busId);
        end
        
        function setBusBorderId(obj, electricalGrid)
            obj.busBorderId = electricalGrid.getBusBorderId(obj.busId, obj.branchBorderIdx);
        end
        
        function setGenOnIdx(obj, electricalGrid)
            obj.genOnIdx = electricalGrid.getGenOnIdx(obj.busId);
        end
        
        function setBattOnIdx(obj, electricalGrid)
            obj.battOnIdx = electricalGrid.getBattOnIdx(obj.busId);
        end
        
        function setMaxPowerGeneration(obj, electricalGrid)
           obj.maxPowerGeneration = electricalGrid.getMaxPowerGeneration(obj.genOnIdx); 
        end
        
        function setNumberOfElements(obj)                     
            obj.numberOfBuses = size(obj.busId,1);
            obj.numberOfBranches = size(obj.branchIdx,1);
            obj.numberOfGenOn = size(obj.genOnIdx,1);
            obj.numberOfBattOn = size(obj.battOnIdx,1);
        end
    end
end