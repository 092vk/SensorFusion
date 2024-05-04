close all;
clear;
clc;


mob = mobiledev
mob.SampleRate = 100;
mob.Logging=1

pause(10);

% stop collecting data 
mob.Logging =0;

%logging the data 
[oin,to] = orientlog(mob);
[a, ta] = accellog(mob);
[w, tw] = angvellog(mob);
[m, tm] = magfieldlog(mob); 



%plotting the Orientation data 
figure(1);
plot(to,oin);
title('Orientation Data');
xlabel('Time (s)');
ylabel('Orientation (degrees)');



%plotting the acceleartion data 
figure(2);
plot(ta,a);
title('Accelearation Data');
xlabel('Time (s)');
ylabel('Acceleartion (m/s^2)');


%plotting the angular velocity data
figure(3);
plot(tw,w);
title('Angular Velocity Data');
xlabel('Time (s)');
ylabel('Angular Velocity (degrees/s)');


%plotting the mfield data 
figure(4);
plot(tm,m);
title('Magnetic Field Data');
xlabel('Time (s)');
ylabel('Mfield (Tesla)');



%Sensor Fusion 


%making sure we select the least time interval among all the sensors 
tfin = min([length(ta),length(tm),length(tw),length(to)]);
t = ta(1:tfin);




%estimation algo which combines data from different sensors to estimate the
%result , we are using ahrs filter (Attitude and Heading Reference System)

aFilter = ahrsfilter('SampleRate',mob.SampleRate);


%noise constants
aFilter.GyroscopeNoise = 0.0002;
aFilter.AccelerometerNoise = 0.0003;
aFilter.LinearAccelerationNoise = 0.0025;
aFilter.MagnetometerNoise = 0.1;
aFilter.MagneticDisturbanceNoise = 0.5;
aFilter.MagneticDisturbanceDecayFactor = 0.5;



%aliging the sensor data , according to toolbox documentation
w(:,1) = -w(:,1);
w(:,3) = -w(:,3);
a(:,2) = -a(:,2);
m(:,1) = m(:,1);
m(:,2) = -m(:,2);
m(:,3) = -m(:,3);


% making a quaternion 
qyaw = quaternion([sqrt(2)/2 0 0 sqrt(2)/2]);



%Fusion Processing loop 

for i=1:length(t)
    % This is where the AHRS fusion function is called 
    orientation(i) = aFilter(a(i,:),w(i,:), m(i,:)); % Note : Yaw is calculated with respect to the magnetic north
 
    % 90 degree rotation to match the phone reference frame 
    orientation(i) = orientation(i)*qyaw;
    
    % Convert quarternion into Euler angles
    eulFilt(i,:)= euler(orientation(i),'ZYX','frame');
end


% Release the system object aFilter so that it frees up the space 
release(aFilter)


%Visualisation-

figure(5);
plot(t,eulFilt(:,3)*180/pi,t,oin((1:tfin),3));
xlabel('Time [s]');
ylabel('Roll [deg]');
legend('MATLAB', 'Android Device');

figure(6)
plot(t,-eulFilt(:,2)*180/pi,t,oin((1:tfin),2));
xlabel('Time [s]');
ylabel('Pitch [deg]');
legend('MATLAB', 'Android Device');

figure(7)
plot(t,eulFilt(:,1)*180/pi,t,oin((1:tfin),1));
xlabel('Time [s]');
ylabel('Yaw [deg]');
legend('MATLAB', 'Android Device');


