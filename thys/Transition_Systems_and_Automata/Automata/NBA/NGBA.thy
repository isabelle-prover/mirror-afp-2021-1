section \<open>Nondeterministic Generalized Büchi Automata\<close>

theory NGBA
imports "../Nondeterministic"
begin

  datatype ('label, 'state) ngba = ngba
    (alphabet: "'label set")
    (initial: "'state set")
    (transition: "'label \<Rightarrow> 'state \<Rightarrow> 'state set")
    (accepting: "'state pred gen")

  global_interpretation ngba: automaton ngba alphabet initial transition accepting
    defines path = ngba.path and run = ngba.run and reachable = ngba.reachable and nodes = ngba.nodes
    by unfold_locales auto
  global_interpretation ngba: automaton_trace ngba alphabet initial transition accepting "gen infs"
    defines language = ngba.language
    by standard

  abbreviation target where "target \<equiv> ngba.target"
  abbreviation states where "states \<equiv> ngba.states"
  abbreviation trace where "trace \<equiv> ngba.trace"
  abbreviation successors where "successors \<equiv> ngba.successors TYPE('label)"

end