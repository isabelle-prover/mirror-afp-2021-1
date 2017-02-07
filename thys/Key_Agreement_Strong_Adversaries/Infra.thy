(*******************************************************************************

  Project: Refining Authenticated Key Agreement with Strong Adversaries

  Module:  Infra.thy (Isabelle/HOL 2016-1)
  ID:      $Id: Infra.thy 132861 2016-12-21 10:34:41Z csprenge $
  Author:  Christoph Sprenger, ETH Zurich <sprenger@inf.ethz.ch>
  
  Infrastructure for refinement proofs (attributes, prover tuning etc)

  Copyright (c) 2009-2016 Christoph Sprenger 
  Licence: LGPL

*******************************************************************************)

section {* Proving infrastructure *}

theory Infra imports Main  
begin

(******************************************************************************)
subsection {* Prover configuration *}
(******************************************************************************)

declare if_split_asm [split]


(******************************************************************************)
subsection {* Forward reasoning ("attributes") *}
(******************************************************************************)

text {* The following lemmas are used to produce intro/elim rules from
set definitions and relation definitions. *}

lemmas set_def_to_intro = meta_eq_to_obj_eq [THEN eqset_imp_iff, THEN iffD2]
lemmas set_def_to_dest = meta_eq_to_obj_eq [THEN eqset_imp_iff, THEN iffD1]
lemmas set_def_to_elim = set_def_to_dest [elim_format]

lemmas setc_def_to_intro = 
  set_def_to_intro [where B="{x. P x}" for P, to_pred]

lemmas setc_def_to_dest = 
  set_def_to_dest [where B="{x. P x}" for P, to_pred]

lemmas setc_def_to_elim = setc_def_to_dest [elim_format]

lemmas rel_def_to_intro = setc_def_to_intro [where x="(s, t)" for s t]
lemmas rel_def_to_dest = setc_def_to_dest [where x="(s, t)" for s t]
lemmas rel_def_to_elim = rel_def_to_dest [elim_format]


(******************************************************************************)
subsection {* General results *}
(******************************************************************************)

subsubsection {* Maps *}
(******************************************************************************)

text {* We usually remove @{term"domIff"} from the simpset and clasets due
to annoying behavior. Sometimes the lemmas below are more well-behaved than 
@{term "domIff"}. Usually to be used as "dest: dom\_lemmas". However, adding 
them as permanent dest rules slows down proofs too much, so we refrain from 
doing this. *}

lemma map_definedness: 
  "f x = Some y \<Longrightarrow> x \<in> dom f"
by (simp add: domIff)

lemma map_definedness_contra:
  "\<lbrakk> f x = Some y; z \<notin> dom f \<rbrakk> \<Longrightarrow> x \<noteq> z"
by (auto simp add: domIff)

lemmas dom_lemmas = map_definedness map_definedness_contra


subsubsection {* Set *}
(******************************************************************************)


lemma vimage_image_subset: "A \<subseteq> f-`(f`A)"
by (auto simp add: image_def vimage_def)


subsubsection {* Relations *}
(******************************************************************************)

lemma Image_compose [simp]:
  "(R1 O R2)``A  = R2``(R1``A)"
by (auto)


subsubsection {* Lists *}
(******************************************************************************)

-- {* Do NOT add the following equation to the simpset! (looping) *}
lemma map_comp: "map (g o f) = map g o map f"  
by (simp)

declare map_comp_map [simp del]

lemma take_prefix: "\<lbrakk> take n l = xs \<rbrakk> \<Longrightarrow> \<exists>xs'. l = xs @ xs'"
by (induct l arbitrary: n xs, auto)
   (rename_tac n, case_tac n, auto)


subsubsection {* Finite sets *}
(******************************************************************************)

text {* Cardinality. *}

declare arg_cong [where f=card, intro] 

lemma finite_positive_cardI [intro!]: 
  "\<lbrakk> A \<noteq> {}; finite A \<rbrakk> \<Longrightarrow> 0 < card A"
by (auto)

lemma finite_positive_cardD [dest!]: 
  "\<lbrakk> 0 < card A; finite A \<rbrakk> \<Longrightarrow> A \<noteq> {}"
by (auto)

lemma finite_zero_cardI [intro!]: 
  "\<lbrakk> A = {}; finite A \<rbrakk> \<Longrightarrow> card A = 0"
by (auto)

lemma finite_zero_cardD [dest!]: 
  "\<lbrakk> card A = 0; finite A \<rbrakk> \<Longrightarrow> A = {}"
by (auto)


end





