% Plot generate comparing OT and EnKF
% Author: Niladri Das
% Date: 12 June 2017
clear; close all; clc;

% Load observations
load date_mee.mat;
load t1;
t_spot = zeros(1,length(t1));
for i = 1:length(t1)
    t_spot(i) = sum(t1(1:i));
end
% t_spot is in seconds
% conversting it into days
t_spot = t_spot./(60*60*24);

% cd('/home/niladri/Documents/GITHUB/RESEARCH/Kalman/Optimal_Transport/Satellite_Data_Analysis/OT_Satellite_Main/sim_data');
% % Load all data
% cd('./50/')
load all_enkf_data.mat;
% The corresponding variable is  x_est_enkf
load all_OT_data.mat;
% The corresponding variable is  x_est_OT


% First compare OT and EnKF with respect to the observed values
obs_var = date_mee(:,7:12);
obs_var(:,6) = mod(obs_var(:,6),2*pi);

% Showing normalised data for all the 6 variables
temp_ob = abs(date_mee(:,7:11));
norm_x =  max(temp_ob,[],1);

for i = 1:5
x_est_OT(:,i) = 100.*x_est_OT(:,i)./norm_x(i);
x_est_enkf(:,i) = 100.*x_est_enkf(:,i)./norm_x(i);
obs_var(:,i) = 100.*obs_var(:,i)./norm_x(i);
end


figure(1)
for i = 1:6
    subplot(3,2,i)
    plot(t_spot,x_est_OT(:,i),'r-+');
    xlabel('Time in Days')
    hold on
    plot(t_spot,x_est_enkf(:,i),'b-o');
    xlabel('Time in Days')
    hold on
    plot(t_spot,obs_var(:,i),'g-*');
    xlabel('Time in Days')
    legend('OT','EnKF','Obs')
    grid on
end