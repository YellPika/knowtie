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
    [#metadata((
      type: "export",
      label: str(it.label),
      value: serialize(it.value.default),
    ))<metadata>]
  }
  it
}

#let _figure(it) = {
  import "module.typ": is-root, module-id
  import "@preview/sertyp:0.1.2": serialize

  if is-root() and it.has("label") and it.supplement.func() != (context {}).func() {
    [#metadata((
      type: "export",
      label: str(it.label),
      value: serialize[#it.supplement #numbering(it.numbering, ..it.counter.get()) (#document.title)],
    ))<metadata>]
  }
  it
}

/// Handles exports.
/// -> content
#let template(
  ..args,
  /// The content to modify.
  /// -> content
  it,
) = context {
  import "module.typ": _config, is-root, module-id, parent-id, root-id
  import "@preview/sertyp:0.1.3": deserialize

  assert.eq(args.named().len(), 0)
  assert(args.pos().len() <= 1)

  if not is-root() {
    // Modules appearing just below the root are imports.
    if parent-id() == root-id() [#metadata((
      type: "import",
      value: module-id(),
    ))<metadata>]
    it
  } else {
    // Figure out index path.
    let index-path = args.pos().at(0, default: none)
    if "index" in sys.inputs { index-path = sys.inputs.index }

    // Load index if possible.
    let raw-index = none
    if index-path != none { raw-index = yaml(index-path) }

    // Clean index
    let index = (:)
    if raw-index != none {
      for (key, entries) in raw-index {
        let data = (
          exports: (:),
          imports: (),
          author: "Unknown Author",
          title: [Untitled],
          modified: datetime(day: 1, month: 1, year: 0),
        )

        if entries == none { entries = (:) }
        assert.eq(type(entries), array)
        for entry in entries {
          assert("type" in entry)
          if entry.type == "author" {
            assert.eq(type(entry.value), str)
            data.author = entry.value
          } else if entry.type == "title" {
            let value = deserialize(entry.value)
            assert.eq(type(value), content)
            data.title = value
          } else if entry.type == "export" {
            let value = deserialize(entry.value)
            assert.eq(type(entry.label), str)
            assert.eq(type(value), content)
            data.exports.insert(entry.label, value)
          } else if entry.type == "import" {
            assert.eq(type(entry.value), str)
            data.imports.push(entry.value)
          } else if entry.type == "modified" {
            data.modified = datetime(..entry.value)
          } else {
            panic("Unknown entry type " + repr(entry.type))
          }
        }

        index.insert(key, data)
      }
    }

    show metadata: _metadata
    show figure: _figure

    let cfg = _config()
    cfg.index = index
    _config(cfg, it)
  }
}

#let get-index() = {
  import "module.typ": _config
  _config().index
}

#let default-missing = {
  import "module.typ" as module
  (id, it, fallback: module.default-missing) => {
    if id == auto { return fallback(id, it) }
    let index = get-index()
    if id not in index { return fallback(id, it) }
    let exports = index.at(id).exports
    if str(it) not in exports { return fallback(id, it) }
    let data = exports.at(str(it))
    link-to(id, text(blue, data))
    if module.is-root() [#metadata((
      type: "import",
      value: id,
    ))<metadata>]
  }
}

#let entries(key: none, section: []) = {
  import "module.typ": module-id, modules

  if key == none { key = (_, _) => true }

  context {
    let entries = ()
    for (id, data) in get-index() {
      if key(id, data) {
        let key = data.modified
        entries.push((
          key: key,
          value: link-to(id)[
            *#data.title*
            #text(luma(70%))[[#id]] \
            #data.modified.display("[weekday], [month repr:long] [day], [year]") \
            #data.author
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
}

#let backlinks() = context {
  import "module.typ": module-id, modules
  entries(
    key: (id, data) => module-id() in data.imports and id not in modules(),
    section: [Backlinks],
  )
}

#let overview() = {
  import "module.typ": module-id, modules
  entries(section: [Overview])
}
