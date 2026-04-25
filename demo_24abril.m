%% DEMO_24ABRIL — Avance de preprocesamiento
% Proyecto de Mitad de Semestre — Visión por Computadora (1MTR27) PUCP 2026-1
%
% Procesa imágenes del dataset/reference/ por condición de iluminación:
%   CL  = Con luz brillante
%   NL  = Normal
%   LL  = Low light (poca luz)
%   RL  = Rotada / inclinada
%   CSL = Con sombra de luz
%
% Genera figuras comparativas (antes/después) en results/figures/avance_24abril/
% CÓMO CORRER: cd a desk-object-detection/ y ejecutar demo_24abril

clear; close all; clc;

projectRoot = fileparts(mfilename('fullpath'));  % el script está en la raíz
addpath(genpath(fullfile(projectRoot, 'src')));

refDir = fullfile(projectRoot, 'dataset', 'reference');
outDir = fullfile(projectRoot, 'results', 'figures', 'avance_24abril');
if ~exist(outDir, 'dir'), mkdir(outDir); end

% Condiciones: carpeta → etiqueta legible
conditions = {
    'NL',  'Normal';
    'CL',  'Con Luz Brillante';
    'LL',  'Poca Luz';
    'RL',  'Rotada/Inclinada';
    'CSL', 'Con Sombra';
};

% Por cada condición tomar hasta MAX_PER_COND imágenes (Small para velocidad)
MAX_PER_COND = 3;

metrics = struct('name',{}, 'condition',{}, 'psnr',{}, 'ssim',{});

for c = 1:size(conditions, 1)
    condCode = conditions{c, 1};
    condName = conditions{c, 2};

    % Preferir Small (más rápido); si no, usar OG
    smallDir = fullfile(refDir, condCode, 'Small');
    ogDir    = fullfile(refDir, condCode, 'OG');
    ogDir2   = fullfile(refDir, condCode, 'Og');

    if     exist(smallDir, 'dir'), searchDir = smallDir;
    elseif exist(ogDir,    'dir'), searchDir = ogDir;
    elseif exist(ogDir2,   'dir'), searchDir = ogDir2;
    else
        fprintf('[demo] Carpeta %s no encontrada, saltando.\n', condCode);
        continue
    end

    files = [dir(fullfile(searchDir,'*.jpg')); dir(fullfile(searchDir,'*.JPG'))];
    if isempty(files)
        fprintf('[demo] Sin imágenes en %s\n', searchDir);
        continue
    end

    nUse = min(MAX_PER_COND, numel(files));
    fprintf('\n[demo] === %s (%s): procesando %d/%d imágenes ===\n', ...
        condName, condCode, nUse, numel(files));

    condOutDir = fullfile(outDir, condCode);
    if ~exist(condOutDir, 'dir'), mkdir(condOutDir); end

    for k = 1:nUse
        filePath = fullfile(files(k).folder, files(k).name);
        [~, baseName, ~] = fileparts(files(k).name);

        img = imread(filePath);
        if size(img, 3) == 1, img = cat(3, img, img, img); end

        fprintf('[demo] (%d/%d) %s ... ', k, nUse, files(k).name);
        tic;
        imgOut = pipeline_preproc(img);
        t = toc;
        fprintf('%.2fs\n', t);

        imgRef  = im2double(img);
        psnrVal = psnr(imgOut, imgRef);
        ssimVal = ssim(imgOut, imgRef);
        metrics(end+1) = struct('name', baseName, 'condition', condCode, ...
                                'psnr', psnrVal, 'ssim', ssimVal); %#ok<SAGROW>

        fig = figure('Visible', 'off', 'Position', [50 50 1400 550]);
        subplot(1,2,1); imshow(img);    title('Original',     'FontSize', 13);
        subplot(1,2,2); imshow(imgOut); title('Preprocesada', 'FontSize', 13);
        sgtitle(sprintf('[%s] %s  |  PSNR=%.1f dB  SSIM=%.3f', ...
            condCode, baseName, psnrVal, ssimVal), 'FontSize', 11, 'Interpreter', 'none');

        outPath = fullfile(condOutDir, sprintf('%s_preproc.png', baseName));
        exportgraphics(fig, outPath, 'Resolution', 120);
        close(fig);
    end
end

% ---------- Resumen ----------
fprintf('\n========== RESUMEN PREPROCESAMIENTO ==========\n');
fprintf('%-35s %-6s %8s %8s\n', 'Imagen', 'Cond.', 'PSNR(dB)', 'SSIM');
fprintf('%s\n', repmat('-', 1, 62));
for k = 1:numel(metrics)
    fprintf('%-35s %-6s %8.2f %8.3f\n', ...
        metrics(k).name, metrics(k).condition, metrics(k).psnr, metrics(k).ssim);
end
fprintf('\nTotal procesadas: %d imágenes\n', numel(metrics));
fprintf('Figuras guardadas en: %s\n', outDir);
