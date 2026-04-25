function bboxes = get_bboxes(imgPreproc, opts)
% GET_BBOXES  Detecta objetos y retorna bounding boxes.
%
%   Pipeline: img_enhancement (FFT) -> Canny -> morfologia -> regionprops
%
%   Entradas:
%       imgPreproc : HxWx3 double [0,1] (salida de pipeline_preproc)
%       opts       : struct opcional:
%           .cannyLow   (default: 0.04)   umbral bajo Canny
%           .cannyHigh  (default: 0.18)   umbral alto Canny
%           .minArea    (default: 1200)   area minima px
%           .maxArea    (default: 120000) area maxima px
%           .minAspect  (default: 1.2)    aspect ratio minimo
%           .dilateR    (default: 4)      radio cierre morfologico
%           .enhAlpha   (default: 0.5)    alpha para img_enhancement
%
%   Salida:
%       bboxes : Nx4 [x y w h]

    if nargin < 2 || isempty(opts), opts = struct(); end
    defaults = struct( ...
        'cannyLow',   0.05, ...
        'cannyHigh',  0.20, ...
        'minArea',    500, ...
        'maxArea',    7500, ...
        'minAspect',  0.5, ...
        'dilateR',    5, ...
        'enhAlpha',   0.5 ...
    );
    opts = merge_opts(defaults, opts);

    % 1. Realce de bordes con img_enhancement del equipo (Laplaciano FFT)
    gray = img_enhancement(im2uint8(imgPreproc), opts.enhAlpha);
    gray = max(0, min(1, gray));

    % 2. Canny
    edges = edge(gray, 'canny', [opts.cannyLow, opts.cannyHigh]);

    % 3. Morfologia: cierra bordes, rellena huecos
    filled = imclose(edges, strel('disk', opts.dilateR));
    filled = imfill(filled, 'holes');
    filled = imclearborder(filled);

    % 4. Filtro por area y aspect ratio
    props  = regionprops(filled, 'BoundingBox', 'Area');
    bboxes = [];
    for k = 1:numel(props)
        a   = props(k).Area;
        bb  = props(k).BoundingBox;
        asp = max(bb(3), bb(4)) / (min(bb(3), bb(4)) + eps);
        if a >= opts.minArea && a <= opts.maxArea && asp >= opts.minAspect
            bboxes = [bboxes; bb]; %#ok<AGROW>
        end
    end

    fprintf('[detect] %d objeto(s) encontrado(s)\n', size(bboxes, 1));
end


function merged = merge_opts(defaults, user)
    merged = defaults;
    fields = fieldnames(user);
    for k = 1:numel(fields)
        merged.(fields{k}) = user.(fields{k});
    end
end
