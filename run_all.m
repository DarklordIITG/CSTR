clear; clc; close all;
fprintf('╔══════════════════════════════════════════════════════╗\n');
fprintf('║    CSTR TEMPERATURE CONTROL PROJECT — IIT GUWAHATI   ║\n');
fprintf('║    Acetic Anhydride Hydrolysis System                 ║\n');
fprintf('╚══════════════════════════════════════════════════════╝\n\n');

%% STEP 1: Parameters
fprintf('\n[1/5] Loading CSTR Parameters...\n');
p = cstr_parameters();
pause(0.5);

%% STEP 2: Steady-State Analysis
fprintf('\n[2/5] Running Steady-State Analysis...\n');
steady_state_analysis;
pause(0.5);

%% STEP 3: Open-Loop Simulation
fprintf('\n[3/5] Running Open-Loop ODE Simulation...\n');
open_loop_simulation;
pause(0.5);

%% STEP 4: PID Tuning + Comparison
fprintf('\n[4/5] Performing ZN Tuning & P/PI/PID Comparison...\n');
pid_tuning;
pause(0.5);

%% STEP 5: Performance Metrics
fprintf('\n[5/5] Computing Performance Metrics...\n');
performance_metrics;

fprintf('\n========================================================\n');
fprintf('  ALL ANALYSES COMPLETE!\n');
fprintf('  Generated Figures:\n');
fprintf('    steady_state_analysis.png\n');
fprintf('    open_loop_simulation.png\n');
fprintf('    zn_reaction_curve.png\n');
fprintf('    pid_comparison.png\n');
fprintf('    performance_metrics.png\n');
fprintf('========================================================\n');
