classdef AaltoPatchRigCalibration < symphonyui.core.descriptions.RigDescription
    
    methods
        
        function obj = AaltoPatchRigCalibration()
            import symphonyui.builtin.daqs.*;
            import symphonyui.builtin.devices.*;
            import symphonyui.core.*;
            
            filterWheelNdfValues = [1, 2, 3, 4, 5, 6];
            filterWheelAttentuationValues = [0.0105, 8.0057e-05, 6.5631e-06, 5.5485e-07, 5.5485e-08, 5.5485e-09];
            
            daq = HekaDaqController(HekaDeviceType.ITC1600);
            obj.daqController = daq;
            
            propertyDevice = sa_labs.devices.RigPropertyDevice('test', false);
            obj.addDevice(propertyDevice);
            propertyDevice.addConfigurationSetting('enableRstarConversion', false, 'isReadOnly', true);

            amp1 = MultiClampDevice('Amp1', 1, 836019).bindStream(daq.getStream('ao0')).bindStream(daq.getStream('ai0'));
            obj.addDevice(amp1);
            
            
            optometer = UnitConvertingDevice('Optometer', 'V').bindStream(daq.getStream('ai4'));
            obj.addDevice(optometer); 
            
            trigger = UnitConvertingDevice('Oscilloscope Trigger', Measurement.UNITLESS).bindStream(daq.getStream('doport1'));
            daq.getStream('doport1').setBitPosition(trigger, 0);
            obj.addDevice(trigger);
              
            lightCrafter = sa_labs.devices.LightCrafterDevice('micronsPerPixel',  1.869);
            lightCrafter.setConfigurationSetting('frameTrackerPosition', [40, 40]);
            lightCrafter.setConfigurationSetting('frameTrackerSize', [80, 80])
            obj.addDevice(lightCrafter);
            
            ndfWheel = sa_labs.devices.NeutralDensityFilterWheelDevice('COM11');
            ndfWheel.setConfigurationSetting('filterWheelNdfValues', filterWheelNdfValues);
            ndfWheel.addResource('filterWheelAttentuationValues', filterWheelAttentuationValues);
            obj.addDevice(ndfWheel);
        end
        
    end
    
end

