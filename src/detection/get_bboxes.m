function bboxes = get_bboxes(imgPreproc, opts)
% GET_BBOXES  Detecta objetos en imagen preprocesada y retorna bounding boxes.
%
%   bboxes = GET_BBOXES(imgPreproc) detecta objetos elongados sobre fondo
%   uniforme (lápices, lapiceros, borradores, plumones) usando bordes Canny
%   + morfología + regionprops.
%
%   Entradas:
%       imgPreproc : HxWx3 double [0,1] — imagen preprocesada (de pipeline_preproc)
%       opts       : struct opcional con campos:
%           .cannyLow     (default: 0.05)  — umbral bajo Canny
%           .cannyHigh    (default: 0.20)  — umbral alto Canny
%           .minArea      (default: 1500)  — área mínima de región (px)
%           .maxArea      (default: 150000)— área máxima de región (px)
%           .minAspect    (default: 1.5)   — aspect ratio mínimo (largo/ancho)
%           .dilateR      (default: 4)     — radio de dilatación morfológica
%
%   Salida:
%       bboxes : Nx4 double [x, y, w, h] en píxeles (formato regionprops)

    if nargin < 2 || isempty(opts), opts = struct(); end
    defaults = struct( ...
        'cannyLow',  0.05, ...
        'cannyHigh', 0.20, ...
        'minArea',   1500, ...
        'maxArea',   150000, ...
        'minAspect', 1.5, ...
        'dilateR',   4 ...
    );
    opts = merge_opts(defaults, opts);

    % 1. Escala de grises
    gray = rgb2gray(imgPreproc);

    % 2. Bordes Canny
    edges = edge(gray, 'canny', [opts.cannyLow, opts.cannyHigh]);

    % 3. Morfología — cierra bordes abiertos, une fragmentos cercanos
    se_close = strel('disk', opts.dilateR);
    filled   = imclose(edges, se_close);
    filled   = imfill(filled, 'holes');

    % 4. Eliminar borde de imagen (artefactos de borde)
    filled = imclearborder(filled);

    % 5. Regiones conectadas y filtro por área y aspecto
    props = regionprops(filled, 'BoundingBox', 'Area', 'Extent');

    bboxes = [];
    for k = 1:numel(props)
        a   = props(k).Area;
        bb  = props(k).BoundingBox;   % [x, y, w, h]
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
