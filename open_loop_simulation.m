clear; clc; close all;
p = cstr_parameters();

fprintf('\n========================================\n');
fprintf('  OPEN-LOOP DYNAMIC SIMULATION\n');
fprintf('========================================\n\n');

x0_guess = [p.CA_ss; p.T_ss; p.Tc_ss];
fprintf('Finding steady state by long-time integration...\n');
x_ss = find_ss(p, x0_guess);
fprintf('  CA_ss  = %.4f mol/L\n', x_ss(1));
fprintf('  T_ss   = %.2f K (%.1f C)\n', x_ss(2), x_ss(2)-273.15);
fprintf('  Tc_ss  = %.2f K (%.1f C)\n', x_ss(3), x_ss(3)-273.15);
fprintf('  X_A_ss = %.3f\n\n', 1 - x_ss(1)/p.CA0_ss);

t_end    = 30;
t_step   = 5;
tspan    = [0, t_end];
ode_opts = odeset('RelTol',1e-8,'AbsTol',1e-10,'MaxStep',0.01);

fprintf('Simulating Case A: Step in Feed Temperature T0 +10 K...\n');
T0_new = p.T0_ss + 10;
ode_a  = @(t,x) cstr_odes(t, x, p, p.F_ss, p.CA0_ss, ...
                           (t < t_step)*p.T0_ss + (t >= t_step)*T0_new, p.Fc_ss);
[t_a, X_a] = ode45(ode_a, tspan, x_ss, ode_opts);

fprintf('Simulating Case B: Step in Feed Flow Rate F +20%%...\n');
F_new  = p.F_ss * 1.20;
ode_b  = @(t,x) cstr_odes(t, x, p, ...
                           (t < t_step)*p.F_ss + (t >= t_step)*F_new, ...
                           p.CA0_ss, p.T0_ss, p.Fc_ss);
[t_b, X_b] = ode45(ode_b, tspan, x_ss, ode_opts);

fprintf('Simulating Case C: Step in Feed Concentration CA0 -15%%...\n');
CA0_new = p.CA0_ss * 0.85;
ode_c   = @(t,x) cstr_odes(t, x, p, p.F_ss, ...
                            (t < t_step)*p.CA0_ss + (t >= t_step)*CA0_new, ...
                            p.T0_ss, p.Fc_ss);
[t_c, X_c] = ode45(ode_c, tspan, x_ss, ode_opts);

fig = figure('Name','Open-Loop Simulation','Position',[30 30 1500 750],'Color','k');
colors = {[0 0.83 1], [1 0.42 0.42], [0.66 1 0.47]};

for row = 1:3
    switch row
        case 1
            t_vec = t_a; X_vec = X_a; label = '+10 K Feed Temp (T_0)'; c = colors{1};
        case 2
            t_vec = t_b; X_vec = X_b; label = '+20% Feed Flow (F)'; c = colors{2};
        case 3
            t_vec = t_c; X_vec = X_c; label = '-15% Feed Conc (C_{A0})'; c = colors{3};
    end

    subplot(3,3,(row-1)*3+1)
    set(gca,'Color',[0.1 0.1 0.15],'XColor','w','YColor','w','GridColor',[0.35 0.35 0.35]);
    hold on; grid on;
    plot(t_vec, X_vec(:,1)*1000, 'Color', c, 'LineWidth', 2);
    xline(t_step,'w--','LineWidth',1.2,'Label','Step','LabelColor','y');
    yline(x_ss(1)*1000,'--','Color',[0.7 0.7 0.7],'LineWidth',1,'Label','SS','LabelColor',[0.7 0.7 0.7]);
    xlabel('Time [min]','Color','w','FontSize',10);
    ylabel('C_A [mmol/L]','Color','w','FontSize',10);
    title(sprintf('Conc — Case %c', 'A'+row-1),'Color','w','FontSize',11,'FontWeight','bold');
    set(gca,'FontSize',9,'TickDir','out');

    subplot(3,3,(row-1)*3+2)
    set(gca,'Color',[0.1 0.1 0.15],'XColor','w','YColor','w','GridColor',[0.35 0.35 0.35]);
    hold on; grid on;
    plot(t_vec, X_vec(:,2)-273.15, 'Color', c, 'LineWidth', 2);
    xline(t_step,'w--','LineWidth',1.2,'Label','Step','LabelColor','y');
    yline(x_ss(2)-273.15,'--','Color',[0.7 0.7 0.7],'LineWidth',1,'Label','SS','LabelColor',[0.7 0.7 0.7]);
    xlabel('Time [min]','Color','w','FontSize',10);
    ylabel('T [°C]','Color','w','FontSize',10);
    title(sprintf('Reactor Temp — %s', label),'Color','w','FontSize',11,'FontWeight','bold');
    set(gca,'FontSize',9,'TickDir','out');

    subplot(3,3,(row-1)*3+3)
    set(gca,'Color',[0.1 0.1 0.15],'XColor','w','YColor','w','GridColor',[0.35 0.35 0.35]);
    hold on; grid on;
    plot(t_vec, X_vec(:,3)-273.15, 'Color', [1 0.65 0], 'LineWidth', 2);
    xline(t_step,'w--','LineWidth',1.2,'Label','Step','LabelColor','y');
    yline(x_ss(3)-273.15,'--','Color',[0.7 0.7 0.7],'LineWidth',1,'Label','SS','LabelColor',[0.7 0.7 0.7]);
    xlabel('Time [min]','Color','w','FontSize',10);
    ylabel('T_c [°C]','Color','w','FontSize',10);
    title(sprintf('Coolant Temp — Case %c', 'A'+row-1),'Color','w','FontSize',11,'FontWeight','bold');
    set(gca,'FontSize',9,'TickDir','out');
end

sgtitle('Open-Loop CSTR Dynamics — ode45 Simulation (No Controller)', ...
        'Color','w','FontSize',14,'FontWeight','bold','Color','w');
set(gcf,'Color','k');
saveas(fig, 'open_loop_simulation.png');
fprintf('\nFigure saved: open_loop_simulation.png\n');

fprintf('\n--- Open-Loop Response Summary ---\n');
fprintf('Case A (DeltaT0 = +10K): Final T = %.2f C (Delta = %.2f C)\n', ...
        X_a(end,2)-273.15, X_a(end,2)-x_ss(2));
fprintf('Case B (DeltaF = +20%%):  Final T = %.2f C (Delta = %.2f C)\n', ...
        X_b(end,2)-273.15, X_b(end,2)-x_ss(2));
fprintf('Case C (DeltaCA0=-15%%): Final T = %.2f C (Delta = %.2f C)\n', ...
        X_c(end,2)-273.15, X_c(end,2)-x_ss(2));
fprintf('\nObservation: Without control, temperature deviates significantly.\n');
fprintf('This motivates the need for a PID feedback controller.\n');
