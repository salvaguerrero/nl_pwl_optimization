* Definition of scalars
* =====================
scalars
*1:K1 triangulation 2: J1 triangulation
type_triangulation /1/
*1:ZZI 2:TextBook 3:Babayev
type_method /1/

num_columns x resolution /4/
num_rows    y resolution /6/

x_u         x upper limit /10/
x_l         x lower limit /0/
y_u         y upper limit /10/
y_l         y lower limit /0/

r_max
s_max
;
* Definition of sets
* ==================
*ZigZag Sets:
$offOrder
sets
    enteros /1*100/
    i(enteros)
    j(enteros)
    r(enteros)
    s(enteros)
    
*K1 triang
    s1(enteros,enteros)
    s2(enteros,enteros)
    s3(enteros,enteros)
    s4(enteros,enteros)
    
*J1 triang
    s1_jk(enteros,enteros)
    s2_jk(enteros,enteros)
;

* Definition of parameters
* ========================
parameters
* Convex combination points
    x_grid(enteros)
    y_grid(enteros)
    z_grid(enteros,enteros)
;
*ZigZag:
Table cr(enteros,enteros);
Table cs(enteros,enteros);

*ZZI or benchmark
if (type_method=1,
    r_max = ceil(log2(num_rows -1));
    s_max = ceil(log2(num_columns -1));
);

if (type_method=2,
    r_max = num_rows-1;
    s_max = num_columns-1;
);

i(enteros)=yes$(enteros.ord <= num_columns and enteros.ord >= 1);
j(enteros)=yes$(enteros.ord <= num_rows    and enteros.ord >= 1);
r(enteros)=yes$(enteros.ord <= r_max       and enteros.ord >= 1);
s(enteros)=yes$(enteros.ord <= s_max       and enteros.ord >= 1);

* Definition of variables
* =======================
positive variables
    x
    y
    z
;
Variables
    theta(enteros,enteros)
    v_fobj
;
integer Variables
    chi_r(enteros)
    chi_s(enteros)
;
binary variables
    z1
    z2
*Babayev variables:
    chi_u(enteros,enteros)
    chi_w(enteros,enteros)
;

*###########################################
$onEmbeddedCode Python:
import numpy as np

def f(x,y):
    return x**2 + y**2

for i in gams.get("num_columns"):
    num_columns = int(i)
for i in gams.get("num_rows"):
    num_rows = int(i)
for i in gams.get("x_u"):
    x_u = i
for i in gams.get("x_l"):
    x_l = i
for i in gams.get("y_u"):
    y_u = i
for i in gams.get("y_l"):
    y_l = i

##################### AUX Functions  #####################
def range_plus(start, stop, num_steps):
    range_size = stop-start
    step_size = float(range_size)/(num_steps-1)
    for step in range(num_steps):
        yield round(start + step*step_size,3)
        
def congruent_modulo(a,b,n):
    return a%n == b%n
    
def iseven(num):
    if num % 2 == 0:
        return True # Even 
    else:
        return False # Odd
        
def S_1(I,J):
    S1 = []
    for i in I:
        for j in J:
            if congruent_modulo(i,j,2) & congruent_modulo(i+j,2,4):
                S1.append((i+1,j+1))
    return S1
def S_2(I,J):
    S2 = []
    for i in I:
        for j in J:
            if congruent_modulo(i,j,2) & congruent_modulo(i+j,0,4):
                S2.append((i+1,j+1))
    return S2
def S_3(I,J):
    S3 = []
    for i in I:
        for j in J:
            if (not congruent_modulo(i,j,2)) & congruent_modulo(i+j,3,4):
                S3.append((i+1,j+1))
    return S3
def S_4(I,J):
    S4 = []
    for i in I:
        for j in J:
            if (not congruent_modulo(i,j,2)) & congruent_modulo(i+j,1,4):
                S4.append((i+1,j+1))
    return S4

def S_1_jk(I,J):
    S1 = []
    for i in I:
        for j in J:
            if ((iseven(i) == True) & (iseven(j) == False)):
                S1.append((i+1,j+1))
    return S1

def S_2_jk(I,J):
    S2 = []
    for i in I:
        for j in J:
            if ((iseven(i) == False) & (iseven(j) == True)):
                S2.append((i+1,j+1))
    return S2

def C_matrix(R):
    C = {}
    C[1] = np.array([[0], [1]])
    for r in range(1, int(R)+1):
        C[r+1] = np.vstack((
                np.hstack((C[r], np.zeros((2**r, 1)))),
                np.hstack((C[r] + 
                    np.ones((2**r, 1)) * C[r][2**r-1],
                    np.ones((2**r, 1))
                    ))
            ))
    return C
##################### End AUX Functions  #####################
 

I = list(range(1,num_columns+1)) 
J = list(range(1,num_rows+1))

s1 = []
s1 = S_1(I,J)
gams.set("s1",s1)

s2 = []
s2 = S_2(I,J)
gams.set("s2",s2)

s3 = []
s3 = S_3(I,J)
gams.set("s3",s3)

s4 = []
s4 = S_4(I,J)
gams.set("s4",s4)

s1_jk = []
s1_jk = S_1_jk(I,J)
gams.set("s1_jk",s1_jk)

s2_jk = []
s2_jk = S_2_jk(I,J)
gams.set("s2_jk",s2_jk)
    
x_grid = list(range_plus(x_l,y_u,num_columns))
aux = []
for i,val in enumerate(x_grid):
    aux.append((i+2,val))
gams.set("x_grid",aux)

y_grid = list(range_plus(x_l,x_u,num_rows)) 
aux = []
for j,val in enumerate(y_grid):
    aux.append((j+2,val))
gams.set("y_grid",aux)


auxZ = []
for i,x_val in enumerate(x_grid):
    for j,y_val in enumerate(y_grid):
        z_val = f(x_val,y_val)
        auxZ.append( (i+2,j+2,z_val) )

gams.set("Z_grid",auxZ)

r = int(np.ceil(np.log2(num_rows    - 1)))
s = int(np.ceil(np.log2(num_columns - 1)))
CRm1 = list(range(1, 2**r+1))   
CSm1 = list(range(1, 2**s+1)) 
C = {}
C = C_matrix(max(r,s))

aux = []
for i in CRm1:
    for j,val in enumerate(C[r][ i-1 ]):
        aux.append((i+1,j+2,val))
gams.set("cr",aux)

aux = []
for i in CSm1:
    for j,val in enumerate(C[s][ i-1 ]):
        aux.append((i+1,j+2,val))
gams.set("cs",aux)
$offEmbeddedCode s1 s2 s3 s4 s1_jk s2_jk x_grid y_grid z_grid cr cs


* Declaration of equations
* ========================
equations
eq_SOS2_1
eq_SOS2_2
eq_SOS2_3
eq_SOS2_4

eq_zigzag_a1
eq_zigzag_a2

eq_bm_a1
eq_bm_a2

eq_zigzag_b1
eq_zigzag_b2

eq_bm_b1
eq_bm_b2

eq_trian1_k1
eq_trian2_k1
eq_trian3_k1
eq_trian4_k1

eq_trian1_jk
eq_trian2_jk

eq_babayev_a1
eq_babayev_a2

e_fobj
;

eq_SOS2_1 ..
    x =E= sum((i,j), x_grid(i)*theta(i,j) )
;
eq_SOS2_2 ..
    y =E= sum((i,j), y_grid(j)*theta(i,j) )
;
eq_SOS2_3 ..
    z =E= sum((i,j), z_grid(i,j)*theta(i,j) )
;
eq_SOS2_4 ..
    1 =E= sum((i,j),theta(i,j) )
;



*############### Row Selection  ###############

*ZigZag Integer formulation:
eq_zigzag_a1(r)..
    sum((i) , cr["1" ,r] *theta(i,"1")) +
    sum((i,j), cr[j-1 ,r]$(not j.first )*theta(i, j )) =l= chi_r(r)
;
eq_zigzag_a2(r) ..
    sum((i,j), cr[j ,r]$(not j.last )*theta(i,j)) +
    sum((i,j), cr[j-1,r]$( j.last )*theta(i,j)) =g= chi_r(r)
;

*TextBook formulation:
eq_bm_a1..
    sum(j, chi_r(j) ) =e= 1
;
eq_bm_a2(j)..
    sum(i, theta(i,j) ) =l= chi_r(j)$(not j.last) + chi_r(j-1)$(not j.first)
;

*############### Column Selection  ###############
eq_zigzag_b1(s) ..
    sum((j) , cs["1",s] *theta("1",j)) +
    sum((i,j), cs[i-1,s]$(not i.first )*theta(i ,j)) =l= chi_s(s)
;
eq_zigzag_b2(s) ..
    sum((i,j), cs[i ,s]$(not i.last )*theta(i,j)) +
    sum((i,j), cs[i-1,s]$( i.last )*theta(i,j)) =g= chi_s(s)
;

*TextBook formulation:
eq_bm_b1..
    sum(i, chi_s(i) ) =e= 1
;
eq_bm_b2(i)..
    sum(j, theta(i,j) ) =l= chi_s(i)$(not i.last) + chi_s(i-1)$(not i.first)
;



*############### Triangle Selection  ###############

*K1 triangulation
eq_trian1_k1..
      z1 =g= sum(s1(i,j),theta(i,j) )
;
eq_trian2_k1..
    1-z1 =g= sum(s2(i,j),theta(i,j) )
;
eq_trian3_k1..
      z2 =g= sum(s3(i,j),theta(i,j) )
;
eq_trian4_k1..
    1-z2 =g= sum(s4(i,j),theta(i,j) )
;

**************************************************
*J1 triangulation
eq_trian1_jk..
       z1 =g= sum(s1_jk(i,j),theta(i,j) )
;
eq_trian2_jk..
     1-z1 =g= sum(s2_jk(i,j),theta(i,j) )
;


*############### Babayev  ###############

eq_babayev_a1(i,j)..
    theta(i,j) =l=  chi_w(i ,j ) + chi_u(i ,j) +
                    chi_w(i ,j+1)$(not j.last) + chi_u(i ,j-1)$(not j.first) +
                    chi_w(i+1,j )$(not i.last) + chi_u(i-1,j )$(not i.first)
;
eq_babayev_a2..
    sum((i,j), chi_u(i,j) + chi_w(i,j) ) =E= 1
;


e_fobj ..
   v_fobj               =E= (z-1.1)*(z-1.1)
;

* ======================
model  pwl_zzi_k1
/
eq_SOS2_1
eq_SOS2_2
eq_SOS2_3
eq_SOS2_4

eq_zigzag_a1
eq_zigzag_a2

eq_zigzag_b1
eq_zigzag_b2

eq_trian1_k1
eq_trian2_k1
eq_trian3_k1
eq_trian4_k1

e_fobj
/
;

model  pwl_zzi_j1
/
eq_SOS2_1
eq_SOS2_2
eq_SOS2_3
eq_SOS2_4

eq_zigzag_a1
eq_zigzag_a2

eq_zigzag_b1
eq_zigzag_b2

eq_trian1_jk
eq_trian2_jk

e_fobj
/
;

model  pwl_bm_k1
/
eq_SOS2_1
eq_SOS2_2
eq_SOS2_3
eq_SOS2_4

eq_bm_a1
eq_bm_a2

eq_bm_b1
eq_bm_b2

eq_trian1_k1
eq_trian2_k1
eq_trian3_k1
eq_trian4_k1

e_fobj
/
;

model  pwl_bm_j1
/
eq_SOS2_1
eq_SOS2_2
eq_SOS2_3
eq_SOS2_4

eq_bm_a1
eq_bm_a2

eq_bm_b1
eq_bm_b2

eq_trian1_jk
eq_trian2_jk

e_fobj
/
;

model  pwl_babayev
/
eq_SOS2_1
eq_SOS2_2
eq_SOS2_3
eq_SOS2_4

eq_babayev_a1
eq_babayev_a2

e_fobj
/
;
if (type_method=1,
    if (type_triangulation=1, 
        solve pwl_zzi_k1 using MIQCP minimizing v_fobj;
    else
        solve pwl_zzi_j1 using MIQCP minimizing v_fobj;
    );
elseif type_method=2,
    if (type_triangulation=1, 
        solve pwl_bm_k1 using MIQCP minimizing v_fobj;
    else
        solve pwl_bm_j1 using MIQCP minimizing v_fobj;
    );
else
    solve pwl_babayev using MIQCP minimizing v_fobj;

);




