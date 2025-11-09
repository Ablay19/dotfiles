def fzf-select [] {
  ls
  | get name
  | fzf --height 40% --min-height 20 --reverse --multi --bind=ctrl-z:ignore
  | lines
  | each { |it| $"'($it)'" }
  | str join " "
}

def fzf-history [] {
  history
  | get command
  | uniq
  | reverse
  | fzf --height 40% --min-height 20 --reverse --multi --bind=ctrl-z:ignore
  | lines
  | str join "\n"
}

def fzf-processes [] {
  ps
  | select pid name
  | each { |it| $"($it.pid) ($it.name)" }
  | fzf --height 40% --min-height 20 --reverse
  | lines
}

def fzf-fd [] {
  fd
  | fzf --height 40% --min-height 20 --reverse
  | lines
  | each { |it| $"'($it)'" }
  | str join " "
}
