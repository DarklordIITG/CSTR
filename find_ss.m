function x_ss = find_ss(p, x0)
    tspan = [0, 500];
    opts  = odeset('RelTol',1e-9,'AbsTol',1e-11,'MaxStep',0.1);
    ode_f = @(t,x) cstr_odes(t, x, p, p.F_ss, p.CA0_ss, p.T0_ss, p.Fc_ss);
    [~, X] = ode45(ode_f, tspan, x0, opts);
    x_ss = X(end,:)';
end
