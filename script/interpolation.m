## ##  Plot starting from mysql dump
## readcl; d = read_dump("c4wsense", fog); cld = collapse_dump(d, fog); intcld = split_dump(cld, fog); cfrss = cross_fog_rss(intcld);

function [fingerprint] = interpolation (d, cfrss, fog)
  ##  creation of interpolation surface points
  ##  x-axis 0-18 meters
  ##  y-axis 0-13 meters
  [xq,yq] = meshgrid(0:14,-21:3);

  ## fog.place = ...
  ## { "C62c" "C64c" "C67c" "C62" "C63" "C64" ...
  ##  "C65" "C66" "C69" "C70a" "C72" "C74" };

  ##  fog euclidean coordinates
  x = [7.4, 7.4, 7.4, 1.3, 0, 4, ...
    3.5, 3.5, 10.3, 14, 11.5, 12];
  y = [-1.5, -9, -17, -0.6, -4, -5.8, ...
    -9.5, -16.8, -1.8, -3, -11.5, -14.5];

  ##  cfrss_mean with no empty vectors
  for index = 1:length(cfrss)
    cfrss{index,index} = [0];
  endfor

  cfrss_mean = cellfun('mean',cfrss);
  cfrss_mean += -20 * diag(ones(length(cfrss),1)');

  ##  getting griddata values for single tx and creation of
  ##  fingerprint databases'
  for index = 1:length(cfrss)
    ##  griddata for single tx
    vq = griddata(x,y,cfrss_mean(index,:),xq,yq);

    ##  fingerprint database is a 3Dmatrix
    ##  z index rappresents different fog
    ##  x,y contains griddata values for z-fog
    fingerprint(:,:,index) = vq;
  endfor

  intensityRange = [-80, -20];

  for ii=1:12;
    subplot(3,4,ii);
    imagesc(fingerprint(:,:,ii));
    caxis(intensityRange);
    colorbar;
    title(fog.place(ii));
  endfor

end
