section\<open>Well-founded relation on names\<close>
theory FrecR
  imports
    Transitive_Models.Discipline_Function
    Edrel
begin

text\<open>\<^term>\<open>frecR\<close> is the well-founded relation on names that allows
us to define forcing for atomic formulas.\<close>

definition
  ftype :: "i\<Rightarrow>i" where
  "ftype \<equiv> fst"

definition
  name1 :: "i\<Rightarrow>i" where
  "name1(x) \<equiv> fst(snd(x))"

definition
  name2 :: "i\<Rightarrow>i" where
  "name2(x) \<equiv> fst(snd(snd(x)))"

definition
  cond_of :: "i\<Rightarrow>i" where
  "cond_of(x) \<equiv> snd(snd(snd((x))))"

lemma components_simp:
  "ftype(\<langle>f,n1,n2,c\<rangle>) = f"
  "name1(\<langle>f,n1,n2,c\<rangle>) = n1"
  "name2(\<langle>f,n1,n2,c\<rangle>) = n2"
  "cond_of(\<langle>f,n1,n2,c\<rangle>) = c"
  unfolding ftype_def name1_def name2_def cond_of_def
  by simp_all

definition eclose_n :: "[i\<Rightarrow>i,i] \<Rightarrow> i" where
  "eclose_n(name,x) = eclose({name(x)})"

definition
  ecloseN :: "i \<Rightarrow> i" where
  "ecloseN(x) = eclose_n(name1,x) \<union> eclose_n(name2,x)"

lemma components_in_eclose :
  "n1 \<in> ecloseN(\<langle>f,n1,n2,c\<rangle>)"
  "n2 \<in> ecloseN(\<langle>f,n1,n2,c\<rangle>)"
  unfolding ecloseN_def eclose_n_def
  using components_simp arg_into_eclose by auto

lemmas names_simp = components_simp(2) components_simp(3)

lemma ecloseNI1 :
  assumes "x \<in> eclose(n1) \<or> x\<in>eclose(n2)"
  shows "x \<in> ecloseN(\<langle>f,n1,n2,c\<rangle>)"
  unfolding ecloseN_def eclose_n_def
  using assms eclose_sing names_simp
  by auto

lemmas ecloseNI = ecloseNI1

lemma ecloseN_mono :
  assumes "u \<in> ecloseN(x)" "name1(x) \<in> ecloseN(y)" "name2(x) \<in> ecloseN(y)"
  shows "u \<in> ecloseN(y)"
proof -
  from \<open>u\<in>_\<close>
  consider (a) "u\<in>eclose({name1(x)})" | (b) "u \<in> eclose({name2(x)})"
    unfolding ecloseN_def  eclose_n_def by auto
  then
  show ?thesis
  proof cases
    case a
    with \<open>name1(x) \<in> _\<close>
    show ?thesis
      unfolding ecloseN_def  eclose_n_def
      using eclose_singE[OF a] mem_eclose_trans[of u "name1(x)" ] by auto
  next
    case b
    with \<open>name2(x) \<in> _\<close>
    show ?thesis
      unfolding ecloseN_def eclose_n_def
      using eclose_singE[OF b] mem_eclose_trans[of u "name2(x)"] by auto
  qed
qed

definition
  is_ftype :: "(i\<Rightarrow>o)\<Rightarrow>i\<Rightarrow>i\<Rightarrow>o" where
  "is_ftype \<equiv> is_fst"

definition
  ftype_fm :: "[i,i] \<Rightarrow> i" where
  "ftype_fm \<equiv> fst_fm"

lemma is_ftype_iff_sats [iff_sats]:
  assumes
    "nth(a,env) = x" "nth(b,env) = y" "a\<in>nat" "b\<in>nat" "env \<in> list(A)"
  shows
    "is_ftype(##A,x,y)  \<longleftrightarrow> sats(A,ftype_fm(a,b), env)"
  unfolding ftype_fm_def is_ftype_def
  using assms sats_fst_fm
  by simp

definition
  is_name1 :: "(i\<Rightarrow>o)\<Rightarrow>i\<Rightarrow>i\<Rightarrow>o" where
  "is_name1(M,x,t2) \<equiv> is_hcomp(M,is_fst(M),is_snd(M),x,t2)"

definition
  name1_fm :: "[i,i] \<Rightarrow> i" where
  "name1_fm(x,t) \<equiv> hcomp_fm(fst_fm,snd_fm,x,t)"

lemma sats_name1_fm [simp]:
  "\<lbrakk> x \<in> nat; y \<in> nat;env \<in> list(A) \<rbrakk> \<Longrightarrow>
    (A, env \<Turnstile> name1_fm(x,y)) \<longleftrightarrow> is_name1(##A, nth(x,env), nth(y,env))"
  unfolding name1_fm_def is_name1_def
  using sats_fst_fm sats_snd_fm sats_hcomp_fm[of A "is_fst(##A)" _ fst_fm "is_snd(##A)"]
  by simp

lemma is_name1_iff_sats [iff_sats]:
  assumes
    "nth(a,env) = x" "nth(b,env) = y" "a\<in>nat" "b\<in>nat" "env \<in> list(A)"
  shows
    "is_name1(##A,x,y)  \<longleftrightarrow> A , env \<Turnstile> name1_fm(a,b)"
  using assms sats_name1_fm
  by simp

definition
  is_snd_snd :: "(i\<Rightarrow>o)\<Rightarrow>i\<Rightarrow>i\<Rightarrow>o" where
  "is_snd_snd(M,x,t) \<equiv> is_hcomp(M,is_snd(M),is_snd(M),x,t)"

definition
  snd_snd_fm :: "[i,i]\<Rightarrow>i" where
  "snd_snd_fm(x,t) \<equiv> hcomp_fm(snd_fm,snd_fm,x,t)"

lemma sats_snd2_fm [simp]:
  "\<lbrakk> x \<in> nat; y \<in> nat;env \<in> list(A) \<rbrakk> \<Longrightarrow>
    (A, env  \<Turnstile> snd_snd_fm(x,y)) \<longleftrightarrow> is_snd_snd(##A, nth(x,env), nth(y,env))"
  unfolding snd_snd_fm_def is_snd_snd_def
  using sats_snd_fm sats_hcomp_fm[of A "is_snd(##A)" _ snd_fm "is_snd(##A)"]
  by simp

definition
  is_name2 :: "(i\<Rightarrow>o)\<Rightarrow>i\<Rightarrow>i\<Rightarrow>o" where
  "is_name2(M,x,t3) \<equiv> is_hcomp(M,is_fst(M),is_snd_snd(M),x,t3)"

definition
  name2_fm :: "[i,i] \<Rightarrow> i" where
  "name2_fm(x,t3) \<equiv> hcomp_fm(fst_fm,snd_snd_fm,x,t3)"

lemma sats_name2_fm :
  "\<lbrakk> x \<in> nat; y \<in> nat;env \<in> list(A) \<rbrakk>
    \<Longrightarrow> (A , env \<Turnstile> name2_fm(x,y)) \<longleftrightarrow> is_name2(##A, nth(x,env), nth(y,env))"
  unfolding name2_fm_def is_name2_def
  using sats_fst_fm sats_snd2_fm sats_hcomp_fm[of A "is_fst(##A)" _ fst_fm "is_snd_snd(##A)"]
  by simp

lemma is_name2_iff_sats [iff_sats]:
  assumes
    "nth(a,env) = x" "nth(b,env) = y" "a\<in>nat" "b\<in>nat" "env \<in> list(A)"
  shows
    "is_name2(##A,x,y)  \<longleftrightarrow> A, env \<Turnstile> name2_fm(a,b)"
  using assms sats_name2_fm
  by simp

definition
  is_cond_of :: "(i\<Rightarrow>o)\<Rightarrow>i\<Rightarrow>i\<Rightarrow>o" where
  "is_cond_of(M,x,t4) \<equiv> is_hcomp(M,is_snd(M),is_snd_snd(M),x,t4)"

definition
  cond_of_fm :: "[i,i] \<Rightarrow> i" where
  "cond_of_fm(x,t4) \<equiv> hcomp_fm(snd_fm,snd_snd_fm,x,t4)"

lemma sats_cond_of_fm :
  "\<lbrakk> x \<in> nat; y \<in> nat;env \<in> list(A) \<rbrakk> \<Longrightarrow>
    (A, env \<Turnstile> cond_of_fm(x,y)) \<longleftrightarrow> is_cond_of(##A, nth(x,env), nth(y,env))"
  unfolding cond_of_fm_def is_cond_of_def
  using sats_snd_fm sats_snd2_fm sats_hcomp_fm[of A "is_snd(##A)" _ snd_fm "is_snd_snd(##A)"]
  by simp

lemma is_cond_of_iff_sats [iff_sats]:
  assumes
    "nth(a,env) = x" "nth(b,env) = y" "a\<in>nat" "b\<in>nat" "env \<in> list(A)"
  shows
    "is_cond_of(##A,x,y) \<longleftrightarrow> A, env \<Turnstile> cond_of_fm(a,b)"
  using assms sats_cond_of_fm
  by simp

lemma components_type[TC] :
  assumes "a\<in>nat" "b\<in>nat"
  shows
    "ftype_fm(a,b)\<in>formula"
    "name1_fm(a,b)\<in>formula"
    "name2_fm(a,b)\<in>formula"
    "cond_of_fm(a,b)\<in>formula"
  using assms
  unfolding ftype_fm_def fst_fm_def snd_fm_def snd_snd_fm_def name1_fm_def name2_fm_def
    cond_of_fm_def hcomp_fm_def
  by simp_all

lemmas components_iff_sats = is_ftype_iff_sats is_name1_iff_sats is_name2_iff_sats
  is_cond_of_iff_sats

lemmas components_defs = ftype_fm_def snd_snd_fm_def hcomp_fm_def
  name1_fm_def name2_fm_def cond_of_fm_def

definition
  is_eclose_n :: "[i\<Rightarrow>o,[i\<Rightarrow>o,i,i]\<Rightarrow>o,i,i] \<Rightarrow> o" where
  "is_eclose_n(N,is_name,en,t) \<equiv>
        \<exists>n1[N].\<exists>s1[N]. is_name(N,t,n1) \<and> is_singleton(N,n1,s1) \<and> is_eclose(N,s1,en)"

definition
  eclose_n1_fm :: "[i,i] \<Rightarrow> i" where
  "eclose_n1_fm(m,t) \<equiv> Exists(Exists(And(And(name1_fm(t+\<^sub>\<omega>2,0),singleton_fm(0,1)),
                                       is_eclose_fm(1,m+\<^sub>\<omega>2))))"

definition
  eclose_n2_fm :: "[i,i] \<Rightarrow> i" where
  "eclose_n2_fm(m,t) \<equiv> Exists(Exists(And(And(name2_fm(t+\<^sub>\<omega>2,0),singleton_fm(0,1)),
                                       is_eclose_fm(1,m+\<^sub>\<omega>2))))"

definition
  is_ecloseN :: "[i\<Rightarrow>o,i,i] \<Rightarrow> o" where
  "is_ecloseN(N,t,en) \<equiv> \<exists>en1[N].\<exists>en2[N].
                is_eclose_n(N,is_name1,en1,t) \<and> is_eclose_n(N,is_name2,en2,t)\<and>
                union(N,en1,en2,en)"

definition
  ecloseN_fm :: "[i,i] \<Rightarrow> i" where
  "ecloseN_fm(en,t) \<equiv> Exists(Exists(And(eclose_n1_fm(1,t+\<^sub>\<omega>2),
                            And(eclose_n2_fm(0,t+\<^sub>\<omega>2),union_fm(1,0,en+\<^sub>\<omega>2)))))"

lemma ecloseN_fm_type [TC] :
  "\<lbrakk> en \<in> nat ; t \<in> nat \<rbrakk> \<Longrightarrow> ecloseN_fm(en,t) \<in> formula"
  unfolding ecloseN_fm_def eclose_n1_fm_def eclose_n2_fm_def by simp

lemma sats_ecloseN_fm [simp]:
  "\<lbrakk> en \<in> nat; t \<in> nat ; env \<in> list(A) \<rbrakk>
    \<Longrightarrow> (A, env \<Turnstile> ecloseN_fm(en,t)) \<longleftrightarrow> is_ecloseN(##A,nth(t,env),nth(en,env))"
  unfolding ecloseN_fm_def is_ecloseN_def eclose_n1_fm_def eclose_n2_fm_def is_eclose_n_def
  using nth_0 nth_ConsI sats_name1_fm sats_name2_fm singleton_iff_sats[symmetric]
  by auto

lemma is_ecloseN_iff_sats [iff_sats]:
  "\<lbrakk> nth(en, env) = ena; nth(t, env) = ta; en \<in> nat; t \<in> nat ; env \<in> list(A) \<rbrakk>
    \<Longrightarrow> is_ecloseN(##A,ta,ena) \<longleftrightarrow> A, env \<Turnstile> ecloseN_fm(en,t)"
  by simp

(* Relation of forces *)
definition
  frecR :: "i \<Rightarrow> i \<Rightarrow> o" where
  "frecR(x,y) \<equiv>
    (ftype(x) = 1 \<and> ftype(y) = 0
      \<and> (name1(x) \<in> domain(name1(y)) \<union> domain(name2(y)) \<and> (name2(x) = name1(y) \<or> name2(x) = name2(y))))
   \<or> (ftype(x) = 0 \<and> ftype(y) =  1 \<and> name1(x) = name1(y) \<and> name2(x) \<in> domain(name2(y)))"

lemma frecR_ftypeD :
  assumes "frecR(x,y)"
  shows "(ftype(x) = 0 \<and> ftype(y) = 1) \<or> (ftype(x) = 1 \<and> ftype(y) = 0)"
  using assms unfolding frecR_def by auto

lemma frecRI1: "s \<in> domain(n1) \<or> s \<in> domain(n2) \<Longrightarrow> frecR(\<langle>1, s, n1, q\<rangle>, \<langle>0, n1, n2, q'\<rangle>)"
  unfolding frecR_def by (simp add:components_simp)

lemma frecRI1': "s \<in> domain(n1) \<union> domain(n2) \<Longrightarrow> frecR(\<langle>1, s, n1, q\<rangle>, \<langle>0, n1, n2, q'\<rangle>)"
  unfolding frecR_def by (simp add:components_simp)

lemma frecRI2: "s \<in> domain(n1) \<or> s \<in> domain(n2) \<Longrightarrow> frecR(\<langle>1, s, n2, q\<rangle>, \<langle>0, n1, n2, q'\<rangle>)"
  unfolding frecR_def by (simp add:components_simp)

lemma frecRI2': "s \<in> domain(n1) \<union> domain(n2) \<Longrightarrow> frecR(\<langle>1, s, n2, q\<rangle>, \<langle>0, n1, n2, q'\<rangle>)"
  unfolding frecR_def by (simp add:components_simp)

lemma frecRI3: "\<langle>s, r\<rangle> \<in> n2 \<Longrightarrow> frecR(\<langle>0, n1, s, q\<rangle>, \<langle>1, n1, n2, q'\<rangle>)"
  unfolding frecR_def by (auto simp add:components_simp)

lemma frecRI3': "s \<in> domain(n2) \<Longrightarrow> frecR(\<langle>0, n1, s, q\<rangle>, \<langle>1, n1, n2, q'\<rangle>)"
  unfolding frecR_def by (auto simp add:components_simp)

lemma frecR_D1 :
  "frecR(x,y) \<Longrightarrow> ftype(y) = 0 \<Longrightarrow> ftype(x) = 1 \<and>
      (name1(x) \<in> domain(name1(y)) \<union> domain(name2(y)) \<and> (name2(x) = name1(y) \<or> name2(x) = name2(y)))"
  unfolding frecR_def
  by auto

lemma frecR_D2 :
  "frecR(x,y) \<Longrightarrow> ftype(y) = 1 \<Longrightarrow> ftype(x) = 0 \<and>
      ftype(x) = 0 \<and> ftype(y) =  1 \<and> name1(x) = name1(y) \<and> name2(x) \<in> domain(name2(y))"
  unfolding frecR_def
  by auto

lemma frecR_DI :
  assumes "frecR(\<langle>a,b,c,d\<rangle>,\<langle>ftype(y),name1(y),name2(y),cond_of(y)\<rangle>)"
  shows "frecR(\<langle>a,b,c,d\<rangle>,y)"
  using assms
  unfolding frecR_def
  by (force simp add:components_simp)

reldb_add "ftype" "is_ftype"
reldb_add "name1" "is_name1"
reldb_add "name2" "is_name2"

relativize "frecR" "is_frecR"

schematic_goal sats_frecR_fm_auto:
  assumes
    "i\<in>nat" "j\<in>nat" "env\<in>list(A)"
  shows
    "is_frecR(##A,nth(i,env),nth(j,env)) \<longleftrightarrow> A, env \<Turnstile> ?fr_fm(i,j)"
  unfolding is_frecR_def
  by (insert assms ; (rule sep_rules' cartprod_iff_sats components_iff_sats
        | simp del:sats_cartprod_fm)+)

synthesize "frecR" from_schematic sats_frecR_fm_auto

text\<open>Third item of Kunen's observations (p. 257) about the trcl relation.\<close>
lemma eq_ftypep_not_frecrR:
  assumes "ftype(x) = ftype(y)"
  shows "\<not> frecR(x,y)"
  using assms frecR_ftypeD by force

definition
  rank_names :: "i \<Rightarrow> i" where
  "rank_names(x) \<equiv> max(rank(name1(x)),rank(name2(x)))"

lemma rank_names_types [TC]:
  shows "Ord(rank_names(x))"
  unfolding rank_names_def max_def using Ord_rank Ord_Un by auto

definition
  mtype_form :: "i \<Rightarrow> i" where
  "mtype_form(x) \<equiv> if rank(name1(x)) < rank(name2(x)) then 0 else 2"

definition
  type_form :: "i \<Rightarrow> i" where
  "type_form(x) \<equiv> if ftype(x) = 0 then 1 else mtype_form(x)"

lemma type_form_tc [TC]:
  shows "type_form(x) \<in> 3"
  unfolding type_form_def mtype_form_def by auto

lemma frecR_le_rnk_names :
  assumes  "frecR(x,y)"
  shows "rank_names(x)\<le>rank_names(y)"
proof -
  obtain a b c d where
    H: "a = name1(x)" "b = name2(x)"
    "c = name1(y)" "d = name2(y)"
    "(a \<in> domain(c)\<union>domain(d) \<and> (b=c \<or> b = d)) \<or> (a = c \<and> b \<in> domain(d))"
    using assms
    unfolding frecR_def
    by force
  then
  consider
    (m) "a \<in> domain(c) \<and> (b = c \<or> b = d) "
    | (n) "a \<in> domain(d) \<and> (b = c \<or> b = d)"
    | (o) "b \<in> domain(d) \<and> a = c"
    by auto
  then
  show ?thesis
  proof(cases)
    case m
    then
    have "rank(a) < rank(c)"
      using eclose_rank_lt  in_dom_in_eclose
      by simp
    with \<open>rank(a) < rank(c)\<close> H m
    show ?thesis
      unfolding rank_names_def
      using Ord_rank max_cong max_cong2 leI
      by auto
  next
    case n
    then
    have "rank(a) < rank(d)"
      using eclose_rank_lt in_dom_in_eclose
      by simp
    with \<open>rank(a) < rank(d)\<close> H n
    show ?thesis
      unfolding rank_names_def
      using Ord_rank max_cong2 max_cong max_commutes[of "rank(c)" "rank(d)"] leI
      by auto
  next
    case o
    then
    have "rank(b) < rank(d)" (is "?b < ?d") "rank(a) = rank(c)" (is "?a = _")
      using eclose_rank_lt in_dom_in_eclose
      by simp_all
    with H
    show ?thesis
      unfolding rank_names_def
      using Ord_rank max_commutes max_cong2[OF leI[OF \<open>?b < ?d\<close>], of ?a]
      by simp
  qed
qed

definition
  \<Gamma> :: "i \<Rightarrow> i" where
  "\<Gamma>(x) = 3 ** rank_names(x) ++ type_form(x)"

lemma \<Gamma>_type [TC]:
  shows "Ord(\<Gamma>(x))"
  unfolding \<Gamma>_def by simp

lemma \<Gamma>_mono :
  assumes "frecR(x,y)"
  shows "\<Gamma>(x) < \<Gamma>(y)"
proof -
  have F: "type_form(x) < 3" "type_form(y) < 3"
    using ltI
    by simp_all
  from assms
  have A: "rank_names(x) \<le> rank_names(y)" (is "?x \<le> ?y")
    using frecR_le_rnk_names
    by simp
  then
  have "Ord(?y)"
    unfolding rank_names_def
    using Ord_rank max_def
    by simp
  note leE[OF \<open>?x\<le>?y\<close>]
  then
  show ?thesis
  proof(cases)
    case 1
    then
    show ?thesis
      unfolding \<Gamma>_def
      using oadd_lt_mono2 \<open>?x < ?y\<close> F
      by auto
  next
    case 2
    consider (a) "ftype(x) = 0 \<and> ftype(y) = 1" | (b) "ftype(x) = 1 \<and> ftype(y) = 0"
      using frecR_ftypeD[OF \<open>frecR(x,y)\<close>]
      by auto
    then show ?thesis
    proof(cases)
      case b
      moreover from this
      have "type_form(y) = 1"
        using type_form_def by simp
      moreover from calculation
      have "name2(x) = name1(y) \<or> name2(x) = name2(y) "  (is "?\<tau> = ?\<sigma>' \<or> ?\<tau> = ?\<tau>'")
        "name1(x) \<in> domain(name1(y)) \<union> domain(name2(y))" (is "?\<sigma> \<in> domain(?\<sigma>') \<union> domain(?\<tau>')")
        using assms unfolding type_form_def frecR_def by auto
      moreover from calculation
      have E: "rank(?\<tau>) = rank(?\<sigma>') \<or> rank(?\<tau>) = rank(?\<tau>')" by auto
      from calculation
      consider (c) "rank(?\<sigma>) < rank(?\<sigma>')" |  (d) "rank(?\<sigma>) < rank(?\<tau>')"
        using eclose_rank_lt in_dom_in_eclose by force
      then
      have "rank(?\<sigma>) < rank(?\<tau>)"
      proof (cases)
        case c
        with \<open>rank_names(x) = rank_names(y) \<close>
        show ?thesis
          unfolding rank_names_def mtype_form_def type_form_def
          using max_D2[OF E c] E assms Ord_rank
          by simp
      next
        case d
        with \<open>rank_names(x) = rank_names(y) \<close>
        show ?thesis
          unfolding rank_names_def mtype_form_def type_form_def
          using max_D2[OF _ d] max_commutes E assms Ord_rank disj_commute
          by simp
      qed
      with b
      have "type_form(x) = 0" unfolding type_form_def mtype_form_def by simp
      with \<open>rank_names(x) = rank_names(y) \<close> \<open>type_form(y) = 1\<close> \<open>type_form(x) = 0\<close>
      show ?thesis
        unfolding \<Gamma>_def by auto
    next
      case a
      then
      have "name1(x) = name1(y)" (is "?\<sigma> = ?\<sigma>'")
        "name2(x) \<in> domain(name2(y))" (is "?\<tau> \<in> domain(?\<tau>')")
        "type_form(x) = 1"
        using assms
        unfolding type_form_def frecR_def
        by auto
      then
      have "rank(?\<sigma>) = rank(?\<sigma>')" "rank(?\<tau>) < rank(?\<tau>')"
        using  eclose_rank_lt in_dom_in_eclose
        by simp_all
      with \<open>rank_names(x) = rank_names(y) \<close>
      have "rank(?\<tau>') \<le> rank(?\<sigma>')"
        using Ord_rank max_D1
        unfolding rank_names_def
        by simp
      with a
      have "type_form(y) = 2"
        unfolding type_form_def mtype_form_def
        using not_lt_iff_le assms
        by simp
      with \<open>rank_names(x) = rank_names(y) \<close> \<open>type_form(y) = 2\<close> \<open>type_form(x) = 1\<close>
      show ?thesis
        unfolding \<Gamma>_def by auto
    qed
  qed
qed

definition
  frecrel :: "i \<Rightarrow> i" where
  "frecrel(A) \<equiv> Rrel(frecR,A)"

lemma frecrelI :
  assumes "x \<in> A" "y\<in>A" "frecR(x,y)"
  shows "\<langle>x,y\<rangle>\<in>frecrel(A)"
  using assms unfolding frecrel_def Rrel_def by auto

lemma frecrelD :
  assumes "\<langle>x,y\<rangle> \<in> frecrel(A1\<times>A2\<times>A3\<times>A4)"
  shows
    "ftype(x) \<in> A1" "ftype(x) \<in> A1"
    "name1(x) \<in> A2" "name1(y) \<in> A2"
    "name2(x) \<in> A3" "name2(x) \<in> A3"
    "cond_of(x) \<in> A4" "cond_of(y) \<in> A4"
    "frecR(x,y)"
  using assms
  unfolding frecrel_def Rrel_def ftype_def by (auto simp add:components_simp)

lemma wf_frecrel :
  shows "wf(frecrel(A))"
proof -
  have "frecrel(A) \<subseteq> measure(A,\<Gamma>)"
    unfolding frecrel_def Rrel_def measure_def
    using \<Gamma>_mono
    by force
  then
  show ?thesis
    using wf_subset wf_measure by auto
qed

lemma core_induction_aux:
  fixes A1 A2 :: "i"
  assumes
    "Transset(A1)"
    "\<And>\<tau> \<theta> p.  p \<in> A2 \<Longrightarrow> \<lbrakk>\<And>q \<sigma>. \<lbrakk> q\<in>A2 ; \<sigma>\<in>domain(\<theta>)\<rbrakk> \<Longrightarrow> Q(0,\<tau>,\<sigma>,q)\<rbrakk> \<Longrightarrow> Q(1,\<tau>,\<theta>,p)"
    "\<And>\<tau> \<theta> p.  p \<in> A2 \<Longrightarrow> \<lbrakk>\<And>q \<sigma>. \<lbrakk> q\<in>A2 ; \<sigma>\<in>domain(\<tau>) \<union> domain(\<theta>)\<rbrakk> \<Longrightarrow> Q(1,\<sigma>,\<tau>,q) \<and> Q(1,\<sigma>,\<theta>,q)\<rbrakk> \<Longrightarrow> Q(0,\<tau>,\<theta>,p)"
  shows "a\<in>2\<times>A1\<times>A1\<times>A2 \<Longrightarrow> Q(ftype(a),name1(a),name2(a),cond_of(a))"
proof (induct a rule:wf_induct[OF wf_frecrel[of "2\<times>A1\<times>A1\<times>A2"]])
  case (1 x)
  let ?\<tau> = "name1(x)"
  let ?\<theta> = "name2(x)"
  let ?D = "2\<times>A1\<times>A1\<times>A2"
  assume "x \<in> ?D"
  then
  have "cond_of(x)\<in>A2"
    by (auto simp add:components_simp)
  from \<open>x\<in>?D\<close>
  consider (eq) "ftype(x)=0" | (mem) "ftype(x)=1"
    by (auto simp add:components_simp)
  then
  show ?case
  proof cases
    case eq
    then
    have "Q(1, \<sigma>, ?\<tau>, q) \<and> Q(1, \<sigma>, ?\<theta>, q)" if "\<sigma> \<in> domain(?\<tau>) \<union> domain(?\<theta>)" and "q\<in>A2" for q \<sigma>
    proof -
      from 1
      have "?\<tau>\<in>A1" "?\<theta>\<in>A1" "?\<tau>\<in>eclose(A1)" "?\<theta>\<in>eclose(A1)"
        using  arg_into_eclose
        by (auto simp add:components_simp)
      moreover from \<open>Transset(A1)\<close> that(1)
      have "\<sigma>\<in>eclose(?\<tau>) \<union> eclose(?\<theta>)"
        using in_dom_in_eclose
        by auto
      then
      have "\<sigma>\<in>A1"
        using mem_eclose_subset[OF \<open>?\<tau>\<in>A1\<close>] mem_eclose_subset[OF \<open>?\<theta>\<in>A1\<close>]
          Transset_eclose_eq_arg[OF \<open>Transset(A1)\<close>]
        by auto
      with \<open>q\<in>A2\<close> \<open>?\<theta> \<in> A1\<close> \<open>cond_of(x)\<in>A2\<close> \<open>?\<tau>\<in>A1\<close>
      have "frecR(\<langle>1, \<sigma>, ?\<tau>, q\<rangle>, x)" (is "frecR(?T,_)")
           "frecR(\<langle>1, \<sigma>, ?\<theta>, q\<rangle>, x)" (is "frecR(?U,_)")
        using frecRI1'[OF that(1)] frecR_DI  \<open>ftype(x) = 0\<close>
          frecRI2'[OF that(1)]
        by (auto simp add:components_simp)
      with \<open>x\<in>?D\<close> \<open>\<sigma>\<in>A1\<close> \<open>q\<in>A2\<close>
      have "\<langle>?T,x\<rangle>\<in> frecrel(?D)" "\<langle>?U,x\<rangle>\<in> frecrel(?D)"
        using frecrelI[of ?T ?D x]  frecrelI[of ?U ?D x]
        by (auto simp add:components_simp)
      with \<open>q\<in>A2\<close> \<open>\<sigma>\<in>A1\<close> \<open>?\<tau>\<in>A1\<close> \<open>?\<theta>\<in>A1\<close>
      have "Q(1, \<sigma>, ?\<tau>, q)"
        using 1
        by (force simp add:components_simp)
      moreover from \<open>q\<in>A2\<close> \<open>\<sigma>\<in>A1\<close> \<open>?\<tau>\<in>A1\<close> \<open>?\<theta>\<in>A1\<close> \<open>\<langle>?U,x\<rangle>\<in> frecrel(?D)\<close>
      have "Q(1, \<sigma>, ?\<theta>, q)"
        using 1 by (force simp add:components_simp)
      ultimately
      show ?thesis
        by simp
    qed
    with assms(3) \<open>ftype(x) = 0\<close> \<open>cond_of(x)\<in>A2\<close>
    show ?thesis
      by auto
  next
    case mem
    have "Q(0, ?\<tau>,  \<sigma>, q)" if "\<sigma> \<in> domain(?\<theta>)" and "q\<in>A2" for q \<sigma>
    proof -
      from 1 assms
      have "?\<tau>\<in>A1" "?\<theta>\<in>A1" "cond_of(x)\<in>A2" "?\<tau>\<in>eclose(A1)" "?\<theta>\<in>eclose(A1)"
        using arg_into_eclose
        by (auto simp add:components_simp)
      with  \<open>Transset(A1)\<close> that(1)
      have "\<sigma>\<in> eclose(?\<theta>)"
        using in_dom_in_eclose
        by auto
      then
      have "\<sigma>\<in>A1"
        using mem_eclose_subset[OF \<open>?\<theta>\<in>A1\<close>] Transset_eclose_eq_arg[OF \<open>Transset(A1)\<close>]
        by auto
      with \<open>q\<in>A2\<close> \<open>?\<theta> \<in> A1\<close> \<open>cond_of(x)\<in>A2\<close> \<open>?\<tau>\<in>A1\<close> \<open>ftype(x) = 1\<close>
      have "frecR(\<langle>0, ?\<tau>, \<sigma>, q\<rangle>, x)" (is "frecR(?T,_)")
        using frecRI3'[OF that(1)] frecR_DI
        by (auto simp add:components_simp)
      with \<open>x\<in>?D\<close> \<open>\<sigma>\<in>A1\<close> \<open>q\<in>A2\<close> \<open>?\<tau>\<in>A1\<close>
      have "\<langle>?T,x\<rangle>\<in> frecrel(?D)" "?T\<in>?D"
        using frecrelI[of ?T ?D x]
        by (auto simp add:components_simp)
      with \<open>q\<in>A2\<close> \<open>\<sigma>\<in>A1\<close> \<open>?\<tau>\<in>A1\<close> \<open>?\<theta>\<in>A1\<close> 1
      show ?thesis
        by (force simp add:components_simp)
    qed
    with assms(2) \<open>ftype(x) = 1\<close> \<open>cond_of(x)\<in>A2\<close>
    show ?thesis
      by auto
  qed
qed

lemma def_frecrel : "frecrel(A) = {z\<in>A\<times>A. \<exists>x y. z = \<langle>x, y\<rangle> \<and> frecR(x,y)}"
  unfolding frecrel_def Rrel_def ..

lemma frecrel_fst_snd:
  "frecrel(A) = {z \<in> A\<times>A .
            ftype(fst(z)) = 1 \<and>
        ftype(snd(z)) = 0 \<and> name1(fst(z)) \<in> domain(name1(snd(z))) \<union> domain(name2(snd(z))) \<and>
            (name2(fst(z)) = name1(snd(z)) \<or> name2(fst(z)) = name2(snd(z)))
          \<or> (ftype(fst(z)) = 0 \<and>
        ftype(snd(z)) = 1 \<and>  name1(fst(z)) = name1(snd(z)) \<and> name2(fst(z)) \<in> domain(name2(snd(z))))}"
  unfolding def_frecrel frecR_def
  by (intro equalityI subsetI CollectI; elim CollectE; auto)

end