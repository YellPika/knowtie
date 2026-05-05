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

  let date = if date != auto {
    date
  } else {
    let index = internal.export.get-index(index)
    if id in index {
      index.at(id).modified
    } else {
      datetime.today()
    }
  }

  show: internal.module.template.with(id)
  context if is-root() {
    show: internal.alias.template
    show: internal.term.template
    show: internal.export.template

    set document(title: title, author: author, keywords: keywords)
    set heading(numbering: "1.1")
    set enum(numbering: "1)")
    set par(justify: true)

    std.title(head)
    [#date.display("[weekday], [month repr:long] [day], [year]") #sym.fence.dotted #author]
    it

    import "@preview/sertyp:0.1.3": serialize
    [#metadata(serialize((title: title, author: author)))<metadata>]
  } else {
    heading(head)
    set heading(depth: heading.depth + 1)
    it
  }

  backlinks(index)
}
