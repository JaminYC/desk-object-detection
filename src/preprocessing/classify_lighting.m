function [lightCond, opts] = classify_lighting(img)
% CLASSIFY_LIGHTING  Estima condición de iluminación y retorna opts adaptativos.
%
%   Analiza tres features:
%     - meanL  : brillo medio (canal L de Lab, normalizado [0,1])
%     - stdL   : contraste (desviación estándar de L)
%     - rb     : temperatura de color (ratio R/B; >1.2 = tinte cálido)
%
%   Clasifica en: 'NL' | 'CL' | 'LL' | 'CSL' | 'RL'
%   y retorna opts optimizados para pipeline_preproc.

    if isa(img, 'uint8'), img = im2double(img); end

    % ── Features ──────────────────────────────────────────────────────────
    lab   = rgb2lab(img);
    L     = lab(:,:,1) / 100;
    meanL = mean(L(:));
    stdL  = std(L(:));
    rb    = mean(img(:,:,1), 'all') / max(mean(img(:,:,3), 'all'), eps);

    % ── Clasificación (umbrales calibrados con dataset real) ─────────────
    %   Valores medidos en fotos Small del equipo:
    %     NL:  meanL~0.43  stdL~0.20  R/B~1.09
    %     CL:  meanL~0.39  stdL~0.18  R/B~1.26
    %     LL:  meanL~0.41  stdL~0.21  R/B~1.07
    %     RL:  meanL~0.35  stdL~0.20  R/B~1.34
    %     CSL: meanL~0.45  stdL~0.16  R/B~1.13
    %
    %   Separadores clave: R/B distingue RL/CL; stdL distingue CSL;
    %   meanL separa NL/LL (LL ligeramente mas oscuro que NL).
    if rb > 1.28
        lightCond = 'RL';    % tinte calido fuerte (luz natural tardia/cortina)
    elseif rb > 1.18
        lightCond = 'CL';    % tinte calido moderado (fluorescente de techo)
    elseif stdL < 0.17
        lightCond = 'CSL';   % contraste bajo uniforme (sombras con cortina)
    elseif meanL >= 0.42
        lightCond = 'NL';    % brillante neutro
    else
        lightCond = 'LL';    % neutro ligeramente oscuro (lampara de escritorio)
    end

    fprintf('[classify] meanL=%.2f  stdL=%.2f  R/B=%.2f  → %s\n', ...
        meanL, stdL, rb, lightCond);

    % ── Opts adaptativos ──────────────────────────────────────────────────
    opts = struct();
    switch lightCond
        case 'NL'
            opts.bilateralGS      = 10;
            opts.bilateralSpatial = 4;
            opts.claheClipLimit   = 0.003;
            opts.sharpenAlpha     = 0.25;
        case 'CL'
            opts.bilateralGS      = 12;
            opts.bilateralSpatial = 5;
            opts.claheClipLimit   = 0.005;
            opts.sharpenAlpha     = 0.30;
        case 'LL'
            opts.bilateralGS      = 20;
            opts.bilateralSpatial = 7;
            opts.claheClipLimit   = 0.012;
            opts.sharpenAlpha     = 0.40;
        case 'CSL'
            opts.bilateralGS      = 18;
            opts.bilateralSpatial = 6;
            opts.claheClipLimit   = 0.015;
            opts.sharpenAlpha     = 0.35;
        case 'RL'
            opts.bilateralGS      = 12;
            opts.bilateralSpatial = 5;
            opts.claheClipLimit   = 0.007;
            opts.sharpenAlpha     = 0.28;
    end
end
