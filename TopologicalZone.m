classdef TopologicalZone < handle
    
    
    properties
        BusId
        BranchIdx
        GenOnIdx % offline generators within the zone are not considered
        BattOnIdx % offline batteries withing the zone are not considered
        
        BusBorderId
        BranchBorderIdx
        
        NumberOfBuses
        NumberOfBranches
        NumberOfGen
        NumberOfBatt
               
    end
    
    methods
        function obj = TopologicalZone(busId, electricalGrid)
            arguments
                busId (:,1) {mustBeInteger}
                electricalGrid
            end
            obj.BusId = busId;
            
            
            obj.setBranchesInZoneAndInBorder(electricalGrid);
            
            obj.setBusBorderId(electricalGrid);
            
            obj.setGenOnIdx(electricalGrid);
            obj.setBattOnIdx(electricalGrid);
            %obj.setGenAndBattOnIdx(electricalGrid);
            
            obj.setNumberOfElements();

        end
        
        function genOffIdx = getGenOffIdx(obj, electricalGrid)
            genOffIdx = electricalGrid.getGenOffIdx(obj.BusId);
        end
         
        function battOffIdx = getBattOffIdx(obj, electricalGrid)
            battOffIdx = electricalGrid.getBattOffIdx(obj.BusId);
        end
        
        function G = getGraphStatic(obj, electricalGrid)
            % Create the static graph of a zone defined by its branch indices in the
            % basecase.
        
            insideAndBorderBranches = [obj.BranchIdx; obj.BranchBorderIdx];
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
            busIdWithGenOn = electricalGrid.getBuses(obj.GenOnIdx);
            busIdWithBattOn = electricalGrid.getBuses(obj.BattOnIdx);
            
            isBusOfZoneWithGenOn = ismember(obj.BusId, busIdWithGenOn);
            isBusOfZoneWithBattOn = ismember(obj.BusId, busIdWithBattOn);
            
            figureGraph = figure('Name', 'Graph of the zone with its border',...
            'NumberTitle', 'off', 'WindowState', 'maximize');
    
            graphStatic = obj.getGraphStatic(electricalGrid);
            P = plot(graphStatic);
            P = obj.configurePlot(P);
            
            % display in red color, each bus inside the zone
            highlight(P, string(obj.BusId), 'NodeColor', 'r')
            
            % for each bus, show a text displaying: bus id, if there is a
            % generator and if there is a battery
            for bus = 1: size(obj.BusId,1)
               %TODO
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
               textNode = [num2str(obj.BusId(bus, 1)), textGen, textBatt];
               labelnode(P, string(obj.BusId(bus, 1)), textNode);
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
            [obj.BranchIdx, obj.BranchBorderIdx] = ...
                electricalGrid.getInnerAndBorderBranchIdx(obj.BusId);
        end
        
        function setBusBorderId(obj, electricalGrid)
            obj.BusBorderId = electricalGrid.getBusBorderId(obj.BusId, obj.BranchBorderIdx);
        end
        
        function setGenOnIdx(obj, electricalGrid)
            obj.GenOnIdx = electricalGrid.getGenOnIdx(obj.BusId);
        end
        
        function setBattOnIdx(obj, electricalGrid)
            obj.BattOnIdx = electricalGrid.getBattOnIdx(obj.BusId);
        end
        
        %{
        function setGenAndBattOnIdx(obj, electricalGrid)
            [obj.GenOnIdx, obj.BattOnIdx] = electricalGrid.getGenAndBattOnIdx(...
                obj.BusId);
        end
        %}
        function setNumberOfElements(obj)                     
            obj.NumberOfBuses = size(obj.BusId,1);
            obj.NumberOfBranches = size(obj.BranchIdx,1);
            obj.NumberOfGen = size(obj.GenOnIdx,1);
            obj.NumberOfBatt = size(obj.BattOnIdx,1);
        end
    end
end