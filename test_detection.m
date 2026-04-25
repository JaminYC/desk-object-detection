%% TEST_DETECTION  Pipeline: classify_lighting -> preproc -> img_enhancement -> Canny
%
%   Por cada condicion procesa 3 imagenes Small y genera figuras de 3 paneles:
%     Original | Preprocesada | Detecciones (bboxes)
%
%   CORRER: cd a desk-object-detection/ y ejecutar test_detection

clear; close all; clc;

projectRoot = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(projectRoot, 'src')));

refDir = fullfile(projectRoot, 'dataset', 'reference');
outDir = fullfile(projectRoot, 'results', 'figures', 'deteccion');
if ~exist(outDir, 'dir'), mkdir(outDir); end

conditions = {'NL','CL','LL','RL','CSL'};
MAX_PER_COND = 3;

results = struct('name',{}, 'condition',{}, 'lightDetected',{}, 'n_bboxes',{});

for c = 1:numel(conditions)
    condCode = conditions{c};

    smallDir = fullfile(refDir, condCode, 'Small');
    ogDir    = fullfile(refDir, condCode, 'OG');
    ogDir2   = fullfile(refDir, condCode, 'Og');

    if     exist(smallDir, 'dir'), searchDir = smallDir;
    elseif exist(ogDir,    'dir'), searchDir = ogDir;
    elseif exist(ogDir2,   'dir'), searchDir = ogDir2;
    else,  fprintf('[test] Carpeta %s no encontrada.\n', condCode); continue
    end

    files = [dir(fullfile(searchDir,'*.jpg')); dir(fullfile(searchDir,'*.JPG'))];
    if isempty(files), fprintf('[test] Sin imagenes en %s\n', searchDir); continue; end

    nUse = min(MAX_PER_COND, numel(files));
    condOutDir = fullfile(outDir, condCode);
    if ~exist(condOutDir, 'dir'), mkdir(condOutDir); end

    fprintf('\n[test] === %s: %d imagenes ===\n', condCode, nUse);

    for k = 1:nUse
        filePath = fullfile(files(k).folder, files(k).name);
        [~, baseName] = fileparts(files(k).name);

        raw = imread(filePath);
        if size(raw,3) == 1, raw = cat(3,raw,raw,raw); end

        fprintf('[test] (%d/%d) %s\n', k, nUse, files(k).name);
        tic;
        [bboxes, lightCond, imgProc] = detect_objects(raw);
        t = toc;
        fprintf('[test] %.2fs | cond: %s | %d bbox(es)\n', t, lightCond, size(bboxes,1));

        results(end+1) = struct('name', baseName, 'condition', condCode, ...
            'lightDetected', lightCond, 'n_bboxes', size(bboxes,1)); %#ok<SAGROW>

        fig = figure('Visible','off','Position',[50 50 1400 480]);

        subplot(1,3,1); imshow(raw);
        title('Original','FontSize',11);

        subplot(1,3,2); imshow(imgProc);
        title(sprintf('Preprocesada [%s]', lightCond),'FontSize',11);

        subplot(1,3,3);
        visualize_detections(imgProc, bboxes, sprintf('Detecciones: %d', size(bboxes,1)));

        sgtitle(sprintf('[%s] %s', condCode, baseName),'FontSize',10,'Interpreter','none');

        outPath = fullfile(condOutDir, sprintf('%s_det.png', baseName));
        exportgraphics(fig, outPath, 'Resolution', 120);
        close(fig);
    end
end

fprintf('\n========== RESUMEN ==========\n');
fprintf('%-32s %-6s %-6s %s\n', 'Imagen', 'Real', 'Det.', 'Bboxes');
fprintf('%s\n', repmat('-',1,52));
for k = 1:numel(results)
    flag = '';
    if ~strcmp(results(k).condition, results(k).lightDetected), flag = ' <-'; end
    fprintf('%-32s %-6s %-6s %d%s\n', results(k).name, ...
        results(k).condition, results(k).lightDetected, results(k).n_bboxes, flag);
end
fprintf('\nFiguras en: %s\n', outDir);
