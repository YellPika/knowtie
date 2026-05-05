#import "/src/main.typ": *

#set heading(numbering: "1.1")

#show: template.with(
  "main",
  title: [Example Title],
  author: "Example Author",
  date: datetime.today(),
)
