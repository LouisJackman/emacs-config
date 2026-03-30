# AI Agent Instructions — Emacs Configuration

Canonical instructions for all AI coding assistants. Tool-specific files are symlinks to this file:
- `CLAUDE.md` → `AGENTS.md`
- `.cursorrules` → `AGENTS.md`
- `.github/copilot-instructions.md` → `AGENTS.md`

## Overview

Personal Emacs configuration using Evil mode for Vim keybindings with spacebar as the leader key, and a strong preference for built-in packages over third-party alternatives.

**Emacs version floor: 29.1** — hard requirement driven by `use-package` and `use-package-ensure` (built-in since 29.1), the `setopt` macro, `named-let`, and `pixel-scroll-precision-mode`. The `which-key-mode` built-in (30.1) is used when available but guarded with `fboundp` and is not required.

## Directory Structure

```
~/.config/emacs/
├── init.el                       # Entry point
└── init/
    ├── use-packages.el           # All use-package declarations
    ├── custom-file.el            # Emacs customize output — do not hand-edit
    └── additional-configuration.el  # Environment-specific overrides
```

## Startup Flow

`init.el` runs `init--configure`, which:

1. Calls `init--with-potential-additional-configuration`, loading `init/additional-configuration.el` if present and calling its `pre-init` / `post-init` hooks around the rest
2. Configures packaging (adds MELPA Stable and MELPA, appended so default ELPA takes priority)
3. Loads packages via `init--use-packages`
4. Configures `exec-path` from the shell environment (zsh/bash on Unix, PowerShell on Windows) so GUI Emacs inherits the correct `PATH`
5. Configures UI (theme from OS appearance mode, fonts, scrollbars)
6. Sets global keybindings (macOS Cmd/Opt swap, ibuffer, etc.)
7. Enables eglot for any modes listed in `init--modes-to-enable-lsp` (currently empty)
8. Applies tree-sitter mode remaps if `init--use-ts` is `t` (currently `nil`)

## Package Management

Uses `package.el` + `use-package` (both built-in since 29.1).

**Archives** (in priority order, highest first):
1. GNU ELPA (default)
2. NonGNU ELPA (default)
3. MELPA Stable
4. MELPA

**Key custom variables** (in `custom-file.el`):
- `use-package-always-ensure t` — auto-install all declared packages
- `use-package-always-defer t` — lazy-load by default; use `:defer nil` / `:demand t` only when eager loading is required

**Non-archive packages** use `:vc` in `use-package`, with `:rev` set to a specific commit SHA for reproducibility:

```elisp
(use-package some-package
  :vc (:url "https://github.com/author/some-package.el"
       :rev "abcdef1234567890"))
```

Upgrade non-archive packages with `package-vc-upgrade-all` (separate from `package-upgrade-all`).

## Third-Party Package Gate

### The threat model

Emacs Lisp executes with full user privileges and **no sandbox**. There is no equivalent of a browser extension permission model, no capability restriction, and no network or filesystem isolation. Any ELisp that loads at startup can silently:

- Read, write, or exfiltrate any file accessible to the user
- Spawn subprocesses (shells, network clients, etc.)
- Make arbitrary network connections
- Modify the running Emacs session, including other packages' behaviour

Third-party packages therefore represent a direct supply chain attack surface. A compromised or malicious package — whether via a typosquatted name, a hijacked maintainer account, or a MELPA/ELPA infrastructure compromise — executes immediately and silently on startup with no prompt.

This is not hypothetical. Emacs packages have historically had no code signing, no reproducible build verification, and MELPA recipes pull directly from GitHub without content-addressing. Even ELPA packages are distributed as tarballs with only HTTPS transport security, not per-package signing.

### The gate mechanism

`init/additional-configuration.el` controls whether third-party packages load:

```elisp
(defconst init--additional-configuration--use-third-party-packages t)
```

When set to `nil`, `init--use-built-in-substitutes-for-third-party-packages` loads instead:

| Third-party | Built-in substitute |
|---|---|
| `evil` | `viper` |
| `eat` | `term` (`shell` on Windows) |

All other third-party packages (magit, elfeed, ement, powerline, neotree, etc.) are simply absent. The result is a fully functional Emacs using only packages shipped with Emacs itself — zero external code.

### When to use the no-third-party mode

Set `init--additional-configuration--use-third-party-packages` to `nil` in `additional-configuration.el` when operating in environments where the supply chain risk of third-party packages outweighs their convenience:

- Machines handling particularly sensitive data or credentials
- Air-gapped or network-restricted environments
- Situations where the MELPA/ELPA infrastructure cannot be trusted (e.g. during an active supply chain incident)
- Emacs sessions used for security-sensitive work where a compromised package could leak context

### Suggestions for AI-suggested changes

When suggesting additions to this config:

- **Prefer built-in packages** wherever they are adequate. Adding a third-party package permanently increases the supply chain attack surface for every environment where `use-third-party` is `t`. Preferring third-party packages is acceptable when they add **substantial** features over a built-in equivalent.
- **Do not depend on third party packages in fallback path for `init--additional-configuration--use-third-party-packages` being `nil`**.
- **If a package is not on a trust-worthy package archive, and therefore is obtained from a VCS like git, version-pin `:vc` packages to a specific commit SHA** (not `:newest`) to prevent silent drift to unreviewed code.

## Code Style

### Equality

Always use `equal` for comparisons, even for symbols. The config prefers generic, abstract APIs over type-specific ones; less generic functions can still be preferred in functions that are a provable performance hotspot.

```elisp
;; Correct
(equal system-type 'darwin)
(equal (process-status process) 'exit)

;; Wrong — too specific
(eq system-type 'darwin)
```

### Function References

Use `#'` (sharp-quote) for function references in higher-order contexts (keybindings, `seq-map`, `seq-each`, `apply-partially`, etc.).

**Exception**: `add-hook` uses bare `'` so hook variable introspection (e.g. `describe-variable`) shows readable symbol names:

```elisp
;; Correct — higher-order context
(seq-each #'disable-theme custom-enabled-themes)
(define-key map (kbd "SPC ff") #'project-find-file)

;; Correct — add-hook uses bare quote deliberately
(add-hook 'text-mode-hook 'init--set-font-based-on-mode)

;; Wrong — sharp-quote in add-hook
(add-hook 'text-mode-hook #'init--set-font-based-on-mode)
```

### Variable Assignment

- `setopt` for `defcustom` variables (runs their setter functions)
- `setf` with generalised setters for everything else
- Never `setq`, `setcar`, `setcdr`

### Sequence Operations

Prefer generic `seq-*` functions over list-specific equivalents:

```elisp
;; Correct
(seq-each #'f list)
(seq-map #'f list)
(seq-find #'pred list)

;; Avoid
(mapc #'f list)
(mapcar #'f list)
```

### cl-lib Macros

`cl-lib` is required at compile time only, for macros (`cl-flet`, `cl-labels`, `cl-macrolet`, `cl-defun`):

```elisp
(eval-when-compile
  (require 'cl-lib))
```

### Lexical Binding

All files must have the file-local variable header:

```elisp
;; -*- lexical-binding: t -*-
```

### Naming Conventions

- `init--` double-hyphen prefix for private/internal functions and constants
- `init-` single-hyphen prefix for public, interactive commands
- Do not define symbols without the `init` prefix in this config

### File Structure

```elisp
;;;;
;;;; Top-Level Section
;;;;


;;;
;;; Subsection
;;;


;; Inline comment
```

Double blank lines between major `;;;;` sections. Single blank lines between `defun`s.

## Key Platform Notes

### Terminal Emulator

**Use `eat`, not `vterm`.** `eat` is declared with `:demand t` and bound to `C-x C-t`. The `vterm` package requires C compilation at bootstrap and is deliberately excluded to improve portability of this Emacs configuration.

### macOS Key Modifiers

`mac-option-modifier` is set to `'super` and `mac-command-modifier` to `'meta`, swapping the physical positions of Opt and Cmd to match other platforms' muscle memory.

## Evil Mode & Keybindings

Leader key: `SPC` (normal mode). Escape sequence: `fd`.

Key bindings are defined in `init/use-packages.el` inside the `evil` `:config` block via the `init--def-evil-keybindings` macro. Selected bindings:

| Key | Command |
|---|---|
| `SPC w` | `save-buffer` |
| `SPC d` | `kill-buffer` |
| `SPC ff` | `project-find-file` |
| `SPC fg` | `project-find-regexp` |
| `SPC v` | `split-window-right` |
| `SPC s` | `split-window-below` |
| `SPC h/j/k/l` | `windmove-*` |
| `SPC cn/cp/cf` | `next-error` / `previous-error` / `first-error` |
| `C-n` | Toggle neotree |
| `C-x C-t` | Open eat terminal |

## Toggles

Modify these constants in `init.el` to change behaviour:

| Constant | Default | Effect |
|---|---|---|
| `init--modes-to-enable-lsp` | `nil` | Add mode hooks to enable eglot |
| `init--use-ts` | `nil` | Set `t` to prefer tree-sitter modes |

To disable all third-party packages, set `init--additional-configuration--use-third-party-packages` to `nil` in `init/additional-configuration.el`.

## AI Agent Guidelines

### Target Emacs variant

Only configure for upstream **GNU Emacs**. Third-party builds of Emacs (e.g. the native macOS ns build) must not be considered. `ns-*` variables and functions are fine when they exist in the upstream GNU build itself — the restriction is against symbols that exist only in third-party builds, not against the `ns-` prefix per se. When platform-specific behaviour is needed on macOS, prefer OS-level CLI tools (e.g. `defaults read`) that work regardless of Emacs build, unless a GNU Emacs built-in covers the need.

### Local-only files

Do not change `init/additional-configuration.el`. It holds machine-specific overrides (e.g. `init--additional-configuration--use-third-party-packages`) that are managed by the user per-machine.

### Validating Elisp edits

After editing any `.el` file, batch-check for syntax errors. Use a depth-tracking script to detect parenthesis mismatches — do not count parens manually.

## Reloading

```
M-x load-file RET ~/.config/emacs/init.el
```

Or use the evil leader bindings: `SPC cl` reloads `init.el`, `SPC ce` opens it for editing.
