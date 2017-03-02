classdef AaltoPatchRig < symphonyui.core.descriptions.RigDescription
    
    methods
        
        function obj = AaltoPatchRig()
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
            
            amp2 = MultiClampDevice('Amp2', 2, 836019).bindStream(daq.getStream('ao1')).bindStream(daq.getStream('ai1'));
            obj.addDevice(amp2);
            
            amp3 = MultiClampDevice('Amp3', 2, 836392).bindStream(daq.getStream('ao2')).bindStream(daq.getStream('ai2'));
            obj.addDevice(amp3);
            
            amp4 = MultiClampDevice('Amp4', 2, 836392).bindStream(daq.getStream('ao3')).bindStream(daq.getStream('ai3'));
            obj.addDevice(amp4);
            
            trigger = UnitConvertingDevice('Oscilloscope Trigger', Measurement.UNITLESS).bindStream(daq.getStream('doport0'));
            daq.getStream('doport0').setBitPosition(trigger, 0);
            obj.addDevice(trigger);
              
            lightCrafter = sa_labs.devices.LightCrafterDevice('micronsPerPixel',  0.6);
            lightCrafter.setConfigurationSetting('frameTrackerPosition', [40, 40]);
            lightCrafter.setConfigurationSetting('frameTrackerSize', [80, 80])
            obj.addDevice(lightCrafter);
            
            ndfWheel = sa_labs.devices.NeutralDensityFilterWheelDevice('COM11');
            ndfWheel.setConfigurationSetting('filterWheelNdfValues', filterWheelNdfValues);
            ndfWheel.addResource('filterWheelAttentuationValues', filterWheelAttentuationValues);
            obj.addDevice(ndfWheel);
            
            rigSwitch1 = UnitConvertingDevice('rigSwitch1', Measurement.UNITLESS).bindStream(daq.getStream('diport1'));
            daq.getStream('diport1').setBitPosition(rigSwitch1, 0);
            obj.addDevice(rigSwitch1);
                        
            rigSwitch2 = UnitConvertingDevice('rigSwitch2', Measurement.UNITLESS).bindStream(daq.getStream('diport1'));
            daq.getStream('diport1').setBitPosition(rigSwitch2, 1);
            obj.addDevice(rigSwitch2);
            
            rigSwitch3 = UnitConvertingDevice('rigSwitch3', Measurement.UNITLESS).bindStream(daq.getStream('diport1'));
            daq.getStream('diport1').setBitPosition(rigSwitch3, 2);
            obj.addDevice(rigSwitch3);
                        
            rigSwitch4 = UnitConvertingDevice('rigSwitch4', Measurement.UNITLESS).bindStream(daq.getStream('diport1'));
            daq.getStream('diport1').setBitPosition(rigSwitch4, 3);
            obj.addDevice(rigSwitch4);
        end
        
    end
    
end

