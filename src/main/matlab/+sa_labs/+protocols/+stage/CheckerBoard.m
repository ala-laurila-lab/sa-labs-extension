classdef CheckerBoard < sa_labs.protocols.StageProtocol
        
    properties
        preTime = 500 % ms
        stimTime = 10000 % ms
        tailTime = 500 % ms

        resolutionX = 4 % number of stimulus segments
        resolutionY = 4 % number of stimulus segments
        sizeX = 300 % um
        sizeY = 300 % um
        standardDeviation = 1; 
        
        frameDwell = 1 % Frames per noise update, use only 1 when colorMode is 2 pattern
        seedStartValue = 1
        seedChangeMode = 'repeat only';

        numberOfEpochs = uint16(30) % number of epochs to queue
    end

    properties (Hidden)
        version = 1;
        
        seedChangeModeType = symphonyui.core.PropertyType('char', 'row', {'repeat only', 'repeat & increment', 'increment only'})
        locationModeType = symphonyui.core.PropertyType('char', 'row', {'Center', 'Surround', 'Center-Surround'})
        
        noiseSeed
        noiseStream
        
        responsePlotMode = 'false';
        responsePlotSplitParameter = 'noiseSeed';
    end
    
    properties (Dependent, Hidden)
        totalNumEpochs
    end
    
    methods
        
%         function prepareRun(obj)
%             if obj.numberOfPatterns == 1 && obj.meanLevel == 0
%                 warning('Mean Level must be greater than 0 for this to work');
%             end
%             
%             prepareRun@sa_labs.protocols.StageProtocol(obj);
%         end
        function d = getPropertyDescriptor(obj, name)
            d = getPropertyDescriptor@sa_labs.protocols.StageProtocol(obj, name);
            
         end
        
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@sa_labs.protocols.StageProtocol(obj, epoch);
            
            if strcmp(obj.seedChangeMode, 'repeat only')
                seed = obj.seedStartValue;
            elseif strcmp(obj.seedChangeMode, 'increment only')
                seed = obj.numEpochsCompleted + obj.seedStartValue;
            else
                seedIndex = mod(obj.numEpochsCompleted,2);
                if seedIndex == 0
                    seed = obj.seedStartValue;
                elseif seedIndex == 1
                    seed = obj.seedStartValue + (obj.numEpochsCompleted + 1) / 2;
                end
            end
                                    
            obj.noiseSeed = seed;
            fprintf('Using seed %g\n', obj.noiseSeed);

            %at start of epoch, set random streams using this cycle's seeds
            obj.noiseStream = RandStream('mt19937ar', 'Seed', obj.noiseSeed);

            epoch.addParameter('noiseSeed', obj.noiseSeed);
        end

        function p = createPresentation(obj)
            canvasSize = obj.rig.getDevice('Stage').getCanvasSize();
                        
            p = stage.core.Presentation((obj.preTime + obj.stimTime + obj.tailTime) * 1e-3); %create presentation of specified duration
            preFrames = round(obj.frameRate * (obj.preTime/1e3));
            
            % create shapes
            % checkerboard is filled from top left (is 1,1)
            checkerboard = stage.builtin.stimuli.Image(uint8(zeros(obj.resolutionY, obj.resolutionX)));
            checkerboard.position = canvasSize / 2;
            checkerboard.size = obj.um2pix([obj.sizeX, obj.sizeY]);
            checkerboard.setMinFunction(GL.NEAREST);
            checkerboard.setMagFunction(GL.NEAREST);
            p.addStimulus(checkerboard);
            
            % add controllers
            % dimensions are swapped correctly
            checkerboardImageController = stage.builtin.controllers.PropertyController(checkerboard, 'imageMatrix',...
                @(state)getImageMatrix(obj, state.frame - preFrames, [obj.resolutionY, obj.resolutionX]));
            
            p.addController(checkerboardImageController);
            
            obj.setOnDuringStimController(p, checkerboard);
            
            % TODO: verify X vs Y in matrix
            
            function i = getImageMatrix(obj, frame, dimensions)
                persistent intensity;
                if frame<0 %pre frames. frame 0 starts stimPts
                    intensity = obj.meanLevel;
                else %in stim frames
                    if mod(frame, obj.frameDwell) == 0 %noise update
                        intensity = obj.meanLevel + ... 
                            obj.standardDeviation * obj.noiseStream.randn(dimensions);
                    end
                end
%                 intensity = imgaussfilt(intensity, 1);
                intensity = clipIntensity(intensity, obj.meanLevel);
                i = intensity;
            end
                       
            
            function intensity = clipIntensity(intensity, mn)
                intensity(intensity < 0) = 0;
                intensity(intensity > 0) = 1;
                intensity = uint8(255 * intensity);
            end

        end
        function totalNumEpochs = get.totalNumEpochs(obj)
            totalNumEpochs = obj.numberOfEpochs;
        end
        
        function setOnDuringStimController(obj, p, stageObject)
            function c = onDuringStim(state, preTime, stimTime)
                c = 1 * (state.time>preTime*1e-3 && state.time<=(preTime+stimTime)*1e-3);
            end
            
            controller = stage.builtin.controllers.PropertyController(stageObject, 'opacity', ...
                @(s)onDuringStim(s, obj.preTime, obj.stimTime));
            p.addController(controller);
        end
    end
    
end