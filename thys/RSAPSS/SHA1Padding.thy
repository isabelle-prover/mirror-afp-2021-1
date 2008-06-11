(*  Title:      RSAPSS/SHA1Padding.thy
    ID:         $Id: SHA1Padding.thy,v 1.3 2008-06-11 14:22:59 lsf37 Exp $
    Author:     Christina Lindenberg, Kai Wirt, Technische Universitšt Darmstadt
    Copyright:  2005 - Technische Universitšt Darmstadt
*)


header "Message Padding for SHA1"

theory SHA1Padding
imports WordOperations
begin

consts sha1padd::"bv \<Rightarrow> bv"
       helppadd::"(bv \<times> bv \<times> nat) \<Rightarrow> bv"
       zerocount::"nat \<Rightarrow> nat"

defs 
  sha1padd:
  "sha1padd x == helppadd (x,nat_to_bv (length x),(length x))"

recdef helppadd "measure(\<lambda> (x,y,n). n)"
  "helppadd (x,y,n) = x@[One]@(zerolist (zerocount n))@(zerolist (64-length y))@y"

defs 
  zerocount:
  "zerocount n == ((((n+64) div 512)+1)*512)-n-(65::nat)"

end
