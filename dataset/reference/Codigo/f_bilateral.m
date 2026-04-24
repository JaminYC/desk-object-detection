function img_proc = f_bilateral(I,g_s,int)

    % Convertir a espacio de color Lab
    I_Lab = rgb2lab(I);

    I_bilat = imbilatfilt(I_Lab, g_s, int);

    % Convertir de nuevo a RGB
    img_proc = lab2rgb(I_bilat,'Out','uint8');
end
