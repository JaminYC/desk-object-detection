function I_enh = img_enhancement(I,alpha)

I2 = rgb2gray(I);

H = zeros(size(I2,1),size(I2,2));

I_fft = fftshift(fft2(I2));
for i = 1:size(I,1)
    for j = 1:size(I,2)
        H(i,j) = -((i-size(I,1)/2)^2+(j-size(I,2)/2)^2);%desplazamiento para el centro de coordenads
    end
end

I_lap = real(ifft2(ifftshift(I_fft.*H)));
I_lap_norm = I_lap/max(max(I_lap));

I_norm = mat2gray(I2);
I_enh = I_norm - alpha*I_lap_norm;%valor empirico
end