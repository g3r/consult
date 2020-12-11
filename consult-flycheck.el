;;; consult-flycheck.el --- Provides the command `consult-flycheck'  -*- lexical-binding: t; -*-

;; Author: Daniel Mendler, Consult and Selectrum contributors
;; Maintainer: Daniel Mendler
;; Created: 2020
;; License: GPL-3.0-or-later
;; Version: 0.1
;; Package-Requires: ((consult "0.1") (flycheck "31") (emacs "26.1"))
;; Homepage: https://github.com/minad/consult

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Provides the command `consult-flycheck'. This is an extra package, since the
;; consult.el package only depends on Emacs core components.

;;; Code:

(require 'consult)
(require 'flycheck)

(defcustom consult-preview-flycheck t
  "Enable flycheck preview during selection."
  :type 'boolean
  :group 'consult)

(defun consult--flycheck-candidates ()
  "Return flycheck errors as alist."
  (consult--forbid-minibuffer)
  (unless flycheck-current-errors
    (user-error "No flycheck errors (Status: %s)" flycheck-last-status-change))
  (let* ((errors (mapcar
                  (lambda (err)
                    (list (file-name-nondirectory (flycheck-error-filename err))
                          (number-to-string (flycheck-error-line err))
                          err))
                  (seq-sort #'flycheck-error-level-< flycheck-current-errors)))
         (file-width (apply #'max (mapcar (lambda (x) (length (car x))) errors)))
         (line-width (apply #'max (mapcar (lambda (x) (length (cadr x))) errors)))
         (fmt (format "%%-%ds %%-%ds %%-7s %%s (%%s)" file-width line-width)))
    (mapcar
     (pcase-lambda (`(,file ,line ,err))
       (flycheck-jump-to-error err)
       (let ((level (flycheck-error-level err)))
         (cons
          (consult--narrow-candidate
           (pcase level
             ('error "e")
             ('warning "w")
             (_ "i"))
           (format fmt
                   (propertize file 'face 'flycheck-error-list-filename)
                   (propertize line 'face 'flycheck-error-list-line-number)
                   (propertize (symbol-name level) 'face (flycheck-error-level-error-list-face level))
                   (propertize (flycheck-error-message err) 'face 'flycheck-error-list-error-message)
                   (propertize (symbol-name (flycheck-error-checker err))
                            'face 'flycheck-error-list-checker-name)))
        (point-marker))))
     errors)))

;;;###autoload
(defun consult-flycheck ()
  "Jump to flycheck error."
  (interactive)
  (consult--goto
   (consult--read "Flycheck error: "
                  (consult--with-increased-gc (consult--flycheck-candidates))
                  :category 'flycheck-error
                  :require-match t
                  :sort nil
                  :narrow '("e" "w" "i")
                  :lookup #'consult--lookup-list
                  :preview (and consult-preview-flycheck #'consult--preview-position))))

(provide 'consult-flycheck)
;;; consult-flycheck.el ends here
