function [payload] = CreatePayload(option)

if option == 1
    % MicroMAS
    comp = struct('Name','Payload','Subsystem','Payload','Shape','Rectangle','Mass',1,'Dim',[.1,.1,.1],'CG_XYZ',[],'Vertices',[],'LocationReq','Specific','Orientation',[],'Thermal',[],'InertiaMatrix',[],'RotateToSatBodyFrame', []);
%     comp2 = struct('Name','Payload','Subsystem','Payload','Shape','Rectangle','Mass',1,'Dim',[.1,.1,.1],'CG_XYZ',[],'Vertices',[],'LocationReq','Specific','Orientation',[],'Thermal',[],'InertiaMatrix',[],'RotateToSatBodyFrame', []);
%     comp = [comp1,comp2];
    payload.comp = comp;
    payload.Orbit = 'LEO';
    payload.h = 400; % Altitude %km
    payload.i = 51.6; % Inclination
    payload.dataperday = 5e9;   % Data per day cubesat 
    payload.lifetime = 3;     % Lifetime
    payload.mass = 1; %kg
    payload.power = 5;
    payload.cost = 200; %($ in thousands of dollars)
    payload.pointingaccuracy = .1;
elseif option == 2
    % Comms satellite.
    payload.mass = 500; %kg
    comp = struct('Name','Payload','Subsystem','Payload','Shape','Cylinder','Mass',payload.mass,'Dim',[1,1],'CG_XYZ',[],'Vertices',[],'LocationReq','Specific','Orientation',[],'Thermal',[],'InertiaMatrix',[],'RotateToSatBodyFrame', []);
    payload.comp = comp;
    payload.Orbit = 'LEO';
    payload.h = 800; % Altitude %km
    payload.i = 30; % Inclination
    payload.dataperday = 5*3600*24*10^6;   %MB/s converted to bit/day (data/day) for telemetry
    payload.lifetime = 3;     % Lifetime
    payload.power = 1200; % 12 TWTAs with 100 Watts each
    payload.cost = 650; % thousand
    payload.pointingaccuracy = .1;
elseif option == 3
    % SpaceX satellite 
    payload.mass = 200; %kg
    comp = struct('Name','Payload','Subsystem','Payload','Shape','Rectangle','Mass',payload.mass,'Dim',[1,1,1/2],'CG_XYZ',[],'Vertices',[],'LocationReq','Specific','Orientation',[],'Thermal',[],'InertiaMatrix',[],'RotateToSatBodyFrame', []);
    payload.comp = comp;
    payload.Orbit = 'LEO';
    payload.h = 1500; % Altitude %km
    payload.i = 53; % Inclination
    payload.dataperday = 5*3600*24*10^6;   %MB/s converted to bit/day (data/day) for telemetry
    payload.lifetime = 5;     % Lifetime
    payload.power = 2000; % 2 kW
    payload.cost = 650; % thousand (Proprietary, not actual cost)
    payload.pointingaccuracy = .1; %(an assumption)
end

% components(i).Name = 'Fuel Tank';
% components(i).Subsystem = 'Propulsion';
% components(i).Shape = 'Sphere';
% components(i).Mass = 150;
% components(i).Dim = 0.4;
% % components(1).isFit = 0;
% components(i).CG_XYZ = [];
% components(i).Vertices = [];
% components(i).LocationReq = 'Specific';
% components(i).Orientation = [];
% components(i).Thermal = [];
% components(i).InertiaMatrix = [];
% components(i).RotateToSatBodyFrame = [];






