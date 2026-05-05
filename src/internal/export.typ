/// Constructs a link to a particular note.
/// -> content
#let link-to(
  /// The identity of the note to link to.
  /// -> str
  id,
  /// The content to display.
  /// -> content
  it,
) = {
  import "module.typ": module-id

  assert.eq(type(id), str)
  context {
    let self = module-id()
    let prefix = ""
    while self.starts-with(regex("[^/]*/")) {
      self = self.trim(regex("[^/]*/"), at: start)
      prefix += "../"
    }

    if "x-preview" in sys.inputs {
      if "root" in sys.inputs {
        let root = read(root)
        link("vscode://file" + root + id + ".typ", it)
      } else {
        it
      }
    } else if "target" in dictionary(std) and target() == "html" {
      link(prefix + id + ".html", it)
    } else {
      link(prefix + id + ".pdf", it)
    }
  }
}

#let _metadata(it) = {
  import "module.typ": is-root, module-id
  import "term.typ": is-term
  import "@preview/sertyp:0.1.2": serialize

  if is-root() and is-term(it) and it.has("label") {
    let value = (
      type: "term",
      default: it.value.default,
    )
    [#metadata((label: str(it.label), value: serialize(value)))<export>]
  }
  it
}

#let _figure(it) = {
  import "module.typ": is-root, module-id
  import "@preview/sertyp:0.1.2": serialize

  if is-root() and it.has("label") and it.supplement.func() != (context {}).func() {
    let value = (
      type: "figure",
      display: [#it.supplement #numbering(it.numbering, ..it.counter.get()) (#document.title)],
    )
    [#metadata((label: str(it.label), value: serialize(value)))<export>]
  }
  it
}

/// Handles exports.
/// -> content
#let template(
  /// The content to modify.
  /// -> content
  it,
) = context {
  show metadata: _metadata
  show figure: _figure
  it
}

#let get-index(..args) = {
  import "@preview/sertyp:0.1.3": deserialize

  assert.eq(args.named().len(), 0)
  assert(args.pos().len() <= 1)
  let index = args.pos().at(0, default: none)

  if index == none {
    if "index" in sys.inputs {
      index = sys.inputs.index
    } else {
      return (:)
    }
  }

  let index = yaml(index)
  if index == none { index = (:) }
  for (key, value) in index {
    if "exports" not in value or value.exports == none {
      value.exports = (:)
    } else {
      for (label, data) in value.exports {
        data = deserialize(data)
        value.exports.at(label) = data
      }
    }
    if "imports" not in value or value.imports == none {
      value.imports = ()
    }
    if "metadata" not in value or value.metadata == none {
      value.metadata = (
        title: [Untitled],
        author: [Unknown Author],
      )
    } else {
      value.metadata = deserialize(value.metadata)
    }
    if "created" not in value or value.created == none {
      value.created = datetime.today()
    } else {
      value.created = datetime(..value.created)
    }
    if "modified" not in value or value.modified == none {
      value.modified = datetime.today()
    } else {
      value.modified = datetime(..value.modified)
    }
    index.at(key) = value
  }
  index
}

#let default-missing = {
  import "module.typ" as module
  (id, it, index: none, fallback: module.default-missing) => {
    if id == auto { return fallback(id, it) }
    let index = get-index(index)
    if id not in index { return fallback(id, it) }
    let exports = index.at(id).exports
    if str(it) not in exports { return fallback(id, it) }
    let data = exports.at(str(it))
    let display = if data.type == "term" {
      text(blue, data.default)
    } else if data.type == "figure" {
      text(blue)[FIGURE]
    } else {
      panic("Unknown export type '" + target.type + "'")
    }
    link-to(id, display)
  }
}

#let entries(key: none, section: [], ..args) = {
  import "module.typ": module-id, modules

  if key == none { key = (_, _) => true }

  let entries = ()
  for (id, data) in get-index(..args) {
    if key(id, data) {
      let key = data.modified
      entries.push((
        key: key,
        value: link-to(id)[
          *#data.metadata.title*
          #text(luma(70%))[[#id]] \
          #data.modified.display("[weekday], [month repr:long] [day], [year]") \
          #data.metadata.author
        ],
      ))
    }
  }

  if entries.len() > 0 {
    heading(numbering: none, section)
    set par(justify: false)
    columns(2, list(..entries.sorted(key: it => it.key).rev().map(it => it.value), tight: false))
  }
}

#let backlinks(..args) = context {
  import "module.typ": module-id, modules
  entries(
    key: (id, data) => module-id() in data.imports and id not in modules(),
    section: [Backlinks],
    ..args,
  )
}

#let overview(..args) = {
  import "module.typ": module-id, modules
  entries(section: [Overview], ..args)
}
