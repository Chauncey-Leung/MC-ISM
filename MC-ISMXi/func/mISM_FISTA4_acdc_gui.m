 function [ParaIter, ReconResult] = mISM_FISTA4_acdc_gui(dataIter, pinhole,filesave)
    lamb = [dataIter.ReconPara(1), dataIter.ReconPara(2)]; 
    iterations = dataIter.ReconPara(3);
    SaveFreq = dataIter.ReconPara(4);
    L = dataIter.ReconPara(5);
    RegItem = dataIter.RegItem;
    
    a = dataIter.image;      
    [M,N,periods] = size(a);

    psfem = dataIter.psfem;

    a = a./max(a(:));
    g = a;
    b = zeros(M,N);
    b(1,1) = sum(a(:))/M/N/periods*sqrt(M*N);
    xk{1} = g;
    xk{2} = b;
    tkp1 = 1.0;
    
    ParaIter.psfem = psfem;
    ParaIter.xk = xk;
    ParaIter.ykp1 = xk;
    ParaIter.tkp1 = tkp1;
    ParaIter.lamb = lamb;
    ParaIter.L = L;
    ParaIter.pinhole = pinhole;
    ParaIter.a = a;
    ParaIter.RegItem = RegItem;
    
    for ii = 1:iterations
        [ParaIter, ReconResult] = oneIteration(ParaIter, pinhole,ii);
        if mod(ii,SaveFreq)==0
            ReconResult_fista_mean = mean(ReconResult{1},3);
            imwrite(uint16(10000*ReconResult_fista_mean./max(ReconResult_fista_mean(:))),...
                strcat(filesave, '\FISTA_',num2str(ii,'%03d'),'.tif'))
        end
    end
end

function [UpdateParaIter, ReconResult] = oneIteration(ParaIter, pinhole,iter)
% Global updates, not single frame updates
    UpdateParaIter = ParaIter;
    a = ParaIter.a;
    xk = ParaIter.xk;
    ykp1 = ParaIter.ykp1;
    psfem = ParaIter.psfem;
    lamb = ParaIter.lamb;
    tkp1 = ParaIter.tkp1;
    L = ParaIter.L;
    RegItem = ParaIter.RegItem;
    
    xk1 = xk;
    yk = ykp1;
    tk = tkp1;
    
    forwardProjectionY = forward(yk, psfem, pinhole);
    maxLikelihoodY = maximumLikelihood(forwardProjectionY, a);
    grad = gradient(forwardProjectionY, a, psfem, pinhole);
    
    for jj = 1:1000
        Ltest = L*power(1.1, jj-1);
        xtest = step(Ltest, lamb, yk, grad, RegItem);
        newForwardProjection = forward(xtest, psfem, pinhole);
        newMaxLikelihood = maximumLikelihood(newForwardProjection, a);
        quadratic = maxLikelihoodY + quadraticApprox(xtest, yk, grad, Ltest);
        disp(strcat("iter: ",num2str(iter), "|| Ltest =", num2str(Ltest), ",newMaxLikelihood =", num2str(newMaxLikelihood), ...
            ",quadratic =", num2str(quadratic),  ",difference =", num2str(newMaxLikelihood - quadratic)))
        if newMaxLikelihood <= quadratic
            xk = xtest;
            L = Ltest;
            maxLikelihoodY = newMaxLikelihood;
            break;
        end
        if jj == 10000
            return
        end
    end
    tkp1 = (1+sqrt(1+4*tk*tk))/2;
    over = (tk-1)/tkp1;
    ykp1{1} = xk{1} + over*(xk{1}-xk1{1});
    ykp1{2} = xk{2} + over*(xk{2}-xk1{2});
    
    UpdateParaIter.xk = xk;
    UpdateParaIter.ykp1 = ykp1;
    UpdateParaIter.tkp1 = tkp1;
    UpdateParaIter.L = L;
    
%     imshow(ykp1,[])
%     pause(0.1)
    
    ReconResult = ykp1;
end

function forwardProjectionY = forward(yk, psfem, pinhole)
% psfem: 2D matrix
% pinhole：3D matrix，1024*1024*100
% Q: 3D matrix，pinhole convolved with psfex，1024*1024*100
    [Height, Width, periods] = size(pinhole);
    forwardProjectionY = zeros(Height, Width, periods);
    g = yk{1};
    b = yk{2};
    idctB = idct2(b);
    for imgIdx = 1:periods
        forwardProjectionY(:,:,imgIdx) = conv2(pinhole(:,:,imgIdx).*g(:,:,imgIdx), psfem, 'same');
    end
    forwardProjectionY = max(forwardProjectionY+repmat(idctB,1,1,periods), 0);
end

function maxLikelihoodY = maximumLikelihood(forwardProjectionY, a)
    temp1 = 0.5*(forwardProjectionY - a).^2;
    maxLikelihoodY = sum(temp1(:));
end


function grad = gradient(forwardProjectionY, a, psfem, pinhole)
    tmp = forwardProjectionY - a;
    grad = backward(tmp, psfem, pinhole);
end

function grad = backward(tmp, psfem, pinhole)
    [Height, Width, periods] = size(pinhole);
    tmp1 = zeros(Height, Width, periods);
    tmp2 = zeros(Height, Width);
    for imgIdx = 1:periods
        tmp1(:,:,imgIdx) = conv2(tmp(:,:,imgIdx), psfem, 'same').*pinhole(:,:,imgIdx);
        tmp2 = tmp2 + dct2(tmp(:,:,imgIdx));
    end
    grad{1} = tmp1;
    grad{2} = tmp2;
end

function xtest = step(L, lamb, yk, grad, RegItem)
    g = yk{1};
    c_g = g - grad{1}/L;
    
    if RegItem(1) == 1
        xtest{1} = c_g;
    elseif RegItem(2) == 1
        [Height, Width, periods] = size(g);
        tmp = zeros(Height, Width);
        meanc = mean(c_g,3);
        tmp(meanc>0) = -lamb(1)/L;
        solution = repmat(tmp,1,1,periods)+c_g;
        xtest{1} = max(solution, 0);
    elseif RegItem(3) == 1
        deno = L * sqrt(sum(c_g.^2, 3))/lamb(1);
        step_length = max(1-1./deno, 0);
        xtest{1} = repmat(step_length, [1, 1, size(c_g, 3)]) .* c_g;
    end
    
    b = yk{2};
    tmp = b - grad{2}/L;
    tmp3 = max(tmp-lamb(2)/L, 0);
    tmp4 = min(tmp+lamb(2)/L, 0);
    xtest{2} = tmp3+tmp4;
end

function quadraticAdd = quadraticApprox(xtest, yk, grad, L)
    delta0 = xtest{1} - yk{1};
    delta1 = xtest{2} - yk{2};
    temp1 = delta0 .* grad{1} + L/2*delta0.*delta0;
    temp2 = delta1 .* grad{2} + L/2*delta1.*delta1;
    quadraticAdd = sum(temp1(:))+ sum(temp2(:));
end