%% TEST_DETECTION — Prueba pipeline completo: preprocesamiento + detección
% Corre sobre todas las imágenes de dataset/reference/ y genera figuras
% con bounding boxes detectados. Guarda resultados en results/figures/deteccion/
%
% CÓMO CORRER:
%   1. Abre MATLAB
%   2. Navega a la carpeta desk-object-detection/
%   3. Ejecuta: test_detection

clear; close all; clc;

projectRoot = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(projectRoot, 'src')));

refDir = fullfile(projectRoot, 'dataset', 'reference');
outDir = fullfile(projectRoot, 'results', 'figures', 'deteccion');
if ~exist(outDir, 'dir'), mkdir(outDir); end

% Recopilar imágenes
exts  = {'*.jpg','*.jpeg','*.png','*.JPG'};
files = [];
for e = 1:numel(exts)
    files = [files; dir(fullfile(refDir, exts{e}))]; %#ok<AGROW>
end

if isempty(files)
    error('No hay imágenes en dataset/reference/');
end
fprintf('[test] %d imágenes encontradas\n\n', numel(files));

% Opciones de detección (ajustables)
detectOpts.cannyLow  = 0.05;
detectOpts.cannyHigh = 0.20;
detectOpts.minArea   = 1500;
detectOpts.maxArea   = 200000;
detectOpts.minAspect = 1.5;
detectOpts.dilateR   = 5;

results = struct('name', {}, 'n_detected', {});

for k = 1:numel(files)
    filePath = fullfile(files(k).folder, files(k).name);
    [~, baseName, ~] = fileparts(files(k).name);

    fprintf('--- (%d/%d) %s ---\n', k, numel(files), files(k).name);

    % Leer y normalizar
    raw = imread(filePath);
    if size(raw, 3) == 1
        raw = cat(3, raw, raw, raw);
    end
    if ~isa(raw, 'uint8')
        raw = uint8(raw * 255);
    end

    % Preprocesamiento
    fprintf('[preproc] procesando...\n');
    imgP = pipeline_preproc(raw);

    % Detección
    bboxes = get_bboxes(imgP, detectOpts);
    nDet   = size(bboxes, 1);
    results(end+1) = struct('name', baseName, 'n_detected', nDet); %#ok<SAGROW>

    % Figura: 3 paneles — original | preprocesada | detecciones
    fig = figure('Visible', 'off', 'Position', [50 50 1800 550]);

    subplot(1,3,1);
    imshow(raw);
    title('Original', 'FontSize', 12);

    subplot(1,3,2);
    imshow(imgP);
    title('Preprocesada', 'FontSize', 12);

    subplot(1,3,3);
    visualize_detections(imgP, bboxes, ...
        sprintf('Detecciones: %d objeto(s)', nDet));

    sgtitle(baseName, 'FontSize', 11, 'Interpreter', 'none');

    outPath = fullfile(outDir, sprintf('%s_deteccion.png', baseName));
    exportgraphics(fig, outPath, 'Resolution', 120);
    close(fig);

    fprintf('[test] guardado: %s\n\n', outPath);
end

% Resumen
fprintf('\n========== RESUMEN ==========\n');
fprintf('%-40s  %s\n', 'Imagen', 'Objetos detectados');
fprintf('%s\n', repmat('-', 1, 55));
for k = 1:numel(results)
    fprintf('%-40s  %d\n', results(k).name, results(k).n_detected);
end
fprintf('\nFiguras guardadas en: %s\n', outDir);
fprintf('Abre esa carpeta en el explorador para ver los resultados.\n');
