function lattice_points = generate_lattice(Width, Height, center_pix, direct_lattice_vectors, edge_buffer)
% center_pix [x y] ([Width Height])
% 
num_vectors = round(1.2 * max(Width,Height) / sqrt(sum(direct_lattice_vectors(1,:).^2)));
lower_bounds = [edge_buffer, edge_buffer];
upper_bounds = [Width - edge_buffer, Height - edge_buffer];
[xx,yy] = meshgrid(-num_vectors:num_vectors, -num_vectors:num_vectors);
xx = xx(:); yy = yy(:);
% lp = zeros(size(xx,1),2);
lp = xx.*direct_lattice_vectors(1,:)+yy.*direct_lattice_vectors(2,:)+center_pix;
lp(sum(lp > lower_bounds, 2) < 2,:) = [];
lp(sum(lp < upper_bounds, 2) < 2,:) = [];
lattice_points = lp;
end

