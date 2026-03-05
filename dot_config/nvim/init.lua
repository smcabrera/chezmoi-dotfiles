-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

vim.opt.wrap = false

--[[
--My old leader mappings, which I can convert over time

" nmap <leader>edm :! git diff master --name-only | cat | fzf > /tmp/some_filename ; :tabedit $somefile
  nmap <Leader>m :CtrlPModified<CR>
  nmap <leader>1 :source ~/.config/nvim/init.vim<CR>
  nmap <leader>2 :PlugInstall<CR>
  nmap <leader>3 :edit ~/.vimrc<CR>
  nmap <leader>at :tabe <cr>
  nmap <leader>b :ls<cr>:b<space>
  nmap <leader>ck :let $file=expand("%") <cr> :let $klass=system("echo $(class_from_file " . $file . ")") <cr> :let @+ = $klass<cr>
  nmap <leader>d <Plug>DashSearch
  nmap <leader>ea :edit ~/.dotfiles/zsh/aliases.zsh<CR>
  nmap <leader>eb :edit ~/.dotfiles/bin<CR>
  nmap <leader>ec :e . <cr> :Econtroller
  nmap <leader>em :e . <cr> :Emodel
  nmap <leader>ed :! url=$(docs_for_file %) ; open $url <cr>
  nmap <leader>esm :tabedit scratch.md<cr>
  nmap <leader>esr :tabedit scratch.rb<cr>
  nmap <leader>ev :edit ~/.dotfiles/config/nvim/init.vim<CR>
  nmap <leader>ez :edit ~/.dotfiles/zshrc<CR>
  nmap <leader>fc :! klass=$(class_from_file %) ; ag $klass app > /tmp/search.txt <cr> :tabedit /tmp/search.txt <cr>
  nmap <leader>fs :! rubocop -a --only FrozenStringLiteralComment % <cr>
  nmap <leader>gb :Git blame<cr>
  nmap <leader>gl :GoLint<cr>
  nmap <leader>gdo :GoDoc<cr>
  nmap <leader>gde :GoDef<cr>
  nmap <leader>gdb :GoDocBrowser<cr>
  nmap <leader>h gT
  nmap <leader>l gt
  nmap <leader>n :NERDTreeToggle<CR>
  nmap <leader>oc oputs "#" * 90<c-m>puts caller<c-m>puts "#" * 90<esc> " output caller courtesy Aaron Patterson: https://tenderlovemaking.com/2016/02/05/i-am-a-puts-debuggerer.html
  nmap <leader>of odef function<c-m><tab>
  nmap <leader>p :FZF <cr>
  nmap <leader>q :q <cr>
  nmap <leader>qq :q! <cr>
  nmap <leader>ra :! rubocop -a % <cr>
  nmap <leader>rr :e! %<cr>
  nmap <leader>st :vs <cr> :A <cr>
  nmap <leader>tf :TestFile<CR>
  nmap <leader>tg :TestVisit<CR>
  nmap <leader>tl :TestLast<CR>
  nmap <leader>tn :TestNearest<CR>
  nmap <leader>ts :TestSuite<CR>
  nmap <leader>te :tabedit % <cr>:A<CR>
  nmap <leader>w :w<CR>
  nmap <leader>x :x<CR>
  nmap <leader>zr zR
--]]
