function new_corrd = SubstackCenter(sub_image, center)
    Height = size(sub_image, 1);
    Width = size(sub_image, 2);
    liney = sum(sub_image, 2);
    linex = sum(sub_image, 1);

    extents = round((Height-1)/6);
    yy = [-extents : extents]';
    xx = yy';
    cy = round(center(1));
    cx = round(center(2));
    liney = liney((Height+1)/2-extents : (Height+1)/2+extents);
    linex = linex((Width+1)/2-extents : (Width+1)/2+extents);
    

    [xData, yData] = prepareCurveData( yy, liney );
    ft = fittype( 'poly2' );
    [fitresult, ~] = fit( xData, yData, ft );
    cy1 = -fitresult.p2/2/fitresult.p1;
    if abs(cy1) > extents
        scy = center(1);
    else
        scy = cy + cy1;
    end


    [xData, yData] = prepareCurveData( xx, linex );
    ft = fittype( 'poly2' );
    [fitresult, ~] = fit( xData, yData, ft );
    cx1 = -fitresult.p2/2/fitresult.p1;
    if abs(cx1) > extents
        scx = center(2);
    else
        scx = cx + cx1;
    end

    new_corrd = [scy, scx];
