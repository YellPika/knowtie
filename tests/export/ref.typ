Number of exports: 2

This is a #text(luma(30%))[_term_].

#figure(caption: [Example Figure])[
  This is a figure referencing #text(luma(30%))[the term].
]

This is an #text(blue)[imported term].

= Backlinks

- *Example Title* #text(luma(70%))[[example-backlink]] \
  #datetime.today().display("[weekday], [month repr:long] [day], [year]") \
  Example Author

= Overview

#set par(justify: false)
#columns(2)[
  - *Example Title* #text(luma(70%))[[example-backlink]] \
    #datetime.today().display("[weekday], [month repr:long] [day], [year]") \
    Example Author

  - *Untitled* #text(luma(70%))[[example-import]] \
    #datetime.today().display("[weekday], [month repr:long] [day], [year]") \
    Unknown Author
]
