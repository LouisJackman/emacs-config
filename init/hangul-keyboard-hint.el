;; -*- lexical-binding: t -*-

(require 'seq)



;;;;
;;;; Hangul Keyboard Hint
;;;;


(defconst init--preferred-hangul-font "NanumGothicCoding")

(defconst init--hangul-keyboard-layout
  '((?q . "ㅂ") (?w . "ㅈ") (?e . "ㄷ") (?r . "ㄱ") (?t . "ㅅ")
    (?y . "ㅛ") (?u . "ㅕ") (?i . "ㅑ") (?o . "ㅐ") (?p . "ㅔ")
    (?a . "ㅁ") (?s . "ㄴ") (?d . "ㅇ") (?f . "ㄹ") (?g . "ㅎ")
    (?h . "ㅗ") (?j . "ㅓ") (?k . "ㅏ") (?l . "ㅣ")
    (?z . "ㅋ") (?x . "ㅌ") (?c . "ㅊ") (?v . "ㅍ") (?b . "ㅠ")
    (?n . "ㅜ") (?m . "ㅡ")
    (?Q . "ㅃ") (?W . "ㅉ") (?E . "ㄸ") (?R . "ㄲ") (?T . "ㅆ")
    (?O . "ㅒ") (?P . "ㅖ")))

(defconst init--hangul-keyboard-rows
  '("qwertyuiop" "asdfghjkl" "zxcvbnm"))

(defvar init--hangul-keyboard-hint-window nil)


(defun init--configure-hangul-font (frame)
  "Use the preferred Hangul font in FRAME when it is installed."
  (when (display-graphic-p frame)
    (with-selected-frame frame
      (let ((font (font-spec :family init--preferred-hangul-font)))
        (when (find-font font)
          (set-fontset-font t 'hangul font frame 'append))))))


(defun init--hangul-keyboard-hint-active-p ()
  "Check whether the built-in 2-beolsik input method is active."
  (equal current-input-method "korean-hangul"))


(defun init--hangul-keyboard-hint-last-key ()
  "Return the last physical character key, if available."
  (let ((keys (this-command-keys-vector)))
    (when (> (length keys) 0)
      (let ((key (aref keys (1- (length keys)))))
        (and (characterp key) key)))))


(defun init--hangul-keyboard-hint-glyph (key)
  "Return KEY's Hangul glyph in bold."
  (propertize (alist-get key init--hangul-keyboard-layout nil nil #'equal)
              'face
              'bold))


(defun init--render-hangul-keyboard-hint (last-key)
  "Render the 2-beolsik layout, highlighting LAST-KEY."
  (let ((buffer (get-buffer-create "*Hangul 2-beolsik*")))
    (with-current-buffer buffer
      (unless (derived-mode-p 'special-mode)
        (special-mode))
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert "Hangul 2-beolsik (C-\\ toggles)\n")
        (seq-doseq (row init--hangul-keyboard-rows)
          (seq-doseq (key (string-to-list row))
            (let* ((shifted-key (upcase key))
                   (display-label (concat (format "%c " key)
                                          (init--hangul-keyboard-hint-glyph key))))
              (when (or (equal last-key key)
                        (equal last-key shifted-key))
                (add-face-text-property 0
                                        (length display-label)
                                        'highlight
                                        t
                                        display-label))
              (insert display-label "   ")))
          (insert "\n"))
        (insert "Shift: Q " (init--hangul-keyboard-hint-glyph ?Q)
                "  W " (init--hangul-keyboard-hint-glyph ?W)
                "  E " (init--hangul-keyboard-hint-glyph ?E)
                "  R " (init--hangul-keyboard-hint-glyph ?R)
                "  T " (init--hangul-keyboard-hint-glyph ?T)
                "  O " (init--hangul-keyboard-hint-glyph ?O)
                "  P " (init--hangul-keyboard-hint-glyph ?P) "\n")))
    buffer))


(defun init--show-hangul-keyboard-hint ()
  "Show the 2-beolsik layout without moving focus to its window."
  (let ((buffer (init--render-hangul-keyboard-hint
                 (init--hangul-keyboard-hint-last-key))))
    (when (and (window-live-p init--hangul-keyboard-hint-window)
               (not (equal (window-frame init--hangul-keyboard-hint-window)
                           (selected-frame))))
      (delete-window init--hangul-keyboard-hint-window)
      (setf init--hangul-keyboard-hint-window nil))
    (unless (window-live-p init--hangul-keyboard-hint-window)
      (setf init--hangul-keyboard-hint-window
            (display-buffer-in-side-window
             buffer '((side . bottom) (slot . 1) (window-height . 7)))))))


(defun init--hide-hangul-keyboard-hint ()
  "Hide the 2-beolsik layout window."
  (when (window-live-p init--hangul-keyboard-hint-window)
    (delete-window init--hangul-keyboard-hint-window))
  (setf init--hangul-keyboard-hint-window nil))


(defun init--update-hangul-keyboard-hint ()
  "Synchronize the keyboard hint with the active input method."
  (if (init--hangul-keyboard-hint-active-p)
      (init--show-hangul-keyboard-hint)
    (init--hide-hangul-keyboard-hint)))


(defgroup init-hangul-keyboard-hint nil
  "Live display of the 2-beolsik Hangul keyboard layout."
  :group 'i18n)


(define-minor-mode init-hangul-keyboard-hint-mode
  "Show a live 2-beolsik layout whenever `korean-hangul` is active."
  :global t
  :group 'init-hangul-keyboard-hint
  (if init-hangul-keyboard-hint-mode
      (progn
        (add-hook 'post-command-hook 'init--update-hangul-keyboard-hint)
        (init--update-hangul-keyboard-hint))
    (remove-hook 'post-command-hook #'init--update-hangul-keyboard-hint)
    (init--hide-hangul-keyboard-hint)))


(defun init--set-hangul-keyboard-hint-enabled (symbol value)
  "Set SYMBOL to VALUE and synchronize the keyboard hint mode."
  (setf (default-value symbol) value)
  (when (fboundp 'init-hangul-keyboard-hint-mode)
    (init-hangul-keyboard-hint-mode (if value 1 -1))))


(defcustom init-hangul-keyboard-hint-enabled t
  "Whether to show the live 2-beolsik keyboard hint."
  :type 'boolean
  :group 'init-hangul-keyboard-hint
  :set #'init--set-hangul-keyboard-hint-enabled)


(defun init--configure-hangul-keyboard-hint ()
  "Configure Hangul input, fonts, and keyboard hints."
  (setopt default-input-method "korean-hangul")
  (add-hook 'after-make-frame-functions 'init--configure-hangul-font)
  (init--configure-hangul-font (selected-frame))
  (init-hangul-keyboard-hint-mode
   (if init-hangul-keyboard-hint-enabled 1 -1)))


(provide 'init-hangul-keyboard-hint)
