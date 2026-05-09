#import "/src/main.typ": internal

#import internal.module: query-in, scope
#import internal.term: intro
#import internal.alias: alias
#import internal.export: backlinks, default-missing, load-index, overview

#show: internal.module.template.with(
  "tests/export/example",
  missing: default-missing.with(fallback: (id, it) => {
    text(orange)[*?#str(it)*]
  }),
)
#show: internal.alias.template
#show: internal.term.template
#show: internal.export.template.with(index: load-index("/bin/index.json"))

Introducing #intro[example term]<example>!

#include "./test.typ"
