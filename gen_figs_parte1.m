%% GEN_FIGS_PARTE1  Genera figuras para el informe Parte 1 (preprocesamiento).
%
%   Figura A: montage de 5 pasos del pipeline (por imagen)
%   Figura B: antes/despues con PSNR y SSIM (por imagen)
%
%   Imagenes fuente: NL/Small (bien iluminada) y CSL/Small (iluminacion combinada)
%   Salida:  results/figures/report/parte1/

clear; close all; clc;

projectRoot = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(projectRoot, 'src')));

outDir = fullfile(projectRoot, 'results', 'figures', 'report', 'parte1');
if ~exist(outDir, 'dir'), mkdir(outDir); end

casos = {
    'NL',  fullfile(projectRoot, 'dataset', 'reference', 'NL',  'Small');
    'CSL', fullfile(projectRoot, 'dataset', 'reference', 'CSL', 'Small');
};

for i = 1:size(casos, 1)
    condCode = casos{i,1};
    imgDir   = casos{i,2};

    files = [dir(fullfile(imgDir,'*.jpg')); dir(fullfile(imgDir,'*.JPG'))];
    if isempty(files)
        fprintf('[!] Sin imagenes en %s\n', imgDir); continue
    end

    raw = imread(fullfile(files(1).folder, files(1).name));
    if size(raw,3)==1, raw = cat(3,raw,raw,raw); end
    fprintf('\n[%s] %s\n', condCode, files(1).name);

    % ── Pasos del pipeline (replicados para capturar intermedios) ─────────
    img = im2double(raw);
    img = max(0, min(1, img));
    step1 = img;                                          % 1. Original

    img_u8 = f_bilateral(im2uint8(img), 15, 5);          % 2. Bilateral (defaults)
    step2  = max(0, min(1, im2double(img_u8)));

    step3  = gray_world_wb(step2);                        % 3. White Balance

    lab = rgb2lab(step3);                                 % 4. CLAHE
    L   = adapthisteq(lab(:,:,1)/100, 'ClipLimit', 0.005, ...
            'NumTiles', [8 8], 'Distribution', 'uniform');
    lab(:,:,1) = L * 100;
    step4 = max(0, min(1, lab2rgb(lab)));

    lap   = f_laplaciano(step4, 0.2);                    % 5. Laplaciano
    step5 = max(0, min(1, step4 - 0.3 * lap));

    % ── Figura A: 5 imagenes separadas (una por paso) ────────────────────
    pasos  = {step1, step2, step3, step4, step5};
    labels = {'1_original','2_bilateral','3_whitebalance','4_clahe','5_laplaciano'};
    titulos = {'Paso 1: Original', 'Paso 2: Filtro Bilateral (preserva bordes)', ...
               'Paso 3: White Balance (gray-world)', ...
               'Paso 4: CLAHE sobre canal L', 'Paso 5: Realce Laplaciano'};
    for k = 1:5
        fig = figure('Visible','off','Position',[50 50 900 480]);
        imshow(pasos{k});
        title(titulos{k}, 'FontSize',12, 'FontWeight','bold');
        exportgraphics(fig, fullfile(outDir, sprintf('step_%s_%s.png', labels{k}, condCode)), ...
            'Resolution', 150);
        close(fig);
        fprintf('  [OK] step_%s_%s.png\n', labels{k}, condCode);
    end

    % ── Figura B: antes/despues con metricas ─────────────────────────────
    psnr_val = psnr(step5, step1);
    ssim_val = ssim(step5, step1);

    fig = figure('Visible','off','Position',[50 50 1200 500]);
    subplot(1,2,1); imshow(step1); title('Original','FontSize',12);
    subplot(1,2,2); imshow(step5); title('Preprocesada','FontSize',12);
    sgtitle(sprintf('[%s]   PSNR = %.2f dB     SSIM = %.3f', condCode, psnr_val, ssim_val), ...
        'FontSize',13, 'FontWeight','bold');
    exportgraphics(fig, fullfile(outDir, sprintf('before_after_%s.png', condCode)), ...
        'Resolution', 150);
    close(fig);
    fprintf('  [OK] before_after_%s.png  (PSNR=%.2f  SSIM=%.3f)\n', ...
        condCode, psnr_val, ssim_val);
end

fprintf('\nFiguras Parte 1 en: %s\n', outDir);


% ── Helper local ──────────────────────────────────────────────────────────
function out = gray_world_wb(img)
    r=img(:,:,1); g=img(:,:,2); b=img(:,:,3);
    m=(mean(r(:))+mean(g(:))+mean(b(:)))/3;
    out=max(0,min(1,cat(3, r*(m/max(mean(r(:)),eps)), ...
                           g*(m/max(mean(g(:)),eps)), ...
                           b*(m/max(mean(b(:)),eps)))));
end
