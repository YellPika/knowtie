#import "/src/main.typ": internal
#import internal.module: scope
#import internal.alias: alias
#import internal.term: intro

#import "@preview/layout-ltd:0.1.0": layout-limiter
#show: layout-limiter.with(max-iterations: 3)

#set heading(numbering: "1.1")

#internal.module.template("parent", internal.alias.template(internal.term.template[
  = Parent <label>

  Introducing #intro[term 1]<term>.
  Referencing @term.

  #alias(scope("child", <term>)) <term-2>
  Referencing @term-2.
  Referencing @label.

  #alias(scope("child", <label>)) <label-2>
  Referencing @label-2.

  #internal.module.template("child", internal.alias.template(internal.term.template[
    = Child <label>

    Introducing #intro[term 2]<term>.
    Referencing @term.

    #alias(scope("parent", <term>)) <term-2>
    Referencing @term-2[term 1 with a supplement].
    Referencing @label.

    #alias(scope("parent", <label>)) <label-2>
    Referencing @label-2.

    // Look at this footnote#footnote[This is a @label].
  ]))
]))
