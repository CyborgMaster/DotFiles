(add-hook 'groovy-mode-hook
          (lambda ()
            (setq indent-tabs-mode nil
                  c-basic-offset 2)))

(prelude-require-package 'unfill)
(define-key global-map (kbd "C-M-q") 'unfill-paragraph)
