function si = get_centered_subimage(img1,center_point, ws)
    center_point2 = round(center_point);
    si = img1(max(center_point2(1)-ws,0):min(center_point2(1)+ws,size(img1,1)), ...
        max(center_point2(2)-ws,0):min(center_point2(2)+ws,size(img1,2)));
end