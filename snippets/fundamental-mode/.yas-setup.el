;;
;; Workaround for snippets not being inherited from `fundamental-mode'.
;; See: https://github.com/joaotavora/yasnippet/issues/557#issuecomment-72368826
;;
(add-hook 'yas-minor-mode-hook
          (lambda()
            (yas-activate-extra-mode 'fundamental-mode)))
