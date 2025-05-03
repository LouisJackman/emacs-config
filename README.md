# Emacs Configuration

An Emacs configuration that assumes:

- **Vanilla Emacs** as a base. At least version 29.
- **Vim-like keybindings** via evil-mode while editing code and prose, but normal
  Emacs keybindings elsewhere to avoid sprawling keymap overrides. Also, a
  Vim-like status line. Should be a reasonable POSIX `vi` alias replacement
  for quick edits.
- "**Spacebar as leader key**" from Spacemacs to reduce modifier key usage. For
  example, supporting `SPC v` to split a window vertically, as an alternative
  to the Vim keybinding `C-w v`.
- Monospace fonts for code. Variable-width, serif fonts for anything else.
- A **preference for built-in packages** wherever possible, e.g. `project.el`
  rather than Projectile, and `eglot` rather than `lsp-mode`.
- **Support for disabling all third party packages**, for environments which are
  particularly high-risk in the face of supply chain attacks. `viper` steps in
  for `evil-mode` here.
- Both **GUI and terminal** support.
- **Support both light and dark mode**, and respect the host OS's preference
- **Wide OS support**, at least Linux, macOS, and Windows.
  on startup.
- `use-package` to configure packages.
- An embrace of `customize` rather than bypassing it.
- Lexically-scoped ELisp that uses more abstract, less concrete APIs. That
  includes `seq-*` over more concrete data structure functions, generalised
  setters via `setf` over `setq` and `setcar`, `equal` unless a more specific
  equality function is necessary, etc.

TODO:

- [ ] Better support running as a service, e.g. `systemctl enable --now --user
   emacs`.
- [ ] Polish the treesitter and LSP integrations more, and enable by default.
- [ ] Enable live previews of in-project grepping and file-finding.
- [ ] Pinning of third party package commits. Not obviously viable with
      `package.el` unless getting packages directly from their VCS
      source. `straight.el` could be another approach.

