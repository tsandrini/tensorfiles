;;; init.el -*- lexical-binding: t; -*-

;; your private configuration here! Remember, you do not need to run 'doom
;;' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets.
(setq user-full-name "Tomáš Sandrini"
      user-mail-address "tomas.sandrini@seznam.cz")

;; Doom exposes five (optional) variables for controlling fonts in Doom. Here
;; are the three important ones:
;;
;; + `doom-font'
;; + `doom-variable-pitch-font'
;; + `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;;
;; They all accept either a font-spec, font string ("Input Mono-12"), or xlfd
;; font string. You generally only need these two:
;; (setq doom-font (font-spec :family "monospace" :size 12 :weight 'semi-light)
;;       doom-variable-pitch-font (font-spec :family "sans" :size 13))

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'ewal-doom-vibrant) ;doom-henna is really good as well

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/"
      org-use-property-inheritance t
      org-log-done 'time)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type 'relative)
(global-display-line-numbers-mode t) ; I really like numbered lines

;; Here are some additional functions/macros that could help you configure Doom:
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.


;; Custom configs
;; -----------------

;; Bug on close
(setq x-select-enable-clipboard-manager nil)

; Set default dictionary
(setq ispell-dictionary "english")

;; Auto-reload PDF files
(add-hook 'doc-view-mode-hook 'auto-revert-mode)
(add-hook 'pdf-view-mode-hook 'auto-revert-mode)

;; Set frame opacity
(set-frame-parameter (selected-frame) 'alpha '(90 . 88))
(add-to-list 'default-frame-alist '(alpha . (90 . 88)))

;; Remap escape key to kj/jk
(after! evil
  (setq evil-escape-unordered-key-sequence t
        evil-escape-key-sequence "jk"
        evil-escape-key-sequence "kj")
  ;; Some weird hack to prevent evil-snipe remapping the s/S vim keys
  (evil-snipe-mode -1))

;; Treemacs settings
(after! treemacs
  (defun treemacs-visit-node-no-split-and-quit (&optional arg)
    (interactive)
    (treemacs-visit-node-in-most-recently-used-window arg)
    (treemacs))
  (treemacs-git-mode 'extended)
  (add-to-list 'treemacs-pre-file-insert-predicates #'treemacs-is-file-git-ignored?)
  (setq treemacs-show-hidden-files nil
        treemacs-default-visit-action 'treemacs-visit-node-no-split-and-quit))

;; Ranger annoying bug hack, more on https://github.com/ralesi/ranger.el/issues/214
(eval-after-load "ranger"
  '(defun ranger-window-check ()
     "Detect when ranger-window is no longer part of ranger-mode"
     (let* (;; (windows (window-list)) ; Unused var
            (ranger-window-props
             (r--aget ranger-w-alist
                      (selected-window)))
            ;; (prev-buffer (caar ranger-window-props)) ; Unused var
            (ranger-windows (r--akeys ranger-w-alist))
            ;; (ranger-buffer (cdr ranger-window-props)) ; Unused var
            (ranger-frames (r--akeys ranger-f-alist)))
       ;; if all frames and windows are killed, revert buffer settings
       (ranger--message "Window Check (%s) : %s
        buffer: %s
        w:%s f:%s "
                        major-mode
                        last-command
                        (current-buffer)
                        (and (memq (selected-window) ranger-windows) t)
                        (and (memq (selected-frame) ranger-frames) t))
       ;; TODO deal with new-frame command
       (if (not  (or (ranger-windows-exists-p)
                     (ranger-frame-exists-p)))
           (progn
             ;; (message "All ranger frames have been killed, reverting ranger settings and cleaning buffers.")
             ;; (ranger-revert)) ; FIXME https://github.com/ralesi/ranger.el/issues/214
             ;; when still in ranger's window, make sure ranger's primary window and buffer are still here.
             (when ranger-window-props
               ;; Unless selected window does not have ranger buffer
               (when (and (memq (selected-window) ranger-windows)
                          (not (eq major-mode 'ranger-mode)))
                 (ranger--message
                  "Window Check : Ranger window is not the selected window
** buffer: %s: %s
** window: %s: %s"
                  (current-buffer)
                  major-mode
                  (selected-window)
                  (memq (selected-window) ranger-windows) )

                 (ranger-still-dired))))))))

(after! ivy
  (setq +ivy-buffer-preview t))

(after! which-key
  (setq which-key-idle-delay 0.5))

;; Various custom mappings
(map! (:leader
       (:desc "Current buffer's undo tree" :n "ou" #'undo-tree-visualize)
       (:desc "evil-quit" :n "q" #'evil-quit)
       (:desc "evil-save" :n "w" #'save-buffer)
       (:desc "evil-window-left" :n "h" #'evil-window-left)
       (:desc "evil-window-down" :n "j" #'evil-window-down)
       (:desc "evil-window-up" :n "k" #'evil-window-up)
       (:desc "evil-window-right" :n "l" #'evil-window-right)
       (:desc "evil-window-split" :n "s" #'evil-window-split)
       (:desc "evil-window-vsplit" :n "v" #'evil-window-vsplit)
       (:desc "workspace-new" :n "n" #'+workspace/new)
       (:desc "highlights-remove" :n "r" #'evil-ex-nohighlight))
      (:n "," #'evil-avy-goto-char-2)
      (:n "m" #'treemacs)
      (:n "J" #'+workspace/switch-left)
      (:n "K" #'+workspace/switch-right)
      (:after treemacs :mn "," #'evil-avy-goto-char-2)
      (:after ibuffer :mn "," #'evil-avy-goto-char-2)
      (:after magit :mn "K" #'+workspace/switch-right))

(use-package! org-roam
  :ensure t
  :init
  :custom
  (org-roam-directory "~/org/")
  (org-roam-complete-everywhere t)
  (org-roam-capture-templates
   '(("d" "default" plain (file "~/org/templates/default_template.org")
      :if-new (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n#+date: %U\n#+author: tsandrini\n")
      :unnarrowed t)
     ("w" "wiki" plain (file "~/org/templates/wiki_template.org")
      :if-new (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n#+filetags: :Wiki:\n#+date: %U\n#+author: tsandrini\n")
      :unnarrowed t)
     ("f" "definition" plain (file "~/org/templates/definition_template.org")
      :if-new (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n#+filetags: :Definition:Wiki:\n#+date: %U\n#+author: tsandrini\n")
      :unnarrowed t)
     ("h" "theorem" plain (file "~/org/templates/theorem_template.org")
      :if-new (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n#+filetags: :Theorem:Wiki:\n#+date: %U\n#+author: tsandrini\n")
      :unnarrowed t)
     ;; ("a" "axiom" plain (file "~/org/templates/axiom_template.org")
     ;;  :if-new (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n#+filetags: :Axiom:Wiki:\n#+date: %U\n#+author: tsandrini\n")
     ;;  :unnarrowed t)
     ("a" "algorithm" plain (file "~/org/templates/algorithm_template.org")
      :if-new (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n#+filetags: :Algorithm:Wiki:ComputerScience:\n#+date: %U\n#+author: tsandrini\n")
      :unnarrowed t)
     ("e" "attachment" plain (file "~/org/templates/attachment_template.org")
      :if-new (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n#+filetags: :Attachment:\n#+date: %U\n#+author: tsandrini\n")
      :unnarrowed t)
     ;; ("r" "reading" plain (file "~/org/templates/reading_template.org")
     ;;  :if-new (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n#+filetags: :Reading:Attachment:\n#+date: %U\n#+author: tsandrini\n")
     ;;  :unnarrowed t)
     ;; ("g" "watching" plain (file "~/org/templates/watching_template.org")
     ;;  :if-new (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n#+filetags: :Watching:Attachment:\n#+date: %U\n#+author: tsandrini\n")
     ;;  :unnarrowed t)
     ("z" "zotero" plain (file "~/org/templates/zotero_template.org")
      :if-new (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n#+filetags: :Zotero:Reading:Attachment:\n#+date: %U\n#+author: tsandrini\n")
      :unnarrowed t)
     ("r" "repository" plain (file "~/org/templates/repository_template.org")
      :if-new (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n#+filetags: :ComputerScience:Repository:\n#+date: %U\n#+author: tsandrini\n")
      :unnarrowed t)
     ("c" "course" plain (file "~/org/templates/course_template.org")
      :if-new (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n#+filetags: :Course:\n#+date: %U\n#+author: tsandrini\n")
      :unnarrowed t)
     )
   )
  :config
  (org-roam-db-autosync-mode))

(use-package! websocket
    :after org-roam)

(use-package! org-roam-ui
    :after org-roam ;; or :after org
;;         normally we'd recommend hooking orui after org-roam, but since org-roam does not have
;;         a hookable mode anymore, you're advised to pick something yourself
;;         if you don't care about startup time, use
;;  :hook (after-init . org-roam-ui-mode)
    :config
    (setq org-roam-ui-sync-theme t
          org-roam-ui-follow t
          org-roam-ui-update-on-save t
          org-roam-ui-open-on-start t))

(defun afs/org-replace-all-links-by-description (&optional start end)
  "Find all org links and replace by their descriptions."
  (interactive
   (if (use-region-p) (list (region-beginning) (region-end))
     (list (point-min) (point-max))))
  (save-excursion
    (save-restriction
      (narrow-to-region start end)
      (goto-char (point-min))
      (while (re-search-forward org-link-bracket-re nil t)
        (replace-match (match-string-no-properties
                        (if (match-end 2) 2 1)))))))

(after! org
  ;; (setq org-roam-directory "~/org/org-roam")
  ;; (setq org-roam-index-file "~/org/")
  (setq org-todo-keywords '((sequence "TODO(t)" "NEXT(n)" "PROG(p)" "INTR(i)" "DONE(d)"))
        org-agenda-files (directory-files-recursively "~/org/todos/" "\\.org$")
        org-archive-location "~/org/todos/archive/%s::"
        ;; Hide tasks taht are scheduled in the future
        org-agenda-todo-ignore-scheduled 'future
        ;; Use "second" instead of "day" for time comparison.
        ;; It hides tasks with a scheduled time like "<2020-11-15 Sun 11:30>"
        org-agenda-todo-ignore-time-comparison-use-seconds t
        ;; Hide the deadline prewarning prior to scheduled date.
        org-agenda-skip-deadline-prewarning-if-scheduled 'pre-scheduled
        org-agenda-custom-commands
        '(("n" "Agenda / INTR / PROG / NEXT"
           ((agenda "" nil)
            (todo "INTR" nil)
            (todo "PROG" nil)
            (todo "NEXT" nil))
           nil)))
  (setq org-capture-templates
        (doct '(( "Personal TODO" :keys "p"
                  :icon (":glasses:" :set "github" :color "green")
                  :prepend t
                  :file "~/org/todos/personal.org"
                  :type entry
                  :template ("* %{todo-state} %?"
                             ":PROPERTIES:"
                             ":CREATED: %U:"
                             ":END:"
                             "** Description"
                             "** Conclusion"
                             "** Notes"
                             "** References")
                  :children ( ("Personal TODO" :keys "t"
                              :todo-state "TODO")
                             ("Personal NEXT" :keys "n"
                              :todo-state "NEXT")
                             ("Personal PROG" :keys "p"
                              :todo-state "PROG")
                             ("Personal INTR" :keys "i"
                              :todo-state "INTR")))
                ( "Work (PešekMudra) TODO" :keys "w"
                  :icon (":glasses:" :set "github" :color "green")
                  :prepend t
                  :file "~/org/todos/work_pesek_mudra.org"
                  :type entry
                  :template ("* %{todo-state} %?"
                             ":PROPERTIES:"
                             ":CREATED: %U:"
                             ":END:"
                             "** Description"
                             "** Conclusion"
                             "** Notes"
                             "** References")
                  :children (
                             ("Work (PešekMudra) TODO" :keys "t"
                              :todo-state "TODO")
                             ("Work (PešekMudra) NEXT" :keys "n"
                              :todo-state "NEXT")
                             ("Work (PešekMudra) PROG" :keys "p"
                              :todo-state "PROG")
                             ("Work (PešekMudra) INTR" :keys "i"
                              :todo-state "INTR")))
                ( "Personal (Bureaucracy) TODO" :keys "b"
                  :icon (":glasses:" :set "github" :color "green")
                  :prepend t
                  :file "~/org/todos/personal_bureaucracy.org"
                  :type entry
                  :template ("* %{todo-state} %?"
                             ":PROPERTIES:"
                             ":CREATED: %U:"
                             ":END:"
                             "** Description"
                             "** Conclusion"
                             "** Notes"
                             "** References")
                  :children (
                             ("Personal (Bureaucracy) TODO" :keys "t"
                              :todo-state "TODO")
                             ("Personal (Bureaucracy) NEXT" :keys "n"
                              :todo-state "NEXT")
                             ("Personal (Bureaucracy) PROG" :keys "p"
                              :todo-state "PROG")
                             ("Personal (Bureaucracy) INTR" :keys "i"
                              :todo-state "INTR")))
                ( "Misc TODO" :keys "m"
                  :icon (":glasses:" :set "github" :color "green")
                  :prepend t
                  :file "~/org/todos/misc.org"
                  :type entry
                  :template ("* %{todo-state} %?"
                             ":PROPERTIES:"
                             ":CREATED: %U:"
                             ":END:"
                             "** Description"
                             "** Conclusion"
                             "** Notes"
                             "** References")
                  :children (
                             ("Misc TODO" :keys "t"
                              :todo-state "TODO")
                             ("Misc NEXT" :keys "n"
                              :todo-state "NEXT")
                             ("Misc PROG" :keys "p"
                              :todo-state "PROG")
                             ("Misc INTR" :keys "i"
                              :todo-state "INTR")))
                ( "Study TODO" :keys "s"
                  :icon (":glasses:" :set "github" :color "green")
                  :prepend t
                  :file "~/org/todos/study.org"
                  :type entry
                  :template ("* %{todo-state} %?"
                             ":PROPERTIES:"
                             ":CREATED: %U:"
                             ":END:"
                             "** Description"
                             "** Conclusion"
                             "** Notes"
                             "** References")
                  :children (
                             ("Study TODO" :keys "t"
                              :todo-state "TODO")
                             ("Study NEXT" :keys "n"
                              :todo-state "NEXT")
                             ("Study PROG" :keys "p"
                              :todo-state "PROG")
                             ("Study INTR" :keys "i"
                              :todo-state "INTR")))
                ))))

;; accept completion from copilot and fallback to company
(use-package! copilot
  :hook (prog-mode . copilot-mode)
  :bind (:map copilot-completion-map
              ("<tab>" . 'copilot-accept-completion)
              ("TAB" . 'copilot-accept-completion)
              ("C-TAB" . 'copilot-accept-completion-by-word)
              ("C-<tab>" . 'copilot-accept-completion-by-word)))

(use-package! lsp-nix
  :ensure lsp-mode
  :after (lsp-mode)
  :demand t
  :custom
  (lsp-nix-nil-formatter ["nixfmt"]))


(use-package! nix-mode
  :hook (nix-mode . lsp-deferred)
  :ensure t)

;; (add-hook 'tuareg-mode-hook #'merlin-mode)
;; (add-hook 'caml-mode-hook #'merlin-mode)
;; (use-package! merlin-company)
