%{
SPDX-License-Identifier: Apache-2.0

Copyright 2021 CentraleSupélec and Réseau de Transport d'Électricité (RTE)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
%}

classdef ZoneTopology < handle
% ZoneTopology aims at informing the zone's topology.
%
% Numerical information corresponds to the information contained in the
% 'electricalGrid' object supplied in the constructor.
% Id = Identity
% Idx = Index, i.e. the row of the element in the electricalGrid.
%
% A zone is defined by its buses, its branches, its generators and its
% batteries.
% Mind the distinction between online and offline generators and batteries.
% some generators or batteries can be offline, thus are not taken into
% account for the simulation.
%
% A zone is connected to the rest of the electricalGrid through its border.
% The border is defined by its buses and its branches.
    
    properties (SetAccess = protected)
        name
        
        busId
        branchIdx
        genOnIdx % offline generators within the zone are not considered
        battOnIdx % offline batteries withing the zone are not considered
        
        busBorderId
        branchBorderIdx
        
        maxPowerGeneration
        maxPowerBattery % if PowerBattery > 0, it consumes the battery
        minPowerBattery % if PowerBattery < 0, it charges the battery
        
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
            obj.setMaxPowerBattery(electricalGrid);
            obj.setMinPowerBattery(electricalGrid);
                        
            obj.setNumberOfElements();
        end
        
        %% GETTER
        function value = getBusId(obj)
            value = obj.busId;
        end
        
        function value = getBranchIdx(obj)
            value = obj.branchIdx;
        end
        
        function value = getGenOnIdx(obj)
            value = obj.genOnIdx;
        end
        
        function value = getBattOnIdx(obj)
            value = obj.battOnIdx;
        end
        
        function value = getMaxPowerGeneration(obj)
            value = obj.maxPowerGeneration;
        end
        
        function value = getMaxPowerBattery(obj)
            value = obj.maxPowerBattery;
        end
        
        function value = getMinPowerBattery(obj)
            value = obj.minPowerBattery;
        end
        
        function value = getNumberOfBuses(obj)
            value = obj.numberOfBuses;
        end
        
        function value = getNumberOfBranches(obj)
            value = obj.numberOfBranches;
        end
        
        function value = getNumberOfGenOn(obj)
            value = obj.numberOfGenOn;
        end
        
        function value = getNumberOfBattOn(obj)
            value = obj.numberOfBattOn;
        end
        
        function value = getBranchBorderIdx(obj)
            value = obj.branchBorderIdx;
        end
        
        function value = getGenOffIdx(obj, electricalGrid)
            value = electricalGrid.getGenOffIdx(obj.busId);
        end
         
        function value = getBattOffIdx(obj, electricalGrid)
            value = electricalGrid.getBattOffIdx(obj.busId);
        end
        
        %% GRAPH
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
    
    %% SETTER
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
        
        function setMaxPowerBattery(obj, electricalGrid)
            obj.maxPowerBattery = electricalGrid.getMaxPowerBattery(obj.battOnIdx);
        end
        
        function setMinPowerBattery(obj, electricalGrid)
            obj.minPowerBattery = electricalGrid.getMinPowerBattery(obj.battOnIdx);
        end
        
        function setNumberOfElements(obj)                     
            obj.numberOfBuses = size(obj.busId,1);
            obj.numberOfBranches = size(obj.branchIdx,1);
            obj.numberOfGenOn = size(obj.genOnIdx,1);
            obj.numberOfBattOn = size(obj.battOnIdx,1);
        end
    end
end