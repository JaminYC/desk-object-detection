function ui_pipeline()
% UI_PIPELINE  Interfaz para testear el pipeline en tiempo real.
%
%   Permite cargar cualquier imagen, activar/desactivar cada paso del
%   pipeline con checkboxes y ajustar parametros con sliders.
%
%   CORRER:  cd a desk-object-detection/ y ejecutar ui_pipeline

    addpath(genpath(fullfile(fileparts(mfilename('fullpath')), 'src')));

    % ── Figura ────────────────────────────────────────────────────────────
    fig = figure('Name', 'Pipeline Tester — desk-object-detection', ...
        'Position', [30 30 1430 820], ...
        'NumberTitle', 'off', 'MenuBar', 'none', 'ToolBar', 'none', ...
        'Resize', 'off', 'Color', [0.94 0.94 0.94]);
    fig.UserData.imgRaw = [];

    % ── Panel izquierdo (controles) ───────────────────────────────────────
    px = 8; pw = 268;

    % Boton cargar imagen
    btnLoad = mkbtn(fig, 'Cargar imagen', [px 774 pw 32], ...
        [0.18 0.46 0.82], 'white', 12);

    lblFile = uicontrol(fig, 'Style','text', 'String','(sin imagen)', ...
        'Position',[px 756 pw 16], 'HorizontalAlignment','left', ...
        'FontSize',7, 'BackgroundColor',[0.94 0.94 0.94], ...
        'ForegroundColor',[0.4 0.4 0.4]);

    % ── Seccion preprocesamiento ──────────────────────────────────────────
    %   btnLoad bottom=774, lblFile bottom=756
    mksep(fig, '  PREPROCESAMIENTO  ', [px 734 pw 16]);

    %   Sep bottom=734. cbBilat debe aparecer abajo con ~8px de gap
    cbBilat  = mkcb(fig, 'Bilateral  (f_bilateral)', [px 708 pw 18], 1);

    %   cbBilat bottom=708. mkslider pone label en pos(2)+16.
    %   Queremos: label_top = slider_y+30 al menos 10px por debajo de cbBilat_bottom
    %   → slider_y <= 708 - 40 = 668
    [slBilatGS, vlBilatGS] = mkslider(fig, [px+10 664 200 14], 5,30,15,'%.0f','GS rango:');
    %   slBilatGS bottom=664. slBilatSP label_top=slider_y+30 <= 664-10=654 → slider_y<=624
    [slBilatSP, vlBilatSP] = mkslider(fig, [px+10 620 200 14], 1,12, 5,'%.0f','Spatial:');

    %   slBilatSP bottom=620. cbWB top debe ser <= 620-12=608 → cbWB_y<=590
    cbWB     = mkcb(fig, 'White Balance  (gray-world)', [px 590 pw 18], 1);

    %   cbWB bottom=590. cbCLAHE top <= 590-8=582 → cbCLAHE_y<=564
    cbCLAHE  = mkcb(fig, 'CLAHE  (canal L)', [px 562 pw 18], 1);

    %   cbCLAHE bottom=562. slCLAHE label_top=slider_y+30 <= 562-10=552 → slider_y<=522
    [slCLAHE, vlCLAHE] = mkslider(fig, [px+10 518 200 14], 0.001,0.030,0.005,'%.3f','Clip limit:');

    %   slCLAHE bottom=518. cbLap top <= 518-14=504 → cbLap_y<=486
    cbLap    = mkcb(fig, 'Laplaciano  (f_laplaciano)', [px 484 pw 18], 1);

    %   cbLap bottom=484. slLapA label_top=slider_y+30 <= 484-10=474 → slider_y<=444
    [slLapA,  vlLapA]  = mkslider(fig, [px+10 440 200 14], 0,0.8,0.3,'%.2f','Alpha:');

    % ── Seccion deteccion ─────────────────────────────────────────────────
    %   slLapA bottom=440. Sep top <= 440-12=428 → sep_y<=412
    mksep(fig, '  DETECCION  ', [px 410 pw 16]);

    %   Sep bottom=410. cbEnh top <= 410-8=402 → cbEnh_y<=384
    cbEnh    = mkcb(fig, 'img_enhancement  (FFT Lap)', [px 382 pw 18], 1);

    %   cbEnh bottom=382. slEnhA label_top=slider_y+30 <= 382-10=372 → slider_y<=342
    [slEnhA,  vlEnhA]  = mkslider(fig, [px+10 338 200 14], 0.0,1.0,0.5,'%.2f','Alpha FFT:');

    %   slEnhA bottom=338. Siguiente label <= 338-10=328
    uicontrol(fig,'Style','text','String','Canny Low:', ...
        'Position',[px+10 316 100 14],'HorizontalAlignment','left','FontSize',8, ...
        'BackgroundColor',[0.94 0.94 0.94]);
    [slCLo,   vlCLo]   = mkslider(fig, [px+10 300 200 14], 0.01,0.15,0.05,'%.3f','');

    %   slCLo bottom=300. Siguiente label <= 300-10=290
    uicontrol(fig,'Style','text','String','Canny High:', ...
        'Position',[px+10 278 100 14],'HorizontalAlignment','left','FontSize',8, ...
        'BackgroundColor',[0.94 0.94 0.94]);
    [slCHi,   vlCHi]   = mkslider(fig, [px+10 262 200 14], 0.05,0.50,0.20,'%.3f','');

    %   slCHi bottom=262. Siguiente label <= 262-10=252
    uicontrol(fig,'Style','text','String','Area minima (px):', ...
        'Position',[px+10 240 130 14],'HorizontalAlignment','left','FontSize',8, ...
        'BackgroundColor',[0.94 0.94 0.94]);
    [slArea,  vlArea]  = mkslider(fig, [px+10 224 200 14], 200,8000,500,'%.0f','');

    % ── Boton procesar ────────────────────────────────────────────────────
    %   slArea bottom=224. btnRun top <= 224-14=210 → btnRun_y<=170
    btnRun = mkbtn(fig, 'PROCESAR', [px 170 pw 42], [0.10 0.65 0.15], 'white', 13);

    % ── Caja de info ──────────────────────────────────────────────────────
    %   btnRun bottom=170. lblInfo ocupa y=10 hasta y=160
    lblInfo = uicontrol(fig, 'Style','text', 'String', '', ...
        'Position',[px 10 pw 152], 'HorizontalAlignment','left', ...
        'FontSize',8, 'BackgroundColor',[1 1 1], ...
        'ForegroundColor',[0.15 0.15 0.15]);

    % ── Axes (imagen) ─────────────────────────────────────────────────────
    gap = 8; axw = 368; axh = 730; axY = 55;
    ax1 = axes(fig,'Position',n([px+pw+gap,           axY, axw, axh])); axis off;
    ax2 = axes(fig,'Position',n([px+pw+gap+axw+gap,   axY, axw, axh])); axis off;
    ax3 = axes(fig,'Position',n([px+pw+gap+2*(axw+gap), axY, axw, axh])); axis off;
    title(ax1,'Original',    'FontSize',11);
    title(ax2,'Preprocesada','FontSize',11);
    title(ax3,'Detecciones', 'FontSize',11);

    % ── Callbacks ─────────────────────────────────────────────────────────
    btnLoad.Callback = @cb_load;
    btnRun.Callback  = @cb_run;

    slBilatGS.Callback = @(s,~) set(vlBilatGS,'String',sprintf('%.0f',s.Value));
    slBilatSP.Callback = @(s,~) set(vlBilatSP,'String',sprintf('%.0f',s.Value));
    slCLAHE.Callback   = @(s,~) set(vlCLAHE,  'String',sprintf('%.3f',s.Value));
    slLapA.Callback    = @(s,~) set(vlLapA,   'String',sprintf('%.2f',s.Value));
    slEnhA.Callback    = @(s,~) set(vlEnhA,   'String',sprintf('%.2f',s.Value));
    slCLo.Callback     = @(s,~) set(vlCLo,    'String',sprintf('%.3f',s.Value));
    slCHi.Callback     = @(s,~) set(vlCHi,    'String',sprintf('%.3f',s.Value));
    slArea.Callback    = @(s,~) set(vlArea,   'String',sprintf('%.0f',s.Value));

    % ─────────────────────────────────────────────────────────────────────
    function cb_load(~,~)
        [f,p] = uigetfile({'*.jpg;*.jpeg;*.png;*.JPG;*.PNG','Imagenes'}, ...
            'Seleccionar imagen');
        if isequal(f,0), return; end
        raw = imread(fullfile(p,f));
        if size(raw,3)==1, raw=cat(3,raw,raw,raw); end
        fig.UserData.imgRaw = raw;
        set(lblFile,'String',f);
        imshow(raw,'Parent',ax1); title(ax1,'Original','FontSize',11);
        cla(ax2); title(ax2,'Preprocesada','FontSize',11);
        cla(ax3); title(ax3,'Detecciones', 'FontSize',11);
        set(lblInfo,'String',sprintf('Cargada: %s\n%dx%d px\n\nPresiona PROCESAR.', ...
            f, size(raw,1), size(raw,2)));
    end

    function cb_run(~,~)
        raw = fig.UserData.imgRaw;
        if isempty(raw)
            set(lblInfo,'String','Carga una imagen primero.'); return
        end
        set(lblInfo,'String','Procesando...'); drawnow;

        [lightCond, autoOpts] = classify_lighting(raw);

        autoOpts.bilateralGS      = round(slBilatGS.Value);
        autoOpts.bilateralSpatial = round(slBilatSP.Value);
        autoOpts.whiteBalance     = logical(cbWB.Value);
        autoOpts.claheClipLimit   = slCLAHE.Value;
        autoOpts.sharpenAlpha     = slLapA.Value * double(cbLap.Value);

        tic;
        imgP = preproc_ui(raw, autoOpts, cbBilat.Value, cbCLAHE.Value);

        dOpts.enhAlpha  = slEnhA.Value * double(cbEnh.Value);
        dOpts.cannyLow  = slCLo.Value;
        dOpts.cannyHigh = slCHi.Value;
        dOpts.minArea   = round(slArea.Value);
        bboxes = get_bboxes(imgP, dOpts);
        t = toc;

        imshow(imgP,'Parent',ax2);
        title(ax2, sprintf('Preprocesada  [cond: %s]', lightCond), 'FontSize',11);

        imshow(imgP,'Parent',ax3); hold(ax3,'on');
        colors = lines(max(size(bboxes,1),1));
        for k = 1:size(bboxes,1)
            bb = bboxes(k,:);
            rectangle(ax3,'Position',bb,'EdgeColor',colors(k,:),'LineWidth',2);
            text(ax3, bb(1)+3, bb(2)+14, sprintf('#%d',k), ...
                'Color','yellow','FontSize',9,'FontWeight','bold');
        end
        hold(ax3,'off');
        title(ax3, sprintf('Detecciones: %d', size(bboxes,1)), 'FontSize',11);

        set(lblInfo,'String', sprintf( ...
            'Condicion: %s\nObjetos: %d\nTiempo: %.2fs\n\n%s Bilateral  GS=%d sp=%d\n%s White Balance\n%s CLAHE  clip=%.3f\n%s Laplaciano  a=%.2f\n%s Enh (FFT)  a=%.2f\n   Canny [%.3f  %.3f]\n   Area min: %.0f', ...
            lightCond, size(bboxes,1), t, ...
            oo(cbBilat.Value), round(slBilatGS.Value), round(slBilatSP.Value), ...
            oo(cbWB.Value), oo(cbCLAHE.Value), slCLAHE.Value, ...
            oo(cbLap.Value), slLapA.Value, oo(cbEnh.Value), slEnhA.Value, ...
            slCLo.Value, slCHi.Value, slArea.Value));
    end

    function s = oo(v)
        if v, s='[ON]'; else, s='[--]'; end
    end

    function npos = n(pxpos)
        fp = fig.Position;
        npos = [pxpos(1)/fp(3), pxpos(2)/fp(4), pxpos(3)/fp(3), pxpos(4)/fp(4)];
    end
end


% ── Helpers de creacion de controles ─────────────────────────────────────

function h = mkbtn(fig, str, pos, bg, fg, fs)
    h = uicontrol(fig, 'Style','pushbutton', 'String',str, ...
        'Position',pos, 'BackgroundColor',bg, 'ForegroundColor',fg, ...
        'FontSize',fs, 'FontWeight','bold');
end

function h = mkcb(fig, str, pos, val)
    h = uicontrol(fig, 'Style','checkbox', 'String',str, ...
        'Position',pos, 'Value',val, 'FontSize',9, 'FontWeight','bold', ...
        'BackgroundColor',[0.94 0.94 0.94], 'ForegroundColor',[0.05 0.35 0.65]);
end

function mksep(fig, str, pos)
    uicontrol(fig,'Style','text','String',str,'Position',pos, ...
        'FontSize',9,'FontWeight','bold','HorizontalAlignment','center', ...
        'BackgroundColor',[0.75 0.85 1.0],'ForegroundColor',[0.05 0.1 0.5]);
end

function [sl, vl] = mkslider(fig, pos, mn, mx, val, fmt, lbl)
    if ~isempty(lbl)
        uicontrol(fig,'Style','text','String',lbl, ...
            'Position',[pos(1) pos(2)+16 120 14], ...
            'HorizontalAlignment','left','FontSize',8, ...
            'BackgroundColor',[0.94 0.94 0.94]);
    end
    sl = uicontrol(fig,'Style','slider','Position',pos, ...
        'Min',mn,'Max',mx,'Value',val);
    vl = uicontrol(fig,'Style','text','String',sprintf(fmt,val), ...
        'Position',[pos(1)+pos(3)+4 pos(2) 44 pos(4)], ...
        'FontSize',8,'BackgroundColor',[1 1 1], ...
        'ForegroundColor',[0.7 0.2 0]);
end


% ── Pipeline con flags on/off ─────────────────────────────────────────────

function imgOut = preproc_ui(imgIn, opts, doBilat, doCLAHE)
    if isa(imgIn,'uint8'), img=im2double(imgIn);
    else,                  img=double(imgIn); if max(img(:))>1, img=img/255; end
    end
    img = max(0,min(1,img));

    if doBilat
        img = max(0,min(1, im2double( ...
            f_bilateral(im2uint8(img), opts.bilateralGS, opts.bilateralSpatial))));
    end

    if opts.whiteBalance
        r=img(:,:,1); g=img(:,:,2); b=img(:,:,3);
        m=(mean(r(:))+mean(g(:))+mean(b(:)))/3;
        img = max(0,min(1, cat(3, r*(m/max(mean(r(:)),eps)), ...
                                   g*(m/max(mean(g(:)),eps)), ...
                                   b*(m/max(mean(b(:)),eps)))));
    end

    if doCLAHE && opts.claheClipLimit > 0
        lab = rgb2lab(img);
        L   = adapthisteq(lab(:,:,1)/100, 'ClipLimit', opts.claheClipLimit, ...
                          'NumTiles',[8 8], 'Distribution','uniform');
        lab(:,:,1) = L*100;
        img = max(0,min(1, lab2rgb(lab)));
    end

    if opts.sharpenAlpha > 0
        img = max(0,min(1, img - opts.sharpenAlpha * f_laplaciano(img, 0.2)));
    end

    imgOut = img;
end
