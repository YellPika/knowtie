#import "/src/main.typ": internal

#import internal.module: query-in, scope
#import internal.term: intro
#import internal.alias: alias
#import internal.export: backlinks, default-missing, overview

#show: internal.module.template.with(
  "tests/export/test",
  missing: default-missing.with(fallback: (id, it) => {
    text(orange)[*?#str(it)*]
  }),
)
#show: internal.alias.template
#show: internal.term.template
#show: internal.export.template.with(index: yaml("/bin/index.json"))

Number of exports: #context query-in(auto, <metadata>).filter(it => it.value.type == "export").len()

This is a #intro[term]<term>.

#figure(caption: [Example Figure])[
  This is a figure referencing @term[the term].
] <fig:example>

#alias(scope("tests/export/example", <example>))<example>

This is an @example.

#backlinks()
