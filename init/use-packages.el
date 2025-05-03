;; -*- lexical-binding: t -*-

(eval-when-compile
  (require 'cl-lib))
(require 'seq)



;;;;
;;;; Package Configuration
;;;;


(defconst init--modes-to-enable-vim-emulation
  '(prog
    text))


(defun init--use-built-in-packages ()
  nil)


(defun init--use-third-party-packages ()
  (use-package dockerfile-mode)
  (use-package elfeed)
  (use-package elpher)
  (use-package ement)

  (use-package evil
    :defer nil
    :after (neotree)
    :config

    (cl-macrolet ((init--def-evil-keybindings (&rest body)
                    `(progn
                       ,@(seq-map (lambda (binding-entry)
                                    (pcase-let* ((`(,evil-mode ,keys ,func) binding-entry)
                                                 (key-map
                                                  (thread-first
                                                    'string
                                                    (seq-concatenate "evil-"
                                                                     (symbol-name evil-mode)
                                                                     "-state-map")
                                                    intern)))
                                      `(define-key ,key-map
                                                   (kbd ,keys)
                                                   ,func)))
                                  body))))

      (defun init--evil-hook-func ()
        (evil-local-mode)
        (evil-escape-mode))

      (seq-doseq (mode-name init--modes-to-enable-vim-emulation)
        (thread-first
          mode-name
          init--add-mode-hook-suffix
          (add-hook 'init--evil-hook-func)))

      (evil-set-leader 'normal (kbd "SPC"))

      (init--def-evil-keybindings

       (normal "<leader>ce" #'init--open-user-init-file)
       (normal "<leader>cl" #'init--load-user-init-file)

       (normal "<leader>w" #'save-buffer)
       (normal "<leader>q" #'save-buffers-kill-terminal)

       (normal "<leader>d" #'kill-buffer)

       (normal "<leader>h" #'windmove-left)
       (normal "<leader>j" #'windmove-down)
       (normal "<leader>k" #'windmove-up)
       (normal "<leader>l" #'windmove-right)
       (normal "<leader>v" #'split-window-right)
       (normal "<leader>s" #'split-window-below)
       (normal "<leader>o" #'delete-other-windows)

       (normal "<leader><" #'shrink-window-horizontally)
       (normal "<leader>>" #'enlarge-window-horizontally)
       (normal "<leader>+" #'enlarge-window)
       (normal "<leader>-" #'shrink-window)
       (normal "<leader>=" #'balance-windows)

       (normal "<leader>cn" #'next-error)
       (normal "<leader>cp" #'previous-error)
       (normal "<leader>cf" #'first-error)

       (normal "<leader>tn" #'tab-new)

       (normal "C-n" 'init--toggle-neotree-in-window-excursion)

       (normal "<leader>ff" #'project-find-file)
       (normal "<leader>fg" #'project-find-regexp)
       (normal "<leader>fb" #'project-switch-to-buffer)
       (normal "<leader>fp" #'project-switch-project))))

  (use-package evil-args
    :after (evil))
  (use-package evil-escape
    :after (evil))
  (use-package evil-exchange
    :after (evil))
  (use-package evil-lisp-state
    :after (evil))
  (use-package evil-nerd-commenter
    :after (evil))
  (use-package evil-numbers
    :after (evil))
  (use-package evil-surround
    :after (evil))
  (use-package evil-visual-mark-mode
    :after (evil))
  (use-package evil-visualstar
    :after (evil))

  (use-package flymake)
  (use-package json-mode)
  (use-package kubed)
  (use-package magit)
  (use-package markdown-mode)
  (use-package mastodon)
  (use-package mentor)

  (use-package neotree
    :defer nil
    :demand t
    :config

    (defun init--toggle-neotree-in-window-excursion ()
      (interactive)
      (save-selected-window
        (neotree-toggle))))

  (use-package password-store)
  (use-package pinentry)

  (use-package powerline
    :defer nil
    :demand t)

  (use-package powerline-evil
    :after (powerline)
    :config (powerline-vim-theme))

  (use-package sqlite3)

  (use-package vterm
    :defer nil
    :demand t
    :bind ("C-x C-t" . vterm))

  (use-package which-key)
  (use-package yaml-mode)
  (use-package yasnippet))


(defun init--use-built-in-substitutes-for-third-party-packages ()

  (use-package viper
    :defer nil
    :demand t
    :init

    ;; Only enable Viper once a hook for a relevant buffer type is
    ;; triggered. Explicitly disable this variable before requiring the
    ;; package, to disable the "Viperise" startup prompt.
    (setf viper-mode nil)

    :config
    (seq-doseq (mode-name init--modes-to-enable-vim-emulation)
      (thread-first
        mode-name
        init--add-mode-hook-suffix
        (add-hook 'viper-mode))))

  (use-package term
    :bind ("C-x C-t" . term)))


(cl-defun init--use-packages (&key use-third-party)
  (init--use-built-in-packages)
  (if use-third-party
      (init--use-third-party-packages)
    (init--use-built-in-substitutes-for-third-party-packages)))

