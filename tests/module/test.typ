#import "/src/main.typ": internal
#import internal.module: scope, template

#import "@preview/layout-ltd:0.1.0": layout-limiter
#show: layout-limiter.with(max-iterations: 3)

#set heading(numbering: "1.1")

#template("parent", missing: (id, it) => text(orange, weight: "bold", "?" + str(it)))[
  = Parent <label>
  This refers to @label.
  This also refers to #ref(scope("parent", <label>)).
  This refers to #ref(scope("child", <label>)).

  #template("child")[
    = Child <label>
    This refers to @label.
    This also refers to #ref(scope("child", <label>)).
    This refers to #ref(scope("parent", <label>)).

    Look at this footnote#footnote[
      Referencing @label.
      #figure(caption: [A figure in a footnote])[Isn't this crazy?] <figure>
    ].

    Referencing @figure.
  ]

  Look at this other footnote#footnote[
    Referencing @label.
  ].

  This is a @missing-reference. This is also a #ref(scope("fake", <missing-reference>)).

  This is a citation @Knuth86a.

  #bibliography("/tests/module/bibliography.bib")
]
