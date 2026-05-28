function dxdt = cstr_odes(t, x, p, F, CA0, T0, Fc)
    CA = x(1);
    T  = x(2);
    Tc = x(3);

    CA = max(CA, 0);
    T  = max(T,  200);
    Tc = max(Tc, 200);

    k = p.k0 * exp(-p.EoverR / T);
    r = k * CA;

    tau_inv = F / p.V;

    dCA_dt = tau_inv * (CA0 - CA) - r;

    Q_rxn  = (-p.dHr) / (p.rho * p.Cp) * r * 1000;
    Q_cool = p.UA / (p.rho * p.Cp * p.V) * (T - Tc);
    dT_dt  = tau_inv * (T0 - T) + Q_rxn - Q_cool;

    Q_transfer = p.UA / (p.rho_c * p.Cp_c * p.Vc) * (T - Tc);
    dTc_dt = (Fc / p.Vc) * (p.Tc_in - Tc) + Q_transfer;

    dxdt = [dCA_dt; dT_dt; dTc_dt];
end
