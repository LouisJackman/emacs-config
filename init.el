;; -*- lexical-binding: t -*-

;;;;
;;;; User Configuration
;;;;



;;;
;;; Requirements, Customisations & Loads
;;;
;;;


;; Requirements

(eval-when-compile
  (require 'cl-lib))
(require 'package)
(require 'use-package)
(require 'use-package-ensure)
(require 'seq)


;; Customisations
;;
;; Doing this before loading additional user configuration is necessary, since
;; their intepretation can change based on customised options, e.g. the
;; macro-expansion of `use-package`.

(defconst init--dir
  (file-name-concat user-emacs-directory
                    "init"))

(setf custom-file (file-name-concat init--dir "custom-file.el"))
(load (file-name-concat init--dir "custom-file"))


;; Loads

(load (file-name-concat init--dir
                        "use-packages"))



;;;
;;; Constants
;;;


(defconst init--modes-to-enable-lsp
  nil)


(defconst init--use-ts nil)


(defconst init--modes-to-prefer-ts-equiv
  (when init--use-ts
    '(bash
      c
      (clojure-clojurescript-mode clojure-ts-clojurescript-mode)
      clojure
      css
      html
      java
      js
      json
      python
      rust
      toml
      tsx
      typescript
      yaml)))


(defconst init--global-bindings
  (list (cons (kbd "C-x C-b") #'ibuffer)))


(defconst init--additional-package-archives
  '(("melpa-stable" . "https://stable.melpa.org/packages/")
    ("melpa"        . "https://melpa.org/packages/")))

                  
(defconst init--additional-configuration
  (file-name-concat init--dir
                   "additional-configuration"))


(defconst init--preferred-monospace-font "FiraCode Nerd Font 14")
(defconst init--preferred-serif-font (if (equal system-type 'darwin)
                                         "Baskerville"
                                         "Liberation Serif"))
(defconst init--preferred-font-height 200)


(defconst init--preferred-light-theme 'modus-operandi)
(defconst init--preferred-dark-theme 'modus-vivendi)



;;;
;;; Top-Level Defuns and Macros
;;;


(defun init--add-mode-suffix (sym)
  (thread-first
    'string
    (seq-concatenate (symbol-name sym) "-mode")
    intern))

(defun init--add-mode-hook-suffix (sym)
  (let ((with-mode-suffix (init--add-mode-suffix sym)))
    (thread-first
      'string
      (seq-concatenate (symbol-name with-mode-suffix) "-hook")
      intern)))

(defun init--add-ts-mode-suffix (sym)
  (thread-first
    'string
    (seq-concatenate (symbol-name sym) "-ts")
    intern
    init--add-mode-suffix))


(defun init--desktop-file-exists-p ()
  "Check whether a desktop file exists in the `desktop-dirname` directory."
  (let ((desktop-file (expand-file-name desktop-base-file-name desktop-dirname)))
    (file-exists-p desktop-file)))


(defun init--detect-os-appearance-mode ()
  "Detect the operating system appearance mode, i.e. light mode or dark mode. Supports Linux (GNOME), macOS, Windows. Default to dark mode if the check does not support the host OS."
  (cond

   ;; Linux (GNOME)
   ((and (equal system-type 'gnu/linux)
         (executable-find "gsettings"))
    (if (string-match-p "dark" (shell-command-to-string
                                "gsettings get org.gnome.desktop.interface color-scheme"))
        'dark
      'light))

   ;; macOS
   ((and (equal system-type 'darwin)
         (fboundp 'ns-system-appearance))
    (if (equal (ns-system-appearance) "dark")
        'dark
      'light))

   ;; Windows
   ((equal system-type 'windows-nt)
    (if (string-match-p "0x0" (shell-command-to-string
                               "reg query HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize /v AppsUseLightTheme"))
        'dark
      'light))

   ;; Unsupported OS
   (t 'dark)))

(let ((appearance-mode (init--detect-os-appearance-mode)))

  (defun init--disable-all-active-themes ()
    "Disable all currently active themes."
    (interactive)
    (seq-each #'disable-theme custom-enabled-themes))

  (defun init--theme-according-to-mode ()
    (init--disable-all-active-themes)
    (let ((new-theme (pcase appearance-mode
                       ('dark init--preferred-dark-theme)
                       ('light init--preferred-light-theme)
                       (_ (error "unknown appearance mode %s" appearance-mode)))))
      (load-theme new-theme t)))

  (defun init-flip-appearance ()
    (interactive)
    (setf appearance-mode (pcase appearance-mode
                            ('dark 'light)
                            ('light 'dark)
                            (_ (error "unknown appearance mode %s" appearance-mode))))
    (init--theme-according-to-mode)))


(defun init--set-font-based-on-mode ()
  "Set the current buffer font based on the current major mode."
  (setopt buffer-face-mode-face (list :family init--preferred-serif-font
                                      :height init--preferred-font-height))
  (buffer-face-mode 1))


(defun init--monospace-markdown-code-font ()
  "Set a monospace font for code snippets in Markdown mode."
  (seq-doseq (attr '(markdown-code-face
                     markdown-inline-code-face))
    (set-face-attribute attr nil
                        :family init--preferred-monospace-font
                        :height init--preferred-font-height)))


(defun init--set-global-keybindings ()
  (seq-doseq (entry init--global-bindings)
    (pcase-let ((`(,key . ,command) entry))
      (global-set-key key command)))

  ;; On macOS, swap the option and command keys, to match physical location of
  ;; keybindings on other platforms. Do this in Emacs rather than in
  ;; macOS. That way, macOS keybindings work elsewhere as expected, while
  ;; Emacs retains consistent "muscle memory" across all platforms.
  (when (equal system-type 'darwin)
    (setopt mac-option-modifier 'super)
    (setopt mac-command-modifier 'meta)))


(defun init--prog-text-mode-hook-func ()
  (setopt indicate-empty-lines t)
  (hl-line-mode)
  (display-fill-column-indicator-mode)
  (display-line-numbers-mode))


(defun init--misc-config ()
  (seq-doseq (hook '(prog-mode-hook text-mode-hook))
    (add-hook hook 'init--prog-text-mode-hook-func))

  (if (init--desktop-file-exists-p)
      ;; Override whatever theme was inherited from the most recent desktop
      ;; file, in favour of the active OS appearance mode.
      (add-hook 'desktop-after-read-hook 'init--theme-according-to-mode)
    (init--theme-according-to-mode))

  (add-hook 'text-mode-hook 'init--set-font-based-on-mode)
  (add-hook 'markdown-mode-hook 'init--monospace-markdown-code-font)

  (setf (get 'dired-find-alternate-file 'disabled) nil)
  (setopt inhibit-startup-echo-area-message (user-login-name))

  ;; Only enable it if it's built-in (as of Emacs 30.1).
  (when (fboundp 'which-key-mode)
    (which-key-mode))

  (set-frame-font init--preferred-monospace-font nil t)
  (context-menu-mode)
  (display-fill-column-indicator-mode)
  (prettify-symbols-mode)
  (icomplete-vertical-mode)
  (pixel-scroll-precision-mode)
  (auto-fill-mode)
  (visual-line-mode)
  (windmove-default-keybindings))


(defun init--configure-ui ()
  (when (display-graphic-p)
    (scroll-bar-mode -1)))


(defun init--configure-packaging ()
  (seq-doseq (entry init--additional-package-archives)

    ;; Append MELPA entries so the default ELPA entries take
    ;; priority. Prioritise Melpa Stable over its non-stable equivalent.
    (add-to-list 'package-archives entry t))
  (package-initialize))


(defun init--configure-path ()

  (cl-flet ((as-pair (entry)
              (pcase-let* ((`(,name . ,value-fragments)
                            (string-split entry "=" t "\\s*"))
                           (values
                            (thread-first
                              value-fragments
                              string-join
                              (string-split ":"))))
                (cons name values)))

            (path-p (entry)
              (pcase-let ((`(,name . _) entry))
                (equal name "PATH")))

            (add-to-exec-path (addenda)
              (seq-each (apply-partially #'add-to-list
                                         'exec-path)
                        addenda)))

    (pcase-let* ((env-lines

                  ;; Assume terminal Emacs already has PATH correctly set up,
                  ;; due to being invoked from a shell.
                  (when (display-graphic-p)

                    (condition-case nil

                        (condition-case nil
                            ;; Try zsh first, in the case of macOS without
                            ;; administrative powers to change the default
                            ;; shell to a modern version of bash.
                            (process-lines "zsh" "-l" "-c" "source ~/.zshrc && env")
                          (file-missing

                           ;; Otherwise, try bash.
                           (process-lines "bash" "-l" "-c" "source ~/.bashrc && env")))

                      ;; Return an empty environment for platforms without zsh
                      ;; or bash.
                      (file-missing nil))))

                 (`(_ . ,paths) (thread-last
                                  env-lines
                                  (seq-map #'as-pair)
                                  (seq-find #'path-p))))
      (when paths
        (add-to-exec-path paths)))))


(defun init--open-user-init-file ()
  (interactive)
  (find-file user-init-file))


(defun init--load-user-init-file ()
  (interactive)
  (load user-init-file))


(defun init--enable-lsp ()
  (seq-doseq (mode init--modes-to-enable-lsp)
    (add-hook mode 'eglot)))


(defun init--prefer-ts-modes ()
  (seq-doseq (mode-entry init--modes-to-prefer-ts-equiv)
    (pcase-let ((`(mode . ts-mode)
                 (if (consp mode-entry)
                     mode-entry
                   (cons (init--add-mode-suffix mode-entry)
                         (init--add-ts-mode-suffix mode-entry)))))
      (add-to-list 'major-mode-remap-alist
		   (cons mode ts-mode)))))


(defun init--with-potential-additional-configuration (body)
  (ignore-errors
    (load init--additional-configuration))

  (if (fboundp 'init--additional-configuration--pre-init)
      (init--additional-configuration--pre-init)
    (message "`init--additional-configuration--pre-init` is missing; skipping…"))

  (unwind-protect

      (let ((use-third-party-packages
             (when (boundp 'init--additional-configuration--use-third-party-packages)
               init--additional-configuration--use-third-party-packages)))
        (funcall body use-third-party-packages))

    (if (fboundp 'init--additional-configuration--post-init)
        (init--additional-configuration--post-init)
      (message "`init--additional-configuration--post-init` is missing; skipping…"))))


(defun init-natively-compile-all-packages ()
  (let ((compilation-wait-seconds 15))

    (cl-labels ((wait-for-compilation-to-finish (process elisp-dir)
                  (named-let recur ()
                    (if (equal (process-status process) 'exit)
                        (message "Asynchronous native compilation of `%s` finished; continuing…"
                                 elisp-dir)
                      (message "Asynchronous native compilation of `%s` not yet finished; waiting for %d more seconds…"
                               elisp-dir
                               compilation-wait-seconds)
                      (sleep-for compilation-wait-seconds)
                      (recur))))

                (find-compilation-process (processes)
                  (seq-find (lambda (process)
                              (thread-last
                                process
                                process-name
                                (string-match-p "^Compiling: ")))
                            processes))

                (natively-compile-elisp-files-in (elisp-dir)
                  (native-compile-async elisp-dir 'recursively)
                  (message "Waiting for asynchronous native compilation of `%s` to start…"
                           elisp-dir)
                  (sleep-for 1)
                  (let* ((processes (process-list))
                         (compilation (find-compilation-process processes)))
                    (when compilation
                      (wait-for-compilation-to-finish compilation elisp-dir)))))

      (when (native-comp-available-p)

        (condition-case nil
            (natively-compile-elisp-files-in package-user-dir)
          ;; The package directory may be missing if third party packages have
          ;; been excluded by the configuration.
          (native-compiler-error nil))

        (natively-compile-elisp-files-in user-emacs-directory)))))


(defun init--configure ()
  (init--with-potential-additional-configuration
   (lambda (use-third-party-packages)
     (init--configure-packaging)
     (init--use-packages :use-third-party use-third-party-packages)
     (init--configure-path)
     (init--configure-ui)
     (init--misc-config)
     (init--set-global-keybindings)
     (init--enable-lsp)
     (init--prefer-ts-modes))))



;;;
;;; Entrypoint
;;;


(init--configure)

