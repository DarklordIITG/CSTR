clear; clc; close all;
p = cstr_parameters();

fprintf('\n========================================\n');
fprintf('  STEADY-STATE ANALYSIS\n');
fprintf('========================================\n\n');

T_range = linspace(280, 420, 500);
tau = p.tau;

k_T     = p.k0 * exp(-p.EoverR ./ T_range);
X_A     = k_T * tau ./ (1 + k_T * tau);
CA_vals = p.CA0_ss * (1 - X_A);

Tc_approx = p.Tc_in + (p.UA .* (T_range - p.Tc_in)) ./ ...
            (p.rho_c * p.Cp_c * p.Fc_ss / p.Vc * p.Vc + p.UA);

Q_gen      = (-p.dHr) * 1000 * p.F_ss * p.CA0_ss .* X_A;
Q_rem_flow = p.F_ss * p.rho * p.Cp * (T_range - p.T0_ss);
Q_rem_cool = p.UA * (T_range - Tc_approx);
Q_rem      = Q_rem_flow + Q_rem_cool;

ss_residual = @(T_ss) heat_balance_residual(T_ss, p);

T_scan = linspace(290, 410, 1000);
residuals = arrayfun(ss_residual, T_scan);

sign_changes = find(diff(sign(residuals)));
fprintf('Found %d potential steady-state region(s)\n', length(sign_changes));

SS_temps = zeros(1, length(sign_changes));
SS_CA    = zeros(1, length(sign_changes));

for i = 1:length(sign_changes)
    T_bracket = [T_scan(sign_changes(i)), T_scan(sign_changes(i)+1)];
    try
        [T_sol, ~, flag] = fzero(ss_residual, T_bracket);
        if flag == 1
            k_sol = p.k0 * exp(-p.EoverR / T_sol);
            CA_sol = p.CA0_ss / (1 + k_sol * tau);
            SS_temps(i) = T_sol;
            SS_CA(i)    = CA_sol;
            fprintf('  SS Point %d: T = %.2f K (%.1f C), CA = %.4f mol/L, X = %.3f\n', ...
                    i, T_sol, T_sol-273.15, CA_sol, 1-CA_sol/p.CA0_ss);
        end
    catch
        fprintf('  Could not converge for bracket %d\n', i);
    end
end

fig1 = figure('Name','Steady-State Analysis','Position',[50 50 1400 550],'Color','k');

subplot(1,3,1)
set(gca,'Color',[0.12 0.12 0.18],'XColor','w','YColor','w','GridColor',[0.4 0.4 0.4]);
hold on; grid on;
plot(T_range - 273.15, X_A * 100, 'c-', 'LineWidth', 2.5);
xlabel('Reactor Temperature [°C]', 'Color','w','FontSize',11);
ylabel('Conversion X_A [%]', 'Color','w','FontSize',11);
title('Conversion vs Temperature (S-curve)', 'Color','w','FontSize',12,'FontWeight','bold');

colors_ss = {'r','y','g'};
labels_ss = {'Lower SS (stable)','Middle SS (unstable)','Upper SS (stable)'};
for i = 1:length(SS_temps)
    x_ss = 1 - SS_CA(i)/p.CA0_ss;
    scatter(SS_temps(i)-273.15, x_ss*100, 120, colors_ss{i}, 'filled', ...
            'MarkerEdgeColor','w','LineWidth',1.5,'DisplayName',labels_ss{i});
end
if ~isempty(SS_temps)
    legend('show','TextColor','w','Color',[0.2 0.2 0.3],'EdgeColor','w','FontSize',9);
end
set(gca,'FontSize',10);
ax = gca; ax.Title.Color = 'w';

subplot(1,3,2)
set(gca,'Color',[0.12 0.12 0.18],'XColor','w','YColor','w','GridColor',[0.4 0.4 0.4]);
hold on; grid on;
plot(T_range - 273.15, Q_gen/1000, 'r-', 'LineWidth', 2.5, 'DisplayName','Heat Generated Q_{gen}');
plot(T_range - 273.15, Q_rem/1000, 'b-', 'LineWidth', 2.5, 'DisplayName','Heat Removed Q_{rem}');
for i = 1:length(SS_temps)
    q_ss = heat_balance_qgen(SS_temps(i), p) / 1000;
    scatter(SS_temps(i)-273.15, q_ss, 120, colors_ss{i}, 'filled', ...
            'MarkerEdgeColor','w','LineWidth',1.5,'HandleVisibility','off');
end
xlabel('Reactor Temperature [°C]', 'Color','w','FontSize',11);
ylabel('Heat Rate [kW]', 'Color','w','FontSize',11);
title('Heat Generation vs Removal', 'Color','w','FontSize',12,'FontWeight','bold');
legend('TextColor','w','Color',[0.2 0.2 0.3],'EdgeColor','w','FontSize',9,'Location','northwest');
set(gca,'FontSize',10);
ax = gca; ax.Title.Color = 'w';

subplot(1,3,3)
set(gca,'Color',[0.12 0.12 0.18],'XColor','w','YColor','w','GridColor',[0.4 0.4 0.4]);
hold on; grid on;
plot(T_range - 273.15, residuals_full(T_range, p)/1000, 'm-', 'LineWidth',2);
yline(0, 'w--', 'LineWidth', 1.5);
for i = 1:length(SS_temps)
    xline(SS_temps(i)-273.15, '--', colors_ss{i}, 'LineWidth',1.5,'Label',sprintf('SS%d',i));
end
xlabel('Temperature [°C]', 'Color','w','FontSize',11);
ylabel('Q_{gen} - Q_{rem} [kW]', 'Color','w','FontSize',11);
title('Steady-State Residual (Zeros = SS Points)', 'Color','w','FontSize',12,'FontWeight','bold');
grid on;
set(gca,'FontSize',10);
ax = gca; ax.Title.Color = 'w';

sgtitle('CSTR Steady-State Analysis — Acetic Anhydride Hydrolysis', ...
        'Color','w','FontSize',14,'FontWeight','bold');

set(gcf,'Color','k');
saveas(fig1, 'steady_state_analysis.png');
fprintf('\nFigure saved: steady_state_analysis.png\n');

fprintf('\n--- Nominal Operating Point (Design SS) ---\n');
if ~isempty(SS_temps)
    idx = min(2, length(SS_temps));
    p.T_ss  = SS_temps(idx);
    p.CA_ss = SS_CA(idx);
    fprintf('T_ss  = %.2f K (%.1f C)\n', p.T_ss, p.T_ss-273.15);
    fprintf('CA_ss = %.4f mol/L\n', p.CA_ss);
    fprintf('X_A   = %.3f (%.1f%%)\n', 1-p.CA_ss/p.CA0_ss, (1-p.CA_ss/p.CA0_ss)*100);
end

function res = heat_balance_residual(T, p)
    tau = p.V / p.F_ss;
    k   = p.k0 * exp(-p.EoverR / T);
    CA  = p.CA0_ss / (1 + k * tau);
    X   = 1 - CA / p.CA0_ss;
    Tc  = p.Tc_in + p.UA*(T-p.Tc_in) / (p.rho_c*p.Cp_c*p.Fc_ss + p.UA);
    Qg  = (-p.dHr) * 1000 * p.F_ss * p.CA0_ss * X;
    Qr  = p.F_ss * p.rho * p.Cp * (T - p.T0_ss) + p.UA*(T - Tc);
    res = Qg - Qr;
end

function Qg = heat_balance_qgen(T, p)
    tau = p.V / p.F_ss;
    k   = p.k0 * exp(-p.EoverR / T);
    CA  = p.CA0_ss / (1 + k * tau);
    X   = 1 - CA / p.CA0_ss;
    Qg  = (-p.dHr) * 1000 * p.F_ss * p.CA0_ss * X;
end

function res = residuals_full(T_arr, p)
    res = arrayfun(@(T) heat_balance_residual(T, p), T_arr);
end
