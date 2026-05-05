#set heading(numbering: "1.1")

= Parent <label-1>
This refers to @label-1.
This also refers to @label-1.
This refers to @label-2.

= Child <label-2>
This refers to @label-2.
This also refers to @label-2.
This refers to @label-1.

This is a #text(orange)[*?missing-reference*].
This is also a #text(orange)[*?missing-reference*].

This is a citation @Knuth86a.

#bibliography("/tests/module/bibliography.bib")
