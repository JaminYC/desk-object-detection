function bboxes = get_bboxes(imgPreproc, opts, mask)
% GET_BBOXES  Detecta objetos y retorna bounding boxes.
%
%   Pipeline: Canny (imagen completa) -> morfologia -> imclearborder ->
%   filtro por solapamiento con mascara de color -> filtro area/aspecto.
%
%   Entradas:
%       imgPreproc : HxWx3 double [0,1]
%       opts       : struct opcional:
%           .cannyLow        (default: 0.04)   umbral bajo Canny
%           .cannyHigh       (default: 0.18)   umbral alto Canny
%           .minArea         (default: 1200)   area minima px
%           .maxArea         (default: 120000) area maxima px
%           .minAspect       (default: 1.2)    aspect ratio minimo
%           .dilateR         (default: 4)      radio cierre morfologico
%           .minMaskOverlap  (default: 0.12)   fraccion minima del bbox
%                             que debe solapar con mascara de color
%       mask : HxW logical opcional (de segment_by_color)
%              Si se omite se usa imagen completa sin filtro de color.
%
%   Salida:
%       bboxes : Nx4 [x y w h]

    if nargin < 2 || isempty(opts), opts = struct(); end
    if nargin < 3, mask = []; end
    defaults = struct( ...
        'cannyLow',       0.04, ...
        'cannyHigh',      0.18, ...
        'minArea',        1200, ...
        'maxArea',        120000, ...
        'minAspect',      1.2, ...
        'dilateR',        4, ...
        'minMaskOverlap', 0.12 ...
    );
    opts = merge_opts(defaults, opts);

    % 1. Escala de grises
    gray = rgb2gray(imgPreproc);

    % 2. Canny sobre imagen COMPLETA (sin enmascarar)
    %    Enmascarar antes crea bordes artificiales en la frontera de la
    %    mascara que Canny detecta como objetos falsos.
    edges = edge(gray, 'canny', [opts.cannyLow, opts.cannyHigh]);

    % 3. Morfologia: cierra bordes, rellena huecos
    se    = strel('disk', opts.dilateR);
    filled = imclose(edges, se);
    filled = imfill(filled, 'holes');
    filled = imclearborder(filled);

    % 4. Filtro por solapamiento con mascara de color
    %    Mantiene solo regiones cuyo interior solapa >= minMaskOverlap
    %    con los pixeles de objeto detectados por HSV.
    if ~isempty(mask) && any(mask(:))
        cc       = bwconncomp(filled);
        keep     = false(size(filled));
        for i = 1:cc.NumObjects
            idx     = cc.PixelIdxList{i};
            overlap = sum(mask(idx)) / numel(idx);
            if overlap >= opts.minMaskOverlap
                keep(idx) = true;
            end
        end
        filled = keep;
    end

    % 5. Filtro por area y aspect ratio
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
