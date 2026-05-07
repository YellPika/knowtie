/// Determines whether a value contains alias metadata.
/// -> bool
#let is-alias(
  /// The value to check.
  /// -> any
  it,
) = (
  type(it) == content
    and it.func() == metadata
    and type(it.value) == dictionary
    and "tag" in it.value
    and it.value.tag == "alias"
)

/// Registers an alias for a link destination.
/// -> content
#let alias(
  /// The link destination to alias.
  /// -> dictionary | location | label | str
  it,
) = {
  assert(type(it) in (dictionary, location, label, str))
  [#metadata((tag: "alias", target: it))]
}

#let _ref(it) = {
  import "module.typ": query-in, scope, unscope

  let (id, dest) = unscope(it.target)
  let targets = query-in(id, selector(metadata).and(dest))
  if targets.len() != 1 or not is-alias(targets.first()) { return it }
  let (target: target) = targets.first().value
  assert.eq(
    type(target),
    label,
    message: "alias " + repr(dest) + " does not refer to a label",
  )
  return ref(
    scope(id, target),
    form: it.form,
    supplement: it.supplement,
  )
}

#let _link(it) = {
  import "module.typ": query-in, scope, unscope

  if type(it.dest) != label { return it }
  let (id, dest) = unscope(it.dest)
  let targets = query-in(id, selector(metadata).and(dest))
  if targets.len() != 1 or not is-alias(targets.first()) { return it }
  let (target: target) = targets.first().value
  if type(target) == label {
    link(scope(id, target), it.body)
  } else {
    link(target, it.body)
  }
}

/// Handles references and links to aliases.
/// -> content
#let template(
  /// The content to modify.
  /// -> content
  it,
) = context {
  import "module.typ": is-root

  assert.eq(type(it), content)
  if is-root() {
    show ref: _ref
    show link: _link
    it
  } else {
    it
  }
}
