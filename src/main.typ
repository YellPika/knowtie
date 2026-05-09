#let internal = {
  import "internal/module.typ" as module
  import "internal/alias.typ" as alias
  import "internal/term.typ" as term
  import "internal/export.typ" as export
  (
    module: module,
    alias: alias,
    term: term,
    export: export,
  )
}

#import internal.module: is-root, module-id, modules, query-in, scope, unscope
#import internal.alias: alias, is-alias
#import internal.term: intro, is-term
#import internal.export: backlinks, link-to, load-index

/// Constructs a note.
/// -> content
#let template(
  /// The globally unique identity of the note.
  /// -> global-id
  id,
  /// The title of the note.
  /// -> content
  title: [],
  /// The author of the note.
  /// -> str | auto
  author: auto,
  /// A set of keywords describing the note.
  /// -> array | str
  keywords: (),
  /// The date of the note.
  /// -> datetime | auto
  date: auto,
  /// The note index.
  /// -> dict
  index: (:),
  /// The content of the note.
  /// -> content
  it,
) = {
  assert.eq(type(id), str)
  assert.eq(type(title), content)
  assert(type(author) in (str, type(auto)))
  assert.eq(type(it), content)
  assert.eq(type(index), dictionary)

  let head = [#title #link-to(id, text(luma(70%))[[#id]])]

  show: internal.module.template.with(id, missing: internal.export.default-missing.with(fallback: (id, it) => text(
    orange,
    weight: "bold",
  )[?#str(it)]))
  show: internal.alias.template
  show: internal.term.template
  show: internal.export.template.with(index: index)
  context if is-root() {
    let date = date
    if date == auto {
      let index = internal.export.get-index()
      if id in index {
        date = index.at(id).modified
      } else {
        date = datetime.today()
      }
    } else {
      let date-dict = (:)
      if date.year() != none { date-dict.insert("year", date.year()) }
      if date.month() != none { date-dict.insert("month", date.month()) }
      if date.day() != none { date-dict.insert("day", date.day()) }
      if date.hour() != none { date-dict.insert("hour", date.hour()) }
      if date.minute() != none { date-dict.insert("minute", date.minute()) }
      if date.second() != none { date-dict.insert("second", date.second()) }
      [#metadata((type: "modified", value: date-dict))<metadata>]
    }

    let author = author
    if author == auto {
      let index = internal.export.get-index()
      if id in index {
        author = index.at(id).author
      } else {
        author = "Unknown Author"
      }
    } else {
      [#metadata((type: "author", value: author))<metadata>]
    }

    set document(title: title, date: date, author: author, keywords: keywords)
    set heading(numbering: "1.1")
    set enum(numbering: "1)")
    set par(justify: true)

    std.title(head)
    [#date.display("[weekday], [month repr:long] [day], [year]") #sym.fence.dotted #author]
    it

    import "@preview/sertyp:0.1.3": serialize
    [#metadata((type: "title", value: serialize(title)))<metadata>]

    backlinks()
  } else {
    heading(head)
    set heading(depth: heading.depth + 1)
    it
  }
}
