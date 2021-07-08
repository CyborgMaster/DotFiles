;; Don't quit without making double checking
(setq confirm-kill-emacs 'y-or-n-p)

(add-hook 'groovy-mode-hook
          (lambda ()
            (setq indent-tabs-mode nil
                  c-basic-offset 2)))

(add-hook 'c-mode-hook (lambda () (c-toggle-comment-style -1)))

(prelude-require-package 'unfill)
(define-key global-map (kbd "C-s-q") 'unfill-paragraph)

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

(defun quote-lines (start end)
  (interactive "r")
  (when (and (called-interactively-p 'any) (not (use-region-p)))
    (setq start (point)) (setq end (+ (point) 1)))
  (save-excursion
    (goto-char start)
    (while (< (point) end)
      (move-to-mode-line-start)
      (insert-char ?\")
      (end-of-line)
      (unless (= (char-before) ?\s)(insert-char ?\s))
      (insert-char ?\")
      (forward-line 1))))

(defun unquote-lines (start end)
  (interactive "r")
  (when (and (called-interactively-p 'any) (not (use-region-p)))
    (setq start (point)) (setq end (+ (point) 1)))
  (save-excursion
    (goto-char start)
    (while (< (point) end)
      (move-to-mode-line-start)
      (when (= (char-after) ?\")(delete-char 1))
      (end-of-line)
      (when (= (char-before) ?\")(delete-char -1))
      (forward-line 1))))

(defun proto-fill-string (start end)
  (interactive "r")
  (let (end-mark saved-fill-column) (save-excursion
    (goto-char start)
    (setq start (line-beginning-position))
    (goto-char end)
    (setq end-mark (make-marker))
    (set-marker end-mark (line-end-position))

    (unquote-lines start (marker-position end-mark))

    ;; Subtract 3 for the 2 quotes and a space used by quote-lines
    (setq saved-fill-column fill-column)
    (setq fill-column (- fill-column 3))
    (fill-region start (marker-position end-mark))
    (setq fill-column saved-fill-column)

    (quote-lines start (marker-position end-mark)))))

;; Org Mode customizations
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

;; Allow code compilation buffers to re-use the same window across frames and
;; don't force those frames to take focus
(add-to-list 'display-buffer-alist
             '("." nil (reusable-frames . t) (inhibit-switch-frame . t)))

;; This package is awesome and allows moving between frames as easy as windows,
;; however it doesn't respect MacOS spaces, so I'm not using it for now.
;; (require 'framemove)
;; ;; (framemove-default-keybindings)
;; (setq framemove-hook-into-windmove t)

;; Better modeline (very customizable, gets rid of all the minor modes)
;; TODO: change the font colors; red when modified is hard to read.
(use-package doom-modeline
  :ensure t
  :init
  (doom-modeline-mode 1)
  (setq doom-modeline-icon nil) ; icon's don't work without anti aliasing
  (setq doom-modeline-height 1)
  (setq doom-modeline-buffer-file-name-style 'truncate-with-project)
  (setq doom-modeline-buffer-encoding nil)
  (setq doom-modeline-env-version nil)
)

(use-package commify :ensure t)

;; This defaults to imenu anywhere.  I prefer it for the current file only.
(define-key prelude-mode-map (kbd "C-c i") 'helm-imenu)

;; Always have ediff open things in the same frame.
(advice-add 'ediff-window-display-p :override #'ignore)

;; Make ediff return to the previous session when quitting a nested one.
(defun restore-last-ediff-session ()
  (when (> (length ediff-session-registry) 0)
    (ediff-with-current-buffer
      (nth 0 ediff-session-registry)
      (ediff-show-meta-buffer (nth 0 ediff-session-registry) t)
      (ediff-update-diffs))))
(add-hook 'ediff-after-quit-hook-internal #'restore-last-ediff-session)

;; When quitting last ediff session, restore the window layout.
(defvar ediff-last-windows nil)
(defun store-pre-ediff-winconfig ()
  (when (= (length ediff-session-registry) 0)
    (setq ediff-last-windows (current-window-configuration))))
(defun restore-pre-ediff-winconfig ()
  (when (= (length ediff-session-registry) 0)
    (set-window-configuration ediff-last-windows)))
(add-hook 'ediff-before-setup-hook #'store-pre-ediff-winconfig)
(add-hook 'ediff-after-quit-hook-internal #'restore-pre-ediff-winconfig)

(prelude-require-package 'multi-line)
(define-key global-map (kbd "s-RET") 'multi-line)

;; Only trigger which-key manually

;; Allow C-h to trigger which-key before it is done automatically
(setq which-key-show-early-on-C-h t)
;; make sure which-key doesn't show normally but refreshes quickly after it is
;; triggered.
(setq which-key-idle-delay 10000)
(setq which-key-idle-secondary-delay 0.05)
