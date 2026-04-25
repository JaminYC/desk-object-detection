function img_prcs = f_laplaciano(I,alpha)
filtro = fspecial('laplacian',alpha); %funcion para especificar un filtro. Varias opciones
img_prcs = imfilter(I,filtro);
end