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
