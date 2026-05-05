#import "/src/main.typ": internal
#import internal.alias: alias
#import internal.module: scope

#import "@preview/layout-ltd:0.1.0": layout-limiter
#show: layout-limiter.with(max-iterations: 3)

#set heading(numbering: "1.1")

#internal.module.template("parent", internal.alias.template[
  = Parent <label>
  #alias(scope("child", <label>))<label-2>
  This refers to @label.
  This refers to @label-2.

  #internal.module.template("child", internal.alias.template[
    = Child <label>
    #alias(scope("parent", <label>))<label-2>
    This refers to @label.
    This refers to @label-2.
  ])
])
