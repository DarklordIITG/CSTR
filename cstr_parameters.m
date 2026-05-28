function p = cstr_parameters()

    p.k0     = 7.08e10;
    p.E      = 69780;
    p.R      = 8.314;
    p.EoverR = p.E / p.R;

    p.dHr   = -209000;
    p.rho   = 1000;
    p.Cp    = 4184;
    p.rho_c = 1000;
    p.Cp_c  = 4184;

    p.V  = 0.1;
    p.Vc = 0.02;

    p.UA = 30000;

    p.CA0_ss = 1.5;
    p.T0_ss  = 300;
    p.F_ss   = 0.025;

    p.Tc_in = 285;
    p.Fc_ss = 0.005;

    p.tau = p.V / p.F_ss;
    fprintf('Nominal residence time (tau) = %.2f min\n', p.tau);

    p.CA_ss = 0.265;
    p.T_ss  = 330;
    p.Tc_ss = 298;

    fprintf('=== CSTR Parameters Loaded ===\n');
    fprintf('k0 = %.3e 1/min,  E/R = %.0f K\n', p.k0, p.EoverR);
    fprintf('Reactor Volume = %.0f L,  Nominal Flow = %.0f L/min\n', p.V*1000, p.F_ss*1000);
end
