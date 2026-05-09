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
#import internal.export: backlinks, link-to

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
  /// -> str
  author: auto,
  /// A set of keywords describing the note.
  /// -> array | str
  keywords: (),
  /// The date of the note.
  /// -> datetime | auto
  date: auto,
  /// The (absolute) location of the note index.
  /// -> string | none
  index: none,
  /// The content of the note.
  /// -> content
  it,
) = {
  assert.eq(type(id), str)
  assert.eq(type(title), content)
  assert.eq(type(author), str)
  assert.eq(type(it), content)

  let head = [#title #link-to(id, text(luma(70%))[[#id]])]

  if date == auto {
    let index = internal.export.get-index(index)
    if id in index {
      index.at(id).modified
    } else {
      datetime.today()
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

  show: internal.module.template.with(id)
  show: internal.alias.template
  show: internal.term.template
  show: internal.export.template.with(index)
  context if is-root() {
    set document(title: title, author: author, keywords: keywords)
    set heading(numbering: "1.1")
    set enum(numbering: "1)")
    set par(justify: true)

    std.title(head)
    [#date.display("[weekday], [month repr:long] [day], [year]") #sym.fence.dotted #author]
    it

    import "@preview/sertyp:0.1.3": serialize
    [#metadata((type: "title", value: serialize(title)))<metadata>]
    [#metadata((type: "author", value: author))<metadata>]

    backlinks()
  } else {
    heading(head)
    set heading(depth: heading.depth + 1)
    it
  }
}
