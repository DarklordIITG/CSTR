clear; clc; close all;

if exist('cstr_pid_gains.mat','file')
    load('cstr_pid_gains.mat');
    fprintf('Loaded PID gains from cstr_pid_gains.mat\n');
else
    fprintf('cstr_pid_gains.mat not found. Run pid_tuning.m first.\n');
    p = cstr_parameters();
    PID_gains = struct('Kp', -0.001, 'Ti', 5, 'Td', 0.5);
    SS_state  = [0.265; 325; 298];
end

fprintf('\n========================================\n');
fprintf('  DISTURBANCE REJECTION ANALYSIS\n');
fprintf('========================================\n\n');

Kp   = PID_gains.Kp;
Ti   = PID_gains.Ti;
Td   = PID_gains.Td;
x_ss = SS_state;
T_sp = x_ss(2);

fprintf('PID Gains: Kp=%.5f, Ti=%.3f min, Td=%.3f min\n', Kp, Ti, Td);
fprintf('Setpoint:  T_sp = %.2f K (%.1f C)\n\n', T_sp, T_sp-273.15);

dt     = 0.001;
t_end  = 50;
t_sim  = 0:dt:t_end;
N      = length(t_sim);
Fc_max = p.Fc_ss * 3.5;
Fc_min = p.Fc_ss * 0.05;

fprintf('Simulating Case A: Feed Temperature Spike (+15 K for 3 min)...\n');
t_dist_A_start = 5;
t_dist_A_end   = 8;
dT0_A          = 15;

[t_A, T_A, CA_A, Fc_A, T0_A_vec] = run_pid_sim(t_sim, dt, N, x_ss, p, T_sp, Kp, Ti, Td, ...
    Fc_max, Fc_min, ...
    @(t) p.T0_ss + (t >= t_dist_A_start && t < t_dist_A_end) * dT0_A, ...
    @(t) p.CA0_ss, ...
    @(t) p.F_ss);

fprintf('Simulating Case B: Feed Concentration Step +20%%...\n');
t_dist_B = 5;
dCA0_B   = 0.20 * p.CA0_ss;

[t_B, T_B, CA_B, Fc_B, ~] = run_pid_sim(t_sim, dt, N, x_ss, p, T_sp, Kp, Ti, Td, ...
    Fc_max, Fc_min, ...
    @(t) p.T0_ss, ...
    @(t) p.CA0_ss + (t >= t_dist_B) * dCA0_B, ...
    @(t) p.F_ss);

fprintf('Simulating Case C: Combined disturbance (T0 spike + CA0 step)...\n');
[t_C, T_C, CA_C, Fc_C, ~] = run_pid_sim(t_sim, dt, N, x_ss, p, T_sp, Kp, Ti, Td, ...
    Fc_max, Fc_min, ...
    @(t) p.T0_ss + (t >= t_dist_A_start && t < t_dist_A_end) * dT0_A, ...
    @(t) p.CA0_ss + (t >= t_dist_B) * dCA0_B, ...
    @(t) p.F_ss);

fig = figure('Name','Disturbance Rejection','Position',[30 30 1500 850],'Color','k');

plot_cases = {
    t_A, T_A, CA_A, Fc_A, 'Feed Temp Spike (+15K, 3min)', [1 0.42 0.42]
    t_B, T_B, CA_B, Fc_B, 'Feed Conc Step (+20%)',         [0 0.9 1]
    t_C, T_C, CA_C, Fc_C, 'Combined Disturbance',           [0.66 1 0.47]
};

for row = 1:3
    t_v  = plot_cases{row,1};
    T_v  = plot_cases{row,2};
    CA_v = plot_cases{row,3};
    Fc_v = plot_cases{row,4};
    lbl  = plot_cases{row,5};
    clr  = plot_cases{row,6};

    subplot(3,3,(row-1)*3+1)
    set(gca,'Color',[0.1 0.1 0.15],'XColor','w','YColor','w','GridColor',[0.35 0.35 0.35]);
    hold on; grid on;
    plot(t_v, T_v - 273.15, 'Color', clr, 'LineWidth', 2);
    yline(T_sp-273.15, 'w--', 'LineWidth', 1.5, 'Label', 'Setpoint', 'LabelColor','w');
    xline(t_dist_A_start, 'y:', 'LineWidth', 1.2);
    ylabel('Reactor T [°C]','Color','w','FontSize',10);
    xlabel('Time [min]','Color','w','FontSize',10);
    title(sprintf('Temperature — %s', lbl),'Color','w','FontSize',10,'FontWeight','bold');
    ylim([T_sp-273.15-8, T_sp-273.15+12]);
    set(gca,'FontSize',9);

    subplot(3,3,(row-1)*3+2)
    set(gca,'Color',[0.1 0.1 0.15],'XColor','w','YColor','w','GridColor',[0.35 0.35 0.35]);
    hold on; grid on;
    plot(t_v, CA_v * 1000, 'Color', [1 0.65 0], 'LineWidth', 2);
    yline(x_ss(1)*1000,'w--','LineWidth',1.5,'Label','SS C_A','LabelColor','w');
    xline(t_dist_A_start,'y:','LineWidth',1.2);
    ylabel('C_A [mmol/L]','Color','w','FontSize',10);
    xlabel('Time [min]','Color','w','FontSize',10);
    title('Reactant Concentration','Color','w','FontSize',10,'FontWeight','bold');
    set(gca,'FontSize',9);

    subplot(3,3,(row-1)*3+3)
    set(gca,'Color',[0.1 0.1 0.15],'XColor','w','YColor','w','GridColor',[0.35 0.35 0.35]);
    hold on; grid on;
    plot(t_v, Fc_v * 1000, 'Color', [0.78 0.46 1], 'LineWidth', 2);
    yline(p.Fc_ss*1000,'w--','LineWidth',1.5,'Label','Nominal','LabelColor','w');
    yline(Fc_max*1000,'r:','LineWidth',1,'Label','Max','LabelColor','r');
    yline(Fc_min*1000,'r:','LineWidth',1,'Label','Min','LabelColor','r');
    xline(t_dist_A_start,'y:','LineWidth',1.2);
    ylabel('Coolant Flow [L/min]','Color','w','FontSize',10);
    xlabel('Time [min]','Color','w','FontSize',10);
    title('Controller Action (F_c)','Color','w','FontSize',10,'FontWeight','bold');
    set(gca,'FontSize',9);
end

sgtitle('PID Disturbance Rejection — CSTR Temperature Control', ...
        'Color','w','FontSize',14,'FontWeight','bold');
set(gcf,'Color','k');
saveas(fig, 'disturbance_rejection.png');
fprintf('\nFigure saved: disturbance_rejection.png\n');

function [t_out, T_out, CA_out, Fc_out, T0_vec] = run_pid_sim(t_sim, dt, N, x_ss, p, T_sp, Kp, Ti, Td, Fc_max, Fc_min, T0_func, CA0_func, F_func)
    x_curr     = x_ss;
    Fc_curr    = p.Fc_ss;
    integral_e = 0;
    e_prev     = 0;
    T_out   = zeros(N,1);
    CA_out  = zeros(N,1);
    Fc_out  = zeros(N,1);
    T0_vec  = zeros(N,1);

    for k = 1:N
        t_k   = t_sim(k);
        T0_k  = T0_func(t_k);
        CA0_k = CA0_func(t_k);
        F_k   = F_func(t_k);
        e_k   = T_sp - x_curr(2);

        if Fc_curr > Fc_min && Fc_curr < Fc_max
            integral_e = integral_e + e_k * dt;
        end
        de_k   = (e_k - e_prev) / dt;
        e_prev = e_k;

        if isinf(Ti), I_term = 0; else, I_term = integral_e / Ti; end
        u_pid   = Kp * (e_k + I_term + Td * de_k);
        Fc_curr = p.Fc_ss - u_pid;
        Fc_curr = max(Fc_min, min(Fc_max, Fc_curr));

        T_out(k)  = x_curr(2);
        CA_out(k) = x_curr(1);
        Fc_out(k) = Fc_curr;
        T0_vec(k) = T0_k;

        dx = cstr_odes(t_k, x_curr, p, F_k, CA0_k, T0_k, Fc_curr);
        x_curr = x_curr + dx * dt;
        x_curr(1) = max(x_curr(1), 0);
        x_curr(2) = max(x_curr(2), 200);
    end
end
