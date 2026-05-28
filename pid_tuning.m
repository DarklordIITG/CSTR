clear; clc; close all;
p = cstr_parameters();

fprintf('\n========================================\n');
fprintf('  PID TUNING — ZIEGLER-NICHOLS\n');
fprintf('========================================\n\n');

x0_guess = [p.CA_ss; p.T_ss; p.Tc_ss];
x_ss = find_ss(p, x0_guess);
T_sp = x_ss(2);

fprintf('Control Objective: Maintain T = %.2f K (%.1f C)\n', T_sp, T_sp-273.15);
fprintf('Manipulated Variable: Coolant flow rate Fc (nominal = %.4f m3/min)\n', p.Fc_ss);

fprintf('\n--- ZN Reaction Curve Method (Open-Loop Step Test) ---\n');

delta_Fc = 0.10 * p.Fc_ss;
Fc_step  = p.Fc_ss + delta_Fc;

tspan_rc  = [0, 25];
ode_opts  = odeset('RelTol',1e-8,'AbsTol',1e-10,'MaxStep',0.01);
t_step_rc = 2;

ode_rc = @(t,x) cstr_odes(t, x, p, p.F_ss, p.CA0_ss, p.T0_ss, ...
                            (t < t_step_rc)*p.Fc_ss + (t >= t_step_rc)*Fc_step);
[t_rc, X_rc] = ode45(ode_rc, tspan_rc, x_ss, ode_opts);

T_initial = X_rc(1,2);
T_final   = X_rc(end,2);
dT_total  = T_final - T_initial;
K_proc    = dT_total / delta_Fc;

level_283 = T_initial + 0.283 * dT_total;
level_632 = T_initial + 0.632 * dT_total;

[~, idx_283] = min(abs(X_rc(:,2) - level_283));
[~, idx_632] = min(abs(X_rc(:,2) - level_632));
t_283 = t_rc(idx_283);
t_632 = t_rc(idx_632);

tau_p = 1.5 * (t_632 - t_283);
theta = t_632 - tau_p - t_step_rc;
theta = max(theta, 0.05);

fprintf('FOPDT Parameters:\n');
fprintf('  Process Gain K  = %.4f K/(m3/min)\n', K_proc);
fprintf('  Time Constant τ = %.4f min\n', tau_p);
fprintf('  Dead Time θ     = %.4f min\n', theta);

R = K_proc / tau_p;
ZN_RC.P   = struct('Kp', 1/(R*theta),       'Ti', Inf,         'Td', 0);
ZN_RC.PI  = struct('Kp', 0.9/(R*theta),     'Ti', 3.33*theta,  'Td', 0);
ZN_RC.PID = struct('Kp', 1.2/(R*theta),     'Ti', 2.0*theta,   'Td', 0.5*theta);

fprintf('\nZN Reaction Curve Tuning:\n');
fprintf('  P   : Kp = %.4f\n', ZN_RC.P.Kp);
fprintf('  PI  : Kp = %.4f,  Ti = %.4f min\n', ZN_RC.PI.Kp, ZN_RC.PI.Ti);
fprintf('  PID : Kp = %.4f,  Ti = %.4f min,  Td = %.4f min\n', ...
        ZN_RC.PID.Kp, ZN_RC.PID.Ti, ZN_RC.PID.Td);

fprintf('\n--- ZN Ultimate Gain Method (Closed-Loop) ---\n');

w_range = logspace(-3, 3, 10000);
angle_G = -atan(tau_p * w_range) - theta * w_range;
[~, idx_ult] = min(abs(angle_G + pi));
w_u = w_range(idx_ult);
P_u = 2*pi / w_u;
mag_G_at_wu = abs(K_proc * exp(-1j*theta*w_u) / (1 + 1j*tau_p*w_u));
K_u = 1 / mag_G_at_wu;

fprintf('  Ultimate Gain   Ku = %.4f\n', K_u);
fprintf('  Ultimate Period Pu = %.4f min\n', P_u);

ZN_UG.P   = struct('Kp', 0.50*K_u, 'Ti', Inf,       'Td', 0);
ZN_UG.PI  = struct('Kp', 0.45*K_u, 'Ti', P_u/1.2,   'Td', 0);
ZN_UG.PID = struct('Kp', 0.60*K_u, 'Ti', P_u/2,     'Td', P_u/8);

fprintf('\nZN Ultimate Gain Tuning:\n');
fprintf('  P   : Kp = %.4f\n', ZN_UG.P.Kp);
fprintf('  PI  : Kp = %.4f,  Ti = %.4f min\n', ZN_UG.PI.Kp, ZN_UG.PI.Ti);
fprintf('  PID : Kp = %.4f,  Ti = %.4f min,  Td = %.4f min\n', ...
        ZN_UG.PID.Kp, ZN_UG.PID.Ti, ZN_UG.PID.Td);

fprintf('\n--- Closed-Loop Setpoint Change Simulations ---\n');

T_new_sp  = T_sp + 5;
t_end_cl  = 40;
t_sp_step = 3;

gains = {ZN_RC.P, ZN_RC.PI, ZN_RC.PID};
labels_ctrl = {'P Controller', 'PI Controller', 'PID Controller'};
colors_ctrl = {[1 0.42 0.42], [1 0.84 0], [0 0.9 1]};

responses = cell(3,1);
times_cl  = cell(3,1);

for g = 1:3
    Kp = gains{g}.Kp;
    Ti = gains{g}.Ti;
    Td = gains{g}.Td;
    fprintf('  Simulating %s (Kp=%.4f)...\n', labels_ctrl{g}, Kp);

    dt     = 0.001;
    t_sim  = 0:dt:t_end_cl;
    N      = length(t_sim);

    x_curr     = x_ss;
    Fc_curr    = p.Fc_ss;
    integral_e = 0;
    e_prev     = 0;
    T_out      = zeros(N,1);
    Fc_out     = zeros(N,1);
    CA_out     = zeros(N,1);
    Fc_max     = p.Fc_ss * 3.0;
    Fc_min     = p.Fc_ss * 0.1;

    for k = 1:N
        t_k  = t_sim(k);
        sp_k = T_sp + (t_k >= t_sp_step) * (T_new_sp - T_sp);
        e_k  = sp_k - x_curr(2);

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

        dx = cstr_odes(t_k, x_curr, p, p.F_ss, p.CA0_ss, p.T0_ss, Fc_curr);
        x_curr = x_curr + dx * dt;
        x_curr(1) = max(x_curr(1), 0);
        x_curr(2) = max(x_curr(2), 200);
    end

    responses{g} = struct('T', T_out, 'CA', CA_out, 'Fc', Fc_out);
    times_cl{g}  = t_sim;
end

fig2 = figure('Name','P PI PID Comparison','Position',[30 30 1400 700],'Color','k');

subplot(2,2,1)
set(gca,'Color',[0.1 0.1 0.15],'XColor','w','YColor','w','GridColor',[0.3 0.3 0.3]);
hold on; grid on;
sp_plot = T_sp + (times_cl{1} >= t_sp_step) * (T_new_sp - T_sp);
plot(times_cl{1}, sp_plot - 273.15, 'w--', 'LineWidth', 1.5, 'DisplayName','Setpoint');
for g = 1:3
    plot(times_cl{g}, responses{g}.T - 273.15, 'Color', colors_ctrl{g}, ...
         'LineWidth', 2, 'DisplayName', labels_ctrl{g});
end
xlabel('Time [min]','Color','w'); ylabel('Reactor T [°C]','Color','w');
title('Temperature Response — P/PI/PID','Color','w','FontWeight','bold');
legend('TextColor','w','Color',[0.2 0.2 0.3],'EdgeColor','w','FontSize',9);
xline(t_sp_step,'y:','LineWidth',1.2);

subplot(2,2,2)
set(gca,'Color',[0.1 0.1 0.15],'XColor','w','YColor','w','GridColor',[0.3 0.3 0.3]);
hold on; grid on;
for g = 1:3
    plot(times_cl{g}, responses{g}.Fc * 1000, 'Color', colors_ctrl{g}, ...
         'LineWidth', 2, 'DisplayName', labels_ctrl{g});
end
yline(p.Fc_ss*1000,'w--','LineWidth',1.5,'Label','Nominal F_c','LabelColor','w');
xlabel('Time [min]','Color','w'); ylabel('Coolant Flow F_c [L/min]','Color','w');
title('Manipulated Variable (Coolant Flow)','Color','w','FontWeight','bold');
legend('TextColor','w','Color',[0.2 0.2 0.3],'EdgeColor','w','FontSize',9);
xline(t_sp_step,'y:','LineWidth',1.2);

subplot(2,2,3)
set(gca,'Color',[0.1 0.1 0.15],'XColor','w','YColor','w','GridColor',[0.3 0.3 0.3]);
hold on; grid on;
yline(0,'w--','LineWidth',1.5);
for g = 1:3
    sp_g = T_sp + (times_cl{g} >= t_sp_step) * (T_new_sp - T_sp);
    err  = sp_g' - responses{g}.T;
    plot(times_cl{g}, err, 'Color', colors_ctrl{g}, 'LineWidth', 2, ...
         'DisplayName', labels_ctrl{g});
end
xlabel('Time [min]','Color','w'); ylabel('Error e(t) [K]','Color','w');
title('Temperature Error vs Time','Color','w','FontWeight','bold');
legend('TextColor','w','Color',[0.2 0.2 0.3],'EdgeColor','w','FontSize',9);
xline(t_sp_step,'y:','LineWidth',1.2);

subplot(2,2,4)
set(gca,'Color',[0.08 0.08 0.12],'XColor','w','YColor','w','Visible','on');
axis off;
param_text = {
    '\bf\fontsize{12}ZN Reaction Curve Parameters'
    ''
    sprintf('Process: K = %.2f K/(L/min)', K_proc/1000)
    sprintf('          τ = %.3f min', tau_p)
    sprintf('          θ = %.3f min', theta)
    ''
    '\bf\color[rgb]{1 0.4 0.4}P Controller'
    sprintf('  Kp = %.4f L/(min·K)', ZN_RC.P.Kp*1000)
    ''
    '\bf\color[rgb]{1 0.85 0}PI Controller'
    sprintf('  Kp = %.4f L/(min·K)', ZN_RC.PI.Kp*1000)
    sprintf('  Ti = %.3f min', ZN_RC.PI.Ti)
    ''
    '\bf\color[rgb]{0 0.9 1}PID Controller'
    sprintf('  Kp = %.4f L/(min·K)', ZN_RC.PID.Kp*1000)
    sprintf('  Ti = %.3f min', ZN_RC.PID.Ti)
    sprintf('  Td = %.3f min', ZN_RC.PID.Td)
};
text(0.05, 0.95, param_text, 'Units','normalized','VerticalAlignment','top', ...
     'Color','w','FontSize',10,'Interpreter','tex');

sgtitle('CSTR PID Control — Setpoint Step Response Comparison', ...
        'Color','w','FontSize',14,'FontWeight','bold');
set(gcf,'Color','k');
saveas(fig2, 'pid_comparison.png');
fprintf('\nFigure saved: pid_comparison.png\n');

PID_gains = ZN_RC.PID;
SS_state  = x_ss;
save('cstr_pid_gains.mat', 'PID_gains', 'SS_state', 'ZN_RC', 'ZN_UG', 'p');
fprintf('Tuning data saved to cstr_pid_gains.mat\n');

fig3 = figure('Name','Process Reaction Curve','Position',[80 80 800 400],'Color','k');
set(gca,'Color',[0.1 0.1 0.15],'XColor','w','YColor','w','GridColor',[0.3 0.3 0.3]);
hold on; grid on;

T_plot = (X_rc(:,2) - T_initial) / delta_Fc;
plot(t_rc, T_plot, 'Color', [0 0.83 1], 'LineWidth', 2.5, 'DisplayName','Process Response');
xline(t_step_rc,'y--','LineWidth',1.5,'Label','Step Applied','LabelColor','y');
xline(t_283,'g:','LineWidth',1.5,'Label','28.3%','LabelColor','g');
xline(t_632,'r:','LineWidth',1.5,'Label','63.2%','LabelColor','r');
yline(0,'w--','LineWidth',1);
xlabel('Time [min]','Color','w','FontSize',12);
ylabel('Normalized T response [K/(m^3/min)]','Color','w','FontSize',12);
title('ZN Reaction Curve — Open-Loop Step Test (10% Step in F_c)','Color','w','FontSize',13,'FontWeight','bold');
legend('TextColor','w','Color',[0.2 0.2 0.3],'EdgeColor','w','FontSize',10);
set(gcf,'Color','k');
saveas(fig3, 'zn_reaction_curve.png');
fprintf('ZN Reaction Curve figure saved.\n');
