classdef ResultGraphic < Result
    
    methods
       
        function obj = ResultGraphic(zoneName,durationSimulation, controlCycle, ...
                numberOfBuses, numberOfBranches, numberOfGenerators, numberOfBatteries, ...
                maxPowerGeneration, branchFlowLimit, busId, branchIdx, genOnIdx, battOnIdx, delayCurt, delayBatt, ...
                delayTimeSeries2Zone, delayController2Zone, delayZone2Controller)
            
           obj@Result(zoneName, durationSimulation, controlCycle, ...
                numberOfBuses, numberOfBranches, numberOfGenerators, numberOfBatteries, ...
                maxPowerGeneration, branchFlowLimit, busId, branchIdx, genOnIdx, battOnIdx, delayCurt, delayBatt, ...
                delayTimeSeries2Zone, delayController2Zone, delayZone2Controller); 
        end
        
        function figStateGenOn = plotStateGen(obj, electricalGrid)
            % plot for each generator On: PA, PC, maxPG - PC, min(PA, maxPG - PC)
            time = 1: obj.numberOfIterations+1;
            xlegend = 'Number of iterations';
            %layout of the plot
            numberOfRowsOfGraph = ceil(sqrt(obj.numberOfBuses));
            %% Create the figure
            % see:  https://www.mathworks.com/help/matlab/ref/matlab.ui.figure-properties.html
            figName = ['Zone ' obj.zoneName ': '...
                'Power Available PA, '...
                'Power Curtailment PC, '...
                'Power Generation PG = min(PA, MaxPG - PC), MaxPG - PC'];
            figStateGenOn = figure('Name', figName, 'NumberTitle', 'off', 'WindowState', 'maximize'); 
            %% plot for each generator On: PA, PC, MaxPG - PC, PG = min(PA, MaxPG - PC)
            for gen = 1:obj.numberOfGen
                % decompose the plot into a square of subplots
                subplot(numberOfRowsOfGraph, numberOfRowsOfGraph, gen);
                hold on;
                stairs(time, obj.powerAvailable(gen,:), ':'); % PA
                stairs(time, obj.powerCurtailment(gen, :), '-.'); % PC
                f1 = obj.maxPowerGeneration(gen) - obj.powerCurtailment(gen,:);
                stairs(time, f1, '--'); % MaxPG - PC
                stairs(time, min(obj.powerAvailable(gen, :), f1)); % min(PA, MaxPG - PC)
                
                legend({'PA', 'PC', 'MaxPG - PC', 'PG = min(PA, MaxPG-PC)'},'Location','Best')
                xlabel(xlegend)
                ylabel('Power [MW]')
                genIdx = obj.genOnIdx(gen);
                busIdOfGen = electricalGrid.getBuses(genIdx);
                name = ['Gen ', int2str(genIdx), ', at ', int2str(busIdOfGen)];
                title(name);
            end
        end
        
        function figDeltaGenOn = plotControlAndDisturbanceGen(obj, electricalGrid)
            time = 1: obj.numberOfIterations;
            xlegend = 'Number of iterations';
            
            numberOfRowsOfGraph = ceil(sqrt(obj.numberOfBuses));
            figName = ['Zone ' obj.zoneName ': ' ...
                'Disturbance of Power Available DeltaPA, ' ...
                'Disturbance of Power Generation DeltaPG, '...
                'Taken Control of Power Curtailment DeltaPC, '...
                'Applied Control DeltaPC(step + delayCurt+ delayTelecom)'];
            figDeltaGenOn = figure('Name', figName, 'NumberTitle', 'off', 'WindowState', 'maximize');
            for gen = 1:obj.numberOfGen
                subplot(numberOfRowsOfGraph, numberOfRowsOfGraph, gen);
                hold on;
                stairs(time, obj.disturbanceAvailable(gen, :), ':'); % DeltaPA
                stairs(time, obj.disturbanceGeneration(gen, :)); % DeltaPG
                stairs(time, obj.controlCurtailment(gen, :), '--'); % DeltaPC: control taken by the controller
                delayForZone = obj.delayCurt + obj.delayController2Zone;
                f1 = [zeros(1, delayForZone) ...
                    obj.controlCurtailment(gen, 1: obj.numberOfIterations-delayForZone)];
                stairs(time, f1, '-.'); % DeltaPC: control applied on the zone
                        
                legend({'\DeltaPA', '\DeltaPG', '\DeltaPC', ...
                    '\DeltaPC(step+delayCurt + delayTelecom)'}, 'Location', 'Best');
                xlabel(xlegend)
                ylabel('Power [MW]')
                genIdx = obj.genOnIdx(gen);
                busIdOfGen = electricalGrid.getBuses(genIdx);
                name = ['Gen ', int2str(genIdx), ' at ', int2str(busIdOfGen)];
                title(name);
            end
        end
        
        function figFlowBranch = plotFlowBranch(obj, electricalGrid)
            time = 1: obj.numberOfIterations+1;
            xlegend = 'Number of iterations';
            numberOfRowsOfPlot = ceil(sqrt(obj.numberOfBranches));
            figName = ['Zone ' obj.zoneName ': branch power flow Fij'];
            figFlowBranch = figure('Name', figName, 'NumberTitle', 'off', 'WindowState', 'maximize');
            for br = 1:obj.numberOfBranches
                subplot(numberOfRowsOfPlot, numberOfRowsOfPlot, br);
                hold on;
                stairs(time, obj.powerBranchFlow(br,:)); % Fij
                legend({'Branch Power Flow Fij'},'Location','Best')
                xlabel(xlegend)
                ylabel('Power [MW]')
                branchIdx = obj.branchIdx(br);
                [fromBus, toBus] = electricalGrid.getEndBuses(branchIdx);
                name = ['Branch ', int2str(branchIdx), ...
                    ' from ', int2str(fromBus), ' to ', int2str(toBus)]; 
                title(name);
            end
        end
        
        function figAbsFlowBranch = plotAbsoluteFlowBranch(obj, electricalGrid)
            time = 1: obj.numberOfIterations+1;
            xlegend = 'Number of iterations';
            numberOfRowsOfPlot = ceil(sqrt(obj.numberOfBranches));
            figName = ['Zone ' obj.zoneName ': absolute branch power flow |Fij|'];
            figAbsFlowBranch = figure('Name', figName, 'NumberTitle', 'off', 'WindowState', 'maximize');
            for br = 1:obj.numberOfBranches
                subplot(numberOfRowsOfPlot, numberOfRowsOfPlot, br);
                hold on;
                stairs(time, abs(obj.powerBranchFlow(br,:)));  % abs(Fij)
                
                branchLimitOverTime = ones(1, obj.numberOfIterations+1)*obj.branchFlowLimit;
                stairs(time, branchLimitOverTime);
                
                legend({'Absolute Branch Power Flow |Fij|','branch flow limit'},'Location','Best')
                xlabel(xlegend)
                ylabel('Power [MW]')
                branchIdx = obj.branchIdx(br);
                [fromBus, toBus] = electricalGrid.getEndBuses(branchIdx);
                name = ['Branch ', int2str(branchIdx), ...
                    ' from ', int2str(fromBus), ' to ', int2str(toBus)]; 
                title(name);
            end
        end
        
        function figDisturbTransit = plotDisturbanceTransit(obj)
           time = 1:obj.numberOfIterations;
           xlegend = 'Number of iterations';
           numberOfRowsOfPlot = ceil(sqrt( obj.numberOfBuses));
           figName = ['Zone ' obj.zoneName ': disturbance of Power Transit DeltaPT'];
           figDisturbTransit = figure('Name', figName, 'NumberTitle', 'off', 'WindowState', 'maximize');
           for bus = 1:obj.numberOfBuses
               subplot(numberOfRowsOfPlot, numberOfRowsOfPlot, bus);
               hold on;
               stairs(time, obj.disturbanceTransit(bus,:)); % DeltaPT
               legend({'Disturbance transit \DeltaPT'}, 'Location','Best')
               xlabel(xlegend)
               ylabel('Power [MW]')
               busId = obj.busId(bus);
               name = ['Bus ' int2str(busId)];
               title(name);
           end
        end
        
        function plotStateAndControlBattery(obj, electricalGrid)
            timeState = 1:obj.numberOfIterations+1;
            xlegend = 'Number of iterations';
            numberOfRowsOfPlot = ceil(sqrt( obj.numberOfBatt));
            figName = ['Zone ' obj.zoneName ': State of Energy in Battery EB, '...
               'Control of Battery Injection DeltaPB (DeltaPB > 0 means injection in the battery'];
            figure('Name', figName, 'NumberTitle', 'off', 'WindowState', 'maximize');
            
            for batt = 1:obj.numberOfBatt
               subplot(numberOfRowsOfPlot, numberOfRowsOfPlot, batt);
               hold on;
               stairs(timeState, obj.powerBattery(batt,:),':'); % PB
               stairs(timeState, obj.energyBattery(batt,:));    % EB
               timeControl = 1:obj.numberOfIterations;
               stairs(timeControl, obj.controlBattery(batt,:),'--'); % DeltaPB
               legend({'PB, EB, DeltaPB'}, 'Location', 'Best')
               xlabel(xlegend)
               ylabel('Power [MW]') % TODO: define the unit for energy
               
               battIdx = obj.battOnIdx(batt);
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