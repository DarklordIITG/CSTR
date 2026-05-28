clear; clc; close all;
if exist('cstr_pid_gains.mat','file')
    load('cstr_pid_gains.mat');
else
    error('Run pid_tuning.m first to generate cstr_pid_gains.mat');
end

fprintf('\n========================================\n');
fprintf('  PERFORMANCE METRICS ANALYSIS\n');
fprintf('========================================\n\n');

x_ss   = SS_state;
T_sp   = x_ss(2);
T_new  = T_sp + 5;
dt     = 0.01;
t_end  = 60;
t_sim  = 0:dt:t_end;
N      = length(t_sim);
t_step = 3;
Fc_max = p.Fc_ss * 3.5;
Fc_min = p.Fc_ss * 0.05;
delta  = T_new - T_sp;

controllers = {
    struct('name','P',   'Kp',ZN_RC.P.Kp,   'Ti',Inf,           'Td',0)
    struct('name','PI',  'Kp',ZN_RC.PI.Kp,  'Ti',ZN_RC.PI.Ti,  'Td',0)
    struct('name','PID', 'Kp',ZN_RC.PID.Kp, 'Ti',ZN_RC.PID.Ti, 'Td',ZN_RC.PID.Td)
};

metrics = struct();

for c = 1:3
    ctrl       = controllers{c};
    fprintf('Computing metrics for %s controller...\n', ctrl.name);
    x_curr     = x_ss;
    Fc_curr    = p.Fc_ss;
    integral_e = 0;
    e_prev     = 0;
    T_vec      = zeros(N,1);

    for k = 1:N
        t_k  = t_sim(k);
        sp_k = T_sp + (t_k >= t_step) * delta;
        e_k  = sp_k - x_curr(2);

        if Fc_curr > Fc_min && Fc_curr < Fc_max
            integral_e = integral_e + e_k * dt;
        end
        de_k   = (e_k - e_prev) / dt;
        e_prev = e_k;

        if isinf(ctrl.Ti), I = 0; else, I = integral_e / ctrl.Ti; end
        u_pid   = ctrl.Kp * (e_k + I + ctrl.Td * de_k);
        Fc_curr = p.Fc_ss - u_pid;
        Fc_curr = max(Fc_min, min(Fc_max, Fc_curr));

        T_vec(k) = x_curr(2);
        dx = cstr_odes(t_k, x_curr, p, p.F_ss, p.CA0_ss, p.T0_ss, Fc_curr);
        x_curr = x_curr + dx * dt;
        x_curr(1) = max(x_curr(1), 0);
    end

    idx_step   = find(t_sim >= t_step, 1);
    T_post     = T_vec(idx_step:end);
    t_post     = (t_sim(idx_step:end) - t_step)';
    sp_post    = T_new * ones(size(t_post));
    error_post = sp_post - T_post;

    T_10   = T_sp + 0.10 * delta;
    T_90   = T_sp + 0.90 * delta;
    idx_10 = find(T_post >= T_10, 1);
    idx_90 = find(T_post >= T_90, 1);
    if ~isempty(idx_10) && ~isempty(idx_90)
        t_rise = t_post(idx_90) - t_post(idx_10);
    else
        t_rise = NaN;
    end

    [T_peak, idx_peak] = max(T_post);
    overshoot = max(0, (T_peak - T_new) / delta * 100);
    t_peak    = t_post(idx_peak);

    band        = 0.02 * delta;
    settled     = abs(T_post - T_new) <= band;
    settled_idx = find(~settled, 1, 'last');
    if isempty(settled_idx) || settled_idx == length(t_post)
        t_settle = NaN;
    else
        t_settle = t_post(settled_idx + 1);
    end

    idx_late = t_post >= (t_post(end) - 5);
    ss_error = mean(sp_post(idx_late)' - T_post(idx_late));

    IAE  = trapz(t_post, abs(error_post));
    ITAE = trapz(t_post, t_post .* abs(error_post));

    metrics(c).name      = ctrl.name;
    metrics(c).t_rise    = t_rise;
    metrics(c).overshoot = overshoot;
    metrics(c).t_settle  = t_settle;
    metrics(c).ss_error  = ss_error;
    metrics(c).IAE       = IAE;
    metrics(c).ITAE      = ITAE;
    metrics(c).T_vec     = T_vec;

    fprintf('  Rise Time     : %.3f min\n', t_rise);
    fprintf('  Overshoot     : %.2f%%\n', overshoot);
    fprintf('  Settling Time : %.3f min\n', t_settle);
    fprintf('  SS Error      : %.4f K\n', ss_error);
    fprintf('  IAE           : %.4f K*min\n', IAE);
    fprintf('  ITAE          : %.4f K*min^2\n\n', ITAE);
end

fprintf('╔══════════════════════════════════════════════════════════════╗\n');
fprintf('║           PERFORMANCE METRICS SUMMARY TABLE                ║\n');
fprintf('╠══════════╦══════════╦══════════╦══════════╦══════════╦══════╣\n');
fprintf('║ Controller║ Rise[min]║Overshoot%%║Settle[min]║ SS Err[K]║  IAE ║\n');
fprintf('╠══════════╬══════════╬══════════╬══════════╬══════════╬══════╣\n');
for c = 1:3
    m = metrics(c);
    fprintf('║ %-9s║ %8.3f ║ %8.2f ║ %9.3f ║ %8.4f ║%5.2f ║\n', ...
            m.name, m.t_rise, m.overshoot, m.t_settle, m.ss_error, m.IAE);
end
fprintf('╚══════════╩══════════╩══════════╩══════════╩══════════╩══════╝\n');

fig = figure('Name','Performance Metrics','Position',[30 30 1400 600],'Color','k');

subplot(1,3,1)
set(gca,'Color',[0.1 0.1 0.15],'XColor','w','YColor','w','GridColor',[0.3 0.3 0.3]);
hold on; grid on;
colors_m = {[1 0.42 0.42], [1 0.84 0], [0 0.9 1]};
sp_plot  = T_sp + (t_sim >= t_step) * delta;
plot(t_sim - t_step, sp_plot - 273.15, 'w--', 'LineWidth', 1.5, 'DisplayName','Setpoint');
for c = 1:3
    plot(t_sim - t_step, metrics(c).T_vec - 273.15, 'Color', colors_m{c}, ...
         'LineWidth', 2.2, 'DisplayName', metrics(c).name);
end
xlim([-1, 30]); xline(0,'y:','LineWidth',1.2,'Label','Step','LabelColor','y');
xlabel('Time after step [min]','Color','w'); ylabel('T [°C]','Color','w');
title('Closed-Loop Setpoint Response','Color','w','FontWeight','bold');
legend('TextColor','w','Color',[0.2 0.2 0.3],'EdgeColor','w','FontSize',9,'Location','southeast');

metric_names = {metrics.name};
subplot(1,3,2)
set(gca,'Color',[0.1 0.1 0.15],'XColor','w','YColor','w','GridColor',[0.3 0.3 0.3]);
hold on; grid on;
ov_vals = [metrics.overshoot];
b = bar(categorical(metric_names), ov_vals, 0.5);
b.FaceColor = 'flat';
b.CData = [1 0.4 0.4; 1 0.85 0; 0 0.9 1];
xlabel('Controller','Color','w','FontSize',11);
ylabel('Overshoot [%]','Color','w','FontSize',11);
title('Overshoot Comparison','Color','w','FontWeight','bold');
set(gca,'FontSize',10);
for i = 1:3
    text(i, ov_vals(i)+0.1, sprintf('%.2f%%', ov_vals(i)), ...
         'Color','w','HorizontalAlignment','center','FontSize',10,'FontWeight','bold');
end

subplot(1,3,3)
set(gca,'Color',[0.1 0.1 0.15],'XColor','w','YColor','w','GridColor',[0.3 0.3 0.3]);
hold on; grid on;
iae_vals  = [metrics.IAE];
itae_vals = [metrics.ITAE];
x_pos     = 1:3;
b1 = bar(x_pos - 0.2, iae_vals,  0.35);  b1.FaceColor = [0 0.75 1];
b2 = bar(x_pos + 0.2, itae_vals, 0.35);  b2.FaceColor = [1 0.39 0.28];
set(gca,'XTick',1:3,'XTickLabel',metric_names,'FontSize',10,'XColor','w','YColor','w');
ylabel('Error Integral Value','Color','w','FontSize',11);
title('IAE vs ITAE','Color','w','FontWeight','bold');
legend({'IAE','ITAE'},'TextColor','w','Color',[0.2 0.2 0.3],'EdgeColor','w','FontSize',9);
grid on;

sgtitle('Controller Performance Metrics — CSTR Temperature Control', ...
        'Color','w','FontSize',14,'FontWeight','bold');
set(gcf,'Color','k');
saveas(fig, 'performance_metrics.png');
fprintf('\nFigure saved: performance_metrics.png\n');
