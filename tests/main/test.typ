#import "/src/main.typ": *

#set heading(numbering: "1.1")

#show: template.with(
  "tests/main/test",
  title: [Example Title],
  author: "Example Author",
  date: datetime(day: 11, month: 11, year: 11),
)
