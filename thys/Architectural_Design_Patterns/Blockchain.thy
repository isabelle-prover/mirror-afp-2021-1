(* TODOS:
  1) Remove identifier from blockchain.
  2) In closed change pout to bc.
  3) Precondition in closed must have active predicate
  4) change kn to nd
*)
section "A Theory of Blockchain Architectures"

theory Blockchain imports Auxiliary DynamicArchitectures.Dynamic_Architecture_Calculus RF_LTL
begin

subsection "Blockchains"
text {*
  A blockchain itself is modeled as a simple list.
*}

type_synonym 'a BC = "'a list"

abbreviation max_cond:: "('a BC) set \<Rightarrow> 'a BC \<Rightarrow> bool"
  where "max_cond B b \<equiv> b \<in> B \<and> (\<forall>b'\<in>B. length b' \<le> length b)"

no_syntax 
  "_MAX1"     :: "pttrns \<Rightarrow> 'b \<Rightarrow> 'b"           ("(3MAX _./ _)" [0, 10] 10)
  "_MAX"      :: "pttrn \<Rightarrow> 'a set \<Rightarrow> 'b \<Rightarrow> 'b"  ("(3MAX _:_./ _)" [0, 0, 10] 10)
  "_MAX1"     :: "pttrns \<Rightarrow> 'b \<Rightarrow> 'b"           ("(3MAX _./ _)" [0, 10] 10)
  "_MAX"      :: "pttrn \<Rightarrow> 'a set \<Rightarrow> 'b \<Rightarrow> 'b"  ("(3MAX _\<in>_./ _)" [0, 0, 10] 10)

definition MAX:: "('a BC) set \<Rightarrow> 'a BC"
  where "MAX B = (SOME b. max_cond B b)"

lemma max_ex:
  fixes XS::"('a BC) set"
  assumes "XS \<noteq> {}"
    and "finite XS"
  shows "\<exists>xs\<in>XS. (\<forall>ys\<in>XS. length ys \<le> length xs)"
proof (rule Finite_Set.finite_ne_induct)
  show "finite XS" using assms by simp
next
  from assms show "XS \<noteq> {}" by simp
next
  fix x::"'a BC"
  show "\<exists>xs\<in>{x}. \<forall>ys\<in>{x}. length ys \<le> length xs" by simp
next
  fix zs::"'a BC" and F::"('a BC) set"
  assume "finite F" and "F \<noteq> {}" and "zs \<notin> F" and "\<exists>xs\<in>F. \<forall>ys\<in>F. length ys \<le> length xs"
  then obtain xs where "xs\<in>F" and "\<forall>ys\<in>F. length ys \<le> length xs" by auto
  show "\<exists>xs\<in>insert zs F. \<forall>ys\<in>insert zs F. length ys \<le> length xs"
  proof (cases)
    assume "length zs \<ge> length xs"
    with \<open>\<forall>ys\<in>F. length ys \<le> length xs\<close> show ?thesis by auto
  next
    assume "\<not> length zs \<ge> length xs"
    hence "length zs \<le> length xs" by simp
    with \<open>xs \<in> F\<close> show ?thesis using \<open>\<forall>ys\<in>F. length ys \<le> length xs\<close> by auto
  qed
qed

lemma max_prop:
  fixes XS::"('a BC) set"
  assumes "XS \<noteq> {}"
    and "finite XS"
  shows "MAX XS \<in> XS"
    and "\<forall>b'\<in>XS. length b' \<le> length (MAX XS)"
proof -
  from assms have "\<exists>xs\<in>XS. \<forall>ys\<in>XS. length ys \<le> length xs" using max_ex[of XS] by auto
  with MAX_def[of XS] show "MAX XS \<in> XS" and "\<forall>b'\<in>XS. length b' \<le> length (MAX XS)"
    using someI_ex[of "\<lambda>b. b \<in> XS \<and> (\<forall>b'\<in>XS. length b' \<le> length b)"] by auto
qed

lemma max_less:
  fixes b::"'a BC" and b'::"'a BC" and B::"('a BC) set"
  assumes "b\<in>B"
    and "finite B"
    and "length b > length b'"
  shows "length (MAX B) > length b'"
proof -
  from assms have "\<exists>xs\<in>B. \<forall>ys\<in>B. length ys \<le> length xs" using max_ex[of B] by auto
  with MAX_def[of B] have "\<forall>b'\<in>B. length b' \<le> length (MAX B)"
    using someI_ex[of "\<lambda>b. b \<in> B \<and> (\<forall>b'\<in>B. length b' \<le> length b)"] by auto
  with \<open>b\<in>B\<close> have "length b \<le> length (MAX B)" by simp
  with \<open>length b > length b'\<close> show ?thesis by simp
qed

subsection "Blockchain Architectures"
text {*
  In the following we describe the locale for blockchain architectures.
*}

locale Blockchain = dynamic_component cmp active
  for active :: "'nid \<Rightarrow> cnf \<Rightarrow> bool" ("\<parallel>_\<parallel>\<^bsub>_\<^esub>" [0,110]60)
    and cmp :: "'nid \<Rightarrow> cnf \<Rightarrow> 'ND" ("\<sigma>\<^bsub>_\<^esub>(_)" [0,110]60) +
  fixes pin :: "'ND \<Rightarrow> ('nid BC) set"
    and pout :: "'ND \<Rightarrow> 'nid BC"
    and bc :: "'ND \<Rightarrow> 'nid BC"
    and mining :: "'ND \<Rightarrow> bool"
    and trusted :: "'nid \<Rightarrow> bool"
    and actTr :: "cnf \<Rightarrow> 'nid set"
    and actUt :: "cnf \<Rightarrow> 'nid set"
    and PoW:: "trace \<Rightarrow> nat \<Rightarrow> nat"
    and tmining:: "trace \<Rightarrow> nat \<Rightarrow> bool"
    and umining:: "trace \<Rightarrow> nat \<Rightarrow> bool"
    and cb:: nat
  defines "actTr k \<equiv> {nid. \<parallel>nid\<parallel>\<^bsub>k\<^esub> \<and> trusted nid}"
    and "actUt k \<equiv> {nid. \<parallel>nid\<parallel>\<^bsub>k\<^esub> \<and> \<not> trusted nid}"
    and "PoW t n \<equiv> (LEAST x. \<forall>nid\<in>actTr (t n). length (bc (\<sigma>\<^bsub>nid\<^esub>(t n))) \<le> x)"
    and "tmining t \<equiv> (\<lambda>n. \<exists>kid\<in>actTr (t n). mining (\<sigma>\<^bsub>kid\<^esub>(t n)))"
    and "umining t \<equiv> (\<lambda>n. \<exists>kid\<in>actUt (t n). mining (\<sigma>\<^bsub>kid\<^esub>(t n)))"
  assumes consensus: "\<And>kid t t' bc'::('nid BC). \<lbrakk>trusted kid\<rbrakk> \<Longrightarrow> eval kid t t' 0
    (\<box>(ass (\<lambda>kt. bc' = (if (\<exists>b\<in>pin kt. length b > length (bc kt)) then (MAX (pin kt)) else (bc kt)))
      \<longrightarrow>\<^sup>b \<circle> (ass (\<lambda>kt.(\<not> mining kt \<and> bc kt = bc' \<or> mining kt \<and> bc kt = bc' @ [kid])))))"
    and attacker: "\<And>kid t t' bc'. \<lbrakk>\<not> trusted kid\<rbrakk> \<Longrightarrow> eval kid t t' 0
    (\<box>(ass (\<lambda>kt. bc' = (SOME b. b \<in> (pin kt \<union> {bc kt}))) \<longrightarrow>\<^sup>b
      \<circle> (ass (\<lambda>kt.(\<not> mining kt \<and> prefix (bc kt) bc' \<or> mining kt \<and> bc kt = bc' @ [kid])))))"
    and forward: "\<And>kid t t'. eval kid t t' 0 (\<box>(ass (\<lambda>kt. pout kt = bc kt)))"
    \<comment> \<open>At each time point a node will forward its blockchain to the network\<close>
    and init: "\<And>kid t t'. eval kid t t' 0 (ass (\<lambda>kt. bc kt=[]))"
    and conn: "\<And>k kid. \<lbrakk>active kid k; trusted kid\<rbrakk>
      \<Longrightarrow> pin (cmp kid k) = (\<Union>kid'\<in>actTr k. {pout (cmp kid' k)})"
    and act: "\<And>t n::nat. finite {kid::'nid. \<parallel>kid\<parallel>\<^bsub>t n\<^esub>}"
    and actTr: "\<And>t n::nat. \<exists>nid. trusted nid \<and> \<parallel>nid\<parallel>\<^bsub>t n\<^esub> \<and> \<parallel>nid\<parallel>\<^bsub>t (Suc n)\<^esub>"
    and fair: "\<And>n n'. ccard n n' (umining t) > cb \<Longrightarrow> ccard n n' (tmining t) > cb"
    and closed: "\<And>t kid b n::nat. \<lbrakk>b \<in> pin (\<sigma>\<^bsub>kid\<^esub>(t n))\<rbrakk> \<Longrightarrow> \<exists>kid'. \<parallel>kid'\<parallel>\<^bsub>t n\<^esub> \<and> pout (\<sigma>\<^bsub>kid'\<^esub>(t n)) = b"
    and mine: "\<And>t kid n::nat. \<lbrakk>trusted kid; \<parallel>kid\<parallel>\<^bsub>t (Suc n)\<^esub>; mining (\<sigma>\<^bsub>kid\<^esub>(t (Suc n)))\<rbrakk> \<Longrightarrow> \<parallel>kid\<parallel>\<^bsub>t n\<^esub>"
begin

lemma init_model:
  assumes "\<not> (\<exists>n'. latestAct_cond nid t n n')"
    and "\<parallel>nid\<parallel>\<^bsub>t n\<^esub>"
  shows "bc (\<sigma>\<^bsub>nid\<^esub>t n) = []"
proof -
  from assms(2) have "\<exists>i\<ge>0. \<parallel>nid\<parallel>\<^bsub>t i\<^esub>" by auto
  with init have "bc (\<sigma>\<^bsub>nid\<^esub>t \<langle>nid \<rightarrow> t\<rangle>\<^bsub>0\<^esub>) = []" using assEA[of 0 nid t] by blast
  moreover from assms have "n=\<langle>nid \<rightarrow> t\<rangle>\<^bsub>0\<^esub>" using nxtAct_eq by simp
  ultimately show ?thesis by simp
qed

lemma fwd_bc:
  fixes nid and t::"nat \<Rightarrow> cnf" and t'::"nat \<Rightarrow> 'ND"
  assumes "\<parallel>nid\<parallel>\<^bsub>t n\<^esub>"
  shows "pout (\<sigma>\<^bsub>nid\<^esub>t n) = bc (\<sigma>\<^bsub>nid\<^esub>t n)"
  using assms forward globEANow[THEN assEANow[of nid t t' n]] by blast

lemma finite_input:
  fixes t n kid
  assumes "\<parallel>kid\<parallel>\<^bsub>t n\<^esub>"
  defines "dep kid' \<equiv> pout (\<sigma>\<^bsub>kid'\<^esub>(t n))"
  shows "finite (pin (cmp kid (t n)))"
proof -
  have "finite {kid'. \<parallel>kid'\<parallel>\<^bsub>t n\<^esub>}" using act by auto
  moreover have "pin (cmp kid (t n)) \<subseteq> dep ` {kid'. \<parallel>kid'\<parallel>\<^bsub>t n\<^esub>}"
  proof
    fix x assume "x \<in> pin (cmp kid (t n))"
    show "x \<in> dep ` {kid'. \<parallel>kid'\<parallel>\<^bsub>t n\<^esub>}"
    proof -
      from closed obtain kid' where "\<parallel>kid'\<parallel>\<^bsub>t n\<^esub>" and "pout (\<sigma>\<^bsub>kid'\<^esub>(t n)) = x"
        using \<open>x \<in> pin (cmp kid (t n))\<close> by blast
      hence "x=dep kid'" using dep_def by simp
      moreover from \<open>\<parallel>kid'\<parallel>\<^bsub>t n\<^esub>\<close> have "kid' \<in> {kid'. \<parallel>kid'\<parallel>\<^bsub>t n\<^esub>}" by simp
      ultimately show ?thesis using image_eqI by simp
    qed
  qed
  ultimately show ?thesis using finite_surj by metis
qed

lemma nempty_input:
  fixes t n kid
  assumes "\<parallel>kid\<parallel>\<^bsub>t n\<^esub>"
    and "trusted kid"
  shows "pin (cmp kid (t n))\<noteq>{}" using conn[of kid "t n"] act assms actTr_def by auto

lemma onlyone:
  assumes "\<exists>n'\<ge>n. \<parallel>tid\<parallel>\<^bsub>t n'\<^esub>"
    and "\<exists>n'<n. \<parallel>tid\<parallel>\<^bsub>t n'\<^esub>"
  shows "\<exists>!i. \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> \<le> i \<and> i < \<langle>tid \<rightarrow> t\<rangle>\<^bsub>n\<^esub> \<and> \<parallel>tid\<parallel>\<^bsub>t i\<^esub>"
proof
  show "\<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> \<le> \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> \<and> \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> < \<langle>tid \<rightarrow> t\<rangle>\<^bsub>n\<^esub> \<and> \<parallel>tid\<parallel>\<^bsub>t \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>\<^esub>"
    by (metis assms dynamic_component.nxtActI latestAct_prop(1) latestAct_prop(2) less_le_trans order_refl)
next
  fix i
  show "\<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> \<le> i \<and> i < \<langle>tid \<rightarrow> t\<rangle>\<^bsub>n\<^esub> \<and> \<parallel>tid\<parallel>\<^bsub>t i\<^esub> \<Longrightarrow> i = \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>"
    by (metis latestActless(1) leI le_less_Suc_eq le_less_trans nxtActI order_refl)
qed

subsubsection "Component Behavior"

lemma bhv_tr_ex:
  fixes t and t'::"nat \<Rightarrow> 'ND" and tid
  assumes "trusted tid"
    and "\<exists>n'\<ge>n. \<parallel>tid\<parallel>\<^bsub>t n'\<^esub>"
    and "\<exists>n'<n. \<parallel>tid\<parallel>\<^bsub>t n'\<^esub>"
    and "\<exists>b\<in>pin (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>). length b > length (bc (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>))"
  shows "\<not> mining (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>) \<and> bc (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>) =
    Blockchain.MAX (pin (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)) \<or> mining (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>) \<and>
    bc (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>) = Blockchain.MAX (pin (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)) @ [tid]"
proof -
  let ?cond = "\<lambda>kt. MAX (pin (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)) =
    (if (\<exists>b\<in>pin kt. length b > length (bc kt)) then (MAX (pin kt)) else (bc kt))"
  let ?check = "\<lambda>kt. \<not> mining kt \<and> bc kt = MAX (pin (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)) \<or> mining kt \<and>
    bc kt = MAX (pin (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)) @ [tid]"
  from \<open>trusted tid\<close> have "eval tid t t' 0 ((\<box>((ass ?cond) \<longrightarrow>\<^sup>b
        \<circle>ass ?check)))" using consensus[of tid _ _ "MAX (pin (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>))"] by simp
  moreover from assms have "\<exists>i\<ge>0. \<parallel>tid\<parallel>\<^bsub>t i\<^esub>" by auto
  moreover have "\<langle>tid \<leftarrow> t\<rangle>\<^bsub>0\<^esub> \<le> \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>" by simp
  ultimately have "eval tid t t' \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> (ass (?cond) \<longrightarrow>\<^sup>b
        \<circle>ass ?check)" using globEA[of 0 tid t t' "((ass ?cond) \<longrightarrow>\<^sup>b \<circle>ass ?check)" "\<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>"]
    by fastforce
  moreover have "eval tid t t' \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> (ass (?cond))"
  proof (rule assIA)
    from \<open>\<exists>n'<n. \<parallel>tid\<parallel>\<^bsub>t n'\<^esub>\<close> show "\<exists>i\<ge>\<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>. \<parallel>tid\<parallel>\<^bsub>t i\<^esub>" using latestAct_prop(1) by blast
    from assms(3) assms(4) show "?cond (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<rightarrow> t\<rangle>\<^bsub>\<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>\<^esub>)" using latestActNxt by simp
  qed
  ultimately have "eval tid t t' \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> (\<circle>ass ?check)"
    using impE[of tid t t' _ "ass (?cond)" "\<circle>ass ?check"] by simp
  moreover have "\<exists>i>\<langle>tid \<rightarrow> t\<rangle>\<^bsub>\<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>\<^esub>. \<parallel>tid\<parallel>\<^bsub>t i\<^esub>"
  proof -
    from assms have "\<langle>tid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>>\<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>" using latestActNxtAct by simp
    with assms(3) have "\<langle>tid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>>\<langle>tid \<rightarrow> t\<rangle>\<^bsub>\<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>\<^esub>" using latestActNxt by simp
    moreover from \<open>\<exists>n'\<ge>n. \<parallel>tid\<parallel>\<^bsub>t n'\<^esub>\<close> have "\<parallel>tid\<parallel>\<^bsub>t \<langle>tid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>\<^esub>"  using nxtActI by simp
    ultimately show ?thesis by auto
  qed
  moreover from assms have "\<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> \<le> \<langle>tid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>"
    using latestActNxtAct by (simp add: order.strict_implies_order)
  moreover from assms have "\<exists>!i. \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> \<le> i \<and> i < \<langle>tid \<rightarrow> t\<rangle>\<^bsub>n\<^esub> \<and> \<parallel>tid\<parallel>\<^bsub>t i\<^esub>"
    using onlyone by simp
  ultimately have "eval tid t t' \<langle>tid \<rightarrow> t\<rangle>\<^bsub>n\<^esub> (ass ?check)"
    using nxtEA1[of tid t "\<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>" t' "ass ?check" "\<langle>tid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>"] by simp
  moreover from \<open>\<exists>n'\<ge>n. \<parallel>tid\<parallel>\<^bsub>t n'\<^esub>\<close> have "\<parallel>tid\<parallel>\<^bsub>t \<langle>tid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>\<^esub>" using nxtActI by simp
  ultimately show ?thesis using assEANow[of tid t t' "\<langle>tid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>" ?check] by simp
qed

lemma bhv_tr_in:
  fixes t and t'::"nat \<Rightarrow> 'ND" and tid
  assumes "trusted tid"
    and "\<exists>n'\<ge>n. \<parallel>tid\<parallel>\<^bsub>t n'\<^esub>"
    and "\<exists>n'<n. \<parallel>tid\<parallel>\<^bsub>t n'\<^esub>"
    and "\<not> (\<exists>b\<in>pin (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>). length b > length (bc (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)))"
  shows "\<not> mining (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>) \<and> bc (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>) = bc (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>) \<or>
    mining (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>) \<and> bc (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>) = bc (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>) @ [tid]"
proof -
  let ?cond = "\<lambda>kt. bc (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>) = (if (\<exists>b\<in>pin kt. length b > length (bc kt)) then (MAX (pin kt)) else (bc kt))"
  let ?check = "\<lambda>kt. \<not> mining kt \<and> bc kt = bc (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>) \<or> mining kt \<and> bc kt = bc (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>) @ [tid]"
  from \<open>trusted tid\<close> have "eval tid t t' 0 ((\<box>((ass ?cond) \<longrightarrow>\<^sup>b
        \<circle>ass ?check)))" using consensus[of tid _ _ "bc (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)"] by simp
  moreover from assms have "\<exists>i\<ge>0. \<parallel>tid\<parallel>\<^bsub>t i\<^esub>" by auto
  moreover have "\<langle>tid \<leftarrow> t\<rangle>\<^bsub>0\<^esub> \<le> \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>" by simp
  ultimately have "eval tid t t' \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> (ass (?cond) \<longrightarrow>\<^sup>b
        \<circle>ass ?check)" using globEA[of 0 tid t t' "((ass ?cond) \<longrightarrow>\<^sup>b \<circle>ass ?check)" "\<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>"]
    by fastforce
  moreover have "eval tid t t' \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> (ass (?cond))"
  proof (rule assIA)
    from \<open>\<exists>n'<n. \<parallel>tid\<parallel>\<^bsub>t n'\<^esub>\<close> show "\<exists>i\<ge>\<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>. \<parallel>tid\<parallel>\<^bsub>t i\<^esub>" using latestAct_prop(1) by blast
    from assms(3) assms(4) show "?cond (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<rightarrow> t\<rangle>\<^bsub>\<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>\<^esub>)" using latestActNxt by simp
  qed
  ultimately have "eval tid t t' \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> (\<circle>ass ?check)"
    using impE[of tid t t' _ "ass (?cond)" "\<circle>ass ?check"] by simp
  moreover have "\<exists>i>\<langle>tid \<rightarrow> t\<rangle>\<^bsub>\<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>\<^esub>. \<parallel>tid\<parallel>\<^bsub>t i\<^esub>"
  proof -
    from assms have "\<langle>tid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>>\<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>" using latestActNxtAct by simp
    with assms(3) have "\<langle>tid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>>\<langle>tid \<rightarrow> t\<rangle>\<^bsub>\<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>\<^esub>" using latestActNxt by simp
    moreover from \<open>\<exists>n'\<ge>n. \<parallel>tid\<parallel>\<^bsub>t n'\<^esub>\<close> have "\<parallel>tid\<parallel>\<^bsub>t \<langle>tid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>\<^esub>"  using nxtActI by simp
    ultimately show ?thesis by auto
  qed
  moreover from assms have "\<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> \<le> \<langle>tid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>"
    using latestActNxtAct by (simp add: order.strict_implies_order)
  moreover from assms have "\<exists>!i. \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> \<le> i \<and> i < \<langle>tid \<rightarrow> t\<rangle>\<^bsub>n\<^esub> \<and> \<parallel>tid\<parallel>\<^bsub>t i\<^esub>"
    using onlyone by simp
  ultimately have "eval tid t t' \<langle>tid \<rightarrow> t\<rangle>\<^bsub>n\<^esub> (ass ?check)"
    using nxtEA1[of tid t "\<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>" t' "ass ?check" "\<langle>tid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>"] by simp
  moreover from \<open>\<exists>n'\<ge>n. \<parallel>tid\<parallel>\<^bsub>t n'\<^esub>\<close> have "\<parallel>tid\<parallel>\<^bsub>t \<langle>tid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>\<^esub>" using nxtActI by simp
  ultimately show ?thesis using assEANow[of tid t t' "\<langle>tid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>" ?check] by simp
qed

lemma bhv_tr_context:
  assumes "trusted tid"
      and "\<parallel>tid\<parallel>\<^bsub>t n\<^esub>"
      and "\<exists>n'<n. \<parallel>tid\<parallel>\<^bsub>t n'\<^esub>"
    shows "\<exists>nid'. \<parallel>nid'\<parallel>\<^bsub>t \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>\<^esub> \<and> (mining (\<sigma>\<^bsub>tid\<^esub>t n) \<and> bc (\<sigma>\<^bsub>tid\<^esub>t n) = bc (\<sigma>\<^bsub>nid'\<^esub>t \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>) @ [tid] \<or>
      \<not> mining (\<sigma>\<^bsub>tid\<^esub>t n) \<and> bc (\<sigma>\<^bsub>tid\<^esub>t n) = bc (\<sigma>\<^bsub>nid'\<^esub>t \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>))"
proof cases
  assume casmp: "\<exists>b\<in>pin (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>). length b > length (bc (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>))"
  moreover from assms(2) have "\<exists>n'\<ge>n. \<parallel>tid\<parallel>\<^bsub>t n'\<^esub>" by auto
  moreover from assms(3) have "\<exists>n'<n. \<parallel>tid\<parallel>\<^bsub>t n'\<^esub>" by auto
  ultimately have "\<not> mining (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>) \<and> bc (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>) = Blockchain.MAX (pin (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)) \<or>
    mining (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>) \<and> bc (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>) = Blockchain.MAX (pin (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)) @ [tid]"
    using assms(1) bhv_tr_ex by auto
  moreover from assms(2) have "\<langle>tid \<rightarrow> t\<rangle>\<^bsub>n\<^esub> = n" using nxtAct_active by simp
  ultimately have "\<not> mining (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>) \<and> bc (\<sigma>\<^bsub>tid\<^esub>t n) = Blockchain.MAX (pin (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)) \<or>
    mining (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>) \<and> bc (\<sigma>\<^bsub>tid\<^esub>t n) = Blockchain.MAX (pin (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)) @ [tid]" by simp
  moreover from assms(2) have "\<langle>tid \<rightarrow> t\<rangle>\<^bsub>n\<^esub> = n" using nxtAct_active by simp
  ultimately have "\<not> mining (\<sigma>\<^bsub>tid\<^esub>t n) \<and> bc (\<sigma>\<^bsub>tid\<^esub>t n) = Blockchain.MAX (pin (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)) \<or>
    mining (\<sigma>\<^bsub>tid\<^esub>t n) \<and> bc (\<sigma>\<^bsub>tid\<^esub>t n) = Blockchain.MAX (pin (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)) @ [tid]" by simp
  moreover have "Blockchain.MAX (pin (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)) \<in> pin (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)"
  proof -
    from \<open>\<exists>n'<n. \<parallel>tid\<parallel>\<^bsub>t n'\<^esub>\<close> have "\<parallel>tid\<parallel>\<^bsub>t \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>\<^esub>" using latestAct_prop(1) by simp
    hence "finite (pin (\<sigma>\<^bsub>tid\<^esub>(t \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)))" using finite_input[of tid t "\<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>"] by simp
    moreover from casmp obtain b where "b \<in> pin (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)" and "length b > length (bc (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>))" by auto
    ultimately show ?thesis using max_prop(1) by auto
  qed
  with closed obtain nid where "\<parallel>nid\<parallel>\<^bsub>t \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>\<^esub>"
    and "pout (\<sigma>\<^bsub>nid\<^esub>t \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>) = Blockchain.MAX (pin (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>))" by blast
  with fwd_bc[of nid t "\<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>"] have "\<parallel>nid\<parallel>\<^bsub>t \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>\<^esub>"
    and "bc (\<sigma>\<^bsub>nid\<^esub>t \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>) = Blockchain.MAX (pin (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>))" by auto
  ultimately show ?thesis by auto
next
  assume "\<not> (\<exists>b\<in>pin (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>). length b > length (bc (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)))"
  moreover from assms(2) have "\<exists>n'\<ge>n. \<parallel>tid\<parallel>\<^bsub>t n'\<^esub>" by auto
  moreover from assms(3) have "\<exists>n'<n. \<parallel>tid\<parallel>\<^bsub>t n'\<^esub>" by auto
  ultimately have "\<not> mining (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>) \<and> bc (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>) = bc (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>) \<or>
    mining (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>) \<and> bc (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>) = bc (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>) @ [tid]"
    using assms(1) bhv_tr_in[of tid n t] by auto
  moreover from assms(2) have "\<langle>tid \<rightarrow> t\<rangle>\<^bsub>n\<^esub> = n" using nxtAct_active by simp
  ultimately have "\<not> mining (\<sigma>\<^bsub>tid\<^esub>t n) \<and> bc (\<sigma>\<^bsub>tid\<^esub>t n) = bc (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>) \<or>
    mining (\<sigma>\<^bsub>tid\<^esub>t n) \<and> bc (\<sigma>\<^bsub>tid\<^esub>t n) = bc (\<sigma>\<^bsub>tid\<^esub>t \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>) @ [tid]" by simp
  moreover from \<open>\<exists>n'. latestAct_cond tid t n n'\<close> have "\<parallel>tid\<parallel>\<^bsub>t \<langle>tid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>\<^esub>"
    using latestAct_prop(1) by simp
  ultimately show ?thesis by auto
qed

lemma bhv_ut:
  fixes t and t'::"nat \<Rightarrow> 'ND" and uid
  assumes "\<not> trusted uid"
    and "\<exists>n'\<ge>n. \<parallel>uid\<parallel>\<^bsub>t n'\<^esub>"
    and "\<exists>n'<n. \<parallel>uid\<parallel>\<^bsub>t n'\<^esub>"
  shows "\<not> mining (\<sigma>\<^bsub>uid\<^esub>t \<langle>uid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>) \<and> prefix (bc (\<sigma>\<^bsub>uid\<^esub>t \<langle>uid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>)) (SOME b. b \<in> pin (\<sigma>\<^bsub>uid\<^esub>t \<langle>uid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>) \<union> {bc (\<sigma>\<^bsub>uid\<^esub>t \<langle>uid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)}) \<or> mining (\<sigma>\<^bsub>uid\<^esub>t \<langle>uid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>) \<and> bc (\<sigma>\<^bsub>uid\<^esub>t \<langle>uid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>) = (SOME b. b \<in> pin (\<sigma>\<^bsub>uid\<^esub>t \<langle>uid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>) \<union> {bc (\<sigma>\<^bsub>uid\<^esub>t \<langle>uid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)}) @ [uid]"
proof -
  let ?cond = "\<lambda>kt. (SOME b. b \<in> (pin (\<sigma>\<^bsub>uid\<^esub>t \<langle>uid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>) \<union> {bc (\<sigma>\<^bsub>uid\<^esub>t \<langle>uid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)})) = (SOME b. b \<in> pin kt \<union> {bc kt})"
  let ?check = "\<lambda>kt. \<not> mining kt \<and> prefix (bc kt) (SOME b. b \<in> pin (\<sigma>\<^bsub>uid\<^esub>t \<langle>uid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>) \<union> {bc (\<sigma>\<^bsub>uid\<^esub>t \<langle>uid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)}) \<or> mining kt \<and> bc kt = (SOME b. b \<in> pin (\<sigma>\<^bsub>uid\<^esub>t \<langle>uid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>) \<union> {bc (\<sigma>\<^bsub>uid\<^esub>t \<langle>uid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)}) @ [uid]"
  from \<open>\<not> trusted uid\<close> have "eval uid t t' 0 ((\<box>((ass ?cond) \<longrightarrow>\<^sup>b \<circle>ass ?check)))"
    using attacker[of uid _ _ "(SOME b. b \<in> pin (\<sigma>\<^bsub>uid\<^esub>t \<langle>uid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>) \<union> {bc (\<sigma>\<^bsub>uid\<^esub>t \<langle>uid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)})"]
    by simp
  moreover from assms have "\<exists>i\<ge>0. \<parallel>uid\<parallel>\<^bsub>t i\<^esub>" by auto
  moreover have "\<langle>uid \<leftarrow> t\<rangle>\<^bsub>0\<^esub> \<le> \<langle>uid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>" by simp
  ultimately have "eval uid t t' \<langle>uid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> (ass (?cond) \<longrightarrow>\<^sup>b
        \<circle>ass ?check)" using globEA[of 0 uid t t' "((ass ?cond) \<longrightarrow>\<^sup>b \<circle>ass ?check)" "\<langle>uid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>"]
    by fastforce
  moreover have "eval uid t t' \<langle>uid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> (ass (?cond))"
  proof (rule assIA)
    from \<open>\<exists>n'<n. \<parallel>uid\<parallel>\<^bsub>t n'\<^esub>\<close> show "\<exists>i\<ge>\<langle>uid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>. \<parallel>uid\<parallel>\<^bsub>t i\<^esub>" using latestAct_prop(1) by blast
    with assms(3) show "?cond (\<sigma>\<^bsub>uid\<^esub>t \<langle>uid \<rightarrow> t\<rangle>\<^bsub>\<langle>uid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>\<^esub>)" using latestActNxt by simp
  qed
  ultimately have "eval uid t t' \<langle>uid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> (\<circle>ass ?check)"
    using impE[of uid t t' _ "ass (?cond)" "\<circle>ass ?check"] by simp
  moreover have "\<exists>i>\<langle>uid \<rightarrow> t\<rangle>\<^bsub>\<langle>uid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>\<^esub>. \<parallel>uid\<parallel>\<^bsub>t i\<^esub>"
  proof -
    from assms have "\<langle>uid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>>\<langle>uid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>" using latestActNxtAct by simp
    with assms(3) have "\<langle>uid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>>\<langle>uid \<rightarrow> t\<rangle>\<^bsub>\<langle>uid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>\<^esub>" using latestActNxt by simp
    moreover from \<open>\<exists>n'\<ge>n. \<parallel>uid\<parallel>\<^bsub>t n'\<^esub>\<close> have "\<parallel>uid\<parallel>\<^bsub>t \<langle>uid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>\<^esub>"  using nxtActI by simp
    ultimately show ?thesis by auto
  qed
  moreover from assms have "\<langle>uid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> \<le> \<langle>uid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>"
    using latestActNxtAct by (simp add: order.strict_implies_order)
  moreover from assms have "\<exists>!i. \<langle>uid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> \<le> i \<and> i < \<langle>uid \<rightarrow> t\<rangle>\<^bsub>n\<^esub> \<and> \<parallel>uid\<parallel>\<^bsub>t i\<^esub>"
    using onlyone by simp
  ultimately have "eval uid t t' \<langle>uid \<rightarrow> t\<rangle>\<^bsub>n\<^esub> (ass ?check)"
    using nxtEA1[of uid t "\<langle>uid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>" t' "ass ?check" "\<langle>uid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>"] by simp
  moreover from \<open>\<exists>n'\<ge>n. \<parallel>uid\<parallel>\<^bsub>t n'\<^esub>\<close> have "\<parallel>uid\<parallel>\<^bsub>t \<langle>uid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>\<^esub>" using nxtActI by simp
  ultimately show ?thesis using assEANow[of uid t t' "\<langle>uid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>" ?check] by simp
qed

lemma bhv_ut_context:
  assumes "\<not> trusted uid"
      and "\<parallel>uid\<parallel>\<^bsub>t n\<^esub>"
      and "\<exists>n'<n. \<parallel>uid\<parallel>\<^bsub>t n'\<^esub>"
  shows "\<exists>nid'. \<parallel>nid'\<parallel>\<^bsub>t \<langle>uid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>\<^esub> \<and> (mining (\<sigma>\<^bsub>uid\<^esub>t n) \<and> prefix (bc (\<sigma>\<^bsub>uid\<^esub>t n)) (bc (\<sigma>\<^bsub>nid'\<^esub>t \<langle>uid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>) @ [uid]) \<or> \<not> mining (\<sigma>\<^bsub>uid\<^esub>t n) \<and> prefix (bc (\<sigma>\<^bsub>uid\<^esub>t n)) (bc (\<sigma>\<^bsub>nid'\<^esub>t \<langle>uid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)))"
proof -
  let ?bc="SOME b. b \<in> pin (\<sigma>\<^bsub>uid\<^esub>t \<langle>uid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>) \<union> {bc (\<sigma>\<^bsub>uid\<^esub>t \<langle>uid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)}"
  have bc_ex: "?bc \<in> pin (\<sigma>\<^bsub>uid\<^esub>t \<langle>uid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>) \<or> ?bc \<in> {bc (\<sigma>\<^bsub>uid\<^esub>t \<langle>uid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)}"
  proof -
    have "\<exists>b. b\<in> pin (\<sigma>\<^bsub>uid\<^esub>t \<langle>uid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>) \<union> {bc (\<sigma>\<^bsub>uid\<^esub>t \<langle>uid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)}" by auto
    hence "?bc \<in> pin (\<sigma>\<^bsub>uid\<^esub>t \<langle>uid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>) \<union> {bc (\<sigma>\<^bsub>uid\<^esub>t \<langle>uid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)}" using someI_ex by simp
    thus ?thesis by auto
  qed

  from assms(2) have "\<exists>n'\<ge>n. \<parallel>uid\<parallel>\<^bsub>t n'\<^esub>" by auto
  moreover from assms(3) have "\<exists>n'<n. \<parallel>uid\<parallel>\<^bsub>t n'\<^esub>" by auto
  ultimately have "\<not> mining (\<sigma>\<^bsub>uid\<^esub>t \<langle>uid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>) \<and> prefix (bc (\<sigma>\<^bsub>uid\<^esub>t \<langle>uid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>)) ?bc \<or>
    mining (\<sigma>\<^bsub>uid\<^esub>t \<langle>uid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>) \<and> bc (\<sigma>\<^bsub>uid\<^esub>t \<langle>uid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>) = ?bc @ [uid]"
    using bhv_ut[of uid n t] assms(1) by simp
  moreover from assms(2) have "\<langle>uid \<rightarrow> t\<rangle>\<^bsub>n\<^esub> = n" using nxtAct_active by simp
  ultimately have casmp: "\<not> mining (\<sigma>\<^bsub>uid\<^esub>t n) \<and> prefix (bc (\<sigma>\<^bsub>uid\<^esub>t n)) ?bc \<or>
    mining (\<sigma>\<^bsub>uid\<^esub>t n) \<and> bc (\<sigma>\<^bsub>uid\<^esub>t n) = ?bc @ [uid]" by simp

  from bc_ex have "?bc \<in> pin (\<sigma>\<^bsub>uid\<^esub>t \<langle>uid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>) \<or> ?bc \<in> {bc (\<sigma>\<^bsub>uid\<^esub>t \<langle>uid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)}" .
  thus ?thesis
  proof
    assume "?bc \<in> pin (\<sigma>\<^bsub>uid\<^esub>t \<langle>uid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)"
    with closed obtain nid where "\<parallel>nid\<parallel>\<^bsub>t \<langle>uid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>\<^esub>" and "pout (\<sigma>\<^bsub>nid\<^esub>t \<langle>uid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>) = ?bc"
      by blast
    with fwd_bc[of nid t "\<langle>uid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>"] have "bc (\<sigma>\<^bsub>nid\<^esub>t \<langle>uid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>) = ?bc" by simp
    with casmp have "\<not> mining (\<sigma>\<^bsub>uid\<^esub>t n) \<and> prefix (bc (\<sigma>\<^bsub>uid\<^esub>t n)) (bc (\<sigma>\<^bsub>nid\<^esub>t \<langle>uid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)) \<or>
      mining (\<sigma>\<^bsub>uid\<^esub>t n) \<and> bc (\<sigma>\<^bsub>uid\<^esub>t n) = (bc (\<sigma>\<^bsub>nid\<^esub>t \<langle>uid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)) @ [uid]" by simp
    with \<open>\<parallel>nid\<parallel>\<^bsub>t \<langle>uid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>\<^esub>\<close> show ?thesis by auto
  next
    assume "?bc \<in> {bc (\<sigma>\<^bsub>uid\<^esub>t \<langle>uid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)}"
    hence "?bc = bc (\<sigma>\<^bsub>uid\<^esub>t \<langle>uid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)" by simp
    moreover from \<open>\<exists>n'. latestAct_cond uid t n n'\<close> have "\<parallel>uid\<parallel>\<^bsub>t \<langle>uid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>\<^esub>"
      using latestAct_prop(1) by simp
    ultimately show ?thesis using casmp by auto
  qed
qed

subsubsection "Maximal Trusted Blockchains"

abbreviation mbc_cond:: "trace \<Rightarrow> nat \<Rightarrow> 'nid \<Rightarrow> bool"
  where "mbc_cond t n nid \<equiv> nid\<in>actTr (t n) \<and> (\<forall>nid'\<in>actTr (t n). length (bc (\<sigma>\<^bsub>nid'\<^esub>(t n))) \<le> length (bc (\<sigma>\<^bsub>nid\<^esub>(t n))))"

lemma mbc_ex:
  fixes t n
  shows "\<exists>x. mbc_cond t n x"
proof -
  let ?ALL="{b. \<exists>nid\<in>actTr (t n). b = bc (\<sigma>\<^bsub>nid\<^esub>(t n))}"
  have "MAX ?ALL \<in> ?ALL"
  proof (rule max_prop)
    from actTr have "actTr (t n) \<noteq> {}" using actTr_def by blast
    thus "?ALL\<noteq>{}" by auto
    from act have "finite (actTr (t n))" using actTr_def by simp
    thus "finite ?ALL" by simp
  qed
  then obtain nid where "nid \<in> actTr (t n) \<and> bc (\<sigma>\<^bsub>nid\<^esub>(t n)) = MAX ?ALL" by auto
  moreover have "\<forall>nid'\<in>actTr (t n). length (bc (\<sigma>\<^bsub>nid'\<^esub>(t n))) \<le> length (MAX ?ALL)"
  proof
    fix nid
    assume "nid \<in> actTr (t n)"
    hence "bc (\<sigma>\<^bsub>nid\<^esub>(t n)) \<in> ?ALL" by auto
    moreover have "\<forall>b'\<in>?ALL. length b' \<le> length (MAX ?ALL)"
    proof (rule max_prop)
      from \<open>bc (\<sigma>\<^bsub>nid\<^esub>(t n)) \<in> ?ALL\<close> show "?ALL\<noteq>{}" by auto
      from act have "finite (actTr (t n))" using actTr_def by simp
      thus "finite ?ALL" by simp
    qed
    ultimately show "length (bc (\<sigma>\<^bsub>nid\<^esub>t n)) \<le> length (Blockchain.MAX {b. \<exists>nid\<in>actTr (t n). b = bc (\<sigma>\<^bsub>nid\<^esub>t n)})" by simp
  qed
  ultimately show ?thesis by auto
qed

definition MBC:: "trace \<Rightarrow> nat \<Rightarrow> 'nid"
  where "MBC t n = (SOME b. mbc_cond t n b)"

lemma mbc_prop[simp]:
  shows "mbc_cond t n (MBC t n)"
  using someI_ex[OF mbc_ex] MBC_def by simp

subsubsection "Trusted Proof of Work"
text {*
  An important construction is the maximal proof of work available in the trusted community.
  The construction was already introduces in the locale itself since it was used to express some of the locale assumptions.
*}

abbreviation pow_cond:: "trace \<Rightarrow> nat \<Rightarrow> nat \<Rightarrow> bool"
  where "pow_cond t n n' \<equiv> \<forall>nid\<in>actTr (t n). length (bc (\<sigma>\<^bsub>nid\<^esub>(t n))) \<le> n'"

lemma pow_ex:
  fixes t n
  shows "pow_cond t n (length (bc (\<sigma>\<^bsub>MBC t n\<^esub>(t n))))"
    and "\<forall>x'. pow_cond t n x' \<longrightarrow> x'\<ge>length (bc (\<sigma>\<^bsub>MBC t n\<^esub>(t n)))"
  using mbc_prop by auto

lemma pow_prop:
  "pow_cond t n (PoW t n)"
proof -
  from pow_ex have "pow_cond t n (LEAST x. pow_cond t n x)" using LeastI_ex[of "pow_cond t n"] by blast
  thus ?thesis using PoW_def by simp
qed 

lemma pow_eq:
  fixes n
  assumes "\<exists>tid\<in>actTr (t n). length (bc (\<sigma>\<^bsub>tid\<^esub>(t n))) = x"
    and "\<forall>tid\<in>actTr (t n). length (bc (\<sigma>\<^bsub>tid\<^esub>(t n))) \<le> x"
  shows "PoW t n = x"
proof -
  have "(LEAST x. pow_cond t n x) = x"
  proof (rule Least_equality)
    from assms(2) show "\<forall>nid\<in>actTr (t n). length (bc (\<sigma>\<^bsub>nid\<^esub>t n)) \<le> x" by simp
  next
    fix y
    assume "\<forall>nid\<in>actTr (t n). length (bc (\<sigma>\<^bsub>nid\<^esub>t n)) \<le> y"
    thus "x \<le> y" using assms(1) by auto
  qed
  with PoW_def show ?thesis by simp
qed

lemma pow_mbc:
  shows "length (bc (\<sigma>\<^bsub>MBC t n\<^esub>t n)) = PoW t n"
  by (metis mbc_prop pow_eq)

lemma pow_less:
  fixes t n nid
  assumes "pow_cond t n x"
  shows "PoW t n \<le> x"
proof -
  from pow_ex assms have "(LEAST x. pow_cond t n x) \<le> x" using Least_le[of "pow_cond t n"] by blast
  thus ?thesis using PoW_def by simp
qed

lemma pow_le_max:
  assumes "trusted tid"
    and "\<parallel>tid\<parallel>\<^bsub>t n\<^esub>"
  shows "PoW t n \<le> length (MAX (pin (\<sigma>\<^bsub>tid\<^esub>t n)))"
proof -
  from mbc_prop have "trusted (MBC t n)" and "\<parallel>MBC t n\<parallel>\<^bsub>t n\<^esub>" using actTr_def by auto
  hence "pout (\<sigma>\<^bsub>MBC t n\<^esub>t n) = bc (\<sigma>\<^bsub>MBC t n\<^esub>t n)"
    using forward globEANow[THEN assEANow[of "MBC t n" t t' n "\<lambda>kt. pout kt = bc kt"]] by auto
  with assms \<open>\<parallel>MBC t n\<parallel>\<^bsub>t n\<^esub>\<close> \<open>trusted (MBC t n)\<close> have "bc (\<sigma>\<^bsub>MBC t n\<^esub>t n) \<in> pin (\<sigma>\<^bsub>tid\<^esub>t n)"
    using conn actTr_def by auto
  moreover from assms (2) have "finite (pin (\<sigma>\<^bsub>tid\<^esub>t n))" using finite_input[of tid t n] by simp
  ultimately have "length (bc (\<sigma>\<^bsub>MBC t n\<^esub>t n)) \<le> length (MAX (pin (\<sigma>\<^bsub>tid\<^esub>t n)))"
    using max_prop(2) by auto
  with pow_mbc show ?thesis by simp
qed

lemma pow_ge_lgth:
  assumes "trusted tid"
    and "\<parallel>tid\<parallel>\<^bsub>t n\<^esub>"
  shows "length (bc (\<sigma>\<^bsub>tid\<^esub>t n)) \<le> PoW t n"
proof -
  from assms have "tid \<in> actTr (t n)" using actTr_def by simp
  thus ?thesis using pow_prop by simp
qed

lemma pow_le_lgth:
  assumes "trusted tid"
    and "\<parallel>tid\<parallel>\<^bsub>t n\<^esub>"
    and "\<not>(\<exists>b\<in>pin (\<sigma>\<^bsub>tid\<^esub>t n). length b > length (bc (\<sigma>\<^bsub>tid\<^esub>t n)))"
  shows "length (bc (\<sigma>\<^bsub>tid\<^esub>t n)) \<ge> PoW t n"
proof -
  from assms (3) have "\<forall>b\<in>pin (\<sigma>\<^bsub>tid\<^esub>t n). length b \<le> length (bc (\<sigma>\<^bsub>tid\<^esub>t n))" by auto
  moreover from assms nempty_input[of tid t n] finite_input[of tid t n]
  have "MAX (pin (\<sigma>\<^bsub>tid\<^esub>t n)) \<in> pin (\<sigma>\<^bsub>tid\<^esub>t n)" using max_prop(1)[of "pin (\<sigma>\<^bsub>tid\<^esub>t n)"] by simp
  ultimately have "length (MAX (pin (\<sigma>\<^bsub>tid\<^esub>t n))) \<le> length (bc (\<sigma>\<^bsub>tid\<^esub>t n))" by simp
  moreover from assms have "PoW t n \<le> length (MAX (pin (\<sigma>\<^bsub>tid\<^esub>t n)))" using pow_le_max by simp
  ultimately show ?thesis by simp
qed

lemma pow_mono:
  shows "n'\<ge>n \<Longrightarrow> PoW t n' \<ge> PoW t n"
proof (induction n' rule: dec_induct)
  case base
  then show ?case by simp
next
  case (step n')
  hence "PoW t n \<le> PoW t n'" by simp
  moreover have "PoW t (Suc n') \<ge> PoW t n'"
  proof -
    from actTr obtain tid where "trusted tid" and "\<parallel>tid\<parallel>\<^bsub>t n'\<^esub>" and "\<parallel>tid\<parallel>\<^bsub>t (Suc n')\<^esub>" by auto
    show ?thesis
    proof cases
      assume "\<exists>b\<in>pin (\<sigma>\<^bsub>tid\<^esub>t n'). length b > length (bc (\<sigma>\<^bsub>tid\<^esub>t n'))"
      moreover from \<open>\<parallel>tid\<parallel>\<^bsub>t (Suc n')\<^esub>\<close> have "\<langle>tid \<rightarrow> t\<rangle>\<^bsub>Suc n'\<^esub> = Suc n'"
        using nxtAct_active by simp
      moreover from \<open>\<parallel>tid\<parallel>\<^bsub>t n'\<^esub>\<close> have "\<langle>tid \<Leftarrow> t\<rangle>\<^bsub>Suc n'\<^esub> = n'"
        using latestAct_prop(2) latestActless le_less_Suc_eq by blast
      moreover from \<open>\<parallel>tid\<parallel>\<^bsub>t n'\<^esub>\<close> have "\<exists>n''<Suc n'. \<parallel>tid\<parallel>\<^bsub>t n''\<^esub>" by blast
      moreover from \<open>\<parallel>tid\<parallel>\<^bsub>t (Suc n')\<^esub>\<close> have "\<exists>n''\<ge>Suc n'. \<parallel>tid\<parallel>\<^bsub>t n''\<^esub>" by auto
      ultimately have "bc (\<sigma>\<^bsub>tid\<^esub>t (Suc n')) = Blockchain.MAX (pin (\<sigma>\<^bsub>tid\<^esub>t n')) \<or>
        bc (\<sigma>\<^bsub>tid\<^esub>t (Suc n')) = Blockchain.MAX (pin (\<sigma>\<^bsub>tid\<^esub>t n')) @ [tid]"
        using \<open>trusted tid\<close> bhv_tr_ex[of tid "Suc n'" t] by auto
      hence "length (bc (\<sigma>\<^bsub>tid\<^esub>t (Suc n'))) \<ge> length (Blockchain.MAX (pin (\<sigma>\<^bsub>tid\<^esub>t n')))" by auto
      moreover from \<open>trusted tid\<close> \<open>\<parallel>tid\<parallel>\<^bsub>t n'\<^esub>\<close>
        have "length (Blockchain.MAX (pin (\<sigma>\<^bsub>tid\<^esub>t n'))) \<ge> PoW t n'" using pow_le_max by simp
      ultimately have "PoW t n' \<le> length (bc (\<sigma>\<^bsub>tid\<^esub>t (Suc n')))" by simp
      moreover from \<open>trusted tid\<close> \<open>\<parallel>tid\<parallel>\<^bsub>t (Suc n')\<^esub>\<close>
        have "length (bc (\<sigma>\<^bsub>tid\<^esub>t (Suc n'))) \<le> PoW t (Suc n')" using pow_ge_lgth by simp
      ultimately show ?thesis by simp
    next
      assume asmp: "\<not>(\<exists>b\<in>pin (\<sigma>\<^bsub>tid\<^esub>t n'). length b > length (bc (\<sigma>\<^bsub>tid\<^esub>t n')))"
      moreover from \<open>\<parallel>tid\<parallel>\<^bsub>t (Suc n')\<^esub>\<close> have "\<langle>tid \<rightarrow> t\<rangle>\<^bsub>Suc n'\<^esub> = Suc n'"
        using nxtAct_active by simp
      moreover from \<open>\<parallel>tid\<parallel>\<^bsub>t n'\<^esub>\<close> have "\<langle>tid \<Leftarrow> t\<rangle>\<^bsub>Suc n'\<^esub> = n'"
        using latestAct_prop(2) latestActless le_less_Suc_eq by blast
      moreover from \<open>\<parallel>tid\<parallel>\<^bsub>t n'\<^esub>\<close> have "\<exists>n''<Suc n'. \<parallel>tid\<parallel>\<^bsub>t n''\<^esub>" by blast
      moreover from \<open>\<parallel>tid\<parallel>\<^bsub>t (Suc n')\<^esub>\<close> have "\<exists>n''\<ge>Suc n'. \<parallel>tid\<parallel>\<^bsub>t n''\<^esub>" by auto
      ultimately have "bc (\<sigma>\<^bsub>tid\<^esub>t (Suc n')) = bc (\<sigma>\<^bsub>tid\<^esub>t n') \<or>
        bc (\<sigma>\<^bsub>tid\<^esub>t (Suc n')) = bc (\<sigma>\<^bsub>tid\<^esub>t n') @ [tid]"
        using \<open>trusted tid\<close> bhv_tr_in[of tid "Suc n'" t] by auto
      hence "length (bc (\<sigma>\<^bsub>tid\<^esub>t (Suc n'))) \<ge> length (bc (\<sigma>\<^bsub>tid\<^esub>t n'))" by auto
      moreover from \<open>trusted tid\<close> \<open>\<parallel>tid\<parallel>\<^bsub>t n'\<^esub>\<close> asmp have "length (bc (\<sigma>\<^bsub>tid\<^esub>t n')) \<ge> PoW t n'"
        using pow_le_lgth by simp
      moreover from \<open>trusted tid\<close> \<open>\<parallel>tid\<parallel>\<^bsub>t (Suc n')\<^esub>\<close>
      have "length (bc (\<sigma>\<^bsub>tid\<^esub>t (Suc n'))) \<le> PoW t (Suc n')" using pow_ge_lgth by simp
      ultimately show ?thesis by simp
    qed
  qed
  ultimately show ?case by auto
qed

lemma pow_equals:
  assumes "PoW t n = PoW t n'"
  and "n'\<ge>n"
  and "n''\<ge>n"
  and "n''\<le>n'"
shows "PoW t n = PoW t n''" by (metis pow_mono assms(1) assms(3) assms(4) eq_iff)

lemma pow_mining_suc:
    assumes "tmining t (Suc n)"
    shows "PoW t n < PoW t (Suc n)"
proof -
  from assms obtain kid where "kid\<in>actTr (t (Suc n))" and "mining (\<sigma>\<^bsub>kid\<^esub>(t (Suc n)))"
    using tmining_def by auto
  show ?thesis
  proof cases
    assume asmp: "(\<exists>b\<in>pin (\<sigma>\<^bsub>kid\<^esub>t \<langle>kid \<Leftarrow> t\<rangle>\<^bsub>Suc n\<^esub>). length b > length (bc (\<sigma>\<^bsub>kid\<^esub>t \<langle>kid \<Leftarrow> t\<rangle>\<^bsub>Suc n\<^esub>)))"
    moreover from \<open>kid\<in>actTr (t (Suc n))\<close> have "trusted kid" and "\<parallel>kid\<parallel>\<^bsub>t (Suc n)\<^esub>"
      using actTr_def by auto
    moreover from \<open>trusted kid\<close> \<open>mining (\<sigma>\<^bsub>kid\<^esub>(t (Suc n)))\<close> \<open>\<parallel>kid\<parallel>\<^bsub>t (Suc n)\<^esub>\<close> have "\<parallel>kid\<parallel>\<^bsub>t n\<^esub>"
      using mine by simp
    hence "\<exists>n'. latestAct_cond kid t (Suc n) n'" by auto
    ultimately have "\<not> mining (\<sigma>\<^bsub>kid\<^esub>t \<langle>kid \<rightarrow> t\<rangle>\<^bsub>Suc n\<^esub>) \<and> bc (\<sigma>\<^bsub>kid\<^esub>t \<langle>kid \<rightarrow> t\<rangle>\<^bsub>Suc n\<^esub>) = MAX (pin (\<sigma>\<^bsub>kid\<^esub>t \<langle>kid \<Leftarrow> t\<rangle>\<^bsub>Suc n\<^esub>)) \<or>
    mining (\<sigma>\<^bsub>kid\<^esub>t \<langle>kid \<rightarrow> t\<rangle>\<^bsub>Suc n\<^esub>) \<and> bc (\<sigma>\<^bsub>kid\<^esub>t \<langle>kid \<rightarrow> t\<rangle>\<^bsub>Suc n\<^esub>) = MAX (pin (\<sigma>\<^bsub>kid\<^esub>t \<langle>kid \<Leftarrow> t\<rangle>\<^bsub>Suc n\<^esub>)) @ [kid]" using bhv_tr_ex[of kid "Suc n"] by auto
    moreover from \<open>\<parallel>kid\<parallel>\<^bsub>t (Suc n)\<^esub>\<close> have "\<langle>kid \<rightarrow> t\<rangle>\<^bsub>Suc n\<^esub> = Suc n" using nxtAct_active by simp
    moreover have "\<langle>kid \<Leftarrow> t\<rangle>\<^bsub>Suc n\<^esub> = n"
    proof (rule latestActEq)
      from \<open>\<parallel>kid\<parallel>\<^bsub>t n\<^esub>\<close> show "\<parallel>kid\<parallel>\<^bsub>t n\<^esub>" by simp
      show "\<not> (\<exists>n''>n. n'' < Suc n \<and> \<parallel>kid\<parallel>\<^bsub>t n\<^esub>)" by simp
      show "n < Suc n" by simp
    qed
    hence "\<langle>kid \<Leftarrow> t\<rangle>\<^bsub>Suc n\<^esub> = n" using latestAct_def by simp
    ultimately have "\<not> mining (\<sigma>\<^bsub>kid\<^esub>t (Suc n)) \<and> bc (\<sigma>\<^bsub>kid\<^esub>t (Suc n)) = MAX (pin (\<sigma>\<^bsub>kid\<^esub>t n)) \<or>
    mining (\<sigma>\<^bsub>kid\<^esub>t (Suc n)) \<and> bc (\<sigma>\<^bsub>kid\<^esub>t (Suc n)) = MAX (pin (\<sigma>\<^bsub>kid\<^esub>t n)) @ [kid]" by simp
    with \<open>mining (\<sigma>\<^bsub>kid\<^esub>(t (Suc n)))\<close>
      have "bc (\<sigma>\<^bsub>kid\<^esub>t (Suc n)) = MAX (pin (\<sigma>\<^bsub>kid\<^esub>t n)) @ [kid]" by simp
    moreover from \<open>trusted kid\<close> \<open>\<parallel>kid\<parallel>\<^bsub>t n\<^esub>\<close> have "length (MAX (pin (\<sigma>\<^bsub>kid\<^esub>t n))) \<ge> PoW t n"
      using pow_le_max by simp
    moreover from \<open>trusted kid\<close> \<open>\<parallel>kid\<parallel>\<^bsub>t (Suc n)\<^esub>\<close> have "length (bc (\<sigma>\<^bsub>kid\<^esub>t (Suc n))) \<le> PoW t (Suc n)"
      using pow_ge_lgth[of kid t "Suc n"] by simp
    ultimately show ?thesis by simp
  next
    assume asmp: "\<not> (\<exists>b\<in>pin (\<sigma>\<^bsub>kid\<^esub>t \<langle>kid \<Leftarrow> t\<rangle>\<^bsub>Suc n\<^esub>). length b > length (bc (\<sigma>\<^bsub>kid\<^esub>t \<langle>kid \<Leftarrow> t\<rangle>\<^bsub>Suc n\<^esub>)))"
    moreover from \<open>kid\<in>actTr (t (Suc n))\<close> have "trusted kid" and "\<parallel>kid\<parallel>\<^bsub>t (Suc n)\<^esub>"
      using actTr_def by auto
    moreover from \<open>trusted kid\<close> \<open>mining (\<sigma>\<^bsub>kid\<^esub>(t (Suc n)))\<close> \<open>\<parallel>kid\<parallel>\<^bsub>t (Suc n)\<^esub>\<close> have "\<parallel>kid\<parallel>\<^bsub>t n\<^esub>"
      using mine by simp
    hence "\<exists>n'. latestAct_cond kid t (Suc n) n'" by auto
    ultimately have "\<not> mining (\<sigma>\<^bsub>kid\<^esub>t \<langle>kid \<rightarrow> t\<rangle>\<^bsub>Suc n\<^esub>) \<and> bc (\<sigma>\<^bsub>kid\<^esub>t \<langle>kid \<rightarrow> t\<rangle>\<^bsub>Suc n\<^esub>) = bc (\<sigma>\<^bsub>kid\<^esub>t \<langle>kid \<Leftarrow> t\<rangle>\<^bsub>Suc n\<^esub>) \<or>
    mining (\<sigma>\<^bsub>kid\<^esub>t \<langle>kid \<rightarrow> t\<rangle>\<^bsub>Suc n\<^esub>) \<and> bc (\<sigma>\<^bsub>kid\<^esub>t \<langle>kid \<rightarrow> t\<rangle>\<^bsub>Suc n\<^esub>) = bc (\<sigma>\<^bsub>kid\<^esub>t \<langle>kid \<Leftarrow> t\<rangle>\<^bsub>Suc n\<^esub>) @ [kid]"
      using bhv_tr_in[of kid "Suc n"] by auto
    moreover from \<open>\<parallel>kid\<parallel>\<^bsub>t (Suc n)\<^esub>\<close> have "\<langle>kid \<rightarrow> t\<rangle>\<^bsub>Suc n\<^esub> = Suc n" using nxtAct_active by simp
    moreover have "\<langle>kid \<Leftarrow> t\<rangle>\<^bsub>Suc n\<^esub> = n"
    proof (rule latestActEq)
      from \<open>\<parallel>kid\<parallel>\<^bsub>t n\<^esub>\<close> show "\<parallel>kid\<parallel>\<^bsub>t n\<^esub>" by simp
      show "\<not> (\<exists>n''>n. n'' < Suc n \<and> \<parallel>kid\<parallel>\<^bsub>t n\<^esub>)" by simp
      show "n < Suc n" by simp
    qed
    hence "\<langle>kid \<Leftarrow> t\<rangle>\<^bsub>Suc n\<^esub> = n" using latestAct_def by simp
    ultimately have "\<not> mining (\<sigma>\<^bsub>kid\<^esub>t (Suc n)) \<and> bc (\<sigma>\<^bsub>kid\<^esub>t (Suc n)) = bc (\<sigma>\<^bsub>kid\<^esub>t n) \<or>
    mining (\<sigma>\<^bsub>kid\<^esub>t (Suc n)) \<and> bc (\<sigma>\<^bsub>kid\<^esub>t (Suc n)) = bc (\<sigma>\<^bsub>kid\<^esub>t n) @ [kid]" by simp
    with \<open>mining (\<sigma>\<^bsub>kid\<^esub>(t (Suc n)))\<close> have "bc (\<sigma>\<^bsub>kid\<^esub>t (Suc n)) = bc (\<sigma>\<^bsub>kid\<^esub>t n) @ [kid]" by simp
    moreover from \<open>\<langle>kid \<Leftarrow> t\<rangle>\<^bsub>Suc n\<^esub> = n\<close>
      have "\<not> (\<exists>b\<in>pin (\<sigma>\<^bsub>kid\<^esub>t n). length (bc (\<sigma>\<^bsub>kid\<^esub>t n)) < length b)"
      using asmp by simp
    with \<open>trusted kid\<close> \<open>\<parallel>kid\<parallel>\<^bsub>t n\<^esub>\<close> have "length (bc (\<sigma>\<^bsub>kid\<^esub>t n)) \<ge> PoW t n"
      using pow_le_lgth[of kid t n] by simp
    moreover from \<open>trusted kid\<close> \<open>\<parallel>kid\<parallel>\<^bsub>t (Suc n)\<^esub>\<close> have "length (bc (\<sigma>\<^bsub>kid\<^esub>t (Suc n))) \<le> PoW t (Suc n)"
      using pow_ge_lgth[of kid t "Suc n"] by simp
    ultimately show ?thesis by simp
  qed
qed

subsubsection "History"
text {*
  In the following we introduce an operator which extracts the development of a blockchain up to a time point @{term n}.
*}

abbreviation "his_prop t n kid n' kid' x \<equiv>
  (\<exists>n. latestAct_cond kid' t n' n) \<and> \<parallel>snd x\<parallel>\<^bsub>t (fst x)\<^esub> \<and> fst x = \<langle>kid' \<Leftarrow> t\<rangle>\<^bsub>n'\<^esub> \<and>
  (prefix (bc (\<sigma>\<^bsub>kid'\<^esub>(t n'))) (bc (\<sigma>\<^bsub>snd x\<^esub>(t (fst x)))) \<or>
    (\<exists>b. bc (\<sigma>\<^bsub>kid'\<^esub>(t n')) = (bc (\<sigma>\<^bsub>snd x\<^esub>(t (fst x)))) @ [b] \<and> mining (\<sigma>\<^bsub>kid'\<^esub>(t n'))))"

inductive_set 
his:: "trace \<Rightarrow> nat \<Rightarrow> 'nid \<Rightarrow> (nat \<times> 'nid) set"
  for t::trace and n::nat and kid::'nid 
  where "\<lbrakk>\<parallel>kid\<parallel>\<^bsub>t n\<^esub>\<rbrakk> \<Longrightarrow> (n,kid) \<in> his t n kid"
  | "\<lbrakk>(n',kid') \<in> his t n kid; \<exists>x. his_prop t n kid n' kid' x\<rbrakk> \<Longrightarrow> (SOME x. his_prop t n kid n' kid' x) \<in> his t n kid"

lemma his_act:
  assumes "(n',kid') \<in> his t n kid"
  shows "\<parallel>kid'\<parallel>\<^bsub>t n'\<^esub>"
  using assms
proof (rule his.cases)
  assume "(n', kid') = (n, kid)" and "\<parallel>kid\<parallel>\<^bsub>t n\<^esub>"
  thus "\<parallel>kid'\<parallel>\<^bsub>t n'\<^esub>" by simp
next
  fix n'' kid'' assume asmp: "(n', kid') = (SOME x. his_prop t n kid n'' kid'' x)"
  and "(n'', kid'') \<in> his t n kid" and "\<exists>x. his_prop t n kid n'' kid'' x"
  hence "his_prop t n kid n'' kid'' (SOME x. his_prop t n kid n'' kid'' x)"
    using someI_ex[of "\<lambda>x. his_prop t n kid n'' kid'' x"] by auto
  hence "\<parallel>snd (SOME x. his_prop t n kid n'' kid'' x)\<parallel>\<^bsub>t (fst (SOME x. his_prop t n kid n'' kid'' x))\<^esub>"
    by blast
  moreover from asmp have "fst (SOME x. his_prop t n kid n'' kid'' x) = fst (n', kid')" by simp
  moreover from asmp have "snd (SOME x. his_prop t n kid n'' kid'' x) = snd (n', kid')" by simp
  ultimately show ?thesis by simp
qed

text {*
  In addition we also introduce an operator to obtain the predecessor of a blockchains development.
*}

definition "hisPred"
  where "hisPred t n kid n' \<equiv> (GREATEST n''. \<exists>kid'. (n'',kid')\<in> his t n kid \<and> n'' < n')"

lemma hisPrev_prop:
  assumes "\<exists>n''<n'. \<exists>kid'. (n'',kid')\<in> his t n kid"
  shows "hisPred t n kid n' < n'" and "\<exists>kid'. (hisPred t n kid n',kid')\<in> his t n kid"
proof -
  from assms obtain n'' where "\<exists>kid'. (n'',kid')\<in> his t n kid \<and> n''<n'" by auto
  moreover from \<open>\<exists>kid'. (n'',kid')\<in> his t n kid \<and> n''<n'\<close>
    have "\<exists>i'\<le>n'. (\<exists>kid'. (i', kid') \<in> his t n kid \<and> i' < n') \<and> (\<forall>n'a. (\<exists>kid'. (n'a, kid') \<in> his t n kid \<and> n'a < n') \<longrightarrow> n'a \<le> i')"
    using boundedGreatest[of "\<lambda>n''. \<exists>kid'. (n'',kid')\<in> his t n kid \<and> n'' < n'" n'' n'] by simp
  then obtain i' where "\<forall>n'a. (\<exists>kid'. (n'a, kid') \<in> his t n kid \<and> n'a < n') \<longrightarrow> n'a \<le> i'" by auto
  ultimately show "hisPred t n kid n' < n'" and "\<exists>kid'. (hisPred t n kid n',kid')\<in> his t n kid"
    using GreatestI_nat[of "\<lambda>n''. \<exists>kid'. (n'',kid')\<in> his t n kid \<and> n'' < n'" n'' i'] hisPred_def by auto
qed

lemma hisPrev_nex_less:
  assumes "\<exists>n''<n'. \<exists>kid'. (n'',kid')\<in> his t n kid"
  shows "\<not>(\<exists>x\<in>his t n kid. fst x < n' \<and> fst x>hisPred t n kid n')"
proof (rule ccontr)
  assume "\<not>\<not>(\<exists>x\<in>his t n kid. fst x < n' \<and> fst x>hisPred t n kid n')"
  then obtain n'' kid'' where "(n'',kid'')\<in>his t n kid" and "n''< n'" and "n''>hisPred t n kid n'" by auto
  moreover have "n''\<le>hisPred t n kid n'"
  proof -
    from \<open>(n'',kid'')\<in>his t n kid\<close> \<open>n''< n'\<close> have "\<exists>kid'. (n'',kid')\<in> his t n kid \<and> n''<n'" by auto
    moreover from \<open>\<exists>kid'. (n'',kid')\<in> his t n kid \<and> n''<n'\<close> have "\<exists>i'\<le>n'. (\<exists>kid'. (i', kid') \<in> his t n kid \<and> i' < n') \<and> (\<forall>n'a. (\<exists>kid'. (n'a, kid') \<in> his t n kid \<and> n'a < n') \<longrightarrow> n'a \<le> i')"
      using boundedGreatest[of "\<lambda>n''. \<exists>kid'. (n'',kid')\<in> his t n kid \<and> n'' < n'" n'' n'] by simp
    then obtain i' where "\<forall>n'a. (\<exists>kid'. (n'a, kid') \<in> his t n kid \<and> n'a < n') \<longrightarrow> n'a \<le> i'" by auto
    ultimately show ?thesis using Greatest_le_nat[of "\<lambda>n''. \<exists>kid'. (n'',kid')\<in> his t n kid \<and> n'' < n'" n'' i'] hisPred_def by simp
  qed
  ultimately show False by simp
qed

lemma his_le:
  assumes "x \<in> his t n kid"
  shows "fst x\<le>n"
using assms
proof (induction rule: his.induct)
  case 1
  then show ?case by simp
next
  case (2 n' kid')
  moreover have "fst (SOME x. his_prop t n kid n' kid' x) \<le> n'"
  proof -
    from "2.hyps" have "\<exists>x. his_prop t n kid n' kid' x" by simp
    hence "his_prop t n kid n' kid' (SOME x. his_prop t n kid n' kid' x)"
      using someI_ex[of "\<lambda>x. his_prop t n kid n' kid' x"] by auto
    hence "fst (SOME x. his_prop t n kid n' kid' x) = \<langle>kid' \<Leftarrow> t\<rangle>\<^bsub>n'\<^esub>" by force
    moreover from \<open>his_prop t n kid n' kid' (SOME x. his_prop t n kid n' kid' x)\<close>
    have "\<exists>n. latestAct_cond kid' t n' n" by simp
    ultimately show ?thesis using latestAct_prop(2)[of n' kid' t] by simp
  qed
  ultimately show ?case by simp
qed

lemma his_determ_base:
  shows "(n, kid') \<in> his t n kid \<Longrightarrow> kid'=kid"
proof (rule his.cases)
  assume "(n, kid') = (n, kid)"
  thus ?thesis by simp
next
  fix n' kid'a
  assume "(n, kid') \<in> his t n kid" and "(n, kid') = (SOME x. his_prop t n kid n' kid'a x)"
    and "(n', kid'a) \<in> his t n kid" and "\<exists>x. his_prop t n kid n' kid'a x"
  hence "his_prop t n kid n' kid'a (SOME x. his_prop t n kid n' kid'a x)"
    using someI_ex[of "\<lambda>x. his_prop t n kid n' kid'a x"] by auto
  hence "fst (SOME x. his_prop t n kid n' kid'a x) = \<langle>kid'a \<Leftarrow> t\<rangle>\<^bsub>n'\<^esub>" by force
  moreover from \<open>his_prop t n kid n' kid'a (SOME x. his_prop t n kid n' kid'a x)\<close>
    have "\<exists>n. latestAct_cond kid'a t n' n" by simp
  ultimately have "fst (SOME x. his_prop t n kid n' kid'a x) < n'"
    using latestAct_prop(2)[of n' kid'a t] by simp
  with \<open>(n, kid') = (SOME x. his_prop t n kid n' kid'a x)\<close> have "fst (n, kid')<n'" by simp
  hence "n<n'" by simp
  moreover from \<open>(n', kid'a) \<in> his t n kid\<close> have "n'\<le>n" using his_le by auto
  ultimately show "kid' = kid" by simp
qed

lemma hisPrev_same:
  assumes "\<exists>n'<n''. \<exists>kid'. (n',kid')\<in> his t n kid"
  and "\<exists>n''<n'. \<exists>kid'. (n'',kid')\<in> his t n kid"
  and "(n',kid')\<in> his t n kid"
  and "(n'',kid'')\<in> his t n kid"
  and "hisPred t n kid n'=hisPred t n kid n''"
  shows "n'=n''"
proof (rule ccontr)
  assume "\<not> n'=n''"
  hence "n'>n'' \<or> n'<n''" by auto
  thus False
  proof
    assume "n'<n''"
    hence "fst (n',kid')<n''" by simp
    moreover from assms(2) have "hisPred t n kid n'<n'" using hisPrev_prop(1) by simp
    with assms have "hisPred t n kid n''<n'" by simp
    hence "hisPred t n kid n''<fst (n',kid')" by simp
    ultimately show False using hisPrev_nex_less[of n'' t n kid] assms by auto
  next (*Symmetric*)
    assume "n'>n''"
    hence "fst (n'',kid')<n'" by simp
    moreover from assms(1) have "hisPred t n kid n''<n''" using hisPrev_prop(1) by simp
    with assms have "hisPred t n kid n'<n''" by simp
    hence "hisPred t n kid n'<fst (n'',kid')" by simp
    ultimately show False using hisPrev_nex_less[of n' t n kid] assms by auto
  qed
qed

lemma his_determ_ext:
  shows "n'\<le>n \<Longrightarrow> (\<exists>kid'. (n',kid')\<in>his t n kid) \<Longrightarrow> (\<exists>!kid'. (n',kid')\<in>his t n kid) \<and>
    ((\<exists>n''<n'. \<exists>kid'. (n'',kid')\<in> his t n kid) \<longrightarrow> (\<exists>x. his_prop t n kid n' (THE kid'. (n',kid')\<in>his t n kid) x) \<and>
    (hisPred t n kid n', (SOME kid'. (hisPred t n kid n', kid') \<in> his t n kid)) = (SOME x. his_prop t n kid n' (THE kid'. (n',kid')\<in>his t n kid) x))"
proof (induction n' rule: my_induct)
  case base
  then obtain kid' where "(n, kid') \<in> his t n kid" by auto
  hence "\<exists>!kid'. (n, kid') \<in> his t n kid"
  proof
    fix kid'' assume "(n, kid'') \<in> his t n kid"
    with his_determ_base have "kid''=kid" by simp
    moreover from \<open>(n, kid') \<in> his t n kid\<close> have "kid'=kid" using his_determ_base by simp
    ultimately show "kid'' = kid'" by simp
  qed
  moreover have "(\<exists>n''<n. \<exists>kid'. (n'',kid')\<in> his t n kid) \<longrightarrow> (\<exists>x. his_prop t n kid n (THE kid'. (n,kid')\<in>his t n kid) x) \<and> (hisPred t n kid n, (SOME kid'. (hisPred t n kid n, kid') \<in> his t n kid)) = (SOME x. his_prop t n kid n (THE kid'. (n,kid')\<in>his t n kid) x)"
  proof
    assume "\<exists>n''<n. \<exists>kid'. (n'',kid')\<in> his t n kid"
    hence "\<exists>kid'. (hisPred t n kid n, kid')\<in> his t n kid" using hisPrev_prop(2) by simp
    hence "(hisPred t n kid n, (SOME kid'. (hisPred t n kid n, kid') \<in> his t n kid)) \<in> his t n kid"
      using someI_ex[of "\<lambda>kid'. (hisPred t n kid n, kid') \<in> his t n kid"] by simp
    thus "(\<exists>x. his_prop t n kid n (THE kid'. (n,kid')\<in>his t n kid) x) \<and>
      (hisPred t n kid n, (SOME kid'. (hisPred t n kid n, kid') \<in> his t n kid)) = (SOME x. his_prop t n kid n (THE kid'. (n,kid')\<in>his t n kid) x)"
    proof (rule his.cases)
      assume "(hisPred t n kid n, SOME kid'. (hisPred t n kid n, kid') \<in> his t n kid) = (n, kid)"
      hence "hisPred t n kid n=n" by simp
      with \<open>\<exists>n''<n. \<exists>kid'. (n'',kid')\<in> his t n kid\<close> show ?thesis using hisPrev_prop(1)[of n t n kid] by force
    next
      fix n'' kid'' assume asmp: "(hisPred t n kid n, SOME kid'. (hisPred t n kid n, kid') \<in> his t n kid) = (SOME x. his_prop t n kid n'' kid'' x)"
      and "(n'', kid'') \<in> his t n kid" and "\<exists>x. his_prop t n kid n'' kid'' x"
      moreover have "n''=n"
      proof (rule antisym)
        show "n''\<ge>n"
        proof (rule ccontr)
          assume "(\<not>n''\<ge>n)"
          hence "n''<n" by simp
          moreover have "n''>hisPred t n kid n"
          proof -
            let ?x="\<lambda>x. his_prop t n kid n'' kid'' x"
            from \<open>\<exists>x. his_prop t n kid n'' kid'' x\<close> have "his_prop t n kid n'' kid'' (SOME x. ?x x)"
              using someI_ex[of ?x] by auto
            hence "n''>fst (SOME x. ?x x)" using latestAct_prop(2)[of n'' kid'' t] by force
            moreover from asmp have "fst (hisPred t n kid n, SOME kid'. (hisPred t n kid n, kid') \<in> his t n kid) = fst (SOME x. ?x x)" by simp
            ultimately show ?thesis by simp
          qed
          moreover from \<open>\<exists>n''<n. \<exists>kid'. (n'',kid')\<in> his t n kid\<close>
            have "\<not>(\<exists>x\<in>his t n kid. fst x < n \<and> fst x > hisPred t n kid n)"
            using hisPrev_nex_less by simp
          ultimately show False using \<open>(n'', kid'') \<in> his t n kid\<close> by auto
        qed
      next
        from \<open>(n'', kid'') \<in> his t n kid\<close> show "n'' \<le> n" using his_le by auto
      qed
      ultimately have "(hisPred t n kid n, SOME kid'. (hisPred t n kid n, kid') \<in> his t n kid) = (SOME x. his_prop t n kid n kid'' x)" by simp
      moreover from \<open>n''=n\<close> \<open>(n'', kid'') \<in> his t n kid\<close> have "(n, kid'') \<in> his t n kid" by simp
      with \<open>\<exists>!kid'. (n,kid') \<in> his t n kid\<close> have "kid''=(THE kid'. (n,kid')\<in>his t n kid)"
        using the1_equality[of "\<lambda>kid'. (n, kid') \<in> his t n kid"] by simp
      moreover from \<open>\<exists>x. his_prop t n kid n'' kid'' x\<close> \<open>n''=n\<close> \<open>kid''=(THE kid'. (n,kid')\<in>his t n kid)\<close>
        have "\<exists>x. his_prop t n kid n (THE kid'. (n,kid')\<in>his t n kid) x" by simp
      ultimately show ?thesis by simp
    qed
  qed
  ultimately show ?case by simp
next
  case (step n')
  then obtain kid' where "(n', kid') \<in> his t n kid" by auto
  hence "\<exists>!kid'. (n', kid') \<in> his t n kid"
  proof (rule his.cases)
    assume "(n', kid') = (n, kid)"
    hence "n'=n" by simp
    with step.hyps show ?thesis by simp
  next
    fix n'''' kid''''
    assume "(n'''', kid'''') \<in> his t n kid"
      and n'kid': "(n', kid') = (SOME x. his_prop t n kid n'''' kid'''' x)"
      and "(n'''', kid'''') \<in> his t n kid" and "\<exists>x. his_prop t n kid n'''' kid'''' x"
    from \<open>(n', kid') \<in> his t n kid\<close> show ?thesis
    proof
      fix kid'' assume "(n', kid'') \<in> his t n kid"
      thus "kid'' = kid'"
      proof (rule his.cases)
        assume "(n', kid'') = (n, kid)"
        hence "n'=n" by simp
        with step.hyps show ?thesis by simp
      next
        fix n''' kid'''
        assume "(n''', kid''') \<in> his t n kid"
          and n'kid'': "(n', kid'') = (SOME x. his_prop t n kid n''' kid''' x)"
          and "(n''', kid''') \<in> his t n kid" and "\<exists>x. his_prop t n kid n''' kid''' x"
        moreover have "n'''=n''''"
        proof -
          have "hisPred t n kid n''' = n'"
          proof -
            from n'kid'' \<open>\<exists>x. his_prop t n kid n''' kid''' x\<close>
              have "his_prop t n kid n''' kid''' (n',kid'')"
              using someI_ex[of "\<lambda>x. his_prop t n kid n''' kid''' x"] by auto
            hence "n'''>n'" using latestAct_prop(2) by simp
            moreover from \<open>(n''', kid''') \<in> his t n kid\<close> have "n'''\<le> n" using his_le by auto
            moreover from \<open>(n''', kid''') \<in> his t n kid\<close>
              have "\<exists>kid'. (n''', kid') \<in> his t n kid" by auto
            ultimately have "(\<exists>n'<n'''. \<exists>kid'. (n',kid')\<in> his t n kid) \<longrightarrow> (\<exists>!kid'. (n''',kid') \<in> his t n kid) \<and> (hisPred t n kid n''', (SOME kid'. (hisPred t n kid n''', kid') \<in> his t n kid)) = (SOME x. his_prop t n kid n''' (THE kid'. (n''',kid')\<in>his t n kid) x)" using step.IH by auto
            with \<open>n'''>n'\<close> \<open>(n', kid') \<in> his t n kid\<close> have "\<exists>!kid'. (n''',kid') \<in> his t n kid" and "(hisPred t n kid n''', (SOME kid'. (hisPred t n kid n''', kid') \<in> his t n kid)) = (SOME x. his_prop t n kid n''' (THE kid'. (n''',kid')\<in>his t n kid) x)" by auto
            moreover from \<open>\<exists>!kid'. (n''',kid') \<in> his t n kid\<close> \<open>(n''', kid''') \<in> his t n kid\<close> have "kid'''=(THE kid'. (n''',kid')\<in>his t n kid)" using the1_equality[of "\<lambda>kid'. (n''', kid') \<in> his t n kid"] by simp
            ultimately have "(hisPred t n kid n''', (SOME kid'. (hisPred t n kid n''', kid') \<in> his t n kid)) = (SOME x. his_prop t n kid n''' kid''' x)" by simp
            with n'kid'' have "(n', kid'') = (hisPred t n kid n''', (SOME kid'. (hisPred t n kid n''', kid') \<in> his t n kid))" by simp
            thus ?thesis by simp
          qed
          moreover have "hisPred t n kid n'''' = n'" (*Symmetric*)
          proof -
            from n'kid' \<open>\<exists>x. his_prop t n kid n'''' kid'''' x\<close> have "his_prop t n kid n'''' kid'''' (n',kid')"
              using someI_ex[of "\<lambda>x. his_prop t n kid n'''' kid'''' x"] by auto
            hence "n''''>n'" using latestAct_prop(2) by simp
            moreover from \<open>(n'''', kid'''') \<in> his t n kid\<close> have "n''''\<le> n" using his_le by auto
            moreover from \<open>(n'''', kid'''') \<in> his t n kid\<close>
              have "\<exists>kid'. (n'''', kid') \<in> his t n kid" by auto
            ultimately have "(\<exists>n'<n''''. \<exists>kid'. (n',kid')\<in> his t n kid) \<longrightarrow> (\<exists>!kid'. (n'''',kid') \<in> his t n kid) \<and> (hisPred t n kid n'''', (SOME kid'. (hisPred t n kid n'''', kid') \<in> his t n kid)) = (SOME x. his_prop t n kid n'''' (THE kid'. (n'''',kid')\<in>his t n kid) x)" using step.IH by auto
            with \<open>n''''>n'\<close> \<open>(n', kid') \<in> his t n kid\<close> have "\<exists>!kid'. (n'''',kid') \<in> his t n kid" and "(hisPred t n kid n'''', (SOME kid'. (hisPred t n kid n'''', kid') \<in> his t n kid)) = (SOME x. his_prop t n kid n'''' (THE kid'. (n'''',kid')\<in>his t n kid) x)" by auto
            moreover from \<open>\<exists>!kid'. (n'''',kid') \<in> his t n kid\<close> \<open>(n'''', kid'''') \<in> his t n kid\<close> have "kid''''=(THE kid'. (n'''',kid')\<in>his t n kid)" using the1_equality[of "\<lambda>kid'. (n'''', kid') \<in> his t n kid"] by simp
            ultimately have "(hisPred t n kid n'''', (SOME kid'. (hisPred t n kid n'''', kid') \<in> his t n kid)) = (SOME x. his_prop t n kid n'''' kid'''' x)" by simp
            with n'kid' have "(n', kid') = (hisPred t n kid n'''', (SOME kid'. (hisPred t n kid n'''', kid') \<in> his t n kid))" by simp
            thus ?thesis by simp
          qed
          ultimately have "hisPred t n kid n'''=hisPred t n kid n''''" ..
          moreover have "\<exists>n'<n'''. \<exists>kid'. (n',kid')\<in> his t n kid"
          proof -
            from n'kid'' \<open>\<exists>x. his_prop t n kid n''' kid''' x\<close> have "his_prop t n kid n''' kid''' (n',kid'')"
              using someI_ex[of "\<lambda>x. his_prop t n kid n''' kid''' x"] by auto
            hence "n'''>n'" using latestAct_prop(2) by simp
            with \<open>(n', kid') \<in> his t n kid\<close> show ?thesis by auto
          qed
          moreover have "\<exists>n'<n''''. \<exists>kid'. (n',kid')\<in> his t n kid"
          proof -
            from n'kid' \<open>\<exists>x. his_prop t n kid n'''' kid'''' x\<close> have "his_prop t n kid n'''' kid'''' (n',kid')"
              using someI_ex[of "\<lambda>x. his_prop t n kid n'''' kid'''' x"] by auto
            hence "n''''>n'" using latestAct_prop(2) by simp
            with \<open>(n', kid') \<in> his t n kid\<close> show ?thesis by auto
          qed
          ultimately show ?thesis
            using hisPrev_same \<open>(n''', kid''') \<in> his t n kid\<close> \<open>(n'''', kid'''') \<in> his t n kid\<close>
            by blast
        qed
        moreover have "kid'''=kid''''"
        proof -
          from n'kid'' \<open>\<exists>x. his_prop t n kid n''' kid''' x\<close>
            have "his_prop t n kid n''' kid''' (n',kid'')"
            using someI_ex[of "\<lambda>x. his_prop t n kid n''' kid''' x"] by auto
          hence "n'''>n'" using latestAct_prop(2) by simp
          moreover from \<open>(n''', kid''') \<in> his t n kid\<close> have "n'''\<le> n" using his_le by auto
          moreover from \<open>(n''', kid''') \<in> his t n kid\<close>
            have "\<exists>kid'. (n''', kid') \<in> his t n kid" by auto
          ultimately have "\<exists>!kid'. (n''', kid') \<in> his t n kid" using step.IH by auto
          with `(n''', kid''') \<in> his t n kid` `(n'''', kid'''') \<in> his t n kid` \<open>n'''=n''''\<close>
            show ?thesis by auto
        qed
        ultimately have "(n', kid') = (n', kid'')" using n'kid' by simp
        thus "kid'' = kid'" by simp
      qed
    qed
  qed
  moreover have "(\<exists>n''<n'. \<exists>kid'. (n'',kid')\<in> his t n kid) \<longrightarrow> (\<exists>x. his_prop t n kid n' (THE kid'. (n',kid')\<in>his t n kid) x) \<and> (hisPred t n kid n', (SOME kid'. (hisPred t n kid n', kid') \<in> his t n kid)) = (SOME x. his_prop t n kid n' (THE kid'. (n',kid')\<in>his t n kid) x)"
  proof
    assume "\<exists>n''<n'. \<exists>kid'. (n'',kid')\<in> his t n kid"
    hence "\<exists>kid'. (hisPred t n kid n', kid')\<in> his t n kid" using hisPrev_prop(2) by simp
    hence "(hisPred t n kid n', (SOME kid'. (hisPred t n kid n', kid') \<in> his t n kid)) \<in> his t n kid"
      using someI_ex[of "\<lambda>kid'. (hisPred t n kid n', kid') \<in> his t n kid"] by simp
    thus "(\<exists>x. his_prop t n kid n' (THE kid'. (n',kid')\<in>his t n kid) x) \<and> (hisPred t n kid n', (SOME kid'. (hisPred t n kid n', kid') \<in> his t n kid)) = (SOME x. his_prop t n kid n' (THE kid'. (n',kid')\<in>his t n kid) x)"
    proof (rule his.cases)
      assume "(hisPred t n kid n', SOME kid'. (hisPred t n kid n', kid') \<in> his t n kid) = (n, kid)"
      hence "hisPred t n kid n'=n" by simp
      moreover from \<open>\<exists>n''<n'. \<exists>kid'. (n'',kid')\<in> his t n kid\<close> have "hisPred t n kid n'<n'"
        using hisPrev_prop(1)[of n'] by force
      ultimately show ?thesis using step.hyps by simp
    next
      fix n'' kid'' assume asmp: "(hisPred t n kid n', SOME kid'. (hisPred t n kid n', kid') \<in> his t n kid) = (SOME x. his_prop t n kid n'' kid'' x)"
      and "(n'', kid'') \<in> his t n kid" and "\<exists>x. his_prop t n kid n'' kid'' x"
      moreover have "n''=n'"
      proof (rule antisym)
        show "n''\<ge>n'"
        proof (rule ccontr)
          assume "(\<not>n''\<ge>n')"
          hence "n''<n'" by simp
          moreover have "n''>hisPred t n kid n'"
          proof -
            let ?x="\<lambda>x. his_prop t n kid n'' kid'' x"
            from \<open>\<exists>x. his_prop t n kid n'' kid'' x\<close> have "his_prop t n kid n'' kid'' (SOME x. ?x x)"
              using someI_ex[of ?x] by auto
            hence "n''>fst (SOME x. ?x x)" using latestAct_prop(2)[of n'' kid'' t] by force
            moreover from asmp have "fst (hisPred t n kid n', SOME kid'. (hisPred t n kid n', kid') \<in> his t n kid) = fst (SOME x. ?x x)" by simp
            ultimately show ?thesis by simp
          qed
          moreover from \<open>\<exists>n''<n'. \<exists>kid'. (n'',kid')\<in> his t n kid\<close>
            have "\<not>(\<exists>x\<in>his t n kid. fst x < n' \<and> fst x > hisPred t n kid n')"
            using hisPrev_nex_less by simp
          ultimately show False using \<open>(n'', kid'') \<in> his t n kid\<close> by auto
        qed
      next
        show "n'\<ge>n''"
        proof (rule ccontr)
          assume "(\<not>n'\<ge>n'')"
          hence "n'<n''" by simp
          moreover from \<open>(n'', kid'') \<in> his t n kid\<close> have "n''\<le> n" using his_le by auto
          moreover from \<open>(n'', kid'') \<in> his t n kid\<close> have "\<exists>kid'. (n'', kid') \<in> his t n kid" by auto
          ultimately have "(\<exists>n'<n''. \<exists>kid'. (n',kid')\<in> his t n kid) \<longrightarrow> (\<exists>!kid'. (n'',kid') \<in> his t n kid) \<and> (hisPred t n kid n'', (SOME kid'. (hisPred t n kid n'', kid') \<in> his t n kid)) = (SOME x. his_prop t n kid n'' (THE kid'. (n'',kid')\<in>his t n kid) x)" using step.IH by auto
          with \<open>n'<n''\<close> \<open>(n', kid') \<in> his t n kid\<close> have "\<exists>!kid'. (n'',kid') \<in> his t n kid" and "(hisPred t n kid n'', (SOME kid'. (hisPred t n kid n'', kid') \<in> his t n kid)) = (SOME x. his_prop t n kid n'' (THE kid'. (n'',kid')\<in>his t n kid) x)" by auto
          moreover from \<open>\<exists>!kid'. (n'',kid') \<in> his t n kid\<close> \<open>(n'', kid'') \<in> his t n kid\<close>
            have "kid'' = (THE kid'. (n'',kid')\<in>his t n kid)"
            using the1_equality[of "\<lambda>kid'. (n'', kid') \<in> his t n kid"] by simp
          ultimately have "(hisPred t n kid n'', (SOME kid'. (hisPred t n kid n'', kid') \<in> his t n kid)) = (SOME x. his_prop t n kid n'' kid'' x)" by simp
          with asmp have "(hisPred t n kid n', SOME kid'. (hisPred t n kid n', kid') \<in> his t n kid)=(hisPred t n kid n'', SOME kid'. (hisPred t n kid n'', kid') \<in> his t n kid)" by simp
          hence "hisPred t n kid n' = hisPred t n kid n''" by simp
          with \<open>\<exists>n''<n'. \<exists>kid'. (n'', kid') \<in> his t n kid\<close> \<open>n'<n''\<close> \<open>(n', kid') \<in> his t n kid\<close> \<open>(n'', kid'') \<in> his t n kid\<close> \<open>(n', kid') \<in> his t n kid\<close> have "n'=n''" using hisPrev_same by blast
          with \<open>n'<n''\<close> show False by simp
        qed
      qed
      ultimately have "(hisPred t n kid n', SOME kid'. (hisPred t n kid n', kid') \<in> his t n kid) = (SOME x. his_prop t n kid n' kid'' x)" by simp
      moreover from \<open>(n'', kid'') \<in> his t n kid\<close> \<open>n''=n'\<close> have "(n', kid'') \<in> his t n kid" by simp
      with \<open>\<exists>!kid'. (n',kid') \<in> his t n kid\<close> have "kid''=(THE kid'. (n',kid')\<in>his t n kid)"
        using the1_equality[of "\<lambda>kid'. (n', kid') \<in> his t n kid"] by simp
      moreover from \<open>\<exists>x. his_prop t n kid n'' kid'' x\<close> \<open>n''=n'\<close> \<open>kid''=(THE kid'. (n',kid')\<in>his t n kid)\<close>
        have "\<exists>x. his_prop t n kid n' (THE kid'. (n',kid')\<in>his t n kid) x" by simp
      ultimately show ?thesis by simp
    qed
  qed
  ultimately show ?case by simp
qed

corollary his_determ_ex:
  assumes "(n',kid')\<in>his t n kid"
  shows "\<exists>!kid'. (n',kid')\<in>his t n kid"
  using assms his_le his_determ_ext[of n' n t kid] by force

corollary his_determ:
  assumes "(n',kid')\<in>his t n kid"
    and "(n',kid'')\<in>his t n kid"
  shows "kid'=kid''" using assms his_le his_determ_ext[of n' n t kid] by force

corollary his_determ_the:
  assumes "(n',kid')\<in>his t n kid"
  shows "(THE kid'. (n', kid')\<in>his t n kid) = kid'"
  using assms his_determ theI'[of "\<lambda>kid'. (n', kid')\<in>his t n kid"] his_determ_ex by simp

subsubsection "Blockchain Development"

definition devBC::"trace \<Rightarrow> nat \<Rightarrow> 'nid \<Rightarrow> nat \<Rightarrow> 'nid option"
  where "devBC t n kid n' \<equiv>
    (if (\<exists>kid'. (n', kid')\<in> his t n kid) then (Some (THE kid'. (n', kid')\<in>his t n kid))
    else Option.None)"

lemma devBC_some[simp]: assumes "\<parallel>kid\<parallel>\<^bsub>t n\<^esub>" shows "devBC t n kid n = Some kid"
proof -
  from assms have "(n, kid)\<in> his t n kid" using his.intros(1) by simp
  hence "devBC t n kid n = (Some (THE kid'. (n, kid')\<in>his t n kid))" using devBC_def by auto
  moreover have "(THE kid'. (n, kid')\<in>his t n kid) = kid"
  proof
    from \<open>(n, kid)\<in> his t n kid\<close> show "(n, kid)\<in> his t n kid" .
  next
    fix kid' assume "(n, kid') \<in> his t n kid"
    thus "kid' = kid" using his_determ_base by simp
  qed
  ultimately show ?thesis by simp
qed

lemma devBC_act: assumes "\<not> Option.is_none (devBC t n kid n')" shows "\<parallel>the (devBC t n kid n')\<parallel>\<^bsub>t n'\<^esub>"
proof -
  from assms have "\<not> devBC t n kid n'=Option.None" by (metis is_none_simps(1))
  then obtain kid' where "(n', kid')\<in> his t n kid" and "devBC t n kid n' = (Some (THE kid'. (n', kid')\<in>his t n kid))"
    using devBC_def[of t n kid] by metis
  hence "kid'= (THE kid'. (n', kid')\<in>his t n kid)" using his_determ_the by simp
  with \<open>devBC t n kid n' = (Some (THE kid'. (n', kid')\<in>his t n kid))\<close> have "the (devBC t n kid n') = kid'" by simp
  with \<open>(n', kid')\<in> his t n kid\<close> show ?thesis using his_act by simp
qed

lemma his_ex:
  assumes "\<not>Option.is_none (devBC t n kid n')"
  shows "\<exists>kid'. (n',kid')\<in>his t n kid"
proof (rule ccontr)
  assume "\<not>(\<exists>kid'. (n',kid')\<in>his t n kid)"
  with devBC_def have "Option.is_none (devBC t n kid n')" by simp
  with assms show False by simp
qed

lemma devExt_nopt_leq:
  assumes "\<not>Option.is_none (devBC t n kid n')"
  shows "n'\<le>n"
proof -
  from assms have "\<exists>kid'. (n',kid')\<in>his t n kid" using his_ex by simp
  then obtain kid' where "(n',kid')\<in>his t n kid" by auto
  with his_le[of "(n',kid')"] show ?thesis by simp
qed

text {*
  An extended version of the development in which deactivations are filled with the last value.
*}

function devExt::"trace \<Rightarrow> nat \<Rightarrow> 'nid \<Rightarrow> nat \<Rightarrow> nat \<Rightarrow> 'nid BC"
  where "\<lbrakk>\<exists>n'<n\<^sub>s. \<not>Option.is_none (devBC t n kid n'); Option.is_none (devBC t n kid n\<^sub>s)\<rbrakk> \<Longrightarrow> devExt t n kid n\<^sub>s 0 = bc (\<sigma>\<^bsub>the (devBC t n kid (GREATEST n'. n'<n\<^sub>s \<and> \<not>Option.is_none (devBC t n kid n')))\<^esub>(t (GREATEST n'. n'<n\<^sub>s \<and> \<not>Option.is_none (devBC t n kid n'))))"
  | "\<lbrakk>\<not> (\<exists>n'<n\<^sub>s. \<not>Option.is_none (devBC t n kid n')); Option.is_none (devBC t n kid n\<^sub>s)\<rbrakk> \<Longrightarrow> devExt t n kid n\<^sub>s 0 = []"
  | "\<not> Option.is_none (devBC t n kid n\<^sub>s) \<Longrightarrow> devExt t n kid n\<^sub>s 0 = bc (\<sigma>\<^bsub>the (devBC t n kid n\<^sub>s)\<^esub>(t n\<^sub>s))"
  | "\<not> Option.is_none (devBC t n kid (n\<^sub>s + Suc n')) \<Longrightarrow> devExt t n kid n\<^sub>s (Suc n') = bc (\<sigma>\<^bsub>the (devBC t n kid (n\<^sub>s + Suc n'))\<^esub>(t (n\<^sub>s + Suc n')))"
  | "Option.is_none (devBC t n kid (n\<^sub>s + Suc n')) \<Longrightarrow> devExt t n kid n\<^sub>s (Suc n') = devExt t n kid n\<^sub>s n'"
proof -
  show "\<And>n\<^sub>s t n kid n\<^sub>s' ta na kida.
       \<exists>n'<n\<^sub>s. \<not> Option.is_none (devBC t n kid n') \<Longrightarrow>
       Option.is_none (devBC t n kid n\<^sub>s) \<Longrightarrow>
       \<exists>n'<n\<^sub>s'. \<not> Option.is_none (devBC ta na kida n') \<Longrightarrow>
       Option.is_none (devBC ta na kida n\<^sub>s') \<Longrightarrow>
       (t, n, kid, n\<^sub>s, 0) = (ta, na, kida, n\<^sub>s', 0) \<Longrightarrow>
       bc (\<sigma>\<^bsub>the (devBC t n kid (GREATEST n'. n' < n\<^sub>s \<and> \<not> Option.is_none (devBC t n kid n')))\<^esub>t (GREATEST n'. n' < n\<^sub>s \<and> \<not> Option.is_none (devBC t n kid n'))) =
       bc (\<sigma>\<^bsub>the (devBC ta na kida
                    (GREATEST n'. n' < n\<^sub>s' \<and> \<not> Option.is_none (devBC ta na kida n')))\<^esub>ta (GREATEST n'. n' < n\<^sub>s' \<and> \<not> Option.is_none (devBC ta na kida n')))" by auto
  show "\<And>n\<^sub>s t n kid n\<^sub>s' ta na kida.
       \<exists>n'<n\<^sub>s. \<not> Option.is_none (devBC t n kid n') \<Longrightarrow>
       Option.is_none (devBC t n kid n\<^sub>s) \<Longrightarrow>
       \<not> (\<exists>n'<n\<^sub>s'. \<not> Option.is_none (devBC ta na kida n')) \<Longrightarrow>
       Option.is_none (devBC ta na kida n\<^sub>s') \<Longrightarrow>
       (t, n, kid, n\<^sub>s, 0) = (ta, na, kida, n\<^sub>s', 0) \<Longrightarrow>
       bc (\<sigma>\<^bsub>the (devBC t n kid (GREATEST n'. n' < n\<^sub>s \<and> \<not> Option.is_none (devBC t n kid n')))\<^esub>t (GREATEST n'. n' < n\<^sub>s \<and> \<not> Option.is_none (devBC t n kid n'))) = []" by auto
  show "\<And>n\<^sub>s t n kid ta na kida n\<^sub>s'.
       \<exists>n'<n\<^sub>s. \<not> Option.is_none (devBC t n kid n') \<Longrightarrow>
       Option.is_none (devBC t n kid n\<^sub>s) \<Longrightarrow>
       \<not> Option.is_none (devBC ta na kida n\<^sub>s') \<Longrightarrow>
       (t, n, kid, n\<^sub>s, 0) = (ta, na, kida, n\<^sub>s', 0) \<Longrightarrow>
       bc (\<sigma>\<^bsub>the (devBC t n kid (GREATEST n'. n' < n\<^sub>s \<and> \<not> Option.is_none (devBC t n kid n')))\<^esub>t (GREATEST n'. n' < n\<^sub>s \<and> \<not> Option.is_none (devBC t n kid n'))) =
       bc (\<sigma>\<^bsub>the (devBC ta na kida n\<^sub>s')\<^esub>ta n\<^sub>s')" by auto
  show "\<And>n\<^sub>s t n kid ta na kida n\<^sub>s' n'.
       \<exists>n'<n\<^sub>s. \<not> Option.is_none (devBC t n kid n') \<Longrightarrow>
       Option.is_none (devBC t n kid n\<^sub>s) \<Longrightarrow>
       \<not> Option.is_none (devBC ta na kida (n\<^sub>s' + Suc n')) \<Longrightarrow>
       (t, n, kid, n\<^sub>s, 0) = (ta, na, kida, n\<^sub>s', Suc n') \<Longrightarrow>
       bc (\<sigma>\<^bsub>the (devBC t n kid (GREATEST n'. n' < n\<^sub>s \<and> \<not> Option.is_none (devBC t n kid n')))\<^esub>t (GREATEST n'. n' < n\<^sub>s \<and> \<not> Option.is_none (devBC t n kid n'))) =
       bc (\<sigma>\<^bsub>the (devBC ta na kida (n\<^sub>s' + Suc n'))\<^esub>ta (n\<^sub>s' + Suc n'))" by auto
  show "\<And>n\<^sub>s t n kid ta na kida n\<^sub>s' n'.
       \<exists>n'<n\<^sub>s. \<not> Option.is_none (devBC t n kid n') \<Longrightarrow>
       Option.is_none (devBC t n kid n\<^sub>s) \<Longrightarrow>
       Option.is_none (devBC ta na kida (n\<^sub>s' + Suc n')) \<Longrightarrow>
       (t, n, kid, n\<^sub>s, 0) = (ta, na, kida, n\<^sub>s', Suc n') \<Longrightarrow>
       bc (\<sigma>\<^bsub>the (devBC t n kid (GREATEST n'. n' < n\<^sub>s \<and> \<not> Option.is_none (devBC t n kid n')))\<^esub>t (GREATEST n'. n' < n\<^sub>s \<and> \<not> Option.is_none (devBC t n kid n'))) =
       devExt_sumC (ta, na, kida, n\<^sub>s', n')" by auto
  show"\<And>n\<^sub>s t n kid n\<^sub>s' ta na kida.
       \<not> (\<exists>n'<n\<^sub>s. \<not> Option.is_none (devBC t n kid n')) \<Longrightarrow>
       Option.is_none (devBC t n kid n\<^sub>s) \<Longrightarrow>
       \<not> (\<exists>n'<n\<^sub>s'. \<not> Option.is_none (devBC ta na kida n')) \<Longrightarrow>
       Option.is_none (devBC ta na kida n\<^sub>s') \<Longrightarrow> (t, n, kid, n\<^sub>s, 0) = (ta, na, kida, n\<^sub>s', 0) \<Longrightarrow> [] = []" by auto
  show "\<And>n\<^sub>s t n kid ta na kida n\<^sub>s'.
       \<not> (\<exists>n'<n\<^sub>s. \<not> Option.is_none (devBC t n kid n')) \<Longrightarrow>
       Option.is_none (devBC t n kid n\<^sub>s) \<Longrightarrow>
       \<not> Option.is_none (devBC ta na kida n\<^sub>s') \<Longrightarrow> (t, n, kid, n\<^sub>s, 0) = (ta, na, kida, n\<^sub>s', 0) \<Longrightarrow> [] = bc (\<sigma>\<^bsub>the (devBC ta na kida n\<^sub>s')\<^esub>ta n\<^sub>s')" by auto
  show "\<And>n\<^sub>s t n kid ta na kida n\<^sub>s' n'.
       \<not> (\<exists>n'<n\<^sub>s. \<not> Option.is_none (devBC t n kid n')) \<Longrightarrow>
       Option.is_none (devBC t n kid n\<^sub>s) \<Longrightarrow>
       \<not> Option.is_none (devBC ta na kida (n\<^sub>s' + Suc n')) \<Longrightarrow>
       (t, n, kid, n\<^sub>s, 0) = (ta, na, kida, n\<^sub>s', Suc n') \<Longrightarrow> [] = bc (\<sigma>\<^bsub>the (devBC ta na kida (n\<^sub>s' + Suc n'))\<^esub>ta (n\<^sub>s' + Suc n'))" by auto
  show "\<And>n\<^sub>s t n kid ta na kida n\<^sub>s' n'.
       \<not> (\<exists>n'<n\<^sub>s. \<not> Option.is_none (devBC t n kid n')) \<Longrightarrow>
       Option.is_none (devBC t n kid n\<^sub>s) \<Longrightarrow>
       Option.is_none (devBC ta na kida (n\<^sub>s' + Suc n')) \<Longrightarrow> (t, n, kid, n\<^sub>s, 0) = (ta, na, kida, n\<^sub>s', Suc n') \<Longrightarrow> [] = devExt_sumC (ta, na, kida, n\<^sub>s', n')" by auto
  show "\<And>t n kid n\<^sub>s ta na kida n\<^sub>s'.
       \<not> Option.is_none (devBC t n kid n\<^sub>s) \<Longrightarrow>
       \<not> Option.is_none (devBC ta na kida n\<^sub>s') \<Longrightarrow>
       (t, n, kid, n\<^sub>s, 0) = (ta, na, kida, n\<^sub>s', 0) \<Longrightarrow> bc (\<sigma>\<^bsub>the (devBC t n kid n\<^sub>s)\<^esub>t n\<^sub>s) = bc (\<sigma>\<^bsub>the (devBC ta na kida n\<^sub>s')\<^esub>ta n\<^sub>s')" by auto
  show "\<And>t n kid n\<^sub>s ta na kida n\<^sub>s' n'.
        \<not> Option.is_none (devBC t n kid n\<^sub>s) \<Longrightarrow>
        \<not> Option.is_none (devBC ta na kida (n\<^sub>s' + Suc n')) \<Longrightarrow>
        (t, n, kid, n\<^sub>s, 0) = (ta, na, kida, n\<^sub>s', Suc n') \<Longrightarrow> bc (\<sigma>\<^bsub>the (devBC t n kid n\<^sub>s)\<^esub>t n\<^sub>s) = bc (\<sigma>\<^bsub>the (devBC ta na kida (n\<^sub>s' + Suc n'))\<^esub>ta (n\<^sub>s' + Suc n'))" by auto
  show "\<And>t n kid n\<^sub>s ta na kida n\<^sub>s' n'.
       \<not> Option.is_none (devBC t n kid n\<^sub>s) \<Longrightarrow>
       Option.is_none (devBC ta na kida (n\<^sub>s' + Suc n')) \<Longrightarrow>
       (t, n, kid, n\<^sub>s, 0) = (ta, na, kida, n\<^sub>s', Suc n') \<Longrightarrow> bc (\<sigma>\<^bsub>the (devBC t n kid n\<^sub>s)\<^esub>t n\<^sub>s) = devExt_sumC (ta, na, kida, n\<^sub>s', n')" by auto
  show "\<And>t n kid n\<^sub>s n' ta na kida n\<^sub>s' n'a.
       \<not> Option.is_none (devBC t n kid (n\<^sub>s + Suc n')) \<Longrightarrow>
       \<not> Option.is_none (devBC ta na kida (n\<^sub>s' + Suc n'a)) \<Longrightarrow>
       (t, n, kid, n\<^sub>s, Suc n') = (ta, na, kida, n\<^sub>s', Suc n'a) \<Longrightarrow>
       bc (\<sigma>\<^bsub>the (devBC t n kid (n\<^sub>s + Suc n'))\<^esub>t (n\<^sub>s + Suc n')) = bc (\<sigma>\<^bsub>the (devBC ta na kida (n\<^sub>s' + Suc n'a))\<^esub>ta (n\<^sub>s' + Suc n'a))" by auto
  show "\<And>t n kid n\<^sub>s n' ta na kida n\<^sub>s' n'a.
       \<not> Option.is_none (devBC t n kid (n\<^sub>s + Suc n')) \<Longrightarrow>
       Option.is_none (devBC ta na kida (n\<^sub>s' + Suc n'a)) \<Longrightarrow>
       (t, n, kid, n\<^sub>s, Suc n') = (ta, na, kida, n\<^sub>s', Suc n'a) \<Longrightarrow> bc (\<sigma>\<^bsub>the (devBC t n kid (n\<^sub>s + Suc n'))\<^esub>t (n\<^sub>s + Suc n')) = devExt_sumC (ta, na, kida, n\<^sub>s', n'a)" by auto
  show "\<And>t n kid n\<^sub>s n' ta na kida n\<^sub>s' n'a.
       Option.is_none (devBC t n kid (n\<^sub>s + Suc n')) \<Longrightarrow>
       Option.is_none (devBC ta na kida (n\<^sub>s' + Suc n'a)) \<Longrightarrow>
       (t, n, kid, n\<^sub>s, Suc n') = (ta, na, kida, n\<^sub>s', Suc n'a) \<Longrightarrow> devExt_sumC (t, n, kid, n\<^sub>s, n') = devExt_sumC (ta, na, kida, n\<^sub>s', n'a)" by auto
  show "\<And>P x. (\<And>n\<^sub>s t n kid. \<exists>n'<n\<^sub>s. \<not> Option.is_none (devBC t n kid n') \<Longrightarrow> Option.is_none (devBC t n kid n\<^sub>s) \<Longrightarrow> x = (t, n, kid, n\<^sub>s, 0) \<Longrightarrow> P) \<Longrightarrow>
           (\<And>n\<^sub>s t n kid. \<not> (\<exists>n'<n\<^sub>s. \<not> Option.is_none (devBC t n kid n')) \<Longrightarrow> Option.is_none (devBC t n kid n\<^sub>s) \<Longrightarrow> x = (t, n, kid, n\<^sub>s, 0) \<Longrightarrow> P) \<Longrightarrow>
           (\<And>t n kid n\<^sub>s. \<not> Option.is_none (devBC t n kid n\<^sub>s) \<Longrightarrow> x = (t, n, kid, n\<^sub>s, 0) \<Longrightarrow> P) \<Longrightarrow>
           (\<And>t n kid n\<^sub>s n'. \<not> Option.is_none (devBC t n kid (n\<^sub>s + Suc n')) \<Longrightarrow> x = (t, n, kid, n\<^sub>s, Suc n') \<Longrightarrow> P) \<Longrightarrow>
           (\<And>t n kid n\<^sub>s n'. Option.is_none (devBC t n kid (n\<^sub>s + Suc n')) \<Longrightarrow> x = (t, n, kid, n\<^sub>s, Suc n') \<Longrightarrow> P) \<Longrightarrow> P"
  proof -
    fix P::bool and x::"trace \<times>nat\<times>'nid\<times>nat\<times>nat"
    assume a1:"(\<And>n\<^sub>s t n kid. \<exists>n'<n\<^sub>s. \<not> Option.is_none (devBC t n kid n') \<Longrightarrow> Option.is_none (devBC t n kid n\<^sub>s) \<Longrightarrow> x = (t, n, kid, n\<^sub>s, 0) \<Longrightarrow> P)" and
           a2:"(\<And>n\<^sub>s t n kid. \<not> (\<exists>n'<n\<^sub>s. \<not> Option.is_none (devBC t n kid n')) \<Longrightarrow> Option.is_none (devBC t n kid n\<^sub>s) \<Longrightarrow> x = (t, n, kid, n\<^sub>s, 0) \<Longrightarrow> P)" and
           a3:"(\<And>t n kid n\<^sub>s. \<not> Option.is_none (devBC t n kid n\<^sub>s) \<Longrightarrow> x = (t, n, kid, n\<^sub>s, 0) \<Longrightarrow> P)" and
           a4:"(\<And>t n kid n\<^sub>s n'. \<not> Option.is_none (devBC t n kid (n\<^sub>s + Suc n')) \<Longrightarrow> x = (t, n, kid, n\<^sub>s, Suc n') \<Longrightarrow> P)" and
           a5:"(\<And>t n kid n\<^sub>s n'. Option.is_none (devBC t n kid (n\<^sub>s + Suc n')) \<Longrightarrow> x = (t, n, kid, n\<^sub>s, Suc n') \<Longrightarrow> P)"
    show P
    proof (cases x)
      case (fields t n kid n\<^sub>s n')
      then show ?thesis
      proof (cases n')
        case 0
        then show ?thesis
        proof cases
          assume "Option.is_none (devBC t n kid n\<^sub>s)"
          thus ?thesis
          proof cases
            assume "\<exists>n'<n\<^sub>s. \<not> Option.is_none (devBC t n kid n')"
            with \<open>x = (t, n , kid, n\<^sub>s, n')\<close> \<open>Option.is_none (devBC t n kid n\<^sub>s)\<close> \<open>n'=0\<close> show ?thesis using a1 by simp
          next
            assume "\<not> (\<exists>n'<n\<^sub>s. \<not> Option.is_none (devBC t n kid n'))"
            with \<open>x = (t, n , kid, n\<^sub>s, n')\<close> \<open>Option.is_none (devBC t n kid n\<^sub>s)\<close> \<open>n'=0\<close> show ?thesis using a2 by simp
          qed
        next
          assume "\<not> Option.is_none (devBC t n kid n\<^sub>s)"
          with \<open>x = (t, n , kid, n\<^sub>s, n')\<close> \<open>n'=0\<close> show ?thesis using a3 by simp
        qed
      next
        case (Suc n'')
        then show ?thesis
        proof cases
          assume "Option.is_none (devBC t n kid (n\<^sub>s + Suc n''))"
          with \<open>x = (t, n , kid, n\<^sub>s, n')\<close> \<open>n'=Suc n''\<close> show ?thesis using a5[of t n kid n\<^sub>s n''] by simp
        next
          assume "\<not> Option.is_none (devBC t n kid (n\<^sub>s + Suc n''))"
          with \<open>x = (t, n , kid, n\<^sub>s, n')\<close> \<open>n'=Suc n''\<close> show ?thesis using a4[of t n kid n\<^sub>s n''] by simp
        qed
      qed
    qed
  qed
qed
termination by lexicographic_order

lemma devExt_same:
  assumes "\<forall>n'''>n'. n'''\<le>n'' \<longrightarrow> Option.is_none (devBC t n kid n''')"
    and "n'\<ge>n\<^sub>s"
    and "n'''\<le>n''"
  shows "n'''\<ge>n'\<Longrightarrow>devExt t n kid n\<^sub>s (n'''-n\<^sub>s) = devExt t n kid n\<^sub>s (n'-n\<^sub>s)"
proof (induction n''' rule: dec_induct)
  case base
  then show ?case by simp
next
  case (step n'''')
  hence "Suc n''''>n'" by simp
  moreover from step.hyps assms(3) have "Suc n''''\<le>n''" by simp
  ultimately have "Option.is_none (devBC t n kid (Suc n''''))" using assms(1) by simp
  moreover from assms(2) step.hyps have "n''''\<ge>n\<^sub>s" by simp
  hence "Suc n'''' = n\<^sub>s + Suc (n''''-n\<^sub>s)" by simp
  ultimately have "Option.is_none (devBC t n kid (n\<^sub>s + Suc (n''''-n\<^sub>s)))" by metis
  hence "devExt t n kid n\<^sub>s (Suc (n''''-n\<^sub>s)) = devExt t n kid n\<^sub>s (n''''-n\<^sub>s)" by simp
  moreover from \<open>n''''\<ge>n\<^sub>s\<close> have "Suc (n''''-n\<^sub>s) = Suc n''''-n\<^sub>s" by simp
  ultimately have "devExt t n kid n\<^sub>s (Suc n''''-n\<^sub>s) = devExt t n kid n\<^sub>s (n''''-n\<^sub>s)" by simp
  with step.IH show ?case by simp
qed

lemma devExt_bc[simp]:
  assumes "\<not> Option.is_none (devBC t n kid (n'+n''))"
  shows "devExt t n kid n' n'' = bc (\<sigma>\<^bsub>the (devBC t n kid (n'+n''))\<^esub>(t (n'+n'')))"
proof (cases n'')
  case 0
  with assms show ?thesis by simp
next
  case (Suc nat)
  with assms show ?thesis by simp
qed

lemma devExt_greatest:
  assumes "\<exists>n'''<n'+n''. \<not> Option.is_none (devBC t n kid n''')"
    and "Option.is_none (devBC t n kid (n'+n''))" and "\<not> n''=0"
  shows "devExt t n kid n' n'' = bc (\<sigma>\<^bsub>the (devBC t n kid (GREATEST n'''. n'''<(n'+n'') \<and> \<not>Option.is_none (devBC t n kid n''')))\<^esub>(t (GREATEST n'''. n'''<(n'+n'') \<and> \<not>Option.is_none (devBC t n kid n'''))))"
proof -
  let ?P="\<lambda>n'''. n'''<(n'+n'') \<and> \<not>Option.is_none (devBC t n kid n''')"
  let ?G="GREATEST n'''. ?P n'''"
  have "\<forall>n'''>n'+n''. \<not> ?P n'''" by simp
  with \<open>\<exists>n'''<n'+n''. \<not> Option.is_none (devBC t n kid n''')\<close> have "\<exists>n'''. ?P n''' \<and> (\<forall>n''''. ?P n'''' \<longrightarrow> n''''\<le>n''')" using boundedGreatest[of ?P] by blast
  hence "?P ?G" using GreatestI_ex_nat[of ?P] by auto
  hence "\<not>Option.is_none (devBC t n kid ?G)" by simp
  show ?thesis
  proof cases
    assume "?G>n'"
    hence "?G-n'+n' = ?G" by simp
    with \<open>\<not>Option.is_none (devBC t n kid ?G)\<close> have "\<not>Option.is_none (devBC t n kid (?G-n'+n'))" by simp
    moreover from \<open>?G>n'\<close> have "?G-n'\<noteq>0" by auto
    hence "\<exists>nat. Suc nat = ?G - n'" by presburger
    then obtain nat where "Suc nat = ?G-n'" by auto
    ultimately have "\<not>Option.is_none (devBC t n kid (n'+Suc nat))" by simp
    hence "devExt t n kid n' (Suc nat) = bc (\<sigma>\<^bsub>the (devBC t n kid (n' + Suc nat))\<^esub>t (n' + Suc nat))" by simp
    with \<open>Suc nat = ?G - n'\<close> have "devExt t n kid n' (?G - n') = bc (\<sigma>\<^bsub>the (devBC t n kid (?G-n'+n'))\<^esub>(t (?G-n'+n')))" by simp
    with \<open>?G-n'+n' = ?G\<close> have "devExt t n kid n' (?G - n') = bc (\<sigma>\<^bsub>the (devBC t n kid ?G)\<^esub>(t ?G))" by simp
    moreover have "devExt t n kid n' (n' + n'' - n') = devExt t n kid n' (?G - n')"
    proof -
      from \<open>\<exists>n'''. ?P n''' \<and> (\<forall>n''''. ?P n'''' \<longrightarrow> n''''\<le>n''')\<close> have "\<forall>n'''. ?P n''' \<longrightarrow> n'''\<le>?G"
        using Greatest_le_nat[of ?P] by blast
      hence "\<forall>n'''>?G. n'''<n'+n'' \<longrightarrow> Option.is_none (devBC t n kid n''')" by auto
      with \<open>Option.is_none (devBC t n kid (n'+n''))\<close>
        have "\<forall>n'''>?G. n'''\<le>n'+n'' \<longrightarrow> Option.is_none (devBC t n kid n''')" by auto
      moreover from \<open>?P ?G\<close> have "?G\<le>n'+n''" by simp
      moreover from \<open>?G>n'\<close> have "?G\<ge>n'" by simp
      ultimately show ?thesis using \<open>?G>n'\<close> devExt_same[of ?G "n'+n''" t n kid n' "n'+n''"] by blast
    qed
    ultimately show ?thesis by simp
  next
    assume "\<not>?G>n'"
    thus ?thesis
    proof cases
      assume "?G=n'"
      with \<open>\<not>Option.is_none (devBC t n kid ?G)\<close> have "\<not> Option.is_none (devBC t n kid n')" by simp
      with \<open>\<not>Option.is_none (devBC t n kid ?G)\<close> have "devExt t n kid n' 0 = bc (\<sigma>\<^bsub>the (devBC t n kid n')\<^esub>(t n'))" by simp
      moreover have "devExt t n kid n' n'' = devExt t n kid n' 0"
      proof -
        from \<open>\<exists>n'''. ?P n''' \<and> (\<forall>n''''. ?P n'''' \<longrightarrow> n''''\<le>n''')\<close> have "\<forall>n'''>?G. ?P n''' \<longrightarrow> n'''\<le>?G"
          using Greatest_le_nat[of ?P] by blast
        with \<open>?G=n'\<close> have "\<forall>n'''>n'. n''' < n' + n'' \<longrightarrow> Option.is_none (devBC t n kid n''')" by simp
        with \<open>Option.is_none (devBC t n kid (n'+n''))\<close>
          have "\<forall>n'''>n'. n'''\<le>n'+n'' \<longrightarrow> Option.is_none (devBC t n kid n''')" by auto
        moreover from \<open>\<not> n''=0\<close> have "n'<n'+n''" by simp
        ultimately show ?thesis using devExt_same[of n' "n'+n''" t n kid n' "n'+n''"] by simp
      qed
      ultimately show ?thesis using \<open>?G=n'\<close> by simp
    next
      assume "\<not>?G=n'"
      with \<open>\<not>?G>n'\<close> have "?G<n'" by simp
      hence "devExt t n kid n' n'' = devExt t n kid n' 0"
      proof -
        from \<open>\<exists>n'''. ?P n''' \<and> (\<forall>n''''. ?P n'''' \<longrightarrow> n''''\<le>n''')\<close> have "\<forall>n'''>?G. ?P n''' \<longrightarrow> n'''\<le>?G"
          using Greatest_le_nat[of ?P] by blast
        with \<open>\<not>?G>n'\<close> have "\<forall>n'''>n'. n'''<n'+n'' \<longrightarrow> Option.is_none (devBC t n kid n''')" by auto
        with \<open>Option.is_none (devBC t n kid (n'+n''))\<close>
          have "\<forall>n'''>n'. n'''\<le>n'+n'' \<longrightarrow> Option.is_none (devBC t n kid n''')" by auto
        moreover from \<open>?P ?G\<close> have "?G<n'+n''" by simp
        moreover from \<open>\<not> n''=0\<close> have "n'<n'+n''" by simp
        ultimately show ?thesis using devExt_same[of n' "n'+n''" t n kid n' "n'+n''"] by simp
      qed
      moreover have "devExt t n kid n' 0 = bc (\<sigma>\<^bsub>the (devBC t n kid (GREATEST n'''. n'''<n' \<and> \<not>Option.is_none (devBC t n kid n''')))\<^esub>(t (GREATEST n'''. n'''<n' \<and> \<not>Option.is_none (devBC t n kid n'''))))"
      proof -
        from \<open>\<not> n''=0\<close> have "n'<n'+n''" by simp
        moreover from \<open>\<exists>n'''. ?P n''' \<and> (\<forall>n''''. ?P n'''' \<longrightarrow> n''''\<le>n''')\<close> have "\<forall>n'''>?G. ?P n''' \<longrightarrow> n'''\<le>?G" using Greatest_le_nat[of ?P] by blast
        ultimately have "Option.is_none (devBC t n kid n')" using \<open>?G<n'\<close> by simp
        moreover from \<open>\<forall>n'''>?G. ?P n''' \<longrightarrow> n'''\<le>?G\<close> \<open>?G<n'\<close> \<open>n'<n'+n''\<close> have "\<forall>n'''\<ge>n'. n'''<n'+n'' \<longrightarrow> Option.is_none (devBC t n kid n''')" by auto
        have "\<exists>n'''<n'. \<not> Option.is_none (devBC t n kid n''')"
        proof -
          from \<open>\<exists>n'''<n'+n''. \<not> Option.is_none (devBC t n kid n''')\<close> obtain n'''
            where "n'''<n'+n''" and "\<not> Option.is_none (devBC t n kid n''')" by auto
          moreover have "n'''<n'"
          proof (rule ccontr)
            assume "\<not>n'''<n'"
            hence "n'''\<ge>n'" by simp
            with \<open>\<forall>n'''\<ge>n'. n'''<n'+n'' \<longrightarrow> Option.is_none (devBC t n kid n''')\<close> \<open>n'''<n'+n''\<close>
              \<open>\<not> Option.is_none (devBC t n kid n''')\<close> show False by simp
          qed
          ultimately show ?thesis by auto
        qed
        ultimately show ?thesis by simp
      qed
      moreover have "(GREATEST n'''. n'''<n' \<and> \<not>Option.is_none (devBC t n kid n''')) = ?G"
      proof(rule Greatest_equality)
        from \<open>?P ?G\<close> have "?G < n'+n''" and "\<not>Option.is_none (devBC t n kid ?G)" by auto
        with \<open>?G<n'\<close> show "?G < n' \<and> \<not> Option.is_none (devBC t n kid ?G)" by simp
      next
        fix y assume "y < n' \<and> \<not> Option.is_none (devBC t n kid y)"
        moreover from \<open>\<exists>n'''. ?P n''' \<and> (\<forall>n''''. ?P n'''' \<longrightarrow> n''''\<le>n''')\<close>
          have "\<forall>n'''. ?P n''' \<longrightarrow> n'''\<le>?G" using Greatest_le_nat[of ?P] by blast
        ultimately show "y \<le> ?G" by simp
      qed
      ultimately show ?thesis by simp
    qed
  qed
qed

lemma devExt_shift: "devExt t n kid (n'+n'') 0 = devExt t n kid n' n''"
proof (cases)
  assume "n''=0"
  thus ?thesis by simp
next
  assume "\<not> (n''=0)"
  thus ?thesis
  proof (cases)
    assume "Option.is_none (devBC t n kid (n'+n''))"
    thus ?thesis
    proof cases
      assume "\<exists>n'''<n'+n''. \<not> Option.is_none (devBC t n kid n''')"
      with \<open>Option.is_none (devBC t n kid (n'+n''))\<close> have "devExt t n kid (n'+n'') 0 = bc (\<sigma>\<^bsub>the (devBC t n kid (GREATEST n'''. n'''<(n'+n'') \<and> \<not>Option.is_none (devBC t n kid n''')))\<^esub>(t (GREATEST n'''. n'''<(n'+n'') \<and> \<not>Option.is_none (devBC t n kid n'''))))" by simp
      moreover from \<open>\<not> (n''=0)\<close> \<open>Option.is_none (devBC t n kid (n'+n''))\<close> \<open>\<exists>n'''<n'+n''. \<not> Option.is_none (devBC t n kid n''')\<close> have "devExt t n kid n' n'' = bc (\<sigma>\<^bsub>the (devBC t n kid (GREATEST n'''. n'''<(n'+n'') \<and> \<not>Option.is_none (devBC t n kid n''')))\<^esub>(t (GREATEST n'''. n'''<(n'+n'') \<and> \<not>Option.is_none (devBC t n kid n'''))))" using devExt_greatest by simp
      ultimately show ?thesis by simp
    next
      assume "\<not> (\<exists>n'''<n'+n''. \<not> Option.is_none (devBC t n kid n'''))"
      with \<open>Option.is_none (devBC t n kid (n'+n''))\<close> have "devExt t n kid (n'+n'') 0=[]" by simp
      moreover have "devExt t n kid n' n''=[]"
      proof -
        from \<open>\<not> (\<exists>n'''<n'+n''. \<not> Option.is_none (devBC t n kid n'''))\<close> \<open>n''\<noteq>0\<close>
          have "Option.is_none (devBC t n kid n')" by simp
        moreover from \<open>\<not> (\<exists>n'''<n'+n''. \<not> Option.is_none (devBC t n kid n'''))\<close>
          have "\<not> (\<exists>n'''<n'. \<not> Option.is_none (devBC t n kid n'''))" by simp
        ultimately have "devExt t n kid n' 0=[]" by simp
        moreover have "devExt t n kid n' n''=devExt t n kid n' 0"
        proof -
          from \<open>\<not> (\<exists>n'''<n'+n''. \<not> Option.is_none (devBC t n kid n'''))\<close>
            have "\<forall>n'''>n'. n''' < n' + n'' \<longrightarrow> Option.is_none (devBC t n kid n''')" by simp
          with \<open>Option.is_none (devBC t n kid (n'+n''))\<close> 
            have "\<forall>n'''>n'. n'''\<le>n'+n'' \<longrightarrow> Option.is_none (devBC t n kid n''')" by auto
          moreover from \<open>\<not> n''=0\<close> have "n'<n'+n''" by simp
          ultimately show ?thesis using devExt_same[of n' "n'+n''" t n kid n' "n'+n''"] by simp
        qed
        ultimately show ?thesis by simp
      qed
      ultimately show ?thesis by simp
    qed
  next
    assume "\<not> Option.is_none (devBC t n kid (n'+n''))"
    hence "devExt t n kid (n'+n'') 0 = bc (\<sigma>\<^bsub>the (devBC t n kid (n'+n''))\<^esub>(t (n'+n'')))" by simp
    moreover from \<open>\<not> Option.is_none (devBC t n kid (n'+n''))\<close>
      have "devExt t n kid n' n'' = bc (\<sigma>\<^bsub>the (devBC t n kid (n'+n''))\<^esub>(t (n'+n'')))" by simp
    ultimately show ?thesis by simp
  qed
qed

lemma devExt_bc_geq:
  assumes "\<not> Option.is_none (devBC t n kid n')" and "n'\<ge>n\<^sub>s"
  shows "devExt t n kid n\<^sub>s (n'-n\<^sub>s) = bc (\<sigma>\<^bsub>the (devBC t n kid n')\<^esub>(t n'))" (is "?LHS = ?RHS")
proof -
  have "devExt t n kid n\<^sub>s (n'-n\<^sub>s) = devExt t n kid (n\<^sub>s+(n'-n\<^sub>s)) 0" using devExt_shift by auto
  moreover from assms(2) have "n\<^sub>s+(n'-n\<^sub>s) = n'" by simp
  ultimately have "devExt t n kid n\<^sub>s (n'-n\<^sub>s) = devExt t n kid n' 0" by simp
  with assms(1) show ?thesis by simp
qed

lemma his_bc_empty:
  assumes "(n',kid')\<in> his t n kid" and "\<not>(\<exists>n''<n'. \<exists>kid''. (n'',kid'')\<in> his t n kid)"
  shows "bc (\<sigma>\<^bsub>kid'\<^esub>(t n')) = []"
proof -
  have "\<not> (\<exists>x. his_prop t n kid n' kid' x)"
  proof (rule ccontr)
    assume "\<not> \<not> (\<exists>x. his_prop t n kid n' kid' x)"
    hence "\<exists>x. his_prop t n kid n' kid' x" by simp
    with \<open>(n',kid')\<in> his t n kid\<close> have "(SOME x. his_prop t n kid n' kid' x) \<in> his t n kid"
      using his.intros by simp
    moreover from \<open>\<exists>x. his_prop t n kid n' kid' x\<close> have "his_prop t n kid n' kid' (SOME x. his_prop t n kid n' kid' x)"
      using someI_ex[of "\<lambda>x. his_prop t n kid n' kid' x"] by auto
    hence "(\<exists>n. latestAct_cond kid' t n' n) \<and> fst (SOME x. his_prop t n kid n' kid' x) = \<langle>kid' \<Leftarrow> t\<rangle>\<^bsub>n'\<^esub>"
      by force
    hence "fst (SOME x. his_prop t n kid n' kid' x) < n'" using latestAct_prop(2)[of n' kid' t] by force
    ultimately have "fst (SOME x. his_prop t n kid n' kid' x)<n' \<and>
      (fst (SOME x. his_prop t n kid n' kid' x),snd (SOME x. his_prop t n kid n' kid' x))\<in> his t n kid" by simp
    thus False using assms(2) by blast
  qed
  hence "\<forall>x. \<not> (\<exists>n. latestAct_cond kid' t n' n) \<or> \<not> \<parallel>snd x\<parallel>\<^bsub>t (fst x)\<^esub> \<or> \<not> fst x = \<langle>kid' \<Leftarrow> t\<rangle>\<^bsub>n'\<^esub> \<or> \<not> (prefix (bc (\<sigma>\<^bsub>kid'\<^esub>(t n'))) (bc (\<sigma>\<^bsub>snd x\<^esub>(t (fst x)))) \<or> (\<exists>b. bc (\<sigma>\<^bsub>kid'\<^esub>(t n')) = (bc (\<sigma>\<^bsub>snd x\<^esub>(t (fst x)))) @ [b] \<and> mining (\<sigma>\<^bsub>kid'\<^esub>(t n'))))" by auto
  hence "\<not> (\<exists>n. latestAct_cond kid' t n' n) \<or> (\<exists>n. latestAct_cond kid' t n' n) \<and> (\<forall>x. \<not> \<parallel>snd x\<parallel>\<^bsub>t (fst x)\<^esub> \<or> \<not> fst x = \<langle>kid' \<Leftarrow> t\<rangle>\<^bsub>n'\<^esub> \<or> \<not> (prefix (bc (\<sigma>\<^bsub>kid'\<^esub>(t n'))) (bc (\<sigma>\<^bsub>snd x\<^esub>(t (fst x)))) \<or> (\<exists>b. bc (\<sigma>\<^bsub>kid'\<^esub>(t n')) = (bc (\<sigma>\<^bsub>snd x\<^esub>(t (fst x)))) @ [b] \<and> mining (\<sigma>\<^bsub>kid'\<^esub>(t n')))))" by auto
  thus ?thesis
  proof
    assume "\<not> (\<exists>n. latestAct_cond kid' t n' n)"
    moreover from assms(1) have "\<parallel>kid'\<parallel>\<^bsub>t n'\<^esub>" using his_act by simp
    ultimately show ?thesis using init_model by simp
  next
    assume "(\<exists>n. latestAct_cond kid' t n' n) \<and> (\<forall>x. \<not> \<parallel>snd x\<parallel>\<^bsub>t (fst x)\<^esub> \<or> \<not> fst x = \<langle>kid' \<Leftarrow> t\<rangle>\<^bsub>n'\<^esub> \<or> \<not> (prefix (bc (\<sigma>\<^bsub>kid'\<^esub>(t n'))) (bc (\<sigma>\<^bsub>snd x\<^esub>(t (fst x)))) \<or> (\<exists>b. bc (\<sigma>\<^bsub>kid'\<^esub>(t n')) = (bc (\<sigma>\<^bsub>snd x\<^esub>(t (fst x)))) @ [b] \<and> mining (\<sigma>\<^bsub>kid'\<^esub>(t n')))))"
    hence "\<exists>n. latestAct_cond kid' t n' n" and "\<forall>x. \<not> \<parallel>snd x\<parallel>\<^bsub>t (fst x)\<^esub> \<or> \<not> fst x = \<langle>kid' \<Leftarrow> t\<rangle>\<^bsub>n'\<^esub> \<or> \<not> (prefix (bc (\<sigma>\<^bsub>kid'\<^esub>(t n'))) (bc (\<sigma>\<^bsub>snd x\<^esub>(t (fst x)))) \<or> (\<exists>b. bc (\<sigma>\<^bsub>kid'\<^esub>(t n')) = (bc (\<sigma>\<^bsub>snd x\<^esub>(t (fst x)))) @ [b] \<and> mining (\<sigma>\<^bsub>kid'\<^esub>(t n'))))" by auto
    hence asmp: "\<forall>x. \<parallel>snd x\<parallel>\<^bsub>t (fst x)\<^esub> \<longrightarrow> fst x = \<langle>kid' \<Leftarrow> t\<rangle>\<^bsub>n'\<^esub> \<longrightarrow> \<not> (prefix (bc (\<sigma>\<^bsub>kid'\<^esub>(t n'))) (bc (\<sigma>\<^bsub>snd x\<^esub>(t (fst x)))) \<or> (\<exists>b. bc (\<sigma>\<^bsub>kid'\<^esub>(t n')) = (bc (\<sigma>\<^bsub>snd x\<^esub>(t (fst x)))) @ [b] \<and> mining (\<sigma>\<^bsub>kid'\<^esub>(t n'))))" by auto
    show ?thesis
    proof cases
      assume "trusted kid'"
      moreover from assms(1) have "\<parallel>kid'\<parallel>\<^bsub>t n'\<^esub>" using his_act by simp
      ultimately obtain nid' where "\<parallel>nid'\<parallel>\<^bsub>t \<langle>kid' \<Leftarrow> t\<rangle>\<^bsub>n'\<^esub>\<^esub>" and "mining (\<sigma>\<^bsub>kid'\<^esub>t n') \<and> bc (\<sigma>\<^bsub>kid'\<^esub>t n') = bc (\<sigma>\<^bsub>nid'\<^esub>t \<langle>kid' \<Leftarrow> t\<rangle>\<^bsub>n'\<^esub>) @ [kid'] \<or> \<not> mining (\<sigma>\<^bsub>kid'\<^esub>t n') \<and> bc (\<sigma>\<^bsub>kid'\<^esub>t n') = bc (\<sigma>\<^bsub>nid'\<^esub>t \<langle>kid' \<Leftarrow> t\<rangle>\<^bsub>n'\<^esub>)" using \<open>\<exists>n. latestAct_cond kid' t n' n\<close> bhv_tr_context[of kid' t n'] by auto
      moreover from \<open>\<parallel>nid'\<parallel>\<^bsub>t \<langle>kid' \<Leftarrow> t\<rangle>\<^bsub>n'\<^esub>\<^esub>\<close> have "\<not> (prefix (bc (\<sigma>\<^bsub>kid'\<^esub>(t n'))) (bc (\<sigma>\<^bsub>nid'\<^esub>(t (\<langle>kid' \<Leftarrow> t\<rangle>\<^bsub>n'\<^esub>)))) \<or> (\<exists>b. bc (\<sigma>\<^bsub>kid'\<^esub>(t n')) = (bc (\<sigma>\<^bsub>nid'\<^esub>(t (\<langle>kid' \<Leftarrow> t\<rangle>\<^bsub>n'\<^esub>)))) @ [b] \<and> mining (\<sigma>\<^bsub>kid'\<^esub>(t n'))))" using asmp by auto
      ultimately have False by auto
      thus ?thesis ..
    next
      assume "\<not> trusted kid'"
      moreover from assms(1) have "\<parallel>kid'\<parallel>\<^bsub>t n'\<^esub>" using his_act by simp
      ultimately obtain nid' where "\<parallel>nid'\<parallel>\<^bsub>t \<langle>kid' \<Leftarrow> t\<rangle>\<^bsub>n'\<^esub>\<^esub>" and "(mining (\<sigma>\<^bsub>kid'\<^esub>t n') \<and> prefix (bc (\<sigma>\<^bsub>kid'\<^esub>t n')) (bc (\<sigma>\<^bsub>nid'\<^esub>t \<langle>kid' \<Leftarrow> t\<rangle>\<^bsub>n'\<^esub>) @ [kid']) \<or> \<not> mining (\<sigma>\<^bsub>kid'\<^esub>t n') \<and> prefix (bc (\<sigma>\<^bsub>kid'\<^esub>t n')) (bc (\<sigma>\<^bsub>nid'\<^esub>t \<langle>kid' \<Leftarrow> t\<rangle>\<^bsub>n'\<^esub>)))" using \<open>\<exists>n. latestAct_cond kid' t n' n\<close> bhv_ut_context[of kid' t n'] by auto
      moreover from \<open>\<parallel>nid'\<parallel>\<^bsub>t \<langle>kid' \<Leftarrow> t\<rangle>\<^bsub>n'\<^esub>\<^esub>\<close> have "\<not> (prefix (bc (\<sigma>\<^bsub>kid'\<^esub>(t n'))) (bc (\<sigma>\<^bsub>nid'\<^esub>(t (\<langle>kid' \<Leftarrow> t\<rangle>\<^bsub>n'\<^esub>)))) \<or> (\<exists>b. bc (\<sigma>\<^bsub>kid'\<^esub>(t n')) = (bc (\<sigma>\<^bsub>nid'\<^esub>(t (\<langle>kid' \<Leftarrow> t\<rangle>\<^bsub>n'\<^esub>)))) @ [b] \<and> mining (\<sigma>\<^bsub>kid'\<^esub>(t n'))))" using asmp by auto
      ultimately have False by auto
      thus ?thesis ..
    qed
  qed
qed

lemma devExt_devop:
  "prefix (devExt t n kid n\<^sub>s (Suc n')) (devExt t n kid n\<^sub>s n') \<or> (\<exists>b. devExt t n kid n\<^sub>s (Suc n') = devExt t n kid n\<^sub>s n' @ [b]) \<and> \<not> Option.is_none (devBC t n kid (n\<^sub>s + Suc n')) \<and> \<parallel>the (devBC t n kid (n\<^sub>s + Suc n'))\<parallel>\<^bsub>t (n\<^sub>s + Suc n')\<^esub> \<and> n\<^sub>s + Suc n' \<le> n \<and> mining (\<sigma>\<^bsub>the (devBC t n kid (n\<^sub>s + Suc n'))\<^esub>(t (n\<^sub>s + Suc n')))"
proof cases
  assume "n\<^sub>s + Suc n' > n"
  hence "\<not>(\<exists>kid'. (n\<^sub>s + Suc n', kid') \<in> his t n kid)" using his_le by fastforce
  hence "Option.is_none (devBC t n kid (n\<^sub>s + Suc n'))" using devBC_def by simp
  hence "devExt t n kid n\<^sub>s (Suc n') = devExt t n kid n\<^sub>s n'" by simp
  thus ?thesis by simp
next
  assume "\<not>n\<^sub>s + Suc n' > n"
  hence "n\<^sub>s + Suc n' \<le> n" by simp
  show ?thesis
  proof cases
    assume "Option.is_none (devBC t n kid (n\<^sub>s + Suc n'))"
    hence "devExt t n kid n\<^sub>s (Suc n') = devExt t n kid n\<^sub>s n'" by simp
    thus ?thesis by simp
  next
    assume "\<not> Option.is_none (devBC t n kid (n\<^sub>s + Suc n'))"
    hence "devExt t n kid n\<^sub>s (Suc n') = bc (\<sigma>\<^bsub>the (devBC t n kid (n\<^sub>s + Suc n'))\<^esub>(t (n\<^sub>s + Suc n')))" by simp
    moreover have "prefix (bc (\<sigma>\<^bsub>the (devBC t n kid (n\<^sub>s + Suc n'))\<^esub>(t (n\<^sub>s + Suc n')))) (devExt t n kid n\<^sub>s n') \<or> (\<exists>b. bc (\<sigma>\<^bsub>the (devBC t n kid (n\<^sub>s + Suc n'))\<^esub>(t (n\<^sub>s + Suc n'))) = devExt t n kid n\<^sub>s n' @ [b] \<and> \<not> Option.is_none (devBC t n kid (n\<^sub>s + Suc n')) \<and> \<parallel>the (devBC t n kid (n\<^sub>s + Suc n'))\<parallel>\<^bsub>t (n\<^sub>s + Suc n')\<^esub> \<and> n\<^sub>s + Suc n' \<le> n \<and> mining (\<sigma>\<^bsub>the (devBC t n kid (n\<^sub>s + Suc n'))\<^esub>(t (n\<^sub>s + Suc n'))))"
    proof cases
      assume "\<exists>n''<n\<^sub>s + Suc n'. \<exists>kid'. (n'',kid')\<in> his t n kid"
      let ?kid="(THE kid'. (n\<^sub>s + Suc n',kid')\<in>his t n kid)"
      let ?x="SOME x. his_prop t n kid (n\<^sub>s + Suc n') ?kid x"
      from \<open>\<not> Option.is_none (devBC t n kid (n\<^sub>s + Suc n'))\<close>
        have "n\<^sub>s + Suc n'\<le>n" using devExt_nopt_leq by simp
      moreover from \<open>\<not> Option.is_none (devBC t n kid (n\<^sub>s + Suc n'))\<close>
        have "\<exists>kid'. (n\<^sub>s + Suc n',kid')\<in>his t n kid" using his_ex by simp
      ultimately have "\<exists>x. his_prop t n kid (n\<^sub>s + Suc n') (THE kid'. ((n\<^sub>s + Suc n'),kid')\<in>his t n kid) x"
        and "(hisPred t n kid (n\<^sub>s + Suc n'), (SOME kid'. (hisPred t n kid (n\<^sub>s + Suc n'), kid') \<in> his t n kid)) = ?x"
        using \<open>\<exists>n''<n\<^sub>s + Suc n'. \<exists>kid'. (n'',kid')\<in> his t n kid\<close>
        his_determ_ext[of "n\<^sub>s + Suc n'" n t kid] by auto
      moreover have "bc (\<sigma>\<^bsub>(SOME kid'. (hisPred t n kid (n\<^sub>s + Suc n'), kid') \<in> his t n kid)\<^esub>(t (hisPred t n kid (n\<^sub>s + Suc n')))) = devExt t n kid n\<^sub>s n'"
      proof cases
        assume "Option.is_none (devBC t n kid (n\<^sub>s+n'))"
        have "devExt t n kid n\<^sub>s n' = bc (\<sigma>\<^bsub>the (devBC t n kid (GREATEST n''. n''<n\<^sub>s+n' \<and> \<not>Option.is_none (devBC t n kid n'')))\<^esub>(t (GREATEST n''. n''<n\<^sub>s+n' \<and> \<not>Option.is_none (devBC t n kid n''))))"
        proof cases
          assume "n'=0"
          moreover have "\<exists>n''<n\<^sub>s+n'. \<not>Option.is_none (devBC t n kid n'')"
          proof -
            from \<open>\<exists>n''<n\<^sub>s + Suc n'. \<exists>kid'. (n'',kid')\<in> his t n kid\<close> obtain n''
              where "n''<Suc n\<^sub>s + n'" and "\<exists>kid'. (n'',kid')\<in> his t n kid" by auto
            hence "\<not> Option.is_none (devBC t n kid n'')" using devBC_def by simp
            moreover from \<open>\<not> Option.is_none (devBC t n kid n'')\<close>
              \<open>Option.is_none (devBC t n kid (n\<^sub>s+n'))\<close> have "\<not> n''=n\<^sub>s+n'" by auto
            with \<open>n''<Suc n\<^sub>s+n'\<close> have "n''<n\<^sub>s+n'" by simp
            ultimately show ?thesis by auto
          qed
          ultimately show ?thesis using \<open>Option.is_none (devBC t n kid (n\<^sub>s+n'))\<close> by simp
        next
          assume "\<not> n'=0"
          moreover have "\<exists>n''<n\<^sub>s + n'. \<not> Option.is_none (devBC t n kid n'')"
          proof -
            from \<open>\<exists>n''<n\<^sub>s + Suc n'. \<exists>kid'. (n'',kid')\<in> his t n kid\<close> obtain n''
              where "n''<Suc n\<^sub>s + n'" and "\<exists>kid'. (n'',kid')\<in> his t n kid" by auto
            hence "\<not> Option.is_none (devBC t n kid n'')" using devBC_def by simp
            moreover from \<open>\<not> Option.is_none (devBC t n kid n'')\<close> \<open>Option.is_none (devBC t n kid (n\<^sub>s+n'))\<close>
              have "\<not> n''=n\<^sub>s+n'" by auto
            with \<open>n''<Suc n\<^sub>s+n'\<close> have "n''<n\<^sub>s+n'" by simp
            ultimately show ?thesis by auto
          qed
          with \<open>\<not> (n'=0)\<close> \<open>Option.is_none (devBC t n kid (n\<^sub>s+n'))\<close> show ?thesis
            using devExt_greatest[of n\<^sub>s n' t n kid] by simp
        qed
        moreover have "(GREATEST n''. n''<n\<^sub>s+n' \<and> \<not>Option.is_none (devBC t n kid n''))=hisPred t n kid (n\<^sub>s + Suc n')"
        proof -
          have "(\<lambda>n''. n''<n\<^sub>s+n' \<and> \<not>Option.is_none (devBC t n kid n'')) = (\<lambda>n''. \<exists>kid'. (n'',kid')\<in> his t n kid \<and> n'' < n\<^sub>s + Suc n')"
          proof
            fix n''
            show "(n'' < n\<^sub>s + n' \<and> \<not> Option.is_none (devBC t n kid n'')) = (\<exists>kid'. (n'', kid') \<in> his t n kid \<and> n'' < n\<^sub>s + Suc n')"
            proof
              assume "n'' < n\<^sub>s + n' \<and> \<not> Option.is_none (devBC t n kid n'')"
              thus "(\<exists>kid'. (n'', kid') \<in> his t n kid \<and> n'' < n\<^sub>s + Suc n')" using his_ex by simp
            next
              assume "(\<exists>kid'. (n'', kid') \<in> his t n kid \<and> n'' < n\<^sub>s + Suc n')"
              hence "\<exists>kid'. (n'', kid') \<in> his t n kid" and "n'' < n\<^sub>s + Suc n'" by auto
              hence "\<not> Option.is_none (devBC t n kid n'')" using devBC_def by simp
              moreover from \<open>\<not> Option.is_none (devBC t n kid n'')\<close> \<open>Option.is_none (devBC t n kid (n\<^sub>s+n'))\<close>
              have "n''\<noteq>n\<^sub>s+n'" by auto
              with \<open>n'' < n\<^sub>s + Suc n'\<close> have "n'' < n\<^sub>s + n'" by simp
              ultimately show "n'' < n\<^sub>s + n' \<and> \<not> Option.is_none (devBC t n kid n'')" by simp
            qed
          qed
          hence "(GREATEST n''. n''<n\<^sub>s+n' \<and> \<not>Option.is_none (devBC t n kid n''))= (GREATEST n''. \<exists>kid'. (n'',kid')\<in> his t n kid \<and> n'' < n\<^sub>s + Suc n')" using arg_cong[of "\<lambda>n''. n''<n\<^sub>s+n' \<and> \<not>Option.is_none (devBC t n kid n'')" "(\<lambda>n''. \<exists>kid'. (n'',kid')\<in> his t n kid \<and> n'' < n\<^sub>s + Suc n')"] by simp
          with hisPred_def show ?thesis by simp
        qed
        moreover have "the (devBC t n kid (hisPred t n kid (n\<^sub>s + Suc n')))=(SOME kid'. (hisPred t n kid (n\<^sub>s + Suc n'), kid') \<in> his t n kid)"
        proof -
          from \<open>\<exists>n''<n\<^sub>s + Suc n'. \<exists>kid'. (n'',kid')\<in> his t n kid\<close>
            have "\<exists>kid'. (hisPred t n kid (n\<^sub>s + Suc n'), kid')\<in> his t n kid"
            using hisPrev_prop(2) by simp
          hence "the (devBC t n kid (hisPred t n kid (n\<^sub>s + Suc n'))) = (THE kid'. (hisPred t n kid (n\<^sub>s + Suc n'), kid')\<in>his t n kid)"
            using devBC_def by simp
          moreover from \<open>\<exists>kid'. (hisPred t n kid (n\<^sub>s + Suc n'), kid')\<in> his t n kid\<close>
            have "(hisPred t n kid (n\<^sub>s + Suc n'), SOME kid'. (hisPred t n kid (n\<^sub>s + Suc n'), kid') \<in> his t n kid) \<in> his t n kid"
            using someI_ex[of "\<lambda>kid'. (hisPred t n kid (n\<^sub>s + Suc n'), kid')\<in>his t n kid"] by simp
          hence "(THE kid'. (hisPred t n kid (n\<^sub>s + Suc n'), kid')\<in>his t n kid) = (SOME kid'. (hisPred t n kid (n\<^sub>s + Suc n'), kid') \<in> his t n kid)"
            using his_determ_the by simp
          ultimately show ?thesis by simp
        qed
        ultimately show ?thesis by simp
      next
        assume "\<not> Option.is_none (devBC t n kid (n\<^sub>s+n'))"
        hence "devExt t n kid n\<^sub>s n' = bc (\<sigma>\<^bsub>the (devBC t n kid (n\<^sub>s+n'))\<^esub>(t (n\<^sub>s+n')))"
        proof cases
          assume "n'=0"
          with \<open>\<not> Option.is_none (devBC t n kid (n\<^sub>s+n'))\<close> show ?thesis by simp
        next
          assume "\<not> n'=0"
          hence "\<exists>nat. n' = Suc nat" by presburger
          then obtain nat where "n' = Suc nat" by auto
          with \<open>\<not> Option.is_none (devBC t n kid (n\<^sub>s+n'))\<close> have "devExt t n kid n\<^sub>s (Suc nat) = bc (\<sigma>\<^bsub>the (devBC t n kid (n\<^sub>s + Suc nat))\<^esub>(t (n\<^sub>s + Suc nat)))" by simp
          with \<open>n' = Suc nat\<close>  show ?thesis by simp
        qed
        moreover have "hisPred t n kid (n\<^sub>s + Suc n') = n\<^sub>s+n'"
        proof -
          have "(GREATEST n''. \<exists>kid'. (n'',kid')\<in> his t n kid \<and> n'' < (n\<^sub>s + Suc n')) = n\<^sub>s+n'"
          proof (rule Greatest_equality)
            from \<open>\<not> Option.is_none (devBC t n kid (n\<^sub>s+n'))\<close> have "\<exists>kid'. (n\<^sub>s + n', kid') \<in> his t n kid" using his_ex by simp
            thus "\<exists>kid'. (n\<^sub>s + n', kid') \<in> his t n kid \<and> n\<^sub>s + n' < n\<^sub>s + Suc n'" by simp
          next
            fix y assume "\<exists>kid'. (y, kid') \<in> his t n kid \<and> y < n\<^sub>s + Suc n'"
            thus "y \<le> n\<^sub>s + n'" by simp
          qed
          thus ?thesis using hisPred_def by simp
        qed
        moreover have "the (devBC t n kid (hisPred t n kid (n\<^sub>s + Suc n')))=(SOME kid'. (hisPred t n kid (n\<^sub>s + Suc n'), kid') \<in> his t n kid)"
        proof -
          from \<open>\<exists>n''<n\<^sub>s + Suc n'. \<exists>kid'. (n'',kid')\<in> his t n kid\<close>
            have "\<exists>kid'. (hisPred t n kid (n\<^sub>s + Suc n'), kid')\<in> his t n kid"
            using hisPrev_prop(2) by simp
          hence "the (devBC t n kid (hisPred t n kid (n\<^sub>s + Suc n'))) = (THE kid'. (hisPred t n kid (n\<^sub>s + Suc n'), kid')\<in>his t n kid)"
            using devBC_def by simp
          moreover from \<open>\<exists>kid'. (hisPred t n kid (n\<^sub>s + Suc n'), kid')\<in> his t n kid\<close>
            have "(hisPred t n kid (n\<^sub>s + Suc n'), SOME kid'. (hisPred t n kid (n\<^sub>s + Suc n'), kid') \<in> his t n kid) \<in> his t n kid"
            using someI_ex[of "\<lambda>kid'. (hisPred t n kid (n\<^sub>s + Suc n'), kid')\<in>his t n kid"] by simp
          hence "(THE kid'. (hisPred t n kid (n\<^sub>s + Suc n'), kid')\<in>his t n kid) = (SOME kid'. (hisPred t n kid (n\<^sub>s + Suc n'), kid') \<in> his t n kid)"
            using his_determ_the by simp
          ultimately show ?thesis by simp
        qed
        ultimately show ?thesis by simp
      qed
      ultimately have "bc (\<sigma>\<^bsub>snd ?x\<^esub>(t (fst ?x))) = devExt t n kid n\<^sub>s n'"
        using fst_conv[of "hisPred t n kid (n\<^sub>s + Suc n')"
        "(SOME kid'. (hisPred t n kid (n\<^sub>s + Suc n'), kid') \<in> his t n kid)"]
        snd_conv[of "hisPred t n kid (n\<^sub>s + Suc n')"
        "(SOME kid'. (hisPred t n kid (n\<^sub>s + Suc n'), kid') \<in> his t n kid)"] by simp
      moreover from \<open>\<exists>x. his_prop t n kid (n\<^sub>s + Suc n') ?kid x\<close>
        have "his_prop t n kid (n\<^sub>s + Suc n') ?kid ?x"
        using someI_ex[of "\<lambda>x. his_prop t n kid (n\<^sub>s + Suc n') ?kid x"] by blast
      hence "prefix (bc (\<sigma>\<^bsub>?kid\<^esub>(t (n\<^sub>s + Suc n')))) (bc (\<sigma>\<^bsub>snd ?x\<^esub>(t (fst ?x)))) \<or> (\<exists>b. bc (\<sigma>\<^bsub>?kid\<^esub>(t (n\<^sub>s + Suc n'))) = (bc (\<sigma>\<^bsub>snd ?x\<^esub>(t (fst ?x)))) @ [b] \<and> mining (\<sigma>\<^bsub>?kid\<^esub>(t (n\<^sub>s + Suc n'))))" by blast
      ultimately have "prefix (bc (\<sigma>\<^bsub>?kid\<^esub>(t (n\<^sub>s + Suc n')))) (devExt t n kid n\<^sub>s n') \<or> (\<exists>b. bc (\<sigma>\<^bsub>?kid\<^esub>(t (n\<^sub>s + Suc n'))) = (devExt t n kid n\<^sub>s n') @ [b] \<and> mining (\<sigma>\<^bsub>?kid\<^esub>(t (n\<^sub>s + Suc n'))))" by simp
      moreover from \<open>\<exists>kid'. (n\<^sub>s + Suc n',kid')\<in> his t n kid\<close>
        have "?kid=the (devBC t n kid (n\<^sub>s + Suc n'))" using devBC_def by simp
      moreover have "\<parallel>the (devBC t n kid (n\<^sub>s + Suc n'))\<parallel>\<^bsub>t (n\<^sub>s + Suc n')\<^esub>"
      proof -
        from \<open>\<exists>kid'. (n\<^sub>s + Suc n',kid')\<in>his t n kid\<close> obtain kid'
          where "(n\<^sub>s + Suc n',kid')\<in>his t n kid" by auto
        with his_determ_the have "kid' = (THE kid'. (n\<^sub>s + Suc n', kid') \<in> his t n kid)" by simp
        with \<open>?kid=the (devBC t n kid (n\<^sub>s + Suc n'))\<close>
          have "the (devBC t n kid (n\<^sub>s + Suc n')) = kid'" by simp
        with \<open>(n\<^sub>s + Suc n',kid')\<in>his t n kid\<close> show ?thesis using his_act by simp
      qed
      ultimately show ?thesis
        using \<open>\<not> Option.is_none (devBC t n kid (n\<^sub>s+Suc n'))\<close> \<open>n\<^sub>s + Suc n' \<le> n\<close> by simp
    next
      assume "\<not> (\<exists>n''<n\<^sub>s + Suc n'. \<exists>kid'. (n'',kid')\<in> his t n kid)"
      moreover have "(n\<^sub>s + Suc n', the (devBC t n kid (n\<^sub>s + Suc n'))) \<in> his t n kid"
      proof -
        from \<open>\<not> Option.is_none (devBC t n kid (n\<^sub>s + Suc n'))\<close>
          have "\<exists>kid'. (n\<^sub>s + Suc n',kid')\<in>his t n kid" using his_ex by simp
        hence "the (devBC t n kid (n\<^sub>s + Suc n')) = (THE kid'. (n\<^sub>s + Suc n', kid') \<in> his t n kid)"
          using devBC_def by simp
        moreover from \<open>\<exists>kid'. (n\<^sub>s + Suc n',kid')\<in>his t n kid\<close> obtain kid'
          where "(n\<^sub>s + Suc n',kid')\<in>his t n kid" by auto
        with his_determ_the have "kid' = (THE kid'. (n\<^sub>s + Suc n', kid') \<in> his t n kid)" by simp
        ultimately have "the (devBC t n kid (n\<^sub>s + Suc n')) = kid'" by simp
        with \<open>(n\<^sub>s + Suc n',kid')\<in>his t n kid\<close> show ?thesis by simp
      qed
      ultimately have "bc (\<sigma>\<^bsub>the (devBC t n kid (n\<^sub>s + Suc n'))\<^esub>(t (n\<^sub>s + Suc n'))) = []"
        using his_bc_empty by simp
      thus ?thesis by simp
    qed
    ultimately show ?thesis by simp
  qed
qed

abbreviation devLgthBC where "devLgthBC t n kid n\<^sub>s \<equiv> (\<lambda>n'. length (devExt t n kid n\<^sub>s n'))"

theorem blockchain_save:
  fixes t::"nat\<Rightarrow>cnf" and n\<^sub>s and sbc and n
  assumes "\<forall>nid. trusted nid \<longrightarrow> prefix sbc (bc (\<sigma>\<^bsub>nid\<^esub>(t (\<langle>nid \<rightarrow> t\<rangle>\<^bsub>n\<^sub>s\<^esub>))))"
    and "\<forall>nid\<in>actUt (t n\<^sub>s). length (bc (\<sigma>\<^bsub>nid\<^esub>(t n\<^sub>s))) < length sbc"
    and "PoW t n\<^sub>s\<ge>length sbc + cb"
    and "\<forall>n'<n\<^sub>s. \<forall>nid. \<parallel>nid\<parallel>\<^bsub>t n'\<^esub> \<longrightarrow> length (bc (\<sigma>\<^bsub>nid\<^esub>t n')) < length sbc \<or> prefix sbc (bc (\<sigma>\<^bsub>nid\<^esub>(t n')))"
    and "n\<ge>n\<^sub>s"
  shows "\<forall>nid \<in> actTr (t n). prefix sbc (bc (\<sigma>\<^bsub>nid\<^esub>(t n)))"
proof (cases)
  assume "sbc=[]"
  thus ?thesis by simp
next
  assume "\<not> sbc=[]"
  have "n\<ge>n\<^sub>s \<Longrightarrow> \<forall>nid \<in> actTr (t n). prefix sbc (bc (\<sigma>\<^bsub>nid\<^esub>(t n)))"
  proof (induction n rule: ge_induct)
    case (step n)
    show ?case
    proof
      fix nid assume "nid \<in> actTr (t n)"
      hence "\<parallel>nid\<parallel>\<^bsub>t n\<^esub>" and "trusted nid" using actTr_def by auto
      show "prefix sbc (bc (\<sigma>\<^bsub>nid\<^esub>t n))"
      proof cases
        assume lAct: "\<exists>n' < n. n' \<ge> n\<^sub>s \<and> \<parallel>nid\<parallel>\<^bsub>t n'\<^esub>"    
        show ?thesis
        proof cases
          assume "\<exists>b\<in>pin (\<sigma>\<^bsub>nid\<^esub>t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>). length b > length (bc (\<sigma>\<^bsub>nid\<^esub>t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>))"
          moreover from \<open>\<parallel>nid\<parallel>\<^bsub>t n\<^esub>\<close> have "\<exists>n'\<ge>n. \<parallel>nid\<parallel>\<^bsub>t n'\<^esub>" by auto
          moreover from lAct have "\<exists>n'. latestAct_cond nid t n n'" by auto
          ultimately have "\<not> mining (\<sigma>\<^bsub>nid\<^esub>t \<langle>nid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>) \<and> bc (\<sigma>\<^bsub>nid\<^esub>t \<langle>nid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>) = MAX (pin (\<sigma>\<^bsub>nid\<^esub>t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)) \<or>
            mining (\<sigma>\<^bsub>nid\<^esub>t \<langle>nid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>) \<and> bc (\<sigma>\<^bsub>nid\<^esub>t \<langle>nid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>) = MAX (pin (\<sigma>\<^bsub>nid\<^esub>t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)) @ [nid]"
            using \<open>trusted nid\<close> bhv_tr_ex[of nid n t] by simp
          moreover have "prefix sbc (MAX (pin (\<sigma>\<^bsub>nid\<^esub>t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)))"
          proof -
            from \<open>\<exists>n'. latestAct_cond nid t n n'\<close> have "\<parallel>nid\<parallel>\<^bsub>t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>\<^esub>"
              using latestAct_prop(1) by simp
            hence "pin (\<sigma>\<^bsub>nid\<^esub>t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>) \<noteq> {}" and "finite (pin (\<sigma>\<^bsub>nid\<^esub>t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>))"
              using nempty_input[of nid t "\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>"] finite_input[of nid t "\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>"] \<open>trusted nid\<close> by auto
            hence "MAX (pin (\<sigma>\<^bsub>nid\<^esub>t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)) \<in> pin (\<sigma>\<^bsub>nid\<^esub>t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)" using max_prop(1) by auto
            with closed[of "MAX (pin (\<sigma>\<^bsub>nid\<^esub>t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>))" nid t "\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>"] obtain kid
              where "\<parallel>kid\<parallel>\<^bsub>t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>\<^esub>"
              and "pout (\<sigma>\<^bsub>kid\<^esub>(t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)) = MAX (pin (\<sigma>\<^bsub>nid\<^esub>t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>))" by auto
            moreover have "prefix sbc (bc (\<sigma>\<^bsub>kid\<^esub>(t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)))"
            proof cases
              assume "trusted kid"
              with \<open>\<parallel>kid\<parallel>\<^bsub>t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>\<^esub>\<close> have "kid \<in> actTr (t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)"
                using actTr_def by simp
              moreover from \<open>\<exists>n'. latestAct_cond nid t n n'\<close> have "\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> < n"
                using latestAct_prop(2) by simp
              moreover from lAct have "\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> \<ge> n\<^sub>s" using latestActless by blast
              ultimately show ?thesis using \<open>\<parallel>kid\<parallel>\<^bsub>t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>\<^esub>\<close> step.IH by simp
            next
              assume "\<not> trusted kid"
              show ?thesis
              proof (rule ccontr)
                assume "\<not> prefix sbc (bc (\<sigma>\<^bsub>kid\<^esub>(t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)))"
                moreover have "\<exists>n'\<le>\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>. n'\<ge>n\<^sub>s \<and> length (devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n' 0) < length sbc \<and> (\<forall>n''>n'. n''\<le>\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> \<and> \<not> Option.is_none (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n'') \<longrightarrow> \<not> trusted (the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n'')))"
                proof cases
                  assume "\<exists>n'\<le>\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>. n'\<ge>n\<^sub>s \<and> \<not> Option.is_none (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n') \<and> trusted (the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n'))"
                  hence "\<exists>n'\<le>\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>. n'\<ge>n\<^sub>s \<and> \<not> Option.is_none (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n') \<and> trusted (the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n')) \<and> (\<forall>n''>n'. n''\<le>\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> \<and> \<not> Option.is_none (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n'') \<longrightarrow> \<not> trusted (the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n'')))"
                  proof -
                    let ?P="\<lambda>n'. n'\<le>\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> \<and> n'\<ge>n\<^sub>s  \<and> \<not> Option.is_none (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n') \<and> trusted (the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n'))"
                    from \<open>\<exists>n'\<le>\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>. n'\<ge>n\<^sub>s  \<and> \<not> Option.is_none (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n') \<and> trusted (the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n'))\<close> have "\<exists>n'. ?P n'" by simp
                    moreover have "\<forall>n'>\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>. \<not> ?P n'" by simp
                    ultimately obtain n' where "?P n'" and "\<forall>n''. ?P n'' \<longrightarrow> n''\<le>n'" using boundedGreatest[of ?P _ "\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>"] by auto
                    hence "\<forall>n''>n'. n''\<le>\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> \<and> \<not> Option.is_none (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n'') \<longrightarrow> \<not> trusted (the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n''))" by auto
                    thus ?thesis using \<open>?P n'\<close> by auto
                  qed
                  then obtain n' where "n'\<le>\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>" and "\<not> Option.is_none (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n')"
                    and "n'\<ge>n\<^sub>s" and "trusted (the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n'))"
                    and "\<forall>n''>n'. n''\<le>\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> \<and> \<not> Option.is_none (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n'') \<longrightarrow> \<not> trusted (the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n''))" by auto
                  hence "n'\<ge>n\<^sub>s" and untrusted: "\<forall>n''>n'. n''\<le>\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> \<and> \<not> Option.is_none (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n'') \<longrightarrow> \<not> trusted (the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n''))" by auto
                  moreover have "\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub><n" using \<open>\<exists>n'. latestAct_cond nid t n n'\<close> latestAct_prop(2) by blast
                  with \<open>n'\<le>\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>\<close> have "n'<n" by simp
                  moreover from \<open>\<not> Option.is_none (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n')\<close>
                    have "\<parallel>the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n')\<parallel>\<^bsub>t n'\<^esub>" using devBC_act by simp
                  with \<open>trusted (the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n'))\<close>
                    have "the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n') \<in>actTr (t n')" using actTr_def by simp
                  ultimately have "prefix sbc (bc (\<sigma>\<^bsub>the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n')\<^esub>t n'))"
                    using step.IH by simp
  
                  interpret ut: untrusted "devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n'" "\<lambda>n. umining t (n' + n)"
                  proof
                    fix n''
                    from devExt_devop[of t "\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>" kid n'] have "prefix (devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n' (Suc n'')) (devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n' n'') \<or> (\<exists>b. devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n' (Suc n'') = devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n' n'' @ [b]) \<and> \<not> Option.is_none (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid (n' + Suc n'')) \<and> \<parallel>the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid (n' + Suc n''))\<parallel>\<^bsub>t (n' + Suc n'')\<^esub> \<and> n' + Suc n'' \<le> \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> \<and> mining (\<sigma>\<^bsub>the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid (n' + Suc n''))\<^esub>t (n' + Suc n''))" .
                    thus "prefix (devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n' (Suc n'')) (devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n' n'') \<or> (\<exists>b. devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n' (Suc n'') = devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n' n'' @ [b]) \<and> umining t (n' + Suc n'')"
                    proof
                      assume "prefix (devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n' (Suc n'')) (devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n' n'')"
                      thus ?thesis by simp
                    next
                      assume "(\<exists>b. devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n' (Suc n'') = devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n' n'' @ [b]) \<and> \<not> Option.is_none (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid (n' + Suc n'')) \<and> \<parallel>the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid (n' + Suc n''))\<parallel>\<^bsub>t (n' + Suc n'')\<^esub> \<and> n' + Suc n'' \<le> \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> \<and> mining (\<sigma>\<^bsub>the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid (n' + Suc n''))\<^esub>t (n' + Suc n''))"
                      hence "\<exists>b. devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n' (Suc n'') = devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n' n'' @ [b]" and "\<not> Option.is_none (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid (n' + Suc n''))" and "\<parallel>the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid (n' + Suc n''))\<parallel>\<^bsub>t (n' + Suc n'')\<^esub>" and "n' + Suc n'' \<le> \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>" and "mining (\<sigma>\<^bsub>the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid (n' + Suc n''))\<^esub>t (n' + Suc n''))" by auto
                      moreover from \<open>n' + Suc n'' \<le> \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>\<close> \<open>\<not> Option.is_none (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid (n' + Suc n''))\<close> have "\<not> trusted (the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid (n' + Suc n'')))" using untrusted by simp
                      with \<open>\<parallel>the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid (n' + Suc n''))\<parallel>\<^bsub>t (n' + Suc n'')\<^esub>\<close> have "the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid (n' + Suc n''))\<in>actUt (t (n' + Suc n''))" using actUt_def by simp
                      ultimately show ?thesis using umining_def by auto
                    qed
                  qed
                  from \<open>\<not> Option.is_none (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n')\<close> have "bc (\<sigma>\<^bsub>the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n')\<^esub>t n') = devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n' 0"
                    using devExt_bc_geq[of t "\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>" kid n'] by simp
                  moreover from \<open>n'\<le>\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>\<close> \<open>\<parallel>kid\<parallel>\<^bsub>t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>\<^esub>\<close> have "bc (\<sigma>\<^bsub>kid\<^esub>t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>) = devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n' (\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>-n')"
                    using devExt_bc_geq by simp
                  with \<open>\<not> prefix sbc (bc (\<sigma>\<^bsub>kid\<^esub>(t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)))\<close> have "\<not> prefix sbc (devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n' (\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>-n'))" by simp
                  ultimately have "\<exists>n'''. n''' \<le> \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>-n' \<and> length (devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n' n''') < length sbc"
                    using \<open>prefix sbc (bc (\<sigma>\<^bsub>the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n')\<^esub>(t n')))\<close>
                    ut.prefix_length[of sbc 0 "\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>-n'"] by auto
                  then obtain n\<^sub>p where "n\<^sub>p \<le> \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>-n'"
                    and "length (devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n' n\<^sub>p) < length sbc" by auto
                  hence "length (devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid (n' + n\<^sub>p) 0) < length sbc" using devExt_shift[of t "\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>" kid n' n\<^sub>p] by simp
                  moreover from \<open>\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>\<ge>n'\<close> \<open>n\<^sub>p \<le> \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>-n'\<close> have "(n' + n\<^sub>p) \<le> \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>" by simp
                  ultimately show ?thesis using \<open>n'\<ge>n\<^sub>s\<close> untrusted by auto
                next
                  assume "\<not>(\<exists>n'\<le>\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>. n'\<ge>n\<^sub>s \<and> \<not> Option.is_none (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n') \<and> trusted (the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n')))"
                  hence cas: "\<forall>n'\<le>\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>. n'\<ge>n\<^sub>s \<and> \<not> Option.is_none (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n') \<longrightarrow> \<not> trusted (the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n'))" by auto
                  show ?thesis
                  proof cases
                    assume "Option.is_none (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n\<^sub>s)"
                    thus ?thesis
                    proof cases
                      assume "\<forall>n'<n\<^sub>s. Option.is_none (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n')"
                      with \<open>Option.is_none (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n\<^sub>s)\<close> have "devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n\<^sub>s 0 = []" by simp
                      with \<open>\<not> sbc=[]\<close> have "length (devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n\<^sub>s 0) < length sbc" by simp
                      moreover from lAct have "\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>\<ge>n\<^sub>s" using latestActless by blast
                      moreover from cas have "\<forall>n''>n\<^sub>s. n''\<le>\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> \<and> \<not> Option.is_none (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n'') \<longrightarrow> \<not> trusted (the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n''))" by simp
                      ultimately show ?thesis by auto
                    next
                      let ?P="\<lambda>n'. n'<n\<^sub>s \<and> \<not>Option.is_none (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n')"
                      let ?n'="GREATEST n'. ?P n'"
                      assume "\<not> (\<forall>n'<n\<^sub>s. Option.is_none (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n'))"
                      moreover have "\<forall>n'>n\<^sub>s. \<not> ?P n'" by simp
                      ultimately have exists: "\<exists>n'. ?P n' \<and> (\<forall>n''. ?P n''\<longrightarrow> n''\<le>n')"
                        using boundedGreatest[of ?P] by blast
                      hence "?P ?n'" using GreatestI_ex_nat[of ?P] by auto
                      moreover from \<open>?P ?n'\<close> have "\<parallel>the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid ?n')\<parallel>\<^bsub>t ?n'\<^esub>" using devBC_act by simp
                      ultimately have "length (bc (\<sigma>\<^bsub>the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid ?n')\<^esub>t ?n')) < length sbc \<or> prefix sbc (bc (\<sigma>\<^bsub>the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid ?n')\<^esub>(t ?n')))" using assms(4) by simp
                      thus ?thesis
                      proof
                        assume "length (bc (\<sigma>\<^bsub>the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid ?n')\<^esub>t ?n')) < length sbc"
                        moreover from exists have "\<not>(\<exists>n'>?n'. ?P n')" using Greatest_ex_le_nat[of ?P] by simp
                        moreover from \<open>?P ?n'\<close> have "\<exists>n'<n\<^sub>s. \<not> Option.is_none (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n')" by blast
                        with \<open>Option.is_none (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n\<^sub>s)\<close>
                          have "devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n\<^sub>s 0 = bc (\<sigma>\<^bsub>the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid ?n')\<^esub>(t ?n'))" by simp
                        ultimately have "length (devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n\<^sub>s 0) < length sbc" by simp
                        moreover from lAct have "\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>\<ge>n\<^sub>s" using latestActless by blast
                        moreover from cas have "\<forall>n''>n\<^sub>s. n''\<le>\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> \<and> \<not> Option.is_none (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n'') \<longrightarrow> \<not> trusted (the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n''))" by simp
                        ultimately show ?thesis by auto
                      next
                        interpret ut: untrusted "devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n\<^sub>s" "\<lambda>n. umining t (n\<^sub>s + n)"
                        proof
                          fix n''
                          from devExt_devop[of t "\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>" kid n\<^sub>s] have "prefix (devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n\<^sub>s (Suc n'')) (devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n\<^sub>s n'') \<or> (\<exists>b. devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n\<^sub>s (Suc n'') = devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n\<^sub>s n'' @ [b]) \<and> \<not> Option.is_none (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid (n\<^sub>s + Suc n'')) \<and> \<parallel>the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid (n\<^sub>s + Suc n''))\<parallel>\<^bsub>t (n\<^sub>s + Suc n'')\<^esub> \<and> n\<^sub>s + Suc n'' \<le> \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> \<and> mining (\<sigma>\<^bsub>the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid (n\<^sub>s + Suc n''))\<^esub>t (n\<^sub>s + Suc n''))" .
                          thus "prefix (devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n\<^sub>s (Suc n'')) (devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n\<^sub>s n'') \<or> (\<exists>b. devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n\<^sub>s (Suc n'') = devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n\<^sub>s n'' @ [b]) \<and> umining t (n\<^sub>s + Suc n'')"
                          proof
                            assume "prefix (devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n\<^sub>s (Suc n'')) (devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n\<^sub>s n'')" thus ?thesis by simp
                          next
                            assume "(\<exists>b. devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n\<^sub>s (Suc n'') = devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n\<^sub>s n'' @ [b]) \<and> \<not> Option.is_none (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid (n\<^sub>s + Suc n'')) \<and> \<parallel>the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid (n\<^sub>s + Suc n''))\<parallel>\<^bsub>t (n\<^sub>s + Suc n'')\<^esub> \<and> n\<^sub>s + Suc n'' \<le> \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> \<and> mining (\<sigma>\<^bsub>the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid (n\<^sub>s + Suc n''))\<^esub>t (n\<^sub>s + Suc n''))"
                            hence "\<exists>b. devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n\<^sub>s (Suc n'') = devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n\<^sub>s n'' @ [b]"
                              and "\<not> Option.is_none (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid (n\<^sub>s + Suc n''))"
                              and "\<parallel>the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid (n\<^sub>s + Suc n''))\<parallel>\<^bsub>t (n\<^sub>s + Suc n'')\<^esub>"
                              and "n\<^sub>s + Suc n'' \<le> \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>"
                              and "mining (\<sigma>\<^bsub>the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid (n\<^sub>s + Suc n''))\<^esub>t (n\<^sub>s + Suc n''))"
                              by auto
                            moreover from \<open>n\<^sub>s + Suc n'' \<le> \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>\<close> \<open>\<not> Option.is_none (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid (n\<^sub>s + Suc n''))\<close>
                              have "\<not> trusted (the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid (n\<^sub>s + Suc n'')))"
                              using cas by simp
                            with \<open>\<parallel>the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid (n\<^sub>s + Suc n''))\<parallel>\<^bsub>t (n\<^sub>s + Suc n'')\<^esub>\<close>
                              have "the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid (n\<^sub>s + Suc n''))\<in>actUt (t (n\<^sub>s + Suc n''))" using actUt_def by simp
                            ultimately show ?thesis using umining_def by auto
                          qed
                        qed
  
                        assume "prefix sbc (bc (\<sigma>\<^bsub>the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid ?n')\<^esub>(t ?n')))"
                        moreover from exists have "\<not>(\<exists>n'>?n'. ?P n')" using Greatest_ex_le_nat[of ?P] by simp
                        moreover from \<open>?P ?n'\<close> have "\<exists>n'<n\<^sub>s. \<not> Option.is_none (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n')" by blast
                        with \<open>Option.is_none (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n\<^sub>s)\<close> have "devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n\<^sub>s 0 = bc (\<sigma>\<^bsub>the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid ?n')\<^esub>(t ?n'))" by simp
                        ultimately have "prefix sbc (devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n\<^sub>s 0)" by simp
                        moreover from lAct have "\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>\<ge>n\<^sub>s" using latestActless by blast
                        with \<open>\<parallel>kid\<parallel>\<^bsub>t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>\<^esub>\<close> have "bc (\<sigma>\<^bsub>the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)\<^esub>t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>) = devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n\<^sub>s (\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>-n\<^sub>s)" using devExt_bc_geq by simp
                        with \<open>\<not> prefix sbc (bc (\<sigma>\<^bsub>kid\<^esub>(t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)))\<close> \<open>\<parallel>kid\<parallel>\<^bsub>t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>\<^esub>\<close> have "\<not> prefix sbc (devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n\<^sub>s (\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>-n\<^sub>s))" by simp
                        ultimately have "\<exists>n'''>0. n''' \<le> \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>-n\<^sub>s \<and> length (devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n\<^sub>s n''') < length sbc" using ut.prefix_length[of sbc 0 "\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>-n\<^sub>s"] by simp
                        then obtain n\<^sub>p where "n\<^sub>p>0" and "n\<^sub>p \<le> \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>-n\<^sub>s" and "length (devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n\<^sub>s n\<^sub>p) < length sbc" by auto
                        hence "length (devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid (n\<^sub>s + n\<^sub>p) 0) < length sbc" using devExt_shift by simp
                        moreover from lAct have "\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>\<ge>n\<^sub>s" using latestActless by blast
                        with \<open>n\<^sub>p \<le> \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>-n\<^sub>s\<close> have "(n\<^sub>s + n\<^sub>p) \<le> \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>" by simp
                        moreover from \<open>n\<^sub>p \<le> \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>-n\<^sub>s\<close> have "n\<^sub>p \<le> \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>" by simp
                        moreover have "\<forall>n''>n\<^sub>s + n\<^sub>p. n'' \<le> \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> \<and> \<not> Option.is_none (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n'') \<longrightarrow> \<not> trusted (the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n''))" using cas by simp
                        ultimately show ?thesis by auto
                      qed
                    qed
                  next
                    assume asmp: "\<not> Option.is_none (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n\<^sub>s)"
                    moreover from lAct have "n\<^sub>s\<le>\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>" using latestActless by blast
                    ultimately have "\<not> trusted (the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n\<^sub>s))" using cas by simp
                    moreover from asmp have "\<parallel>the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n\<^sub>s)\<parallel>\<^bsub>t n\<^sub>s\<^esub>"
                      using devBC_act by simp
                    ultimately have "the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n\<^sub>s)\<in>actUt (t n\<^sub>s)"
                      using actUt_def by simp
                    hence "length (bc (\<sigma>\<^bsub>the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n\<^sub>s)\<^esub>(t n\<^sub>s))) < length sbc"
                      using assms(2) by simp
                    moreover from asmp have
                      "devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n\<^sub>s 0 = bc (\<sigma>\<^bsub>the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n\<^sub>s)\<^esub>(t n\<^sub>s))"
                      by simp
                    ultimately have "length (devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n\<^sub>s 0) < length sbc" by simp
                    moreover from lAct have "\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>\<ge>n\<^sub>s" using latestActless by blast
                    moreover from cas have "\<forall>n''>n\<^sub>s. n''\<le>\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> \<and> \<not> Option.is_none (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n'') \<longrightarrow> \<not> trusted (the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n''))" by simp
                    ultimately show ?thesis by auto
                  qed
                qed
                then obtain n' where "\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>\<ge>n'" and "n'\<ge>n\<^sub>s"
                  and "length (devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n' 0) < length sbc"
                  and untrusted: "\<forall>n''>n'. n''\<le>\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> \<and> \<not> Option.is_none (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n'') \<longrightarrow> \<not> trusted (the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n''))" by auto
                interpret ut: untrusted "devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n'" "\<lambda>n. umining t (n' + n)"
                proof
                  fix n''
                  from devExt_devop[of t "\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>" kid n']
                  have "prefix (devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n' (Suc n'')) (devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n' n'') \<or>
                    (\<exists>b. devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n' (Suc n'') = devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n' n'' @ [b]) \<and> \<not> Option.is_none (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid (n' + Suc n'')) \<and> \<parallel>the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid (n' + Suc n''))\<parallel>\<^bsub>t (n' + Suc n'')\<^esub> \<and> n' + Suc n'' \<le> \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> \<and> mining (\<sigma>\<^bsub>the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid (n' + Suc n''))\<^esub>t (n' + Suc n''))" .
                  thus "prefix (devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n' (Suc n'')) (devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n' n'')
                    \<or> (\<exists>b. devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n' (Suc n'') = devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n' n'' @ [b]) \<and> umining t (n' + Suc n'')"
                  proof
                    assume "prefix (devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n' (Suc n'')) (devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n' n'')"
                    thus ?thesis by simp
                  next
                    assume "(\<exists>b. devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n' (Suc n'') = devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n' n'' @ [b]) \<and> \<not> Option.is_none (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid (n' + Suc n'')) \<and> \<parallel>the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid (n' + Suc n''))\<parallel>\<^bsub>t (n' + Suc n'')\<^esub> \<and> n' + Suc n'' \<le> \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> \<and> mining (\<sigma>\<^bsub>the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid (n' + Suc n''))\<^esub>t (n' + Suc n''))"
                    hence "\<exists>b. devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n' (Suc n'') = devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n' n'' @ [b]"
                      and "\<not> Option.is_none (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid (n' + Suc n''))"
                      and "\<parallel>the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid (n' + Suc n''))\<parallel>\<^bsub>t (n' + Suc n'')\<^esub>"
                      and "n' + Suc n'' \<le> \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>"
                      and "mining (\<sigma>\<^bsub>the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid (n' + Suc n''))\<^esub>t (n' + Suc n''))"
                      by auto
                    moreover from \<open>n' + Suc n'' \<le> \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>\<close> \<open>\<not> Option.is_none (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid (n' + Suc n''))\<close>
                      have "\<not> trusted (the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid (n' + Suc n'')))" using untrusted by simp
                    with \<open>\<parallel>the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid (n' + Suc n''))\<parallel>\<^bsub>t (n' + Suc n'')\<^esub>\<close>
                      have "the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid (n' + Suc n''))\<in>actUt (t (n' + Suc n''))"
                      using actUt_def by simp
                    ultimately show ?thesis using umining_def by auto
                  qed
                qed
                interpret untrusted_growth "devLgthBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n'" "\<lambda>n. umining t (n' + n)"
                  by unfold_locales
                interpret trusted_growth "\<lambda>n. PoW t (n' + n)" "\<lambda>n. tmining t (n' + n)"
                proof
                  show "\<And>n. PoW t (n' + n) \<le> PoW t (n' + Suc n)" using pow_mono by simp
                  show "\<And>n. tmining t (n' + Suc n) \<Longrightarrow> PoW t (n' + n) < PoW t (n' + Suc n)"
                    using pow_mining_suc by simp
                qed
                interpret bg: bounded_growth "length sbc" "\<lambda>n. PoW t (n' + n)" "devLgthBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n'" "\<lambda>n. tmining t (n' + n)" "\<lambda>n. umining t (n' + n)" "length sbc" cb
                proof
                  from assms(3) \<open>n'\<ge>n\<^sub>s\<close> show "length sbc + cb \<le> PoW t (n' + 0)" using pow_mono[of n\<^sub>s n' t] by simp
                next
                  from \<open>length (devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n' 0) < length sbc\<close> show "length (devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n' 0) < length sbc" .
                next
                  fix n'' n'''
                  assume "cb < card {i. n'' < i \<and> i \<le> n''' \<and> umining t (n' + i)}"
                  hence "cb < card {i. n'' + n' < i \<and> i \<le> n''' + n' \<and> umining t i}"
                    using cardshift[of n'' n''' "umining t" n'] by simp
                  with fair[of "n'' + n'" "n''' + n'" t]
                  have "cb < card {i. n'' + n' < i \<and> i \<le> n''' + n' \<and> tmining t i}" by simp
                  thus "cb < card {i. n'' < i \<and> i \<le> n''' \<and> tmining t (n' + i)}"
                    using cardshift[of n'' n''' "tmining t" n'] by simp
                qed
                from \<open>\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>\<ge>n'\<close> have "length (devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n' (\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>-n')) < PoW t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>"
                  using bg.tr_upper_bound[of "\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>-n'"] by simp
                moreover from \<open>\<parallel>kid\<parallel>\<^bsub>t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>\<^esub>\<close> \<open>\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>\<ge>n'\<close>
                  have "bc (\<sigma>\<^bsub>the (devBC t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)\<^esub>t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>) = devExt t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> kid n' (\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>-n')"
                  using devExt_bc_geq[of t "\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>" kid "\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>" n'] by simp
                ultimately have "length (bc (\<sigma>\<^bsub>kid\<^esub>(t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>))) < PoW t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>"
                  using \<open>\<parallel>kid\<parallel>\<^bsub>t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>\<^esub>\<close> by simp
                moreover have "PoW t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> \<le> length (bc (\<sigma>\<^bsub>kid\<^esub>(t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)))" (is "?lhs \<le> ?rhs")
                proof -
                  from \<open>trusted nid\<close> \<open>\<parallel>nid\<parallel>\<^bsub>t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>\<^esub>\<close>
                    have "?lhs \<le> length (MAX (pin (\<sigma>\<^bsub>nid\<^esub>t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)))" using pow_le_max by simp
                  also from \<open>pout (\<sigma>\<^bsub>kid\<^esub>(t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)) = MAX (pin (\<sigma>\<^bsub>nid\<^esub>t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>))\<close>
                    have "\<dots> = length (pout (\<sigma>\<^bsub>kid\<^esub>(t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)))" by simp
                  also from \<open>\<parallel>kid\<parallel>\<^bsub>t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>\<^esub>\<close> have "\<dots> = ?rhs" using fwd_bc by simp
                  finally show ?thesis .
                qed
                ultimately show False by simp
              qed
            qed
            with \<open>\<parallel>kid\<parallel>\<^bsub>t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>\<^esub>\<close> have "prefix sbc (pout (\<sigma>\<^bsub>kid\<^esub>(t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)))"
              using fwd_bc by simp
            moreover from \<open>\<parallel>nid\<parallel>\<^bsub>t n\<^esub>\<close> have "\<langle>nid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>=n" using nxtAct_active by simp
            ultimately show ?thesis by auto
          qed
          moreover from \<open>\<parallel>nid\<parallel>\<^bsub>t n\<^esub>\<close> have "\<langle>nid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>=n" using nxtAct_active by simp
          ultimately show ?thesis by auto
        next
          assume "\<not> (\<exists>b\<in>pin (\<sigma>\<^bsub>nid\<^esub>t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>). length b > length (bc (\<sigma>\<^bsub>nid\<^esub>t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)))"
          moreover from \<open>\<parallel>nid\<parallel>\<^bsub>t n\<^esub>\<close> have "\<exists>n'\<ge>n. \<parallel>nid\<parallel>\<^bsub>t n'\<^esub>" by auto
          moreover from lAct have "\<exists>n'. latestAct_cond nid t n n'" by auto
          ultimately have "\<not> mining (\<sigma>\<^bsub>nid\<^esub>t \<langle>nid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>) \<and> bc (\<sigma>\<^bsub>nid\<^esub>t \<langle>nid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>) = bc (\<sigma>\<^bsub>nid\<^esub>t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>) \<or>
            mining (\<sigma>\<^bsub>nid\<^esub>t \<langle>nid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>) \<and> bc (\<sigma>\<^bsub>nid\<^esub>t \<langle>nid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>) = bc (\<sigma>\<^bsub>nid\<^esub>t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>) @ [nid]"
            using \<open>trusted nid\<close> bhv_tr_in[of nid n t] by simp
          moreover have "prefix sbc (bc (\<sigma>\<^bsub>nid\<^esub>t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>))"
          proof -
            from \<open>\<exists>n'. latestAct_cond nid t n n'\<close> have "\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> < n" using latestAct_prop(2) by simp
            moreover from lAct have "\<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub> \<ge> n\<^sub>s" using latestActless by blast
            moreover from \<open>\<exists>n'. latestAct_cond nid t n n'\<close> have "\<parallel>nid\<parallel>\<^bsub>t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>\<^esub>"
              using latestAct_prop(1) by simp
            with \<open>trusted nid\<close> have "nid \<in> actTr (t \<langle>nid \<Leftarrow> t\<rangle>\<^bsub>n\<^esub>)" using actTr_def by simp
            ultimately show ?thesis using step.IH by auto
          qed
          moreover from \<open>\<parallel>nid\<parallel>\<^bsub>t n\<^esub>\<close> have "\<langle>nid \<rightarrow> t\<rangle>\<^bsub>n\<^esub>=n" using nxtAct_active by simp
          ultimately show ?thesis by auto
        qed
      next
        assume nAct: "\<not> (\<exists>n' < n. n' \<ge> n\<^sub>s \<and> \<parallel>nid\<parallel>\<^bsub>t n'\<^esub>)"
        moreover from step.hyps have "n\<^sub>s \<le> n" by simp
        ultimately have "\<langle>nid \<rightarrow> t\<rangle>\<^bsub>n\<^sub>s\<^esub> = n" using \<open>\<parallel>nid\<parallel>\<^bsub>t n\<^esub>\<close> nxtAct_eq[of n\<^sub>s n nid t] by simp
        with \<open>trusted nid\<close> show ?thesis using assms(1) by auto
      qed
    qed
  qed
  with assms(5) show ?thesis by simp
qed

end

end