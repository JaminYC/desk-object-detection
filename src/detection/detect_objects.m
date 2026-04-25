function [bboxes, lightCond, imgProc] = detect_objects(imgIn, detectOpts)
% DETECT_OBJECTS  Pipeline completo: clasifica iluminacion -> preproc -> deteccion
%
%   classify_lighting -> pipeline_preproc -> get_bboxes (img_enhancement + Canny)
%
%   Entradas:
%       imgIn      : HxWx3 uint8 o double (RGB)
%       detectOpts : struct opcional para get_bboxes
%
%   Salidas:
%       bboxes    : Nx4 [x y w h]
%       lightCond : 'NL'|'CL'|'LL'|'CSL'|'RL'
%       imgProc   : imagen preprocesada double [0,1]

    if nargin < 2, detectOpts = struct(); end

    [lightCond, preprocOpts] = classify_lighting(imgIn);
    imgProc = pipeline_preproc(imgIn, preprocOpts);
    bboxes  = get_bboxes(imgProc, detectOpts);
end
