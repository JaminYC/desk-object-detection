function mask = segment_by_color(img, lightCond)
% SEGMENT_BY_COLOR  Mascara HSV de objetos de escritorio.
%   Cubre: lapiz (gris oscuro), lapicero (azul/negro/rojo),
%          borrador rosa, plumones (colores saturados).
%   El objetivo es reducir la region de busqueda de Canny, no capturar
%   absolutamente todos los pixeles — mejor ser conservador.

    if isa(img, 'uint8'), img = im2double(img); end

    hsv = rgb2hsv(img);
    H = hsv(:,:,1);
    S = hsv(:,:,2);
    V = hsv(:,:,3);

    % Umbral de saturacion minima segun condicion
    switch lightCond
        case {'LL','CSL'}, satMin = 0.10;
        otherwise,         satMin = 0.15;
    end

    % ── Objetos especificos ───────────────────────────────────────────────
    % Lapiz / grafito: muy oscuro, baja saturacion (grafito gris oscuro)
    pencil      = V < 0.30 & S < 0.20;

    % Lapicero azul (H 0.55-0.72, moderada-alta S)
    pen_blue    = H >= 0.55 & H <= 0.72 & S >= satMin & S >= 0.20;

    % Lapicero rojo / naranja (H cerca de 0 o 1)
    pen_red     = (H >= 0.94 | H <= 0.05) & S >= satMin & S >= 0.25;

    % Cuerpo oscuro metalico / plastico negro
    pen_dark    = V < 0.22;

    % Plumones: saturacion alta (colores brillantes)
    marker      = S >= 0.45 & V >= 0.20 & V <= 0.90;

    % Borrador rosa (H 0.84-0.99, saturacion moderada)
    eraser_pink = H >= 0.84 & H <= 0.99 & S >= 0.18 & S <= 0.60 & V >= 0.50;

    objects = pencil | pen_blue | pen_red | pen_dark | marker | eraser_pink;

    % ── Fondo a excluir ───────────────────────────────────────────────────
    % Madera / escritorio (cafe, marron)
    wood    = H >= 0.03 & H <= 0.14 & S >= 0.06 & S <= 0.60 ...
            & V >= 0.15 & V <= 0.82;

    % Papel blanco / pared (muy alto V, baja S)
    white   = V > 0.88 & S < 0.10;

    % Zonas grises neutras (cuadernos, fondo uniforme)
    neutral = S < 0.10 & V > 0.25 & V < 0.90;

    % Piel humana (por si hay manos en la foto: H amarillo-naranja)
    skin    = H >= 0.02 & H <= 0.10 & S >= 0.15 & S <= 0.55 & V >= 0.50;

    mask = objects & ~wood & ~white & ~neutral & ~skin;

    % ── Limpieza morfologica ──────────────────────────────────────────────
    mask = imopen (mask, strel('disk', 2));
    mask = imclose(mask, strel('disk', 5));
    mask = imfill (mask, 'holes');
    mask = bwareaopen(mask, 600);

    pct = 100 * mean(mask(:));
    fprintf('[segment] pixeles objeto: %.1f%%\n', pct);

    % Si la mascara es demasiado agresiva (>50%) es senal de mal umbral
    if pct > 50
        fprintf('[segment] AVISO: mascara muy amplia (%.1f%%), usando imagen completa\n', pct);
        mask = true(size(mask));
    end
end
