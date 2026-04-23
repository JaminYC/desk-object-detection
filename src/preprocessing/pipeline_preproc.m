function imgOut = pipeline_preproc(imgIn, opts)
% PIPELINE_PREPROC  Preprocesamiento automático de imágenes de escritorio.
%
%   imgOut = PIPELINE_PREPROC(imgIn) aplica el pipeline de preprocesamiento
%   completo a una imagen RGB de entrada.
%
%   imgOut = PIPELINE_PREPROC(imgIn, opts) permite sobrescribir parámetros.
%
%   Entradas:
%       imgIn : matriz HxWx3 uint8 o double (RGB)
%       opts  : struct opcional con campos:
%           .gaussianSigma   (default: 0.8)  — sigma para denoising suave
%           .medianSize      (default: [3 3]) — kernel de mediana
%           .claheClipLimit  (default: 0.005) — limit para CLAHE
%           .claheTiles      (default: [8 8]) — grid de tiles CLAHE
%           .whiteBalance    (default: true)  — aplicar gray-world WB
%
%   Salida:
%       imgOut : matriz HxWx3 double en rango [0, 1]
%
%   Ejemplo:
%       img = imread('dataset/raw/mixed/desk_001.jpg');
%       out = pipeline_preproc(img);
%       imshowpair(img, out, 'montage');
%
%   Justificación de cada paso: ver sección 2 del informe.

    % ---------- Defaults ----------
    if nargin < 2 || isempty(opts)
        opts = struct();
    end
    defaults = struct( ...
        'gaussianSigma',  0.8, ...
        'medianSize',     [3 3], ...
        'claheClipLimit', 0.005, ...
        'claheTiles',     [8 8], ...
        'whiteBalance',   true ...
    );
    opts = merge_opts(defaults, opts);

    % ---------- 1. Normalización a double [0, 1] ----------
    if isa(imgIn, 'uint8')
        img = im2double(imgIn);
    else
        img = imgIn;
    end
    fprintf('[preproc] Input: %dx%dx%d, range [%.3f, %.3f]\n', ...
        size(img,1), size(img,2), size(img,3), min(img(:)), max(img(:)));

    % ---------- 2. Denoise — mediana en cada canal (robusto contra sal/pimienta) ----------
    img = cat(3, ...
        medfilt2(img(:,:,1), opts.medianSize), ...
        medfilt2(img(:,:,2), opts.medianSize), ...
        medfilt2(img(:,:,3), opts.medianSize));

    % ---------- 3. Denoise suave — Gaussian (residual de ruido gaussiano) ----------
    img = imgaussfilt(img, opts.gaussianSigma);

    % ---------- 4. White balance gray-world (robustece contra tintes de iluminación) ----------
    if opts.whiteBalance
        img = gray_world_wb(img);
    end

    % ---------- 5. Normalización de iluminación — CLAHE en canal L de Lab ----------
    lab = rgb2lab(img);
    L = lab(:,:,1) / 100;   % Lab.L está en [0, 100], adaptamos a [0, 1]
    L = adapthisteq(L, ...
        'ClipLimit',   opts.claheClipLimit, ...
        'NumTiles',    opts.claheTiles, ...
        'Distribution','uniform');
    lab(:,:,1) = L * 100;
    img = lab2rgb(lab);

    % Clamp por seguridad
    img = max(0, min(1, img));

    imgOut = img;
    fprintf('[preproc] Output: range [%.3f, %.3f]\n', min(imgOut(:)), max(imgOut(:)));
end


% ============================================================
% Helpers
% ============================================================

function out = gray_world_wb(img)
%GRAY_WORLD_WB  Balance de blancos por asunción de mundo gris.
%   Asume que el promedio de color de la escena debería ser gris neutro.
    r = img(:,:,1); g = img(:,:,2); b = img(:,:,3);
    meanR = mean(r(:)); meanG = mean(g(:)); meanB = mean(b(:));
    meanAll = (meanR + meanG + meanB) / 3;
    r = r * (meanAll / max(meanR, eps));
    g = g * (meanAll / max(meanG, eps));
    b = b * (meanAll / max(meanB, eps));
    out = cat(3, r, g, b);
    out = max(0, min(1, out));
end


function merged = merge_opts(defaults, user)
%MERGE_OPTS  Sobreescribe defaults con campos provistos por el usuario.
    merged = defaults;
    fields = fieldnames(user);
    for k = 1:numel(fields)
        merged.(fields{k}) = user.(fields{k});
    end
end
