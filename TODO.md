# TODO

## High-value modernisations

- [ ] Add `early-init.el` — move `tool-bar-mode`, `scroll-bar-mode`, and package archive setup there to avoid startup flicker and reduce init time
- [ ] Enable tree-sitter — set `init--use-ts t`; stable since Emacs 29, Emacs 30 bundles more grammars; improves Go, YAML, JSON, Dockerfile, TypeScript modes already in config
- [ ] Consider vertico stack — `vertico` + `orderless` + `marginalia` + `consult` as a significant upgrade over `icomplete-vertical`; `consult` adds live-previewing grep/find-file
- [ ] Better support running as a service, e.g. `systemctl enable --now --user emacs`
- [ ] Polish the tree-sitter and LSP integrations more, and enable by default
- [ ] Pin third-party package versions — `:vc` with `:rev` covers VCS packages, but archive packages (MELPA, ELPA) are still unpinned

## Smaller improvements

- [ ] Replace powerline — largely unmaintained; consider `doom-modeline` or a custom `mode-line-format`
- [ ] Drop neotree — lightly maintained; replace with treemacs (integrates with project.el + magit) or just dired
- [ ] Fix PATH sourcing — `init--configure-path` still spawns a full shell and parses `env`, costing ~200–500ms; set `exec-path` directly or use `(getenv "PATH")`
- [ ] GC tuning — raise `gc-cons-threshold` during init, reset after; simple and measurable

## Housekeeping

- [ ] Turn off `debug-on-error` in `custom-file.el` — throws into debugger on transient errors (e.g. elfeed network timeouts) in daily use
