(*
  File:     Min_Int_Poly.thy
  Author:   Manuel Eberl, TU München
*)
section \<open>The minimal polynomial of an algebraic number\<close>
theory Min_Int_Poly
imports
  Algebraic_Numbers_Prelim
begin

text \<open>
  Given an algebraic number \<open>x\<close> in a field, the minimal polynomial is the unique irreducible
  integer polynomial with positive leading coefficient that has \<open>x\<close> as a root.

  Note that we assume characteristic 0 since the material upon which all of this builds also
  assumes it.
\<close>

definition min_int_poly :: "'a :: field_char_0 \<Rightarrow> int poly" where
  "min_int_poly x =
     (if algebraic x then THE p. p represents x \<and> irreducible p \<and> lead_coeff p > 0
      else [:0, 1:])"

lemma
  fixes x :: "'a :: {field_char_0, field_gcd}"
  shows min_int_poly_represents [intro]: "algebraic x \<Longrightarrow> min_int_poly x represents x"
  and   min_int_poly_irreducible [intro]: "irreducible (min_int_poly x)"
  and   lead_coeff_min_int_poly_pos: "lead_coeff (min_int_poly x) > 0"
proof -
  note * = theI'[OF algebraic_imp_represents_unique, of x]
  show "min_int_poly x represents x" if "algebraic x"
    using *[OF that] by (simp add: that min_int_poly_def)
  have "irreducible [:0, 1::int:]"
    by (rule irreducible_linear_poly) auto
  thus "irreducible (min_int_poly x)"
    using * by (auto simp: min_int_poly_def)
  show "lead_coeff (min_int_poly x) > 0"
    using * by (auto simp: min_int_poly_def)
qed

lemma 
  fixes x :: "'a :: {field_char_0, field_gcd}"
  shows degree_min_int_poly_pos [intro]: "degree (min_int_poly x) > 0"
    and degree_min_int_poly_nonzero [simp]: "degree (min_int_poly x) \<noteq> 0"
proof -
  show "degree (min_int_poly x) > 0"
  proof (cases "algebraic x")
    case True
    hence "min_int_poly x represents x"
      by auto
    thus ?thesis by blast
  qed (auto simp: min_int_poly_def)
  thus "degree (min_int_poly x) \<noteq> 0"
    by blast
qed

lemma min_int_poly_primitive [intro]:
  fixes x :: "'a :: {field_char_0, field_gcd}"
  shows "primitive (min_int_poly x)"
  by (rule irreducible_imp_primitive) auto

lemma min_int_poly_content [simp]:
  fixes x :: "'a :: {field_char_0, field_gcd}"
  shows "content (min_int_poly x) = 1"
  using min_int_poly_primitive[of x] by (simp add: primitive_def)

lemma ipoly_min_int_poly [simp]: 
  "algebraic x \<Longrightarrow> ipoly (min_int_poly x) (x :: 'a :: {field_gcd, field_char_0}) = 0"
  using min_int_poly_represents[of x] by (auto simp: represents_def)

lemma min_int_poly_nonzero [simp]:
  fixes x :: "'a :: {field_char_0, field_gcd}"
  shows "min_int_poly x \<noteq> 0"
  using lead_coeff_min_int_poly_pos[of x] by auto

lemma min_int_poly_normalize [simp]:
  fixes x :: "'a :: {field_char_0, field_gcd}"
  shows "normalize (min_int_poly x) = min_int_poly x"
  unfolding normalize_poly_def using lead_coeff_min_int_poly_pos[of x] by simp

lemma min_int_poly_prime_elem [intro]:
  fixes x :: "'a :: {field_char_0, field_gcd}"
  shows "prime_elem (min_int_poly x)"
  using min_int_poly_irreducible[of x] by blast

lemma min_int_poly_prime [intro]:
  fixes x :: "'a :: {field_char_0, field_gcd}"
  shows "prime (min_int_poly x)"
  using min_int_poly_prime_elem[of x]
  by (simp only: prime_normalize_iff [symmetric] min_int_poly_normalize)

lemma min_int_poly_unique:
  fixes x :: "'a :: {field_char_0, field_gcd}"
  assumes "p represents x" "irreducible p" "lead_coeff p > 0"
  shows "min_int_poly x = p"
proof -
  from assms(1) have x: "algebraic x"
    using algebraic_iff_represents by blast
  thus ?thesis
    using the1_equality[OF algebraic_imp_represents_unique[OF x], of p] assms
    unfolding min_int_poly_def by auto
qed

lemma min_int_poly_of_int [simp]:
  "min_int_poly (of_int n :: 'a :: {field_char_0, field_gcd}) = [:-of_int n, 1:]"
  by (intro min_int_poly_unique irreducible_linear_poly) auto

lemma min_int_poly_of_nat [simp]:
  "min_int_poly (of_nat n :: 'a :: {field_char_0, field_gcd}) = [:-of_nat n, 1:]"
  using min_int_poly_of_int[of "int n"] by (simp del: min_int_poly_of_int)

lemma min_int_poly_0 [simp]: "min_int_poly (0 :: 'a :: {field_char_0, field_gcd}) = [:0, 1:]"
  using min_int_poly_of_int[of 0] unfolding of_int_0 by simp

lemma min_int_poly_1 [simp]: "min_int_poly (1 :: 'a :: {field_char_0, field_gcd}) = [:-1, 1:]"
  using min_int_poly_of_int[of 1] unfolding of_int_1 by simp

lemma poly_min_int_poly_0_eq_0_iff [simp]:
  fixes x :: "'a :: {field_char_0, field_gcd}"
  assumes "algebraic x"
  shows "poly (min_int_poly x) 0 = 0 \<longleftrightarrow> x = 0"
proof
  assume *: "poly (min_int_poly x) 0 = 0"
  show "x = 0"
  proof (rule ccontr)
    assume "x \<noteq> 0"
    hence "poly (min_int_poly x) 0 \<noteq> 0"
      using assms by (intro represents_irr_non_0) auto
    with * show False by contradiction
  qed
qed auto

lemma min_int_poly_eqI:
  fixes x :: "'a :: {field_char_0, field_gcd}"
  assumes "p represents x" "irreducible p" "lead_coeff p \<ge> 0"
  shows   "min_int_poly x = p"
proof -
  from assms have [simp]: "p \<noteq> 0"
    by auto
  have "lead_coeff p \<noteq> 0"
    by auto
  with assms(3) have "lead_coeff p > 0"
    by linarith
  moreover have "algebraic x"
    using \<open>p represents x\<close> by (meson algebraic_iff_represents)
  ultimately show ?thesis
    unfolding min_int_poly_def
    using the1_equality[OF algebraic_imp_represents_unique[OF \<open>algebraic x\<close>], of p] assms by auto
qed

text \<open>Implementation for real and rational numbers\<close>

lemma min_int_poly_of_rat: "min_int_poly (of_rat r :: 'a :: {field_char_0, field_gcd}) = poly_rat r"
  by (intro min_int_poly_unique, auto)

definition min_int_poly_real :: "real \<Rightarrow> int poly" where
  [simp]: "min_int_poly_real = min_int_poly"

lemma min_int_poly_real_code_unfold [code_unfold]: "min_int_poly = min_int_poly_real"
  by simp

lemma min_int_poly_real_basic_impl[code]: "min_int_poly_real (real_of_rat x) = poly_rat x" 
  unfolding min_int_poly_real_def by (rule min_int_poly_of_rat)

lemma min_int_poly_rat_code_unfold [code_unfold]: "min_int_poly = poly_rat"
  by (intro ext, insert min_int_poly_of_rat[where ?'a = rat], auto)
 
end