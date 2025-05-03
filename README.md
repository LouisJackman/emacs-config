# Emacs Configuration

An [Emacs](https://www.gnu.org/software/emacs/) configuration that assumes:

- **Vanilla Emacs** as a base. At least version 29.
- **[Vim](https://www.vim.org/)-like keybindings** via
  [evil-mode](https://github.com/emacs-evil/evil) while editing code and
  prose, but normal Emacs keybindings elsewhere to avoid sprawling keymap
  overrides. Also, a vi-like status line. Should be a reasonable [POSIX
  `vi`](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/vi.html)
  alias replacement for quick edits.
- "**Spacebar as [leader
  key](https://learnvimscriptthehardway.stevelosh.com/chapters/06.html#leader)**"
  from [Spacemacs](https://www.spacemacs.org/) to reduce modifier key
  usage. For example, supporting `SPC v` to split a window vertically, as an
  alternative to the Vim keybinding `C-w v`.
- Monospace fonts for code. Variable-width, serif fonts for anything else.
- A **preference for built-in packages** wherever possible,
  e.g. [`project.el`](https://www.gnu.org/software/emacs/manual/html_node/emacs/Projects.html)
  rather than [Projectile](https://github.com/bbatsov/projectile), and
  [`eglot`](https://github.com/joaotavora/eglot) rather than
  [`lsp-mode`](https://emacs-lsp.github.io/lsp-mode/).
- **Support for disabling all third party packages**, for environments which
  are particularly high-risk in the face of supply chain
  attacks. [`viper`](https://www.gnu.org/software/emacs/manual/html_node/viper/)
  steps in for `evil-mode` here.
- Both **GUI and terminal** support.
- **Support both light and dark mode**, and respect the host OS's preference.
- **Wide OS support**, at least Linux, macOS, and Windows.
  on startup.
- [`use-package`](https://www.gnu.org/software/emacs/manual/html_mono/use-package.html)
  to configure packages.
- An embrace of
  [`customize`](https://www.gnu.org/software/emacs/manual/html_node/emacs/Easy-Customization.html)
  rather than bypassing it.
- Lexically-scoped
  [ELisp](https://www.gnu.org/software/emacs/manual/html_node/elisp/index.html)
  that uses more abstract, less concrete APIs. That includes the [generic
  sequence
  functions](https://www.gnu.org/software/emacs/manual/html_node/elisp/Sequence-Functions.html)
  over more concrete data structure functions, [generalised setters via
  `setf`](https://www.gnu.org/software/emacs/manual/html_node/elisp/Generalized-Variables.html)
  over `setq` and `setcar`, `equal` unless a more specific equality function
  is necessary, etc.

TODO:

- [ ] Better support running as a service, e.g. `systemctl enable --now --user
   emacs`.
- [ ] Polish the treesitter and LSP integrations more, and enable by default.
- [ ] Enable live previews of in-project grepping and file-finding.
- [ ] Pinning of third party package commits. Not obviously viable with
      `package.el` unless getting packages directly from their VCS
      source. `straight.el` could be another approach.

