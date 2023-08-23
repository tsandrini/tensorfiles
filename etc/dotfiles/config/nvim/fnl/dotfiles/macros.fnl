{:augroup
 (fn [name ...]
   `(do
      (nvim.ex.augroup ,(tostring name))
      (nvim.ex.autocmd_)
      ,...
      (nvim.ex.augroup :END)))

 :autocmd
 (fn [...]
   `(nvim.ex.autocmd ,...))

 :execstr
 (fn [name ...]
   `((. nvim.ex ,(tostring name)) ,...))

 :viml->fn
 (fn [name]
   `(.. "lua require('" *module-name* "')['" ,(tostring name) "']()"))

 :test
 (fn [name]
   `(.. "lua require('" ,(tostring name) "')"))}
