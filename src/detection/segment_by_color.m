function mask = segment_by_color(img, lightCond)
% SEGMENT_BY_COLOR  Mascara HSV de objetos de escritorio.
%   La mascara NO restringe Canny — se usa DESPUES para filtrar regiones
%   detectadas por solapamiento. Solo captura colores claramente de objetos.
%
%   Objetos cubiertos (segun fotos reales del dataset):
%     - Lapiz grafito: muy oscuro
%     - Lapicero azul / rojo / negro
%     - Post-it amarillo
%     - Borrador verde / rosa
%     - Plumones (colores saturados variados)

    if isa(img, 'uint8'), img = im2double(img); end

    hsv = rgb2hsv(img);
    H = hsv(:,:,1);
    S = hsv(:,:,2);
    V = hsv(:,:,3);

    % Umbral de saturacion segun condicion de iluminacion
    switch lightCond
        case {'LL','CSL'}, satMin = 0.12;
        otherwise,         satMin = 0.18;
    end

    % ── Objetos de escritorio ─────────────────────────────────────────────
    % Lapiz / grafito: muy oscuro, casi sin color
    pencil      = V < 0.28 & S < 0.22;

    % Lapicero / cuerpo plastico oscuro o negro
    pen_dark    = V < 0.20;

    % Lapicero azul (H 0.55-0.72)
    pen_blue    = H >= 0.55 & H <= 0.72 & S >= satMin;

    % Lapicero rojo (H 0.94-1.0 o 0.0-0.05)
    pen_red     = (H >= 0.94 | H <= 0.05) & S >= satMin;

    % Post-it amarillo (H 0.10-0.18, S alta)
    yellow_note = H >= 0.10 & H <= 0.18 & S >= 0.40 & V >= 0.55;

    % Borrador / regla verde (H 0.25-0.42)
    green_obj   = H >= 0.25 & H <= 0.42 & S >= 0.22 & V >= 0.20;

    % Borrador rosa / salmon (H 0.84-0.99, S moderada)
    eraser_pink = H >= 0.84 & H <= 0.99 & S >= 0.18 & S <= 0.60 & V >= 0.45;

    % Plumones: cualquier color saturado
    marker      = S >= 0.45 & V >= 0.20 & V <= 0.90;

    objects = pencil | pen_dark | pen_blue | pen_red | ...
              yellow_note | green_obj | eraser_pink | marker;

    % ── Fondo a excluir ───────────────────────────────────────────────────
    % Escritorio de madera oscura (cafe/marron oscuro o claro)
    wood    = H >= 0.03 & H <= 0.13 & S >= 0.05 & S <= 0.55 ...
            & V >= 0.08 & V <= 0.80;

    % Papel / fondo blanco (V muy alto, S casi cero)
    white   = V > 0.90 & S < 0.08;

    % Superficie gris neutra muy desaturada
    neutral = S < 0.08 & V > 0.20 & V < 0.88;

    mask = objects & ~wood & ~white & ~neutral;

    % ── Limpieza morfologica ──────────────────────────────────────────────
    mask = imopen (mask, strel('disk', 2));
    mask = imclose(mask, strel('disk', 6));
    mask = imfill (mask, 'holes');
    mask = bwareaopen(mask, 500);

    pct = 100 * mean(mask(:));
    fprintf('[segment] pixeles objeto: %.1f%%\n', pct);
end
