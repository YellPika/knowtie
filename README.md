# knowtie

> [!WARNING]
> This package is a work in progress.

This is a package and tool for creating linked notes in [Typst](https://github.com/typst/typst).

## Prerequisites

To use this package you need the following components:

1. [Typst](https://github.com/typst/typst) (obviously)
2. [A Haskell Toolchain](https://www.haskell.org/ghcup/) (for the build tool)
    - This is only necessary for now because we have no binary distributions.

## Installation

Clone this repository:

```sh
git clone github.com/YellPika/knowtie
cd knowtie
```

Install the package:

```sh
mkdir -p ${XDG_DATA_HOME:-$HOME/.local/share}/typst/packages/local/knowtie
ln -s $PWD ${XDG_DATA_HOME:-$HOME/.local/share}/typst/packages/local/knowtie/1.0.0
```

Install the build tool:

```sh
cabal install knowtie
```

## Getting Started

To create a new set of notes, run `knowtie init` in a new directory:

```sh
mkdir my-notes
cd my-notes
knowtie init
```
```
# git (for init)
Initialized empty Git repository in /.../my-notes/.git/
# git (for init)
# git (for init)
[main (root-commit) cd367c2] Initial Commit
 5 files changed, 39 insertions(+)
 create mode 100644 .gitignore
 create mode 100644 .vscode/extensions.json
 create mode 100644 .vscode/settings.json
 create mode 100644 .vscode/tasks.json
 create mode 100644 knowtie.cfg
Build completed in 0.02s
```

This command initializes a `git` repository and some [VSCode](https://code.visualstudio.com/) configuration, which includes some recommended extensions. If you install the extensions, you can
1. preview your notes in real time using `Ctrl+Shift+P: Browsing Preview`, and
2. automatically update the notes index on save (this is necessary for linking between notes).

Create a new note using `knowtie new`.

```sh
knowtie new
```
```
# mktemp (for new)
# code (for new)
Build completed in 1.17s
```
