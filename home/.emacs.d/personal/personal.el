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

;; Org mode customizations
(add-to-list 'auto-mode-alist '("\\.org\\.txt\\'" . org-mode))
(with-eval-after-load 'org
  ;; Make windmove work in Org mode:
  (define-key org-mode-map (kbd "<S-up>") nil)
  (define-key org-mode-map (kbd "<S-down>") nil)
  (define-key org-mode-map (kbd "<S-left>") nil)
  (define-key org-mode-map (kbd "<S-right>") nil)

  ;; This version keeps the basic org mode commands and then moves to another
  ;; window if the command wouldn't do anything.  This isn't worth it to me.  I
  ;; would rather have window moving always work, regardless of context.
  ;;
  ;; (add-hook 'org-shiftup-final-hook 'windmove-up)
  ;; (add-hook 'org-shiftleft-final-hook 'windmove-left)
  ;; (add-hook 'org-shiftdown-final-hook 'windmove-down)
  ;; (add-hook 'org-shiftright-final-hook 'windmove-right)

  ;; In org-mode, swap M-RET and RET
  ;;
  ;; For most note taking, I want return to insert a new item, not create a new
  ;; line, for those rare times I actually want a new line character, I can use
  ;; M-RET.
  (let ((old-ret (lookup-key org-mode-map (kbd "RET"))))
    (define-key org-mode-map (kbd "RET") (lookup-key org-mode-map (kbd "M-RET")))
    (define-key org-mode-map (kbd "M-RET") old-ret)))

;; Integrate Dash documentation viewer
(prelude-require-package 'dash-at-point)
(define-key global-map (kbd "C-h D") 'dash-at-point)
