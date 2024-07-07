clc;clear;

num_row = 15
num_columns = 15

% 1:    J1 triangulation 
% o.t.: K1 triangulation
type_triangulation = 0

x_u = 4  ;
x_l = -4   ;
y_u = 4  ;
y_l = -4   ;

%Substite by your function:
f = @(x,y) 3*(1-x).^2 .* exp(-x.^2-(y+1).^2) - 10*(x./5 -x.^3 - y.^5).*exp(-x.^2-y.^2)  - exp(-(x+1).^2 - y.^2 )./3;



step      = (x_u-x_l)/(num_columns-1) ;
x_range = x_l:step:x_u;     
step      = (y_u-y_l)/(num_row-1)     ;
y_range   = y_l:step:y_u;         
[x,y] = meshgrid(x_range,y_range);



if type_triangulation == 1
    tt = @(i,j) (i-1)*num_row + j;
    T = [];
    diag = false;
    for i = 1:(num_columns-1)
        for j = 1:(num_row-1)
            diag = ~diag;
            if diag
                T = [T; tt(i,j) tt(i,j+1) tt(i+1,j+1) ];
                T = [T; tt(i,j) tt(i+1,j) tt(i+1,j+1) ];
            else
                T = [T; tt(i,j) tt(i+1,j) tt(i,j+1) ];
                T = [T; tt(i+1,j) tt(i+1,j+1) tt(i,j+1) ];
            end
        end
        if ~rem(num_columns,2)%odd
            diag = diag;
        else %even
            diag = ~diag;
        end
    end
else
    T = delaunay(x,y);
end

figure()

%Linearized fucntion:
trisurf(T,x,y, f(x,y) , 'FaceAlpha',0.3,'FaceColor',[1 0 0],'HandleVisibility','off' )
xlabel("X")
ylabel("Y")
zlabel("Z")
hold on 

%Real function
fsurf(f,[x_l x_u y_l y_u], 'EdgeColor','none' ,'FaceAlpha',0.3,'FaceColor',[0 1 0],'HandleVisibility','off' )

hold off
