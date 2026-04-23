function visualize_detections(img, bboxes, title_str)
% VISUALIZE_DETECTIONS  Dibuja bounding boxes sobre la imagen.
%
%   visualize_detections(img, bboxes, title_str)
%
%   Entradas:
%       img       : HxWx3 imagen (double [0,1] o uint8)
%       bboxes    : Nx4 [x, y, w, h]
%       title_str : string para el título de la figura

    imshow(img);
    hold on;
    for k = 1:size(bboxes, 1)
        bb = bboxes(k, :);
        rectangle('Position', bb, 'EdgeColor', 'r', 'LineWidth', 2);
        text(bb(1)+4, bb(2)-6, sprintf('#%d', k), ...
            'Color', 'yellow', 'FontSize', 10, 'FontWeight', 'bold');
    end
    hold off;
    if nargin >= 3
        title(title_str, 'FontSize', 12, 'Interpreter', 'none');
    end
end
