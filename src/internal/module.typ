#let _encode(it) = {
  assert.eq(type(it), str)
  it.replace(regex("[~:]"), it => { if it.text == "~" { "~0" } else { "~1" } })
}

#let _decode(it) = {
  assert.eq(type(it), str)
  it.replace(regex("~[01]"), it => { if it.text == "~0" { "~" } else { ":" } })
}

#let _config(..args) = {
  assert.eq(args.named().len(), 0)
  if args.pos().len() == 0 {
    assert.eq(type(title.body), content)
    assert.eq(title.body.func(), metadata)
    title.body.value
  } else {
    assert.eq(args.pos().len(), 2)
    let (value, it) = args.pos()
    assert.eq(type(it), content)
    set title(metadata(value))
    it
  }
}

#let _config-init(it) = context {
  if title.body == auto {
    _config((:), {
      show title: it => {
        if type(it.body) == content and it.body.func() == metadata {
          title(auto)
        } else {
          it
        }
      }
      it
    })
  } else {
    it
  }
}

/// Gets the set of modules which appear in the current document.
/// -> array
#let modules() = query(<module:begin>).map(it => it.value)

/// Finds elements in a specific module.
/// -> array
#let query-in(
  /// The identifier of the module to query.
  /// -> str | auto
  id,
  /// Describes the element to search for.
  /// -> function | label | location | selector
  target,
) = {
  if id == auto { id = _config().id }
  assert.eq(type(id), str)
  target = selector(target)

  let markers = query(
    selector(<module:begin>).or(selector(<module:end>)).and(metadata.where(value: id)),
  )
  let restrict = selector(<module:none>)
  for (begin, end) in markers.chunks(2) {
    // panic(markers.map(it => (it.label, it.location().position())))
    // if begin.label == <module:end> {
    //   (begin, end) = (end, begin)
    // }
    assert.eq(begin.label, <module:begin>)
    assert.eq(end.label, <module:end>)
    restrict = restrict.or(target.after(begin.location()).before(end.location()))
  }

  query(restrict)
}

/// If `x` is a scoped label, the `unscope(x)` returns a pair `(y, z)` containing the module id
/// (`y`) and unscoped label (`z`). If `x` is unscoped, then returns the pair `(auto, x)`.
/// -> (str, label)
#let unscope(
  /// The label to deconstruct.
  /// -> label
  target,
) = {
  if str(target).starts-with("module:ref:") {
    let parts = str(target).split(":")
    assert.eq(parts.len(), 4)
    (_decode(parts.at(2)), label(_decode(parts.at(3))))
  } else {
    (auto, target)
  }
}

/// Constructs a label that refers to content in another module.
/// -> label
#let scope(
  /// The global id of the module to reference.
  /// -> str | auto
  id,
  /// The name of the label in the referenced module.
  /// -> label
  it,
) = {
  assert.eq(type(it), label)
  if unscope(it).first() != auto or id == auto {
    it
  } else {
    label("module:ref:" + _encode(id) + ":" + _encode(str(it)))
  }
}

/// The default behaviour for missing references.
/// -> none
#let default-missing(
  /// The global id of the module in which the reference cannot be found.
  /// -> str | auto
  id,
  /// The reference which cannot be found.
  /// -> label
  it,
) = {
  if id == auto {
    panic("label `" + repr(it) + "` does not appear in the current module")
  } else {
    panic("label `" + repr(it) + "` does not appear in module " + id)
  }
}

/// The default behaviour for duplicate references.
/// -> none
#let default-duplicate(
  /// The global id of the module in which the reference is duplicated.
  /// -> str | auto
  id,
  /// The reference which is duplicated.
  /// -> label
  it,
) = {
  if id == auto {
    panic("label `" + repr(it) + "` appears multiple times in the current module")
  } else {
    panic("label `" + repr(it) + "` appears multiple times in module " + id)
  }
}

#let _link(missing, duplicate, it) = {
  // If the destination is not a label, then no further processing necessary.
  if type(it.dest) != label { return it }

  let (id, dest) = unscope(it.dest)
  let targets = query-in(id, dest)
  if targets.len() > 1 { return duplicate(id, dest) }
  if targets.len() == 0 { return missing(id, dest) }
  let target = targets.first()

  link(target.location(), it.body)
}

#let _ref(missing, duplicate, it) = {
  let (id, dest) = unscope(it.target)

  let targets = query-in(id, dest)
  if targets.len() > 1 { return duplicate(id, dest) }

  if targets.len() == 0 {
    // If the target is missing, this may be because it is a bibliography reference.
    for bibliography in query(bibliography) {
      for source in bibliography.sources {
        import "@preview/citegeist:0.2.2": load-bibliography
        if str(dest) in load-bibliography(read(source)) {
          let supplement = it.supplement
          if supplement == auto { supplement = none }
          return cite(dest, supplement: supplement)
        }
      }
    }
    return missing(id, dest)
  }

  let target = targets.first()

  // There are three cases for the supplement:
  let supplement = if it.supplement != auto {
    // 1. Manually specified
    it.supplement
  } else if target.has("supplement") {
    // 2. Automatically specified
    target.supplement
  } else {
    // 3. Non-existent (error)
    panic("cannot reference " + repr(target.func()))
  }

  // The counter may be specified by the content.
  // If not, we get the default counter for the content type.
  let counter = if target.has("counter") { target.counter } else { counter(target.func()) }

  // The `numbering` may be set to `none` (e.g., the default setting for headings).
  if target.numbering == none {
    panic("cannot reference " + repr(target.func()) + " without numbering")
  }

  link(target.location())[#supplement~#numbering(target.numbering, ..counter.at(target.location()))]
}

#let _footnote_entry(it) = {
  // Configuration is not propagated to footnote entries, so we have to do it manually.
  let cfg = _config()
  cfg.at("id") = query(selector(<module:begin>).before(here())).rev().first().value
  _config(cfg, it)
}

/// Constructs a module.
/// -> content
#let template(
  /// The globally unique identifier of the module being defined.
  /// -> str
  id,
  /// The contents of the module.
  /// -> content
  it,
  missing: default-missing,
  duplicate: default-duplicate,
) = _config-init(context {
  let cfg = _config()
  let parent = cfg.at("id", default: none)
  cfg.root = "root" not in cfg
  cfg.id = id
  // assert.eq(
  //   query(selector(<module:begin>).and(metadata.where(value: id)).before(here(), inclusive: false)).len(),
  //   0,
  //   message: "Module '" + id + "' is already defined",
  // )
  _config(cfg, {
    [#metadata(parent)<module:end>]
    [#metadata(id)<module:begin>]
    if cfg.root {
      show ref: _ref.with(missing, duplicate)
      show link: _link.with(missing, duplicate)
      show footnote.entry: _footnote_entry
      it
    } else {
      it
    }
    [#metadata(id)<module:end>]
    [#metadata(parent)<module:begin>]
  })
})

/// Determines whether the current module is a root module.
/// -> bool
#let is-root() = _config().root

/// Gets the unique identifier for the current module.
/// -> str
#let module-id() = _config().id
