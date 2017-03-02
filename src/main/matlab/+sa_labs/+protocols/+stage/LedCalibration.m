classdef LedCalibration < sa_labs.protocols.StageProtocol

    properties
        %times in ms
        preTime = 500	% Spot leading duration (ms)
        stimTime = 1000	% Spot duration (ms)
        tailTime = 500	% Spot trailing duration (ms)
        
        intensity = 1;
        
        spotSize = 500; % um
        numberOfCycles = 3;
    end
    
    properties (Hidden)
        version = 4
        
        responsePlotMode = 'cartesian';
        responsePlotSplitParameter = '';
        blueLEDs
        curBlueLED
    end
    
    properties (Hidden, Dependent)
        totalNumEpochs
    end
    
    methods
      
        
        %unlike in a "simple" protocol, here I need to add sth to the prepare run and prepare epoch functions
        %which are executed by the parents, because I want to change a
        %parameter with every epoch
        %the stage protocol sets the LED value of the LightCrafter before
        %each run (=group of epochs), so if we wanted to change its
        %value for the entire run, we would have to add a prepareRun
        %function here, but we want to change it in an epoch dependent way,
        %so we need to add an extension to the prepareEpoch function
        % obj.numEpochsPrepared is the current epoch count
        
        function prepareRun(obj)
            prepareRun@sa_labs.protocols.StageProtocol(obj);
            obj.showFigure('symphonyui.builtin.figures.ResponseFigure', obj.rig.getDevice('Optometer'));
            %set LED current vector
           obj.blueLEDs=[0:1:15 20:10:100 120:20:240 255];
           % obj.blueLEDs=[0 5 15 255];

        end
        
        function prepareEpoch(obj, epoch)

            index = mod(obj.numEpochsPrepared, length(obj.blueLEDs)) + 1;
            
            % compute current LED current 
            
            obj.curBlueLED = obj.blueLEDs(index);
            lightCrafter = obj.rig.getDevice('LightCrafter');
            lightCrafter.setLedCurrents(0, obj.greenLED, obj.curBlueLED);
            pause(0.2); % let the projector get set up
            
            % Call the base method.
            prepareEpoch@sa_labs.protocols.StageProtocol(obj, epoch);
            optometer = obj.rig.getDevice('Optometer');
            epoch.addResponse(optometer);
            epoch.addParameter('curBlueLED', obj.curBlueLED);
        end
        
        
        function p = createPresentation(obj)
            
            p = stage.core.Presentation((obj.preTime + obj.stimTime + obj.tailTime) * 1e-3);

            %set bg
            p.setBackgroundColor(obj.meanLevel);
            
            spot = stage.builtin.stimuli.Ellipse();
            spot.radiusX = round(obj.um2pix(obj.spotSize / 2));
            spot.radiusY = spot.radiusX;
            %spot.color = obj.intensity;
            canvasSize = obj.rig.getDevice('Stage').getCanvasSize();
            spot.position = canvasSize / 2;
            p.addStimulus(spot);
            
            function c = onDuringStim(state, preTime, stimTime, intensity, meanLevel)
                if state.time>preTime*1e-3 && state.time<=(preTime+stimTime)*1e-3
                    c = intensity;
                else
                    c = meanLevel;
                end
            end
            
            controller = stage.builtin.controllers.PropertyController(spot, 'color', @(s)onDuringStim(s, obj.preTime, obj.stimTime, obj.intensity, obj.meanLevel));
            p.addController(controller);

        end
        
        
        
        function totalNumEpochs = get.totalNumEpochs(obj)
            totalNumEpochs = obj.numberOfCycles * length(obj.blueLEDs);
        end

    end
    
end