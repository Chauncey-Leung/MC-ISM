function ReconResult_jRL = mISM_jRL_gui(dataIter, pinhole, filesave)
    Img = dataIter.image;
    [M,N,~] = size(Img);
    psfem = dataIter.psfem;
    psfem = psfem/sum(sum(psfem));
    
    iterations = dataIter.ReconPara(2);
    SaveFreq = dataIter.ReconPara(1);
    initialgeuss = mean(Img,3);
    
    for epoch = 1:iterations
        m = forwardpropagatorjRL(initialgeuss, pinhole, psfem);
        m = m + 1e-6;
        r = Img./m;
        correction_factor = backpropagatorjRL(r, pinhole,psfem);
%         tmp = initialgeuss;
        initialgeuss = initialgeuss.*(correction_factor);
%         difference = sum(sum(sum(abs(initialgeuss - tmp).^2)));
        disp(strcat('Iter: ',num2str(epoch),'  done!'))
        if mod(epoch,SaveFreq)==0
            tmp = mean(initialgeuss, 3);
            imwrite(uint16(1000*tmp./max(tmp(:))), strcat(filesave,'\jRL_',num2str(epoch,'%03d'),'.tif'))
        end
    end
    ReconResult_jRL = initialgeuss;
end

function tmp1 = forwardpropagatorjRL(initialgeuss, pinhole, psfem)
    tmp1 = zeros(size(pinhole));
    slice = size(pinhole, 3);
    for idx = 1:slice
        tmp1(:,:,idx) = fftconvolve(pinhole(:,:,idx).*initialgeuss, psfem, 'same');
    end
end

function correction_factor = backpropagatorjRL(r, pinhole,psfem)
    slice = size(pinhole, 3);
    tmp1 = zeros(size(pinhole));
    for idx = 1:slice
%         tmp1(:,:,idx) = fftconvolve(r(:,:,idx).*pinhole(:,:,idx),psfem, 'same');
        tmp1(:,:,idx) = fftconvolve(r(:,:,idx),psfem, 'same').*pinhole(:,:,idx);
    end
    correction_factor = mean(tmp1,3);
end