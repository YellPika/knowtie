#import "/src/main.typ": internal

#import internal.module: query-in, scope
#import internal.term: intro
#import internal.alias: alias
#import internal.export: backlinks, default-missing, overview

#show: internal.module.template.with(
  "export/test",
  missing: default-missing.with(index: "/tests/export/index.yaml"),
)
#show: internal.alias.template
#show: internal.term.template
#show: internal.export.template

Number of exports: #context query-in(auto, <export>).len()

This is a #intro[term]<term>.

#figure(caption: [Example Figure])[
  This is a figure referencing @term[the term].
] <fig:example>

#alias(scope("example-import", <example-label>))<example>

This is an @example.

#backlinks("/tests/export/index.yaml")

#overview("/tests/export/index.yaml")
