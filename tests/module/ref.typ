#set heading(numbering: "1.1")

= Parent <label-1>
This refers to @label-1.
This also refers to @label-1.
This refers to @label-2.

= Child <label-2>
This refers to @label-2.
This also refers to @label-2.
This refers to @label-1.

Look at this footnote#footnote[
  Referencing @label-2.
  #figure(caption: [A figure in a footnote])[Isn't this crazy?] <figure>
].

Referencing @figure.

Look at this other footnote#footnote[
  Referencing @label-1.
].

This is a #text(orange)[*?missing-reference*].
This is also a #text(orange)[*?missing-reference*].

This is a citation @Knuth86a.

#bibliography("/tests/module/bibliography.bib")
