# emacs-config - AI Coding Agent Instructions

Canonical instructions for AI coding agents working in this repository.
Tool-specific entrypoints symlink to this file where supported:
- `CLAUDE.md`
- `.cursorrules`
- `.github/copilot-instructions.md`

## Scope And Layout

- Target upstream GNU Emacs 29.1 or newer, including GUI and terminal sessions
  on Linux, macOS, and Windows. Do not rely on features unique to third-party
  Emacs builds; guard features introduced after 29.1.
- `init.el` is the entrypoint and owns startup, shared UI, platform, path, LSP,
  and tree-sitter behavior. `init/use-packages.el` owns every `use-package`
  declaration and the Evil/Viper package branches.
- `init/hangul-keyboard-hint.el` is a bundled, built-in-only global minor mode;
  it owns Hangul input setup, font selection, hint rendering, and window
  lifecycle. Load it directly from `init.el`, not through `use-package`.
- Do not edit `init/additional-configuration.el`; it is a checked-in template
  whose contents are replaced by machine-local pre/post hooks and package-gate
  settings.
- Do not hand-edit `init/custom-file.el`; it is Emacs Customize output. Notably,
  it sets `use-package-always-ensure` and `use-package-always-defer` to `t`, so
  declarations install automatically and defer unless explicitly overridden.

## Package Constraints

- Prefer built-in packages. `init--use-packages` must remain usable with
  third-party packages disabled: that path may use only Emacs-built-in code
  (`viper` and `term`, or `shell` on Windows, currently replace Evil and Eat).
- Pin packages fetched directly from VCS with `use-package :vc` and an exact
  commit SHA in `:rev`; do not use a moving revision such as `:newest`.
- Keep Eat as the third-party terminal (`C-x C-t`); do not replace it with
  Vterm, whose native build dependency is intentionally avoided.

## Elisp Conventions

- Start every `.el` file with `;; -*- lexical-binding: t -*-`.
- Prefix all defined symbols with `init`: `init--` for internal symbols and
  `init-` for public interactive commands.
- Use `equal` even for symbol comparisons. Prefer generic `seq-*` operations
  over list-specific alternatives.
- Use `setopt` for user options and `setf` for other assignment; do not use
  `setq`, `setcar`, or `setcdr`.
- Sharp-quote function references (`#'foo`) except in `add-hook`, where this
  repository deliberately uses `'foo` to keep hook variable displays readable.
- Require `cl-lib` only at compile time with `eval-when-compile` when using its
  macros.
- Preserve the existing section format: `;;;;` major headings, `;;;`
  subsections, two blank lines between major sections, and one between defuns.

## Verification

- There is no automated test suite or CI. After any Elisp edit, run the
  depth-aware parser check below rather than counting parentheses manually:

```sh
emacs --batch -Q --eval "(dolist (file '(\"init.el\" \"init/use-packages.el\" \"init/hangul-keyboard-hint.el\")) (with-temp-buffer (insert-file-contents file) (emacs-lisp-mode) (check-parens)))"
```

- For behavior changes, smoke-test by loading `init.el` in the affected GUI or
  terminal/platform context; a batch load does not exercise frame or OS paths.
