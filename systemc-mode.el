;; systemc-mode.el --- major mode for editing SystemC files
;; $VERSION = '1.310';

;; Author          : Wilson Snyder <wsnyder@wsnyder.org>
;; Keywords        : languages

;;; Commentary:
;;
;; Distributed from the web
;;	http://www.veripool.org
;;
;; To use this package, simply put it in a file called "systemc-mode.el" in
;; a Lisp directory known to Emacs (see `load-path').
;;
;; Byte-compile the file (in the systemc-mode.el buffer, enter dired with C-x d
;; then press B yes RETURN)
;;
;; Put these lines in your ~/.emacs or site's site-start.el file (excluding
;; the START and END lines):
;;
;;	---INSTALLER-SITE-START---
;;	;; Systemc mode
;;	(autoload 'systemc-mode "systemc-mode" "Mode for SystemC files." t)
;;	(setq auto-mode-alist (append (list '("\\.sp$" . systemc-mode)) auto-mode-alist))
;;	---INSTALLER-SITE-END---
;;
;; COPYING:
;;
;; Copyright 2001-2009 by Wilson Snyder.  This program is free software;
;; you can redistribute it and/or modify it under the terms of either the GNU
;; Lesser General Public License or the Perl Artistic License.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;

;;; History:
;;


;;; Code:

(provide 'systemc-mode)
(require 'cc-mode)
(require 'cc-langs)
(require 'compile)
(when (>= emacs-major-version 22)
  (require 'cc-fonts))

;; Must be first
(eval-and-compile
  (when (>= emacs-major-version 22)
    (c-add-language 'systemc-mode 'c++-mode)))

;;;;========================================================================
;;;; Variables/ Keymap

(defvar systemc-mode-hook nil
  "Run at the very end of `systemc-mode'.")

(defvar systemc-mode-map ()
    "Keymap used in systemc-mode buffers.")
(if systemc-mode-map
    nil
  (setq systemc-mode-map (c-make-inherited-keymap))
  ;; additional bindings
  (define-key systemc-mode-map "\C-c\C-e" 'c-macro-expand))

(defvar systemc-mode-abbrev-table nil
  "Abbreviation table used in systemc-mode buffers.")
(when (< emacs-major-version 22)
  (define-abbrev-table 'systemc-mode-abbrev-table '()))
(when (>= emacs-major-version 22)
  (c-define-abbrev-table 'systemc-mode-abbrev-table '()))

(when (>= emacs-major-version 22)
  (easy-menu-define systemc-menu systemc-mode-map "SystemC Mode Commands"
    (cons "SystemC" (c-lang-const c-mode-menu systemc))))

(defvar systemc-mode-syntax-table nil
  "Syntax table used in systemc-mode buffers.")
(when (>= emacs-major-version 22)
  (or systemc-mode-syntax-table
      (setq systemc-mode-syntax-table
	    (funcall (c-lang-const c-make-mode-syntax-table systemc)))))

;;;;========================================================================
;;;; Compile-mode error checking

(defvar systemc-error-regexp-alist
  '(
    ;; SystemPerl preprocessor
    ("^\\s *%[EWF][a-zA-Z]+: ?\\([^:]+\\):\\([0-9]+\\):" 1 2)
    ;; Perl
    ("^.*\\s +at\\s +\\(\/[^ ]+\\) line \\([0-9]+\\)\\." 1 2)
    ;; AcCheck
    ("^\"\\([^\"]+\\)\", line \\([0-9]+\\):" 1 2)
    )
  "List of additional errors for SystemC compilers.")

(cond ((boundp 'compilation-error-regexp-alist-alist) ;; Emacs 22, XEmacs 20.x
       (setq compilation-error-regexp-alist-alist
	     (cons (cons 'systemc systemc-error-regexp-alist)
		   compilation-error-regexp-alist-alist))
       (make-local-variable 'compilation-error-regexp-alist)
       (push 'systemc compilation-error-regexp-alist))
      (t ;; older Emacsen
       (setq compilation-error-regexp-alist
	     (append systemc-error-regexp-alist
		     compilation-error-regexp-alist))))

;;;;========================================================================
;;;; Fonts

(defcustom systemc-font-lock-extra-types nil
  "*List of extra types (aside from the type keywords) to recognize in SystemC mode.
Each list item should be a regexp matching a single identifier.")

(when (>= emacs-major-version 22)
  (defconst systemc-font-lock-keywords-1 (c-lang-const c-matchers-1 systemc)
    "Minimal highlighting for SystemC mode.")

  (defconst systemc-font-lock-keywords-2 (c-lang-const c-matchers-2 systemc)
    "Fast normal highlighting for SystemC mode.")

  (defconst systemc-font-lock-keywords-3
    (append (c-lang-const c-matchers-3 systemc)
	    (list
	      ;; Keywords
	      '("^\\s *AUTO[A-Z0-9_]+" 0 'font-lock-builtin-face t)
	      '("\\bsc_bv\\b" 0 'font-lock-type-face t)
	      '("\\bS[PC]_\\(TRACED\\|CELL\\|PIN\\|METHOD\\|THREAD\\)\\b" 0 'font-lock-keyword-face t)
	      '("\\bSP_AUTO[A-Z0-9_]+" 0 'font-lock-keyword-face t)
	      ))
    "Accurate normal highlighting for SystemC mode.")

  (defvar systemc-font-lock-keywords systemc-font-lock-keywords-3
    "Default expressions to highlight in SystemC mode.")
  )

(when (< emacs-major-version 22)
  (defvar c++-font-lock-keywords-3 "")

  (defvar systemc-font-lock-keywords
    (append c++-font-lock-keywords-3
	    '(
	      ;; Keywords
	      ("^\\s *AUTO[A-Z0-9_]+" 0 'font-lock-builtin-face t)
	      ("\\bsc_bv\\b" 0 'font-lock-type-face t)
	      ("\\bS[PC]_\\(TRACED\\|CELL\\|PIN\\|METHOD\\|THREAD\\)\\b" 0 'font-lock-keyword-face t)
	      ("\\bSP_AUTO[A-Z0-9_]+" 0 'font-lock-keyword-face t)
	      ;; Fontify preprocessor directive names.
	      ;; / is a hack so "#sp  // comment" gets some highlighting.
	      ("^#\\s *\\(sp\\s +[^\n/]*\\)" 1 'font-lock-builtin-face)
	      ;; Fontify filenames in #include <...> preprocessor directives as strings.
	      ("^#\\s *\\(sp\\s +use\\)\\s *\\([\"]?[^\"\n]*[\"]?\\)"
	       nil nil (1 font-lock-builtin-face) (2 font-lock-string-face))
	      ;; Commentary
	      ("//.*$" 0 'font-lock-comment-face t)	; red
	      ))))

(when (>= emacs-major-version 22)
  (c-lang-defconst c-primitive-type-kwds
    systemc (append '("sc_bv")
		    (append
		     (c-lang-const c-primitive-type-kwds)
		     nil)))

  (c-lang-defconst c-modifier-kwds
    systemc (c-lang-const c-modifier-kwds))

  (c-lang-defconst c-cpp-matchers
    systemc (cons
	     ;; Use the eval form for `font-lock-keywords' to be able to use
	     ;; the `c-preprocessor-face-name' variable that maps to a
	     ;; suitable face depending on the (X)Emacs version.
	     '(eval . (list
		       ;; Fontify preprocessor directive names.
		       ;; / is a hack so "#sp  // comment" gets some highlighting.
		       ("^#\\s *\\(sp\\s +[^\n/]*\\)" 1 'font-lock-builtin-face)
		       ;; Fontify filenames in #include <...> preprocessor directives as strings.
		       ("^#\\s *\\(sp\\s +use\\)\\s *\\([\"]?[^\"\n]*[\"]?\\)"
			nil nil (1 font-lock-builtin-face) (2 font-lock-string-face))
		       '(2 font-lock-string-face)))
	     ;; There are some other things in `c-cpp-matchers' besides the
	     ;; preprocessor support, so include it.
	     (c-lang-const c-cpp-matchers)))
  )

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.sp\\'" . systemc-mode))

;;;###autoload
(defun systemc-mode ()
  "Major mode for editing SystemC C++ Files.

This mode inherits most of the cc-mode (C++ mode) editing keys and
functions.

The hook `c-mode-common-hook' is run with no args at mode
initialization, then `systemc-mode-hook'.

Key bindings:
\\{systemc-mode-map}"
  (interactive)
  (kill-all-local-variables)
  (when (< emacs-major-version 22)
    (c-initialize-cc-mode))
  (when (>= emacs-major-version 22)
    (c-initialize-cc-mode t))
  (when (>= emacs-major-version 22)
    (set-syntax-table systemc-mode-syntax-table))
  (setq major-mode 'systemc-mode
	mode-name "SystemC"
	local-abbrev-table systemc-mode-abbrev-table
	abbrev-mode t)
  (use-local-map systemc-mode-map)
  (when (< emacs-major-version 22)
	 (c-common-init)
	 (setq comment-start "// "
	       comment-end ""
	       c-conditional-key c-C++-conditional-key
	       c-comment-start-regexp c-C++-comment-start-regexp
	       c-class-key c-C++-class-key
	       c-extra-toplevel-key c-C++-extra-toplevel-key
	       c-access-key c-C++-access-key
	       c-recognize-knr-p nil
	       imenu-generic-expression cc-imenu-c++-generic-expression
	       imenu-case-fold-search nil
	       )
	 ;; Font lock
	 (make-local-variable 'font-lock-defaults)
	 (setq font-lock-defaults
	       '((c++-font-lock-keywords c++-font-lock-keywords-1
					 c++-font-lock-keywords-2
					 c++-font-lock-keywords-3
					 systemc-font-lock-keywords
					 )
		 nil nil ((?_ . "w")) beginning-of-defun
		 (font-lock-mark-block-function . mark-defun)))
	 )
  (when (>= emacs-major-version 22)
	 (c-init-language-vars systemc-mode)
	 (c-common-init 'systemc-mode)
	 (easy-menu-add systemc-menu))
  ;; Hooks
  (run-hooks 'c-mode-common-hook)
  (run-hooks 'systemc-mode-hook)
  (c-update-modeline))


(provide 'systemc-mode)
;;; systemc-mode.el ends here
