% OT and EnKF predictors
function [x_est_OT,x_est_enkf] = ot_enkf(date_mee,samples,rep)
    % TO-DO : all the function use some subset of the global parameters.
    % Fix this so that no repetitions of these constants are required
    mu = 398600.4418;
    R_e = 6378.135;
    J = [0;0.00108263;-2.51e-6;-1.6e-6;-1.3e-7;5e-7];
    prop_params = struct('mu',mu,'R_e',R_e,'J',J);
    equinoc_dyn = @(t,x) equinoctial_dyn(t,x,prop_params);
    MU = date_mee(1,7:11);
    t1 = zeros(1,size(date_mee,1));
    t1(1) = 0;
    for i = 1:(size(date_mee,1)-1)
        t1(i+1) = time_diff(date_mee(i,1:6),date_mee(i+1,1:6));
    end
    measured_output = date_mee(:,7:12);
    % INITIAL SAMPLE GENERATION
    diag_sigma_init = [20 abs(MU(2:5)).*0.3]; % GUESS
    diag_sigma_init = (diag_sigma_init.*diag_sigma_init); % variance
    SIGMA_init = diag(diag_sigma_init);
    % Date structure for storing the estimated values
    x_est_OT = zeros(size(date_mee(:,7:end),1),size(date_mee(:,7:end),2),rep);
    x_est_enkf = x_est_OT;
    kappa_init = 66;
    for m = 1:rep
        init_r5 = mvnrnd(MU,SIGMA_init,samples); % First R5 elements
        init_c1 = circ_vmrnd(mod(date_mee(1,12),2*pi), kappa_init, samples);
        X_init_OT = [init_r5,init_c1]'; 
        X_init_enkf = [init_r5,normrnd(date_mee(1,12),0.4,samples,1)]'; % 10 degree error as the sigma
        % OT Filtering essential functions
        cost = @(x) distance_matrix(x);
        OT_constantshdl = @(x) OT_constants(x);
        N1 = 100;% Number of discrete steps in between 0 and 1
        % since point 1 is undefined we have taken 0 to 1-e-2
        int_fun = @(x) bessel_C(x,N1);
        weight = @(x,y) weight_newcal(x,y,int_fun);
        % EnKF Parameters
        H = eye(6); % All state are assumed to be measurable
        last_entry = 1- (besseli(1,kappa_init)/besseli(0,kappa_init));
        R_enkf = 2*diag([diag_sigma_init,last_entry]);
%         R_enkf = 10*diag([diag_sigma_init,0.4^2]);% FIX THE END VALUE
        % OT used marginalization 
        for j = 1:size(date_mee,1)
            if(j~=1)
                for i = 1:length(X_init_enkf(1,:))
                    [~,x_temp] = ode45(equinoc_dyn,[0 t1(j)],X_init_enkf(:,i));
                    X_init_enkf(:,i) = x_temp(end,:)';
                end
            end
            X_init_enkf = EnKF_filter(X_init_enkf,measured_output(j,:)',H,R_enkf);
%             X_init_enkf(6,:) = mod(X_init_enkf(6,:),2*pi);
            x_est_enkf(j,:,m) = mean(X_init_enkf,2)';
            x_est_enkf(j,6,m) = mod(x_est_enkf(j,6,m),2*pi);
            error_acc = measured_output(1:j,:) - x_est_enkf(1:j,:,m);
            if j >= 5 % Window that needs to be deleted
                R_enkf = cov(error_acc);
            end
        end
        for j = 1:size(date_mee,1)
            if(j~=1)
                for i = 1:length(X_init_OT(1,:))
                    [~,x_temp] = ode45(equinoc_dyn,[0 t1(j)],X_init_OT(:,i));
                    X_init_OT(:,i) = x_temp(end,:)';
%                     X_init_OT(6,i) = mod(X_init_OT(6,i),2*pi);
                end
            end
            X_init_OT = OT_filter(X_init_OT,measured_output(j,:)',cost,weight,OT_constantshdl);
            x_est_OT(j,:,m) = mean(X_init_OT,2)';
            x_est_OT(j,6,m) = mod(x_est_OT(j,6,m),2*pi); 
        end
    end
    mat_name = strcat('enkf_repeat_',num2str(samples),'.mat');
    save(mat_name, 'x_est_enkf');
    mat_name = strcat('ot_repeat_',num2str(samples),'.mat');
    save(mat_name, 'x_est_OT');
end