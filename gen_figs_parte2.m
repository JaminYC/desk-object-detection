%% GEN_FIGS_PARTE2  Genera figuras para el informe Parte 2 (deteccion).
%
%   Figura D: pipeline de deteccion paso a paso (5 subplots, imagen CSL)
%   Figuras E1-E5: panel 3 columnas por cada condicion (NL/CL/LL/RL/CSL)
%
%   Salida: results/figures/report/parte2/

clear; close all; clc;

projectRoot = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(projectRoot, 'src')));

outDir = fullfile(projectRoot, 'results', 'figures', 'report', 'parte2');
if ~exist(outDir, 'dir'), mkdir(outDir); end

dOpts = struct('cannyLow',0.05,'cannyHigh',0.20,'minArea',500, ...
               'maxArea',7500,'minAspect',0.5,'dilateR',5,'enhAlpha',0.5);

% ── Figura D: pipeline de deteccion paso a paso ───────────────────────────
fprintf('\n=== Figura D: detection_steps.png ===\n');
cslDir = fullfile(projectRoot, 'dataset', 'reference', 'CSL', 'Small');
files  = [dir(fullfile(cslDir,'*.jpg')); dir(fullfile(cslDir,'*.JPG'))];
raw    = imread(fullfile(files(1).folder, files(1).name));
if size(raw,3)==1, raw=cat(3,raw,raw,raw); end

[lightCond, pOpts] = classify_lighting(raw);
imgP = pipeline_preproc(raw, pOpts);

% Paso 2: Enhancement FFT
gray_enh = img_enhancement(im2uint8(imgP), dOpts.enhAlpha);
gray_enh = max(0, min(1, gray_enh));

% Paso 3: Canny
edges = edge(gray_enh, 'canny', [dOpts.cannyLow, dOpts.cannyHigh]);

% Paso 4: Morfologia
filled = imclose(edges, strel('disk', dOpts.dilateR));
filled = imfill(filled, 'holes');
filled = imclearborder(filled);

% Paso 5: Detecciones
bboxes = get_bboxes(imgP, dOpts);

fig = figure('Visible','off','Position',[50 50 1600 360]);

subplot(1,5,1); imshow(imgP);
title('1. Preprocesada','FontSize',10,'FontWeight','bold');

subplot(1,5,2); imshow(gray_enh,[]);
title('2. Enhancement FFT','FontSize',10,'FontWeight','bold');

subplot(1,5,3); imshow(edges);
title('3. Bordes Canny','FontSize',10,'FontWeight','bold');

subplot(1,5,4); imshow(filled);
title('4. Morfología','FontSize',10,'FontWeight','bold');

subplot(1,5,5);
imshow(imgP); hold on;
clrs = lines(max(size(bboxes,1),1));
for k = 1:size(bboxes,1)
    bb = bboxes(k,:);
    rectangle('Position',bb,'EdgeColor',clrs(k,:),'LineWidth',2);
end
hold off;
title(sprintf('5. Detecciones: %d',size(bboxes,1)),'FontSize',10,'FontWeight','bold');

sgtitle(sprintf('Pipeline de detección — condición %s', lightCond), ...
    'FontSize',13,'FontWeight','bold');
exportgraphics(fig, fullfile(outDir,'detection_steps.png'),'Resolution',150);
close(fig);
fprintf('[OK] detection_steps.png  (%d objetos)\n', size(bboxes,1));

% ── Figuras E1-E5: resultados por condicion ───────────────────────────────
conditions = {'NL','CL','LL','RL','CSL'};

for c = 1:numel(conditions)
    condCode = conditions{c};
    fprintf('\n=== Figura E_%s ===\n', condCode);

    smallDir = fullfile(projectRoot,'dataset','reference',condCode,'Small');
    ogDir    = fullfile(projectRoot,'dataset','reference',condCode,'OG');
    ogDir2   = fullfile(projectRoot,'dataset','reference',condCode,'Og');

    if     exist(smallDir,'dir'), searchDir = smallDir;
    elseif exist(ogDir,   'dir'), searchDir = ogDir;
    elseif exist(ogDir2,  'dir'), searchDir = ogDir2;
    else, fprintf('[!] Sin carpeta para %s\n',condCode); continue
    end

    files = [dir(fullfile(searchDir,'*.jpg')); dir(fullfile(searchDir,'*.JPG'))];
    if isempty(files), fprintf('[!] Sin imagenes en %s\n',searchDir); continue; end

    raw = imread(fullfile(files(1).folder, files(1).name));
    if size(raw,3)==1, raw=cat(3,raw,raw,raw); end

    tic;
    [bboxes, detCond, imgProc] = detect_objects(raw, dOpts);
    t = toc;
    fprintf('  cond detectada: %s | %d objetos | %.2fs\n', detCond, size(bboxes,1), t);

    fig = figure('Visible','off','Position',[50 50 1400 480]);

    subplot(1,3,1); imshow(raw);
    title('Original','FontSize',12);

    subplot(1,3,2); imshow(imgProc);
    title(sprintf('Preprocesada  [cond: %s]', detCond),'FontSize',12);

    subplot(1,3,3);
    imshow(imgProc); hold on;
    clrs = lines(max(size(bboxes,1),1));
    for k = 1:size(bboxes,1)
        bb = bboxes(k,:);
        rectangle('Position',bb,'EdgeColor',clrs(k,:),'LineWidth',2);
        text(bb(1)+3, bb(2)+14, sprintf('#%d',k), ...
            'Color','yellow','FontSize',9,'FontWeight','bold');
    end
    hold off;
    title(sprintf('Detecciones: %d',size(bboxes,1)),'FontSize',12);

    match = '';
    if ~strcmp(condCode, detCond), match = sprintf('  [clasificó como %s]', detCond); end
    sgtitle(sprintf('Condición %s%s  |  %d objetos  |  %.2f s', ...
        condCode, match, size(bboxes,1), t), ...
        'FontSize',11,'FontWeight','bold','Interpreter','none');

    exportgraphics(fig, fullfile(outDir, sprintf('results_%s.png',condCode)), ...
        'Resolution',150);
    close(fig);
    fprintf('  [OK] results_%s.png\n', condCode);
end

fprintf('\nFiguras Parte 2 en: %s\n', outDir);
