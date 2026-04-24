% I = imread('Ft_01_RL (Small).jpg');
%I = imread('../Small/Ft_01_RL_S.jpg');
adr = 'C:\Users\ISAAC\Desktop\Maestría\Visión por computadora\Fotos\CL\Small';
I = imread(fullfile(adr, 'Ft_04_CL_S.jpg'));


% figure
% imshow(I)
g_s = 200;
int = 10;
im1 = f_bilateral(I,g_s,int);
figure()
subplot(121)
imshow(I)
subplot(122)
imshow(im1)

%%
alpha = .8;
I_filt = f_laplaciano(im1, alpha);
figure()
subplot(121)
imshow(I)
subplot(122)
imshow(I_filt)
%%
I_enh = img_enhancement(I, 0.5);
im2 = f_laplaciano(I_enh, alpha);
figure()
subplot(121)
imshow(I)
subplot(122)
imshow(im2)
