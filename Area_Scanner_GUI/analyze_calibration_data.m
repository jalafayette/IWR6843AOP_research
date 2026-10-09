%% analyze_calibration_data.m
%
% Objetivo:
%   Ler o features_log.csv gerado pelo calibrate_person_car_logger.m
%   (com sessões rotuladas 'Pessoa' e 'Carro'), visualizar a separação
%   de cada feature entre as duas classes, e sugerir limiares para usar
%   no script de classificação em tempo real.

clear; clc; close all;

INPUT_CSV = 'dados_xpto.csv';

T = readtable(INPUT_CSV);
T.Properties.VariableNames = {'frame','tid','numPts','bboxDiag','meanSNR','medianSNR','snrQ1','snrQ3','range','snrNorm','dopplerStd','trackSpeed','label'};
T.label = string(T.label);
T.label = regexprep(T.label, ';.*$', '');   % remove o ";;;;;;;" agarrado ao fim
T.label = categorical(T.label);

fprintf('Total de linhas: %d\n', height(T));
summary(T.label)

%% ---------------- BOXPLOTS POR FEATURE ----------------
figure('Name','Calibração - separação por feature');

subplot(1,2,1);
boxplot(T.range, T.label);
ylabel('Distância ao sensor [m]'); title('Range');
grid on;

subplot(1,2,2);
boxplot(T.snrNorm, T.label);
ylabel('SNR normalizado [dB]'); title('Reflectividade (compensada pela distância)');
grid on;

subplot(1,3,1);
boxplot(T.bboxDiag, T.label);
ylabel('Diagonal do bbox [m]'); title('Tamanho');
grid on;

subplot(1,3,2);
boxplot(T.meanSNR, T.label);
ylabel('SNR médio [dB]'); title('Reflectividade (proxy RCS)');
grid on;

subplot(1,3,3);
boxplot(T.dopplerStd, T.label);
ylabel('Desvio-padrão do Doppler dentro do cluster [m/s]'); title('Proxy micro-Doppler');
grid on;

%% ---------------- ESTATÍSTICAS POR CLASSE ----------------
groupsummary(T, 'label', {'mean','std','median'}, {'bboxDiag','meanSNR','range','snrNorm','dopplerStd','trackSpeed'})

%% ---------------- ÁRVORE DE DECISÃO PARA SUGERIR LIMIARES ----------------
% Requer Statistics and Machine Learning Toolbox
predictors = T(:, {'bboxDiag','snrNorm','dopplerStd','trackSpeed'});
tree = fitctree(predictors, T.label, 'MaxNumSplits', 4, 'MinLeafSize', 20);

figure('Name','Árvore de decisão - limiares sugeridos');
view(tree, 'Mode', 'graph');

fprintf('\n--- Regras da árvore (usa estes cortes como ponto de partida para THRESH_*) ---\n');
view(tree, 'Mode', 'text');

% Validação cruzada simples para veres a fiabilidade dos limiares sugeridos
cvTree = crossval(tree);
fprintf('Erro de classificação (validação cruzada, 10-fold): %.1f%%\n', ...
    kfoldLoss(cvTree) * 100);
