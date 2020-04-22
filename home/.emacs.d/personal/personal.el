(add-hook 'groovy-mode-hook
          (lambda ()
            (setq indent-tabs-mode nil
                  c-basic-offset 2)))

(add-hook 'c-mode-hook (lambda () (c-toggle-comment-style -1)))

(prelude-require-package 'unfill)
(define-key global-map (kbd "C-M-q") 'unfill-paragraph)

(global-unset-key (kbd "ESC ESC ESC"))

(prelude-require-package 'string-inflection)
(define-key global-map (kbd "s-b c") 'string-inflection-lower-camelcase)
(define-key global-map (kbd "s-b C") 'string-inflection-camelcase)
(define-key global-map (kbd "s-b s") 'string-inflection-underscore)
(define-key global-map (kbd "s-b S") 'string-inflection-upcase)
(define-key global-map (kbd "s-b k") 'string-inflection-kebab-case)

(defun fill-to-end (char)
  (interactive "cFill Character:")
  (save-excursion
    (end-of-line)
    (while (< (current-column) 80)
      (insert-char char))))
(define-key global-map (kbd "s-b f") 'fill-to-end)

;; Make windmove work in Org mode:
(add-hook 'org-shiftup-final-hook 'windmove-up)
(add-hook 'org-shiftleft-final-hook 'windmove-left)
(add-hook 'org-shiftdown-final-hook 'windmove-down)
(add-hook 'org-shiftright-final-hook 'windmove-right)

;; In org-mode, swap M-RET and RET
;;
;; For most note taking, I want return to insert a new item, not create a new
;; line, for those rare times I actually want a new line character, I can use
;; M-RET.
(with-eval-after-load 'org
  (let ((old-ret (lookup-key org-mode-map (kbd "RET"))))
    (define-key org-mode-map (kbd "RET") (lookup-key org-mode-map (kbd "M-RET")))
    (define-key org-mode-map (kbd "M-RET") old-ret)))
