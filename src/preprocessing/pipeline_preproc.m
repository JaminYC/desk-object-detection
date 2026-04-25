function imgOut = pipeline_preproc(imgIn, opts)
% PIPELINE_PREPROC  Pipeline integrado de preprocesamiento para imágenes de escritorio.
%
%   Combina el enfoque del equipo (filtro bilateral + Laplaciano) con
%   normalización de iluminación (CLAHE) y balance de blancos (gray-world).
%
%   Pipeline completo (5 pasos):
%     1. Normalización   → double [0,1]
%     2. Bilateral       → denoising preservando bordes (Lab, edge-preserving)
%     3. White balance   → corrige tinte de color según condición de luz
%     4. CLAHE           → normaliza iluminación (útil en LL, RL, CSL)
%     5. Laplaciano      → realce de bordes para facilitar detección
%
%   Entradas:
%       imgIn : HxWx3 uint8 o double (RGB)
%       opts  : struct opcional:
%           .bilateralGS      (default: 15)    — sigma rango bilateral (Lab units)
%           .bilateralSpatial (default: 5)     — sigma espacial bilateral (px)
%           .whiteBalance     (default: true)  — gray-world WB
%           .claheClipLimit   (default: 0.005) — clip limit CLAHE
%           .claheTiles       (default: [8 8]) — tiles CLAHE
%           .sharpenAlpha     (default: 0.3)   — intensidad Laplaciano (0=off)
%
%   Salida:
%       imgOut : HxWx3 double [0,1]
%
%   Ejemplo:
%       img = imread('dataset/reference/NL/Small/Ft_01_NL (Small).jpg');
%       out = pipeline_preproc(img);
%       imshowpair(img, out, 'montage');

    if nargin < 2 || isempty(opts), opts = struct(); end
    defaults = struct( ...
        'bilateralGS',      15, ...
        'bilateralSpatial',  5, ...
        'whiteBalance',   true, ...
        'claheClipLimit', 0.005, ...
        'claheTiles',     [8 8], ...
        'sharpenAlpha',    0.3  ...
    );
    opts = merge_opts(defaults, opts);

    % ── 1. Normalización ──────────────────────────────────────────────────
    if isa(imgIn, 'uint8')
        img = im2double(imgIn);
    else
        img = double(imgIn);
        if max(img(:)) > 1, img = img / 255; end
    end
    img = max(0, min(1, img));
    fprintf('[preproc] 1/5 Input: %dx%dx%d\n', size(img,1), size(img,2), size(img,3));

    % ── 2. Bilateral (Lab) via f_bilateral del equipo ────────────────────
    % f_bilateral recibe uint8, trabaja en Lab con imbilatfilt, retorna uint8
    img_u8 = im2uint8(img);
    img_u8 = f_bilateral(img_u8, opts.bilateralGS, opts.bilateralSpatial);
    img    = im2double(img_u8);
    img    = max(0, min(1, img));
    fprintf('[preproc] 2/5 Bilateral OK (f_bilateral: GS=%d, spatial=%d)\n', ...
        opts.bilateralGS, opts.bilateralSpatial);

    % ── 3. White balance (gray-world) ─────────────────────────────────────
    % Corrige tinte de color: fundamental para CL (techo), LL (lámpara)
    if opts.whiteBalance
        img = gray_world_wb(img);
        fprintf('[preproc] 3/5 White balance OK\n');
    else
        fprintf('[preproc] 3/5 White balance OFF\n');
    end

    % ── 4. CLAHE en L de Lab ─────────────────────────────────────────────
    % Normaliza iluminación local: imprescindible para LL, RL, CSL
    lab = rgb2lab(img);
    L   = lab(:,:,1) / 100;
    L   = adapthisteq(L, ...
            'ClipLimit',    opts.claheClipLimit, ...
            'NumTiles',     opts.claheTiles, ...
            'Distribution', 'uniform');
    lab(:,:,1) = L * 100;
    img = lab2rgb(lab);
    img = max(0, min(1, img));
    fprintf('[preproc] 4/5 CLAHE OK\n');

    % ── 5. Realce Laplaciano via f_laplaciano del equipo ─────────────────
    % f_laplaciano(I, kernelAlpha) devuelve la respuesta del filtro Laplaciano.
    % Aplicamos sharpening: img_sharp = img - sharpenAlpha * laplaciano(img)
    if opts.sharpenAlpha > 0
        lap = f_laplaciano(img, 0.2);          % kernelAlpha=0.2 (forma del kernel)
        img = img - opts.sharpenAlpha * lap;   % sharpenAlpha controla intensidad
        img = max(0, min(1, img));
        fprintf('[preproc] 5/5 Laplaciano OK (f_laplaciano: kernelAlpha=0.2, sharpen=%.2f)\n', ...
            opts.sharpenAlpha);
    else
        fprintf('[preproc] 5/5 Laplaciano OFF\n');
    end

    imgOut = img;
    fprintf('[preproc] Output: range [%.3f, %.3f]\n', min(imgOut(:)), max(imgOut(:)));
end


% ═══════════════════════════════════════════════════════════════════════════
% Helpers locales
% ═══════════════════════════════════════════════════════════════════════════

function out = gray_world_wb(img)
% GRAY_WORLD_WB  Balance de blancos asunción mundo gris.
    r = img(:,:,1); g = img(:,:,2); b = img(:,:,3);
    meanR = mean(r(:)); meanG = mean(g(:)); meanB = mean(b(:));
    meanAll = (meanR + meanG + meanB) / 3;
    out = cat(3, ...
        r * (meanAll / max(meanR, eps)), ...
        g * (meanAll / max(meanG, eps)), ...
        b * (meanAll / max(meanB, eps)));
    out = max(0, min(1, out));
end

function merged = merge_opts(defaults, user)
% MERGE_OPTS  Combina struct de defaults con overrides del usuario.
    merged = defaults;
    fields = fieldnames(user);
    for k = 1:numel(fields)
        merged.(fields{k}) = user.(fields{k});
    end
end
