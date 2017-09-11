classdef LightCrafterDevice < symphonyui.core.Device
    
    properties (Access = protected, Transient)
        stageClient
        lightCrafter
        patternRatesToAttributes
    end
    
    methods
        
        function obj = LightCrafterDevice(varargin)
            ip = inputParser();
            ip.addParameter('host', 'localhost', @ischar);
            ip.addParameter('port', 5678, @isnumeric);
            ip.addParameter('micronsPerPixel', @isnumeric);
            ip.parse(varargin{:});
            
            cobj = Symphony.Core.UnitConvertingExternalDevice(['LightCrafter Stage@' ip.Results.host], 'Texas Instruments', Symphony.Core.Measurement(0, symphonyui.core.Measurement.UNITLESS));
            obj@symphonyui.core.Device(cobj);
            obj.cobj.MeasurementConversionTarget = symphonyui.core.Measurement.UNITLESS;
            
            obj.stageClient = stage.core.network.StageClient();
            obj.stageClient.connect(ip.Results.host, ip.Results.port);
            obj.stageClient.setMonitorGamma(1);
            
            trueCanvasSize = obj.stageClient.getCanvasSize();
            canvasSize = [trueCanvasSize(1) * 2, trueCanvasSize(2)];
            frameTrackerSize = [80,80];
            frameTrackerPosition = [40,40];
            
            obj.stageClient.setCanvasProjectionIdentity();
            obj.stageClient.setCanvasProjectionOrthographic(0, canvasSize(1), 0, canvasSize(2));
            
            obj.lightCrafter = LightCrafter4500(obj.stageClient.getMonitorRefreshRate());
            obj.lightCrafter.connect();
            obj.lightCrafter.setMode('pattern');
            [auto, red, green, blue] = obj.lightCrafter.getLedEnables();
            
            monitorRefreshRate = obj.stageClient.getMonitorRefreshRate();
            renderer = stage.builtin.renderers.PatternRenderer(1, 8);
            obj.stageClient.setCanvasRenderer(renderer);
            
            obj.addConfigurationSetting('canvasSize', canvasSize, 'isReadOnly', true);
            obj.addConfigurationSetting('trueCanvasSize', trueCanvasSize, 'isReadOnly', true);
            obj.addConfigurationSetting('frameTrackerSize', frameTrackerSize);
            obj.addConfigurationSetting('frameTrackerPosition', frameTrackerPosition);
            obj.addConfigurationSetting('monitorRefreshRate', monitorRefreshRate, 'isReadOnly', true);
            obj.addConfigurationSetting('prerender', false, 'isReadOnly', true);
            obj.addConfigurationSetting('lightCrafterLedEnables',  [auto, red, green, blue], 'isReadOnly', true);
            obj.addConfigurationSetting('lightCrafterPatternRate', obj.lightCrafter.currentPatternRate(), 'isReadOnly', true);
            obj.addConfigurationSetting('micronsPerPixel', ip.Results.micronsPerPixel, 'isReadOnly', true);
            obj.addConfigurationSetting('canvasTranslation', [0,0]);
            obj.addConfigurationSetting('backgroundSize', canvasSize);  
            obj.addConfigurationSetting('backgroundIntensity', 0); % also pattern 1 if contrast mode
        end
        
        function close(obj)
            try %#ok<TRYNC>
                obj.stageClient.resetCanvasProjection();
                obj.stageClient.resetCanvasRenderer();
            end
            if ~isempty(obj.stageClient)
                obj.stageClient.disconnect();
            end
            if ~isempty(obj.lightCrafter)
                obj.lightCrafter.disconnect();
            end
        end
        
        function s = getCanvasSize(obj)
            s = obj.getConfigurationSetting('canvasSize');
        end
        
        function s = getTrueCanvasSize(obj)
            s = obj.getConfigurationSetting('trueCanvasSize');
        end
        
        function s = getFrameTrackerSize(obj)
            s = obj.getConfigurationSetting('frameTrackerSize');
        end
        
        function s = getFrameTrackerPosition(obj)
            s = obj.getConfigurationSetting('frameTrackerPosition');
        end
        
        function s = getCanvasTranslation(obj)
            s = obj.getConfigurationSetting('canvasTranslation');
        end            
        
        function r = getMonitorRefreshRate(obj)
            r = obj.getConfigurationSetting('monitorRefreshRate');
        end
        
        function setPrerender(obj, tf)
            obj.setReadOnlyConfigurationSetting('prerender', logical(tf));
        end
        
        function tf = getPrerender(obj)
            tf = obj.getConfigurationSetting('prerender');
        end
        
        function setLedCurrents(obj, r, g, b)
            obj.lightCrafter.setLedCurrents(r, g, b)
        end
        
        function background = getBackground(obj)
            backGroundSize = obj.getConfigurationSetting('backgroundSize');
            canvasSize = obj.getCanvasSize();
            canvasTranslation = obj.getConfigurationSetting('canvasTranslation');
            background = stage.builtin.stimuli.Rectangle();
            background.size = backGroundSize;
            background.position = canvasSize/2 - canvasTranslation;
            background.opacity = 1;
        end

        function backGroundSize = getBackgroundSizeInMicrons(obj)
            micronsPerPixel = obj.getConfigurationSetting('micronsPerPixel');
            backGroundSize = obj.getConfigurationSetting('backgroundSize') * micronsPerPixel;
        end

        function setBackgroundSizeInMicrons(obj, backGroundSize)
            obj.setConfigurationSetting('backgroundSize', obj.um2pix(backGroundSize));
        end

        function play(obj, presentation)
            canvasSize = obj.getCanvasSize();
            canvasTranslation = obj.getConfigurationSetting('canvasTranslation');
            obj.stageClient.setCanvasProjectionIdentity();
            obj.stageClient.setCanvasProjectionOrthographic(0, canvasSize(1), 0, canvasSize(2));            
            obj.stageClient.setCanvasProjectionTranslate(canvasTranslation(1), canvasTranslation(2), 0);

            background = obj.getBackground();
            intensity1 = obj.getConfigurationSetting('backgroundIntensity');
            presentation.insertStimulus(1, background);
            
            tracker = stage.builtin.stimuli.Rectangle();
            tracker.size = obj.getFrameTrackerSize();
            tracker.position = obj.getFrameTrackerPosition() - canvasTranslation;
            presentation.addStimulus(tracker);
            
            function c = addTrackerColor(s)
                 
                 t = double(s.time + (1/s.frameRate));
                 c = t < frameTrackerDuration;
            end
            
            frameTrackerDuration = 6* (1/obj.stageClient.getMonitorRefreshRate());
            trackerColor = stage.builtin.controllers.PropertyController(tracker, 'color', @(s) addTrackerColor(s));
            presentation.addController(trackerColor);
            
            if obj.getPrerender()
                player = stage.builtin.players.PrerenderedPlayer(presentation);
            else
                player = stage.builtin.players.RealtimePlayer(presentation);
            end
            player.setCompositor(stage.builtin.compositors.PatternCompositor());
            obj.stageClient.play(player);
        end
        
        function replay(obj)
            obj.stageClient.replay();
        end
        
        function i = getPlayInfo(obj)
            i = obj.stageClient.getPlayInfo();
        end
        
        function clearMemory(obj)
           obj.stageClient.clearMemory();
        end
        
        function setLedEnables(obj, auto, red, green, blue)
            obj.lightCrafter.setLedEnables(auto, red, green, blue);
            [a, r, g, b] = obj.lightCrafter.getLedEnables();
            obj.setReadOnlyConfigurationSetting('lightCrafterLedEnables', [a, r, g, b]);
        end
        
        function [auto, red, green, blue] = getLedEnables(obj)
            [auto, red, green, blue] = obj.lightCrafter.getLedEnables();
        end
        
        function setPatternAttributes(obj, bitDepth, color, numPatterns)
            setState = false;
            attempt = 0;
            while ~ setState
                try
                    obj.lightCrafter.setPatternAttributes(bitDepth, color, numPatterns)
                    setState = true;
                catch exception
                    if attempt > 2
                        rethrow(exception);
                    end
                    warning(exception.message);
                    attempt = attempt + 1;
                    disp('retrying in 0.1 second');
                    obj.reconnectLightCrafter();
                end
            end
        end
        
        function reconnectLightCrafter(obj)
            obj.lightCrafter.disconnect();
            pause(0.1);
            obj.lightCrafter.connect();
            obj.lightCrafter.setMode('pattern');
        end
                
        function r = getPatternRate(obj)
            r = obj.lightCrafter.currentPatternRate();
        end
        
        function p = um2pix(obj, um)
            micronsPerPixel = obj.getConfigurationSetting('micronsPerPixel');
            p = round(um / micronsPerPixel);
        end
        
    end
    
end

