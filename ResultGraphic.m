classdef ResultGraphic < Result
    
    methods
       
        function obj = ResultGraphic(zoneName,durationSimulation, controlCycle, ...
                numberOfBuses, numberOfBranches, numberOfGenerators, numberOfBatteries, ...
                maxPowerGeneration, busId, branchIdx, genOnIdx, battOnIdx, delayCurt, delayBatt, ...
                delayTimeSeries2Zone, delayController2Zone, delayZone2Controller)
            
           obj@Result(zoneName, durationSimulation, controlCycle, ...
                numberOfBuses, numberOfBranches, numberOfGenerators, numberOfBatteries, ...
                maxPowerGeneration, busId, branchIdx, genOnIdx, battOnIdx, delayCurt, delayBatt, ...
                delayTimeSeries2Zone, delayController2Zone, delayZone2Controller); 
        end
        
        function figStateGenOn = plotStateGen(obj, electricalGrid)
            % plot for each generator On: PA, PC, maxPG - PC, min(PA, maxPG - PC)
            time = 1: obj.NumberOfIterations+1;
            xlegend = 'Number of iterations';
            %layout of the plot
            numberOfRowsOfGraph = ceil(sqrt(obj.NumberOfBuses));
            %% Create the figure
            % see:  https://www.mathworks.com/help/matlab/ref/matlab.ui.figure-properties.html
            figName = ['Zone ' obj.zoneName ': '...
                'Power Available PA, '...
                'Power Curtailment PC, '...
                'Power Generation PG = min(PA, MaxPG - PC), MaxPG - PC'];
            figStateGenOn = figure('Name', figName, 'NumberTitle', 'off', 'WindowState', 'maximize'); 
            %% plot for each generator On: PA, PC, MaxPG - PC, min(PA, MaxPG - PC)
            for gen = 1:obj.NumberOfGen
                % decompose the plot into a square of subplots
                subplot(numberOfRowsOfGraph, numberOfRowsOfGraph, gen);
                hold on;
                stairs(time, obj.PowerAvailable(gen,:), ':'); % PA
                stairs(time, obj.PowerCurtailment(gen, :), '-.'); % PC
                f1 = obj.MaxPowerGeneration(gen) - obj.PowerCurtailment(gen,:);
                stairs(time, f1, '--'); % MaxPG - PC
                stairs(time, min(obj.PowerAvailable(gen, :), f1)); % min(PA, MaxPG - PC)
                
                legend({'PA', 'PC', 'MaxPG - PC', 'PG = min(PA, MaxPG-PC)'},'Location','Best')
                xlabel(xlegend)
                ylabel('Power [MW]')
                genIdx = obj.GenOnIdx(gen);
                busIdOfGen = electricalGrid.getBuses(genIdx);
                name = ['Gen ', int2str(genIdx), ', at ', int2str(busIdOfGen)];
                title(name);
            end
        end
        
        function figDeltaGenOn = plotControlAndDisturbanceGen(obj, electricalGrid)
            time = 1: obj.NumberOfIterations;
            xlegend = 'Number of iterations';
            
            numberOfRowsOfGraph = ceil(sqrt(obj.NumberOfBuses));
            figName = ['Zone ' obj.zoneName ': ' ...
                'Disturbance of Power Available DeltaPA, ' ...
                'Disturbance of Power Generation DeltaPG, '...
                'Taken Control of Power Curtailment DeltaPC, '...
                'Applied Control DeltaPC(step + delayCurt+ delayTelecom)'];
            figDeltaGenOn = figure('Name', figName, 'NumberTitle', 'off', 'WindowState', 'maximize');
            for gen = 1:obj.NumberOfGen
                subplot(numberOfRowsOfGraph, numberOfRowsOfGraph, gen);
                hold on;
                stairs(time, obj.DisturbanceAvailable(gen, :), ':'); % DeltaPA
                stairs(time, obj.DisturbanceGeneration(gen, :)); % DeltaPG
                stairs(time, obj.ControlCurtailment(gen, :), '--'); % DeltaPC: control taken by the controller
                delayForZone = obj.DelayCurt + obj.DelayController2Zone;
                f1 = [zeros(1, delayForZone) ...
                    obj.ControlCurtailment(gen, 1: obj.NumberOfIterations-delayForZone)];
                stairs(time, f1, '-.'); % DeltaPC: control applied on the zone
                        
                legend({'\DeltaPA', '\DeltaPG', '\DeltaPC', ...
                    '\DeltaPC(step+delayCurt + delayTelecom)'}, 'Location', 'Best');
                xlabel(xlegend)
                ylabel('Power [MW]')
                genIdx = obj.GenOnIdx(gen);
                busIdOfGen = electricalGrid.getBuses(genIdx);
                name = ['Gen ', int2str(genIdx), ' at ', int2str(busIdOfGen)];
                title(name);
            end
        end
        
        function figFlowBranch = plotFlowBranch(obj, electricalGrid)
            time = 1: obj.NumberOfIterations+1;
            xlegend = 'Number of iterations';
            numberOfRowsOfPlot = ceil(sqrt(obj.NumberOfBranches));
            figName = ['Zone ' obj.zoneName ': branch power flow Fij'];
            figFlowBranch = figure('Name', figName, 'NumberTitle', 'off', 'WindowState', 'maximize');
            for br = 1:obj.NumberOfBranches
                subplot(numberOfRowsOfPlot, numberOfRowsOfPlot, br);
                hold on;
                stairs(time, obj.PowerBranchFlow(br,:)); % Fij
                legend({'Branch Power Flow Fij'},'Location','Best')
                xlabel(xlegend)
                ylabel('Power [MW]')
                branchIdx = obj.BranchIdx(br);
                [fromBus, toBus] = electricalGrid.getEndBuses(branchIdx);
                name = ['Branch ', int2str(branchIdx), ...
                    ' from ', int2str(fromBus), ' to ', int2str(toBus)]; 
                title(name);
            end
        end
        
        function figAbsFlowBranch = plotAbsoluteFlowBranch(obj, electricalGrid)
            time = 1: obj.NumberOfIterations+1;
            xlegend = 'Number of iterations';
            numberOfRowsOfPlot = ceil(sqrt(obj.NumberOfBranches));
            figName = ['Zone ' obj.zoneName ': absolute branch power flow |Fij|'];
            figAbsFlowBranch = figure('Name', figName, 'NumberTitle', 'off', 'WindowState', 'maximize');
            for br = 1:obj.NumberOfBranches
                subplot(numberOfRowsOfPlot, numberOfRowsOfPlot, br);
                hold on;
                stairs(time, abs(obj.PowerBranchFlow(br,:)));  % abs(Fij)
                legend({'Absolute Branch Power Flow |Fij|'},'Location','Best')
                xlabel(xlegend)
                ylabel('Power [MW]')
                branchIdx = obj.BranchIdx(br);
                [fromBus, toBus] = electricalGrid.getEndBuses(branchIdx);
                name = ['Branch ', int2str(branchIdx), ...
                    ' from ', int2str(fromBus), ' to ', int2str(toBus)]; 
                title(name);
            end
        end
        
        function figDisturbTransit = plotDisturbanceTransit(obj)
           time = 1:obj.NumberOfIterations;
           xlegend = 'Number of iterations';
           numberOfRowsOfPlot = ceil(sqrt( obj.NumberOfBuses));
           figName = ['Zone ' obj.zoneName ': disturbance of Power Transit DeltaPT'];
           figDisturbTransit = figure('Name', figName, 'NumberTitle', 'off', 'WindowState', 'maximize');
           for bus = 1:obj.NumberOfBuses
               subplot(numberOfRowsOfPlot, numberOfRowsOfPlot, bus);
               hold on;
               stairs(time, obj.DisturbanceTransit(bus,:)); % DeltaPT
               legend({'Disturbance transit \DeltaPT'}, 'Location','Best')
               xlabel(xlegend)
               ylabel('Power [MW]')
               busId = obj.BusId(bus);
               name = ['Bus ' int2str(busId)];
               title(name);        
           end
        end
        
        function plotStateAndControlBattery(obj, electricalGrid)
            timeState = 1:obj.NumberOfIterations+1;
            xlegend = 'Number of iterations';
            numberOfRowsOfPlot = ceil(sqrt( obj.NumberOfBatt));
            figName = ['Zone ' obj.zoneName ': State of Energy in Battery EB, '...
               'Control of Battery Injection DeltaPB (DeltaPB > 0 means injection in the battery'];
            figure('Name', figName, 'NumberTitle', 'off', 'WindowState', 'maximize');
            
            for batt = 1:obj.NumberOfBatt
               subplot(numberOfRowsOfPlot, numberOfRowsOfPlot, batt);
               hold on;
               stairs(timeState, obj.PowerBattery(batt,:),':'); % PB
               stairs(timeState, obj.EnergyBattery(batt,:));    % EB
               timeControl = 1:obj.NumberOfIterations;
               stairs(timeControl, obj.ControlBattery(batt,:),'--'); % DeltaPB
               legend({'PB, EB, DeltaPB'}, 'Location', 'Best')
               xlabel(xlegend)
               ylabel('Power [MW]') % TODO: define the unit for energy
               
               battIdx = obj.BattOnIdx(batt);
               busIdOfBatt = electricalGrid.getBuses(battIdx);
               name = ['Batt ', int2str(battIdx), ' at ', int2str(busIdOfBatt)];
               title(name);
            end
        end
        
        function plotAllFigures(obj, electricalGrid)
            obj.plotStateGen(electricalGrid);
            obj.plotControlAndDisturbanceGen(electricalGrid);
            obj.plotAbsoluteFlowBranch(electricalGrid);
            obj.plotDisturbanceTransit();
        end
        
    end
    
end