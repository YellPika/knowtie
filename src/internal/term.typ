/// Determines whether a value contains term metadata.
/// -> bool
#let is-term(
  /// The value to check
  /// -> any
  it,
) = (
  type(it) == content
    and it.func() == metadata
    and type(it.value) == dictionary
    and "tag" in it.value
    and it.value.tag == "term"
)

/// Introduces a term. This result of this function can be labelled.
/// -> content
#let intro(
  /// The default representation of this term.
  /// -> content
  def,
  /// The content to display. If not specified, the default representation is shown.
  /// -> content | none
  ..it,
) = {
  assert.eq(it.named(), (:))
  assert(it.pos().len() <= 1)
  let disp = if it.pos().len() == 0 { def } else { it.pos().first() }
  [#metadata((tag: "term", default: def, display: disp))]
}

#let _metadata(it) = {
  if not is-term(it) { return it }
  text(luma(30%), emph(it.value.display))
}

#let _ref(it) = {
  import "module.typ": query-in, unscope

  let (id, dest) = unscope(it.target)
  let targets = query-in(id, selector(metadata).and(dest))
  if targets.len() != 1 or not is-term(targets.first()) { return it }
  let (default: default) = targets.first().value
  text(luma(30%), link(it.target, if it.supplement == auto { default } else { it.supplement }))
}

/// Handles references to terms.
/// -> content
#let template(
  /// The content to modify.
  /// -> content
  it,
) = context {
  assert.eq(type(it), content)
  show metadata: _metadata
  show ref: _ref
  it
}
