(add-hook 'groovy-mode-hook
          (lambda ()
            (setq indent-tabs-mode nil
                  c-basic-offset 2)))

(prelude-require-package 'unfill)
(define-key global-map (kbd "C-M-q") 'unfill-paragraph)

(prelude-require-package 'narrow-indirect)
(define-key ctl-x-4-map "nd" 'ni-narrow-to-defun-indirect-other-window)
(define-key ctl-x-4-map "nn" 'ni-narrow-to-region-indirect-other-window)
(define-key ctl-x-4-map "np" 'ni-narrow-to-page-indirect-other-window)

(prelude-require-package 'isearch+)
(eval-after-load "isearch" '(require 'isearch+))
(global-unset-key (kbd "ESC ESC ESC"))

(prelude-require-package 'string-inflection)
(define-key global-map (kbd "s-b c") 'string-inflection-lower-camelcase)
(define-key global-map (kbd "s-b C") 'string-inflection-camelcase)
(define-key global-map (kbd "s-b s") 'string-inflection-underscore)
(define-key global-map (kbd "s-b S") 'string-inflection-upcase)
(define-key global-map (kbd "s-b k") 'string-inflection-kebab-case)
