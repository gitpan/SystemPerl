;; systemc-mode.el --- major mode for editing SystemC files
;;
;; $Id: systemc-mode.el 4305 2005-08-02 13:21:57Z wsnyder $

;; Author          : Wilson Snyder <wsnyder@wsnyder.org>
;; Keywords        : languages

;;; Commentary:
;;
;; Distributed from the web
;;	http://www.veripool.com
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
;; Copyright 2001-2005 by Wilson Snyder.  This program is free software;
;; you can redistribute it and/or modify it under the terms of either the GNU
;; General Public License or the Perl Artistic License.
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
(require 'compile)

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
(define-abbrev-table 'systemc-mode-abbrev-table ())


;;;;========================================================================
;;;; Compile-mode error checking

(setq compilation-error-regexp-alist
      (append
       '(
	 ;; SystemPerl preprocessor
	 ("^\\s *%[EWF][a-zA-Z]+: ?\\([^:]+\\):\\([0-9]+\\):" 1 2)
	 ;; Perl
	 ("^.*\\s +at\\s +\\(\/[^ ]+\\) line \\([0-9]+\\)\\." 1 2)
	 ;; AcCheck
	 ("^\"\\([^\"]+\\)\", line \\([0-9]+\\):" 1 2)
	 ) compilation-error-regexp-alist))

(defvar c++-font-lock-keywords-3 "")

(defvar systemc-font-lock-keywords
  (append c++-font-lock-keywords-3
	  (list
	   ;;
	   ;; Fontify filenames in #include <...> preprocessor directives as strings.
	   '("^#\\s *\\(sp\\s +use\\)\\s *\\([\"]?[^\"\n]*[\"]?\\)"
	     nil nil (1 font-lock-builtin-face) (2 font-lock-string-face))
	   ;; Fontify preprocessor directive names.
	   '("^#\\s *\\(sp\\s +[^\n]*\\)" 1 'font-lock-builtin-face)
	   '("^\\s *AUTO[A-Z0-9_]+" 0 'font-lock-builtin-face t)
	   '("\\bsc_bv\\b" 0 'font-lock-type-face t)
	   '("\\bS[PC]_\\(TRACED\\|CELL\\|PIN\\|METHOD\\)\\b" 0 'font-lock-keyword-face t)
	   '("\\bSP_AUTO[A-Z0-9_]+" 0 'font-lock-keyword-face t)
	   )))

;;;;
;;;; Mode stuff
;;;;


(defun systemc-mode ()
  "Major mode for editing SystemC C++ Files.

This mode inherits most of the cc-mode (C++ mode) editing keys and
functions.

Turning on Systemc mode calls the value of the variable
`systemc-mode-hook' with no args, if that value is non-nil.

Key bindings:
\\{systemc-mode-map}"
  (interactive)
  (c-initialize-cc-mode)
  (kill-all-local-variables)
  (set-syntax-table c++-mode-syntax-table)
  (setq major-mode 'systemc-mode
 	mode-name "SystemC"
 	local-abbrev-table systemc-mode-abbrev-table)
  (use-local-map systemc-mode-map)
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
  ;; Hooks
  (run-hooks 'c-mode-common-hook)
  (run-hooks 'systemc-mode-hook)
  (c-update-modeline))


;;; systemc-mode.el ends here
