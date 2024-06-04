 function [ParaIter, ReconResult] = mISM_FISTA4_gui(dataIter, pinhole,filesave)
    lamb = [dataIter.ReconPara(1), dataIter.ReconPara(2)];  
    iterations = dataIter.ReconPara(3);
    SaveFreq = dataIter.ReconPara(4);
    L = dataIter.ReconPara(5);
    RegItem = dataIter.RegItem;
    
    a = dataIter.image;    

    psfem = dataIter.psfem;

    a = a./max(a(:));
    g = a;
    xk = g;
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
            ReconResult_fista_mean = mean(ReconResult,3);
            imwrite(uint16(10000*ReconResult_fista_mean./max(ReconResult_fista_mean(:))),...
                strcat(filesave, '\FISTA_',num2str(ii),'.tif'))
        end
    end
end

function [UpdateParaIter, ReconResult] = oneIteration(ParaIter, pinhole,iter)
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
    ykp1 = xk + over * ( xk - xk1);
    
    UpdateParaIter.xk = xk;
    UpdateParaIter.ykp1 = ykp1;
    UpdateParaIter.tkp1 = tkp1;
    UpdateParaIter.L = L;
    
%     imshow(ykp1,[])
%     pause(0.1)
    
    ReconResult = ykp1;
end

function forwardProjectionY = forward(yk, psfem, pinhole)
    [Height, Width, periods] = size(pinhole);
    forwardProjectionY = zeros(Height, Width, periods);
    g = yk;
    for imgIdx = 1:periods
        forwardProjectionY(:,:,imgIdx) = conv2(pinhole(:,:,imgIdx).*g(:,:,imgIdx), psfem, 'same');
    end
    forwardProjectionY = max(forwardProjectionY, 0);
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
    for imgIdx = 1:periods
        tmp1(:,:,imgIdx) = conv2(tmp(:,:,imgIdx), psfem, 'same').*pinhole(:,:,imgIdx);
    end
    grad = tmp1;
end

function xtest = step(L, lamb, yk, grad, RegItem)
    g = yk;
    c_g = g - grad/L;
    if RegItem(1) == 1
        xtest = c_g;
    elseif RegItem(2) == 1
        deno = L * sqrt(sum(c_g.^2, 3))/lamb(1);
        step_length = max(1-1./deno, 0);
        xtest = repmat(step_length, [1, 1, size(c_g, 3)]) .* c_g; 
    end
end

function quadraticAdd = quadraticApprox(xtest, yk, grad, L)
    delta0 = xtest - yk;
    temp1 = delta0 .* grad + L/2*delta0.*delta0;
    quadraticAdd = sum(temp1(:));
end