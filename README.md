# CSTR Temperature Control — MATLAB/Simulink Project

**Chemical Engineering | IIT Guwahati**

A complete process control project simulating a Continuous Stirred Tank Reactor (CSTR) for acetic anhydride hydrolysis. Covers mathematical modeling, steady-state analysis, open-loop dynamics, and PID controller design using Ziegler-Nichols tuning.

---

## Reaction System

```
(CH₃CO)₂O  +  H₂O  →  2 CH₃COOH
 Acetic Anhydride     Acetic Acid
```

First-order irreversible exothermic reaction. Arrhenius kinetics with **E/R = 10,000 K**.

---

## Project Structure

```
cstr_control/
├── run_all.m                  ← Run this first — executes all steps in order
├── cstr_parameters.m          ← All system parameters (kinetics, geometry, thermodynamics)
├── cstr_odes.m                ← 3-state ODE model (mass + energy balances)
├── steady_state_analysis.m    ← S-curves, heat balance, multiple steady states
├── open_loop_simulation.m     ← ode45 step responses without any controller
├── pid_tuning.m               ← Ziegler-Nichols tuning + P/PI/PID comparison
├── disturbance_rejection.m    ← PID response to feed disturbances
├── performance_metrics.m      ← Rise time, overshoot, settling time, IAE, ITAE
└── cstr_odes_simulink.m       ← ODE function for the Simulink MATLAB Function block
```

---

## How to Run

1. Open MATLAB and set the working directory to this folder:
   ```matlab
   cd('path/to/cstr_control')
   ```

2. Run the master script:
   ```matlab
   run_all
   ```

This runs all 5 analysis steps sequentially and saves figures as `.png` files.

To run a single step manually:
```matlab
p = cstr_parameters();
steady_state_analysis
open_loop_simulation
pid_tuning                % also saves cstr_pid_gains.mat
disturbance_rejection     % requires cstr_pid_gains.mat
performance_metrics       % requires cstr_pid_gains.mat
```

---

## System Model

The reactor is described by 3 state variables:

| Variable | Meaning | Units |
|---|---|---|
| `CA` | Reactant concentration | mol/L |
| `T` | Reactor temperature | K |
| `Tc` | Coolant jacket temperature | K |

**Governing ODEs:**

```
dCA/dt = (F/V)*(CA0 - CA) - k(T)*CA
dT/dt  = (F/V)*(T0 - T) + (-dHr)/(ρCp)*k(T)*CA*1000 - UA/(ρCp*V)*(T - Tc)
dTc/dt = (Fc/Vc)*(Tc_in - Tc) + UA/(ρc*Cp_c*Vc)*(T - Tc)
k(T)   = k0 * exp(-E/R / T)
```

**Control loop:**
- Controlled Variable (CV): Reactor temperature `T`
- Manipulated Variable (MV): Coolant flow rate `Fc`

---

## Key Parameters

| Parameter | Value | Units |
|---|---|---|
| Pre-exponential factor k₀ | 7.08 × 10¹⁰ | 1/min |
| Activation energy E/R | 10,000 | K |
| Heat of reaction ΔHr | −209,000 | J/mol |
| Reactor volume V | 0.1 (100 L) | m³ |
| Feed concentration CA₀ | 1.5 | mol/L |
| Feed temperature T₀ | 300 (27°C) | K |
| Nominal flow rate F | 0.025 (25 L/min) | m³/min |
| UA (heat transfer) | 30,000 | W/K |
| Coolant inlet temp Tc,in | 285 (12°C) | K |
| Nominal coolant flow Fc | 0.005 (5 L/min) | m³/min |

---

## What Each Script Does

### `steady_state_analysis.m`
- Sweeps temperature from 280–420 K and plots conversion (S-curve)
- Computes heat generation and heat removal curves
- Uses `fzero` to find all steady-state operating points (possibly 3)
- Identifies stable and unstable steady states

### `open_loop_simulation.m`
- Finds steady state using `fsolve`
- Simulates 3 step disturbances using `ode45`:
  - Case A: Feed temperature +10 K
  - Case B: Feed flow rate +20%
  - Case C: Feed concentration −15%
- Shows reactor response without any controller

### `pid_tuning.m`
- **Reaction Curve Method**: applies 10% step in coolant flow, fits FOPDT model, computes ZN gains
- **Ultimate Gain Method**: finds Ku and Pu from FOPDT Bode plot (phase = −180°)
- Simulates P, PI, and PID closed-loop responses to a +5 K setpoint step
- Saves gains to `cstr_pid_gains.mat`

### `disturbance_rejection.m`
- Loads PID gains from `cstr_pid_gains.mat`
- Simulates 3 disturbance scenarios:
  - Case A: Feed temperature spike +15 K (3 min pulse)
  - Case B: Feed concentration step +20% (persistent)
  - Case C: Both simultaneously (stress test)

### `performance_metrics.m`
- Runs all 3 controllers and computes:
  - Rise time (10%→90%)
  - Overshoot (%)
  - Settling time (±2% band)
  - Steady-state error
  - IAE and ITAE
- Prints a formatted summary table to console

---

## Simulink Setup

Use `cstr_odes_simulink.m` inside a **MATLAB Function** block in Simulink.

Paste this into the MATLAB Function block:
```matlab
function [dCA, dT, dTc] = fcn(CA, T, Tc, Fc, T0)
    [dCA, dT, dTc] = cstr_odes_simulink(CA, T, Tc, Fc, T0);
end
```

Connect:
- 3 `Integrator` blocks (initial conditions: CA_ss, T_ss, Tc_ss)
- 1 `PID Controller` block (Parallel form, anti-windup enabled)
- 1 `Saturation` block on Fc (limits: 0.5–17.5 L/min)
- `Step` blocks for setpoint and disturbances
- `Scope` blocks to visualize outputs

Solver settings: `ode45`, max step = 0.01, stop time = 60 min.

---

## Output Figures

| File | Contents |
|---|---|
| `steady_state_analysis.png` | S-curve, heat balance, residual plot |
| `open_loop_simulation.png` | 3×3 grid of CA, T, Tc responses |
| `zn_reaction_curve.png` | FOPDT identification from step test |
| `pid_comparison.png` | P vs PI vs PID setpoint tracking |
| `disturbance_rejection.png` | 3 disturbance cases with PID |
| `performance_metrics.png` | Overshoot bar chart + IAE/ITAE comparison |

---

## Requirements

- MATLAB R2020b or later
- Optimization Toolbox (`fsolve`, `optimoptions`)
- Simulink (for `cstr_odes_simulink.m` only)

---

## References

1. Luyben, W.L. (1990). *Process Modeling, Simulation and Control for Chemical Engineers*, 2nd Ed., McGraw-Hill.
2. Marlin, T.E. (2000). *Process Control*, 2nd Ed., McGraw-Hill.
3. Seborg, D.E. et al. (2016). *Process Dynamics and Control*, 4th Ed., Wiley.
