section "LTL integration"
theory PromelaLTL
imports
  "Promela"
  "../LTL_to_GBA/LTL"
begin

text {* We have a semantic engine for Promela. But we need to have 
an integration with LTL -- more specificly, we must know when a proposition
is true in a global state. This is achieved in this theory. *}

subsection {* Proposition types and conversion *}

text {* LTL formulae and propositions are also generated by an SML parser.
Hence we have the same setup as for Promela itself: Mirror the data structures and
(sometimes) map them to new ones. *}

datatype binOp = Eq | Le | LEq | Gr | GEq

datatype ident = Ident "String.literal" "integer option"

datatype propc = CProp ident
               | BProp binOp ident ident
               | BExpProp binOp ident integer

fun identConv :: "ident \<Rightarrow> varRef" where
  "identConv (Ident name None) = VarRef True name None"
| "identConv (Ident name (Some i)) = VarRef True name (Some (ExprConst i))"

definition ident2expr :: "ident \<Rightarrow> expr" where
  "ident2expr = ExprVarRef \<circ> identConv"

primrec binOpConv :: "binOp \<Rightarrow> PromelaDatastructures.binOp" where
  "binOpConv Eq = BinOpEq"
| "binOpConv Le = BinOpLe"
| "binOpConv LEq = BinOpLEq"
| "binOpConv Gr = BinOpGr"
| "binOpConv GEq = BinOpGEq"

primrec propConv :: "propc \<Rightarrow> expr" where
  "propConv (CProp ident) = 
     ExprBinOp BinOpEq (ident2expr ident) (ExprConst 1)"
| "propConv (BProp bop il ir) = 
     ExprBinOp (binOpConv bop) (ident2expr il) (ident2expr ir)"
| "propConv (BExpProp bop il ir) = 
     ExprBinOp (binOpConv bop) (ident2expr il) (ExprConst ir)"

definition evalProp :: "gState \<Rightarrow> propc \<Rightarrow> bool" where
  "evalProp g p \<longleftrightarrow> exprArith g emptyProc (propConv p) \<noteq> 0"

definition printProp 
  :: "(integer \<Rightarrow> char list) \<Rightarrow> propc \<Rightarrow> char list"
where
  "printProp f p = printExpr f (propConv p)" 

text {* Find all propositions in an LTL formula and give each a unique ID. *}
primrec ltlPropcs' :: "propc ltlc \<Rightarrow> propc list \<Rightarrow> propc list"
where
  "ltlPropcs' LTLcTrue l = l"
| "ltlPropcs' LTLcFalse l = l"
| "ltlPropcs' (LTLcProp p) l = p#l"
| "ltlPropcs' (LTLcNeg x) l = ltlPropcs' x l"
| "ltlPropcs' (LTLcNext x) l = ltlPropcs' x l"
| "ltlPropcs' (LTLcFinal x) l = ltlPropcs' x l"
| "ltlPropcs' (LTLcGlobal x) l = ltlPropcs' x l"
| "ltlPropcs' (LTLcAnd x y) l = ltlPropcs' y (ltlPropcs' x l)"
| "ltlPropcs' (LTLcOr x y) l = ltlPropcs' y (ltlPropcs' x l)"
| "ltlPropcs' (LTLcImplies x y) l = ltlPropcs' y (ltlPropcs' x l)"
| "ltlPropcs' (LTLcIff x y) l = ltlPropcs' y (ltlPropcs' x l)"
| "ltlPropcs' (LTLcUntil x y) l = ltlPropcs' y (ltlPropcs' x l)"
| "ltlPropcs' (LTLcRelease x y) l = ltlPropcs' y (ltlPropcs' x l)"

definition ltlPropcs :: "propc ltlc \<Rightarrow> (expr,nat) lm" where
  "ltlPropcs p = (let ps = remdups (map propConv (ltlPropcs' p [])) in
                  lm.to_map (zip ps [0..<length ps]))"

definition "propcs_inv m = finite (ran (lm.\<alpha> m))"

lemma ltlPropcs_propcs_inv:
  "propcs_inv (ltlPropcs p)"
unfolding ltlPropcs_def propcs_inv_def
by (simp add: lm.correct ran_distinct)

text {* Then map the formula to talk about those IDs instead of the propositions. *}
primrec ltlConv :: "(expr, nat) lm \<Rightarrow> propc ltlc \<Rightarrow> nat ltlc"
where
  "ltlConv _ LTLcTrue = LTLcTrue"
| "ltlConv _ LTLcFalse = LTLcFalse"
| "ltlConv P (LTLcProp p) = LTLcProp (the (lm.lookup (propConv p) P))"
| "ltlConv P (LTLcNeg x) = LTLcNeg (ltlConv P x)"
| "ltlConv P (LTLcNext x) = LTLcNext (ltlConv P x)"
| "ltlConv P (LTLcFinal x) = LTLcFinal (ltlConv P x)"
| "ltlConv P (LTLcGlobal x) = LTLcGlobal (ltlConv P x)"
| "ltlConv P (LTLcAnd x y) = LTLcAnd (ltlConv P x) (ltlConv P y)"
| "ltlConv P (LTLcOr x y) = LTLcOr (ltlConv P x) (ltlConv P y)"
| "ltlConv P (LTLcImplies x y) = LTLcImplies (ltlConv P x) (ltlConv P y)"
| "ltlConv P (LTLcIff x y) = LTLcIff (ltlConv P x) (ltlConv P y)"
| "ltlConv P (LTLcUntil x y) = LTLcUntil (ltlConv P x) (ltlConv P y)"
| "ltlConv P (LTLcRelease x y) = LTLcRelease (ltlConv P x) (ltlConv P y)"

subsection {* Promela integration *}

type_synonym config = "bitset \<times> gState"
type_synonym promela = "program \<times> (expr, nat) lm"

definition lm_filter where
  "lm_filter P m = 
     lm.iterate m (\<lambda>(k,v) \<sigma>.
                     if P k then bs_insert v \<sigma> else \<sigma>
                  ) (bs_empty())"

lemma lm_filter_correct:
  "bs_\<alpha> (lm_filter P m) = {v. \<exists>k. P k \<and> lm.\<alpha> m k = Some v}"
  unfolding lm_filter_def
  by (rule lm.iterate_rule_insert_P[where 
           I="\<lambda>S \<sigma>. bs_\<alpha> \<sigma> = {v | k v. (k,v) \<in> S \<and> P k}"]) 
     (auto simp add: lm.correct map_to_set_def)

definition validPropcs :: "gState \<Rightarrow> (expr, nat) lm \<Rightarrow> bitset" where
  "validPropcs g P = lm_filter (\<lambda>e. exprArith g emptyProc e \<noteq> 0) P"

lemma validPropcs_correct:
  "bs_\<alpha> (validPropcs g P) = 
     {v. \<exists>k. exprArith g emptyProc k \<noteq> 0 \<and> lm.\<alpha> P k = Some v}"
unfolding validPropcs_def
by (metis lm_filter_correct)

lemma validPropcs_ran:
  "bs_\<alpha> (validPropcs g P) \<subseteq> ran (lm.\<alpha> P)"
unfolding validPropcs_correct ran_def
by auto

text {* Now lift the successor function of Promela proper (@{const Promela.nexts}). *}

definition nexts :: "promela \<Rightarrow> config \<Rightarrow> config ls nres" where
  "nexts prom c = ( 
           let (prog, P) = prom in
           Promela.nexts prog (\<lambda>g. (validPropcs g P,g)) (snd c))"

lemma nexts_SPEC:
  assumes "gState_inv prog g"
  and "program_inv prog"
  shows "nexts (prog,P) (ps,g) 
  \<le> SPEC (\<lambda>gs. \<forall>(ps',g') \<in> ls.\<alpha> gs. 
                 (g,g') \<in> gState_progress_rel prog 
               \<and> bs_\<alpha> ps' \<subseteq> ran (lm.\<alpha> P))"
using assms
unfolding nexts_def
apply (refine_rcg refine_vcg)
  apply (rule order_trans[OF Promela.nexts_SPEC[where 
           I="\<lambda>(ps,g) (ps',g'). 
                  (g,g') \<in> gState_progress_rel prog 
                \<and> ps = validPropcs g P 
                \<and> bs_\<alpha> ps' \<subseteq> ran (lm.\<alpha> P)"]])
  apply (auto simp add: validPropcs_ran)
 done

subsubsection {* Handle non-termination *}

text {* 
  A Promela model may include non-terminating parts. Therefore we cannot guarantee, that @{const nexts} will actually terminate.
  To avoid having to deal with this in the model checker, we fail in case of non-termination.
*}

(* TODO: Integrate such a concept into refine_transfer! *)
definition SUCCEED_abort where
  "SUCCEED_abort msg dm m = ( 
     case m of 
       RES X \<Rightarrow> if X={} then Code.abort msg (\<lambda>_. dm) else RES X
     | _ \<Rightarrow> m)"


definition dSUCCEED_abort where
  "dSUCCEED_abort msg dm m = (
     case m of 
       dSUCCEEDi \<Rightarrow> Code.abort msg (\<lambda>_. dm)
     | _ \<Rightarrow> m)"

definition ref_succeed where 
  "ref_succeed m m' \<longleftrightarrow> m \<le> m' \<and> (m=SUCCEED \<longrightarrow> m'=SUCCEED)"

lemma dSUCCEED_abort_SUCCEED_abort:
   "\<lbrakk> RETURN dm' \<le> dm; ref_succeed (nres_of m') m \<rbrakk> 
       \<Longrightarrow> nres_of (dSUCCEED_abort msg (dRETURN dm') (m')) 
           \<le> SUCCEED_abort msg dm m"
unfolding dSUCCEED_abort_def SUCCEED_abort_def ref_succeed_def
by (auto split: dres.splits nres.splits)

schematic_lemma nexts_code_aux:
  "nres_of (?nexts prog g) \<le> nexts prog g"
  unfolding nexts_def
  by (refine_transfer Promela.nexts_code.refine the_resI)

concrete_definition nexts_code_aux for prog g uses nexts_code_aux

text {* The final successor function now incorporates:
  \begin{enumerate}
    \item @{const Promela.nexts}
    \item handling of the LTL propositions (cf. @{const PromelaLTL.nexts})
    \item handling of non-termination
  \end{enumerate} *}
definition nexts_code where 
  "nexts_code prog g = 
     the_res (dSUCCEED_abort (STR ''The Universe is broken!'') 
                             (dRETURN (ls.sng g)) 
                             (nexts_code_aux prog g))"

lemma nexts_code_SPEC:
  assumes "gState_inv prog g"
  and "program_inv prog"
  and "bs_\<alpha> ps \<subseteq> ran (lm.\<alpha> P)"
  shows "(ps',g') \<in> ls.\<alpha> (nexts_code (prog,P) (ps,g)) 
         \<Longrightarrow> (g,g') \<in> gState_progress_rel prog \<and> bs_\<alpha> ps' \<subseteq> ran (lm.\<alpha> P)"
unfolding nexts_code_def
unfolding dSUCCEED_abort_def
using assms
using order_trans[OF nexts_code_aux.refine nexts_SPEC[OF assms(1,2)], of P ps]
by (auto split: dres.splits simp: ls.correct)

subsection {* Finiteness of the state space *}

inductive_set reachable_configs
  for P :: promela
  and c\<^sub>s :: config -- "start configuration"
where
"c\<^sub>s \<in> reachable_configs P c\<^sub>s" |
"c \<in> reachable_configs P c\<^sub>s \<Longrightarrow> x \<in> ls.\<alpha> (nexts_code P c) 
                               \<Longrightarrow> x \<in> reachable_configs P c\<^sub>s"

lemmas reachable_configs_induct[case_names init step] = 
  reachable_configs.induct[split_format (complete)]

definition promela_inv where
  "promela_inv prom = (case prom of (prog,P) \<Rightarrow> program_inv prog \<and> propcs_inv P)"
definition config_inv where 
  "config_inv prom c = (
     case c of (ps,g) \<Rightarrow> case prom of (prog, P) \<Rightarrow> 
       gState_inv prog g \<and> bs_\<alpha> ps \<subseteq> ran (lm.\<alpha> P))"

lemma reachable_configs_finite:
  assumes "promela_inv prom"
  and "config_inv prom c"
  shows "finite (reachable_configs prom c)"
proof (rule finite_subset)
  obtain prog P where [simp, intro!]: "prom = (prog,P)" by (metis prod.exhaust)
  obtain g ps where [simp, intro!]: "c = (ps,g)" by (metis prod.exhaust)

  from assms have I: "program_inv prog" "propcs_inv P"
                     "gState_inv prog g" "bs_\<alpha> ps \<subseteq> ran (lm.\<alpha> P)"
    by (simp_all add: promela_inv_def config_inv_def)
  
  def INV \<equiv> "\<lambda>(ps',g').  bs_\<alpha> ps' \<subseteq> ran (lm.\<alpha> P) 
                       \<and> g' \<in> (gState_progress_rel prog)\<^sup>* `` {g}  
                       \<and> gState_inv prog g'"

  {
    fix ps' g'
    have "(ps',g') \<in> reachable_configs (prog,P) (ps,g) \<Longrightarrow> INV (ps',g')"
    proof (induct rule: reachable_configs_induct)
      case init with I show ?case by (simp add: INV_def)
    next
      case (step ps g ps' g')
      from step(2,3) have 
        "(g, g') \<in> gState_progress_rel prog \<and> bs_\<alpha> ps' \<subseteq> ran (lm.\<alpha> P)"
        using nexts_code_SPEC[OF _ `program_inv prog`, of g ps P ps' g']
        unfolding INV_def by auto
      thus ?case using step(2) unfolding INV_def by auto
    qed
   }

  thus "reachable_configs prom c \<subseteq> 
        {bs. bs_\<alpha> bs \<subseteq> ran (lm.\<alpha> (snd prom))} 
      \<times> (gState_progress_rel (fst prom))\<^sup>* `` {snd c}"
    unfolding INV_def by auto
  
  note gStates_finite[of prog g]
  moreover have "finite {bs. bs_\<alpha> bs \<subseteq> ran (lm.\<alpha> P)}"
    using [[simproc finite_Collect]]
    apply auto
    apply (intro finite_vimageI)
      apply (simp add: I[unfolded propcs_inv_def])
    apply (metis bs_eq_correct bs_eq_def injI)
    done
  ultimately 
  show "finite ({bs. bs_\<alpha> bs \<subseteq> ran (lm.\<alpha> (snd prom))} 
                \<times> (gState_progress_rel (fst prom))\<^sup>* `` {snd c})"
    by simp
qed

definition promela_E :: "promela \<Rightarrow> (config \<times> config) set"
  -- "Transition relation of a promela program"
where
  "promela_E prom \<equiv> {(c,c'). c' \<in> ls.\<alpha> (nexts_code prom c)}"

definition promela_is_run :: "promela \<times> config \<Rightarrow> config word \<Rightarrow> bool"
  -- "Predicate defining runs of promela programs"
where
  "promela_is_run promc r \<equiv> 
      let (prom,c)=promc in 
           r 0 = c 
        \<and> (\<forall>i. r (Suc i) \<in> ls.\<alpha> (nexts_code prom (r i)))"

definition promela_props :: "config \<Rightarrow> nat set" 
where
  [code_unfold]: "promela_props = bs_\<alpha> \<circ> fst"

definition promela_language :: "promela \<times> config \<Rightarrow> nat set word set" where
  "promela_language promc \<equiv> {promela_props \<circ> r | r. promela_is_run promc r}"

text {*
Prepare the AST for the Promela interpreter.

This takes as arguments:
  \begin{itemize}
   \item Function to return the ltl formula $\phi$. This function gets passed a lookup onto the LTLs defined in the code.
   \item AST of the promela code
  \end{itemize}

Returns:
  \begin{itemize}
   \item Program representation (@{typ promela})
   \item Initial configuration  (@{typ config})
   \item LTL representation to use (@{typ "nat ltlc"})
  \end{itemize}
*}

definition prepare 
  :: "((String.literal \<Rightarrow> String.literal option) \<Rightarrow> propc ltlc)
      \<Rightarrow> AST.module list 
      \<Rightarrow> (promela \<times> config) \<times> nat ltlc"
where 
  "prepare ltlChoose ast = (
      let
         _ = PromelaStatistics.start();
         eAst = preprocess ast;
         (ltls,g\<^sub>0,prog) = Promela.setUp eAst;
         \<phi> = ltlChoose (\<lambda>l. lm.lookup l ltls);
         P = ltlPropcs \<phi>;
         \<phi>\<^sub>c = ltlConv P \<phi>;
         ps\<^sub>0 = validPropcs g\<^sub>0 P;
         _ = PromelaStatistics.stop_timer()
      in
      (((prog, P), (ps\<^sub>0, g\<^sub>0)), \<phi>\<^sub>c))"

lemma prepare_correct':
  assumes "prepare ltlChoose ast = (((prog,P), (ps\<^sub>0, g\<^sub>0)), \<phi>\<^sub>c)"
  shows "program_inv prog"
    and "propcs_inv P"
    and "bs_\<alpha> ps\<^sub>0 \<subseteq> ran (lm.\<alpha> P)"
    and "gState_inv prog g\<^sub>0"
using assms setUp_program_inv setUp_gState_inv 
      ltlPropcs_propcs_inv validPropcs_ran[of g\<^sub>0 P]
unfolding prepare_def
by (auto split: prod.splits)

lemma prepare_connect:
  assumes "prepare ltlChoose ast = ((prom, c\<^sub>0), \<phi>\<^sub>c)"
  shows "promela_inv prom" and "config_inv prom c\<^sub>0"
using prepare_correct'[of ltlChoose ast] assms
  apply (force simp add: promela_inv_def split: prod.splits)
using  prepare_correct'[of ltlChoose ast] assms
  apply (force simp add: config_inv_def split: prod.splits)
  done

definition printConfig 
  :: "(integer \<Rightarrow> string) \<Rightarrow> promela \<Rightarrow> config option \<Rightarrow> config \<Rightarrow> string" 
where
  "printConfig f prom c\<^sub>0 c\<^sub>1 = Promela.printConfig f (fst prom) (map_option snd c\<^sub>0) (snd c\<^sub>1)"

export_code nexts_code printConfig prepare checking SML

(* from PromelaDatastructures *)
hide_const (open) abort abort' abortv 
                  err err' errv
                  usc usc'
                  warn the_warn with_warn
end
