(*
Author:     Wenda Li <wl302@cam.ac.uk / liwenda1990@hotmail.com>
*)

section \<open>Some examples for complex root counting\<close>

theory Count_Complex_Roots_Examples
  imports Count_Complex_Roots
begin

(*the result will be 1, as the polynomial P(x) = ii*x^2 - 2*ii has exactly one complex root 
  (i.e. sqrt(2)*ii) (counted with multiplicity) within the rectangle box (-1,2+2*ii)*)  
value "proots_rect [:2*\<i>,0,\<i>:] (Complex (-1) 0) (Complex 2 2)"
 
(*the result will be 2, as the polynomial P(x) = x^2 - 2*ii*x - 1 has exactly two complex roots (i.e. 
  ii with multiplicity 2) within the rectangle box (-1,2+2*ii)*)  
value "proots_rect [:-1,-2*\<i>,1:] 
          (Complex (-1) 0) (Complex 2 2)"

(*the result will be 1, as the polynomial P(x) = x - 1 has exactly one complex roots (i.e. 
  1 with multiplicity 1) within the rectangle box (-1,2+2*ii) INCLUDING the lower
  left two borders*)  
value "proots_rect_ll [:-1,1:] 
          (Complex (-1) 0) (Complex 2 2)" 
  
(*the result will be 2, as the polynomial P(x) = x^2 + (2-ii)*x + (1-ii) has exactly two complex 
  roots (i.e. -1 and -1+ii) within the left half plane of the vector (0,1) (i.e. left plane of
  the imaginary axis)*)    
value "proots_half [:1-\<i>,2-\<i>,1:] 
        0 (Complex 0 1)" 
 
(*the result will be 0, as the polynomial P(x) = x^2 + (2-ii)*x + (1-ii) has no root 
  within the left half plane of the vector (0,-1) (i.e. right plane of the imaginary axis) *)    
value "proots_half [:1-\<i>,2-\<i>,1:] (Complex 0 1) 0"  
  
(*the result will be 3, as the polynomial P(x) = (x-2)^2*(x-3) has three complex roots counted 
  with multiplicity within the circle centered as 0 with radius 4.*)
value [code] "proots_ball ([:-2,1:]*[:-2,1:]*[:-3,1:]) 0 4"

end
