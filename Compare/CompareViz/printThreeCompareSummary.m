function printThreeCompareSummary(comparison, cfg)
% printThreeCompareSummary  Print three-algorithm comparison summary and save report

    fprintf('\n========================================\n');
    fprintf('    Three-Algorithm Comparison Report\n');
    fprintf('========================================\n\n');

    fprintf('%-30s %10s %10s %10s\n', 'Metric', 'Traditional', 'MaxEntropy', 'CARS');
    fprintf('%-30s %10s %10s %10s\n', '------', '--------', '----------', '--------');

    fprintf('%-30s %10.2f%% %10.2f%% %10.2f%%\n', 'Final Coverage', ...
        comparison.finalCovOld*100, comparison.finalCovMax*100, comparison.finalCovImproved*100);
    fprintf('%-30s %10.2f%% %10.2f%% %10.2f%%\n', 'Sea Coverage', ...
        comparison.finalSeaOld*100, comparison.finalSeaMax*100, comparison.finalSeaImproved*100);
    fprintf('%-30s %10.2f%% %10.2f%% %10.2f%%\n', 'Island Coverage', ...
        comparison.finalIslandOld*100, comparison.finalIslandMax*100, comparison.finalIslandImproved*100);
    fprintf('%-30s %10d %10d %10d\n', 'Stop Time(s)', ...
        comparison.stopTimeOld, comparison.stopTimeMax, comparison.stopTimeImproved);
    fprintf('%-30s %10d %10d %10d\n', 'Stop Step', ...
        comparison.stopStepOld, comparison.stopStepMax, comparison.stopStepImproved);

    if isfield(comparison, 'eta_B_Old')
        fprintf('\n--- Communication Metrics ---\n');
        fprintf('%-30s %10.4f %10.4f %10.4f\n', 'eta_B (Basic Service)', ...
            comparison.eta_B_Old, comparison.eta_B_Max, comparison.eta_B_Improved);
        fprintf('%-30s %10.4f %10.4f %10.4f\n', 'eta_L (LoS Service)', ...
            comparison.eta_L_Old, comparison.eta_L_Max, comparison.eta_L_Improved);
        fprintf('%-30s %10.4f %10.4f %10.4f\n', 'rho_LoS', ...
            comparison.rho_LoS_Old, comparison.rho_LoS_Max, comparison.rho_LoS_Improved);
        fprintf('%-30s %10.2f %10.2f %10.2f\n', 'Mean SINR (dB)', ...
            comparison.gamma_bar_Old, comparison.gamma_bar_Max, comparison.gamma_bar_Improved);
        fprintf('%-30s %10.2f %10.2f %10.2f\n', 'Mean Data Rate (kbps)', ...
            comparison.R_bar_Old, comparison.R_bar_Max, comparison.R_bar_Improved);
        fprintf('%-30s %10.4f %10.4f %10.4f\n', 'lambda2_B', ...
            comparison.lambda2_B_Old, comparison.lambda2_B_Max, comparison.lambda2_B_Improved);
        fprintf('%-30s %10.4f %10.4f %10.4f\n', 'lambda2_L', ...
            comparison.lambda2_L_Old, comparison.lambda2_L_Max, comparison.lambda2_L_Improved);
        fprintf('%-30s %10d %10d %10d\n', 'Max Discon (steps)', ...
            comparison.tau_out_Old, comparison.tau_out_Max, comparison.tau_out_Improved);
    end

    fprintf('%-30s %10.2f%% %10.2f%% %10.2f%%\n', 'Final Repeat Rate', ...
        comparison.repeatRateOld*100, comparison.repeatRateMax*100, comparison.repeatRateImproved*100);
    fprintf('%-30s %10.2f %10.2f %10.2f\n', 'Avg Connected UAVs', ...
        comparison.avgConnOld, comparison.avgConnMax, comparison.avgConnImproved);

    % Key comparison
    fprintf('\n--- Key Comparison ---\n');
    covDiff_m_o = (comparison.finalCovMax - comparison.finalCovOld)*100;
    covDiff_i_o = (comparison.finalCovImproved - comparison.finalCovOld)*100;
    fprintf('MaxEntropy vs Traditional: coverage %+.2f%% · CARS vs Traditional: coverage %+.2f%%\n', covDiff_m_o, covDiff_i_o);

    if isfield(comparison, 'eta_B_Old')
        etaDiff_m_o = (comparison.eta_B_Max - comparison.eta_B_Old)*100;
        etaDiff_i_o = (comparison.eta_B_Improved - comparison.eta_B_Old)*100;
        fprintf('MaxEntropy vs Traditional: eta_B %+.1f%% · CARS vs Traditional: eta_B %+.1f%%\n', etaDiff_m_o, etaDiff_i_o);
        if comparison.eta_B_Max < comparison.eta_B_Old
            fprintf('[OK] MaxEntropy algorithm degrades communication (as expected)\n');
        end
        if comparison.finalCovImproved > comparison.finalCovOld && comparison.eta_B_Improved > comparison.eta_B_Old
            fprintf('[OK] CARS achieves BOTH coverage AND communication improvement (GOAL ACHIEVED)\n');
        end
    end
    fprintf('========================================\n\n');

    % Save report
    fid = fopen(fullfile(cfg.outputDir, 'three_compare_report.txt'), 'w');
    fprintf(fid, 'Three-Algorithm Comparison Results\n');
    fprintf(fid, 'Traditional vs MaxEntropy vs CARS\n\n');
    fprintf(fid, 'Coverage: Traditional=%.2f%%, MaxEntropy=%.2f%%, CARS=%.2f%%\n', ...
        comparison.finalCovOld*100, comparison.finalCovMax*100, comparison.finalCovImproved*100);
    if isfield(comparison, 'eta_B_Old')
        fprintf(fid, 'eta_B: Traditional=%.4f, MaxEntropy=%.4f, CARS=%.4f\n', ...
            comparison.eta_B_Old, comparison.eta_B_Max, comparison.eta_B_Improved);
        fprintf(fid, 'eta_L: Traditional=%.4f, MaxEntropy=%.4f, CARS=%.4f\n', ...
            comparison.eta_L_Old, comparison.eta_L_Max, comparison.eta_L_Improved);
        fprintf(fid, 'lambda2_B: Traditional=%.4f, MaxEntropy=%.4f, CARS=%.4f\n', ...
            comparison.lambda2_B_Old, comparison.lambda2_B_Max, comparison.lambda2_B_Improved);
    end
    fprintf(fid, 'Repeat Rate: Traditional=%.2f%%, MaxEntropy=%.2f%%, CARS=%.2f%%\n', ...
        comparison.repeatRateOld*100, comparison.repeatRateMax*100, comparison.repeatRateImproved*100);
    fclose(fid);
    fprintf('  Three-algorithm report saved\n');
end
