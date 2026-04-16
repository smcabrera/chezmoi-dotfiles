##################################
# Show/Hide hidden files
##################################
alias showFiles='defaults write com.apple.finder AppleShowAllFiles YES; killall Finder /System/Library/CoreServices/Finder.app'
alias hideFiles='defaults write com.apple.finder AppleShowAllFiles NO; killall Finder /System/Library/CoreServices/Finder.app'

##################################
# PICKing Stuff
##################################
alias vim='nvim'
alias vimp='vim $(ls . -type d | pick)' # cd with pick--open source command line fuzzy select: https://robots.thoughtbot.com/announcing-pick
alias cdp='cd ~/Code/ ; cd $(ls ~/Code/ | pick | cut -c 6-)'
alias gbp='git checkout $(git branch --list | fzf | cut -c 3-)'

##################################
# General Stuff
##################################
#alias vi='nvim'
#alias vim="nvim"
alias vimdiff="nvim -d"
alias foundry="~/Library/Application\ Support/FoundryVTT/Data"

alias cop='bundle exec rubocop -A'
alias recop='bundle exec rubocop --auto-gen-config --exclude-limit 3000'
alias deletebranches='git branch --list | cat | fzf -m | xargs git branch -D $1'
# alias test='RAILS_ENV=test bundle exec rspec'
alias dockerup='cpid ; cd ~/Code/development ; docker-compose up'
alias grc='git rebase --continue'
# alias git-delete-squashed='git checkout -q main && git for-each-ref refs/heads/ "--format=%(refname:short)" | while read branch; do mergeBase=$(git merge-base main $branch) && [[ $(git cherry main $(git commit-tree $(git rev-parse $branch\^{tree}) -p $mergeBase -m _)) == "-"* ]] && git branch -D $branch; done'
alias updatemaster='git checkout main ;  git fetch ; git pull origin main ; git-delete-squashed'
alias redb='rm /usr/local/var/postgres/postmaster.pid ; brew services restart postgressql@15'
alias start='bundle install ; bin/generate-ruby-ts ; rails yard:generate -y; bin/db-migrate ; say finished ; bundle exec rails server'
alias newfiles='git diff main --name-only | cat'

# Just doing this because I keep ending up with extra stuff I don't want in the structure.sql
alias rdm='bin/db-migrate ; git checkout db/structure.sql ; test-dirty'
alias rdr='rails db:rollback ; bin/rails db:rollback RAILS_ENV=test'
alias fdry='cd /Users/stephen/Library/Application\ Support/FoundryVTT'
alias rmtdb='bin/rails db:drop RAILS_ENV=test ; bin/rails db:create RAILS_ENV=test ; bin/rails db:migrate RAILS_ENV=test'
alias wds='webpack-dev-server'
alias pstart='brew services start postgresql@16'
alias pstop='brew services stop postgresql@16'

alias lcm='git log -1 --pretty=%B' # Last commit message
alias lch='git log -1 --pretty=%h | pbcopy' # Last commit hash

# Re-migrate test db: RMT
alias rmt='rails db:drop RAILS_ENV=test ; rails db:create RAILS_ENV=test ; rails db:migrate RAILS_ENV=test'


alias branch_name='git branch | grep \* | cut -d " " -f2'
alias backitup='current_branch=$(git branch | grep \* | cut -d " " -f2) ; git checkout -b $current_branch-bak'
alias cb='git branch --show-current'
alias yb='cb | pbcopy ; cb'

# Shorter ones
alias remup='current_branch=$(git branch | grep \* | cut -d " " -f2) ; git checkout main ; git fetch ; git pull origin main ; git checkout $current_branch ; git merge main'
alias mvwip='current_branch=$(git branch | grep \* | cut -d " " -f2) ; git commit -nam "wip" ; git checkout main ; git cherry-pick $current_branch ; git checkout $current_branch ; git reset HEAD~1 --hard ; git checkout main ; git reset HEAD~1'
alias rerup='current_branch=$(git branch | grep \* | cut -d " " -f2) ; git checkout main ; git fetch ; git pull origin main ; git checkout $current_branch ; git rebase main'
alias um='updatemaster'
alias nf='newfiles'
alias nfn='git diff main --name-only | cat'
alias cmoi='~/.local/share/chezmoi/'

alias vim='nvim'
alias zshe='nvim $dotfiles/.zshrc' # Edit zshrc
alias zs='source ~/.zshrc' # ...and source it
alias rc='pry -r ./config/environment'

alias todo='~/Dropbox/GTD/todo.sh -d /home/$USER/Dropbox/GTD/todo.cfg'
alias todoe="vim ~/Dropbox/GTD/todo.txt" # Open up your task list for editing
alias openpr='gh pr view --web'
alias opr=openpr
# alias prc='bin/pr-create --label="lintbot,Create flaky test issues"'
alias prc='bin/pr-create'
alias hs='cat ~/.zsh_history'

# open branch
alias obr='git checkout $(git branch | cut -c 3- | pick)'
# alias docs='fd .*\.md .'
alias usecurrentnvm='nvm use 14.17.4'

# Frontend build
alias feb='yarn install && bin/local-dev --shaka --node-renderer'

##################################
# Git
##################################

alias gp='git push origin $(git branch | grep \* | cut -d " " -f2)'
alias st='git status'
alias gl='git log --graph --pretty=format:'\''%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'\'' --abbrev-commit'
alias ga='git add .'
# alias gac='git add . ; git commit -S -v' # git add all and commit
alias la='bin/lintbot -F'
alias gac='bin/lintbot -F ; git add . ; git commit -nv' # git add all and commit
alias gc='bin/lintbot -F ; git commit -vn'

alias co='checkout_advanced'
alias gb='git branch --list --color | cat'
alias bb='browse-branches'
alias gpf='git push origin $(git branch | grep \* | cut -d " " -f2) --force-with-lease'
alias gam='la ; git add . ; git commit --amend --no-edit -n'
alias wip='git add . ; git commit -nam "WIP"'
alias unwip='git reset HEAD~1'
#alias gbp='git checkout $(git branch --list | pick | cut -d \w -f 1) ; git checkout $branch'

# making ls faster and adding color
# if [ $TERM_PROGRAM = "iTerm.app" ]; then
  # alias ls="colorls --$POWERLEVEL9K_COLOR_SCHEME"
# fi
# alias la='\ls'

##################################
# Tmux
##################################

alias tls="tmux ls" # see my running tmux sessions
alias nest='unset TMUX'

# infocmp $TERM | sed 's/kbs=^[hH]/kbs=\\177/' > $TERM.ti
# tic $TERM.ti

alias claude-yolo='claude --dangerously-skip-permissions'
alias ccy='claude --dangerously-skip-permissions'
