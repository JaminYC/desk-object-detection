%% DEMO_24ABRIL — Avance del preprocesamiento
% Proyecto de Mitad de Semestre — Visión por Computadora (1MTR27)
% Grupo: [nombres]
%
% Este script:
%   1. Carga imágenes de dataset/raw + dataset/reference
%   2. Aplica el pipeline de preprocesamiento automático
%   3. Genera figuras comparativas (antes/después) en results/figures
%   4. Reporta métricas básicas en consola

clear; close all; clc;

% ---------- Configuración ----------
projectRoot = fileparts(mfilename('fullpath'));  % el script está en la raíz
addpath(genpath(fullfile(projectRoot, 'src')));

rawDir       = fullfile(projectRoot, 'dataset', 'raw');
referenceDir = fullfile(projectRoot, 'dataset', 'reference');
outDir       = fullfile(projectRoot, 'results', 'figures', 'avance_24abril');
if ~exist(outDir, 'dir'); mkdir(outDir); end

% ---------- Recopilar imágenes a procesar ----------
exts = {'*.jpg','*.jpeg','*.png'};
files = [];
for dir_ = {rawDir, referenceDir}
    d = dir_{1};
    if exist(d, 'dir')
        for e = 1:numel(exts)
            files = [files; dir(fullfile(d, '**', exts{e}))]; %#ok<AGROW>
        end
    end
end

if isempty(files)
    warning('No se encontraron imágenes en dataset/raw ni dataset/reference.');
    return;
end

fprintf('[demo] Se procesarán %d imágenes.\n', numel(files));

% ---------- Procesar ----------
metrics = struct('name', {}, 'psnr', {}, 'ssim', {});

for k = 1:numel(files)
    filePath = fullfile(files(k).folder, files(k).name);
    [~, baseName, ~] = fileparts(files(k).name);

    fprintf('\n[demo] (%d/%d) %s\n', k, numel(files), files(k).name);

    img = imread(filePath);
    if size(img, 3) == 1
        img = cat(3, img, img, img);   % escala a RGB si es gris
    end

    tic;
    imgOut = pipeline_preproc(img);
    t = toc;
    fprintf('[demo] tiempo: %.3f s\n', t);

    % Métricas cuantitativas rápidas (referencia = imagen original normalizada)
    imgRef = im2double(img);
    psnrVal = psnr(imgOut, imgRef);
    ssimVal = ssim(imgOut, imgRef);
    metrics(end+1) = struct('name', baseName, 'psnr', psnrVal, 'ssim', ssimVal); %#ok<SAGROW>

    % Figura comparativa
    fig = figure('Visible', 'off', 'Position', [100 100 1400 600]);
    subplot(1,2,1); imshow(img);    title('Original', 'FontSize', 14);
    subplot(1,2,2); imshow(imgOut); title('Preprocesada', 'FontSize', 14);
    sgtitle(sprintf('%s  |  PSNR=%.2f dB  SSIM=%.3f', baseName, psnrVal, ssimVal), 'FontSize', 12);

    outPath = fullfile(outDir, sprintf('%s_comparacion.png', baseName));
    exportgraphics(fig, outPath, 'Resolution', 150);
    close(fig);
end

% ---------- Resumen ----------
fprintf('\n========== Resumen ==========\n');
fprintf('%-30s  %8s  %8s\n', 'Imagen', 'PSNR', 'SSIM');
for k = 1:numel(metrics)
    fprintf('%-30s  %8.2f  %8.3f\n', metrics(k).name, metrics(k).psnr, metrics(k).ssim);
end
fprintf('\nFiguras guardadas en: %s\n', outDir);
