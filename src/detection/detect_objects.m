function [bboxes, lightCond, imgProc, colorMask] = detect_objects(imgIn, detectOpts)
% DETECT_OBJECTS  Pipeline completo de visión:
%   classify_lighting → pipeline_preproc → segment_by_color → get_bboxes
%
%   Entradas:
%       imgIn      : HxWx3 uint8 o double (RGB)
%       detectOpts : struct opcional para get_bboxes
%
%   Salidas:
%       bboxes    : Nx4 [x y w h]
%       lightCond : condición detectada ('NL'|'CL'|'LL'|'CSL'|'RL')
%       imgProc   : imagen preprocesada double [0,1]
%       colorMask : máscara binaria de segmentación por color

    if nargin < 2, detectOpts = struct(); end

    % 1. Clasifica iluminación → opts adaptativos para preproc
    [lightCond, preprocOpts] = classify_lighting(imgIn);

    % 2. Preprocesamiento con parámetros ajustados a la condición
    imgProc = pipeline_preproc(imgIn, preprocOpts);

    % 3. Segmentación por color → máscara de regiones con objetos
    colorMask = segment_by_color(imgProc, lightCond);

    % 4. Detección Canny restringida a la máscara
    bboxes = get_bboxes(imgProc, detectOpts, colorMask);
end
