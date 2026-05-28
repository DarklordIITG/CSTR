function [dCA, dT, dTc] = cstr_odes_simulink(CA, T, Tc, Fc, T0)
    k0     = 7.08e10;
    EoverR = 10000;
    dHr    = -209000;
    rho    = 1000;
    Cp     = 4184;
    rho_c  = 1000;
    Cp_c   = 4184;
    UA     = 30000;
    V      = 0.1;
    Vc     = 0.02;
    F      = 0.025;
    CA0    = 1.5;
    Tc_in  = 285;

    CA = max(CA, 0);
    T  = max(T,  200);
    Tc = max(Tc, 200);
    Fc = max(Fc, 1e-5);

    k = k0 * exp(-EoverR / T);

    dCA = (F/V)*(CA0 - CA) - k*CA;

    dT = (F/V)*(T0 - T) ...
         + (-dHr)/(rho*Cp) * k*CA * 1000 ...
         - UA/(rho*Cp*V) * (T - Tc);

    dTc = (Fc/Vc)*(Tc_in - Tc) ...
          + UA/(rho_c*Cp_c*Vc) * (T - Tc);
end
