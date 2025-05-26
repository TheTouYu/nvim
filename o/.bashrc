alias proxy='export https_proxy=http://127.0.0.1:7897 http_proxy=http://127.0.0.1:7897 all_proxy=socks5://127.0.0.1:7897'
#export https_proxy=http://127.0.0.1:7897 http_proxy=http://127.0.0.1:7897 all_proxy=socks5://127.0.0.1:7897
alias unproxy='unset all_proxy;unset https_proxy;unset http_proxy'
# conda
eval "$(conda "shell.$(basename "${SHELL}")" hook)"

alias vim='nvim'

# bash completion
[[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && . "/usr/local/etc/profile.d/bash_completion.sh"

export PATH="/usr/local/opt/imagemagick@6/bin:$PATH"
export LDFLAGS="-L/usr/local/opt/imagemagick@6/lib"
export CPPFLAGS="-I/usr/local/opt/imagemagick@6/include"
export PKG_CONFIG_PATH="/usr/local/opt/imagemagick@6/lib/pkgconfig"
export CGO_CFLAGS_ALLOW="-Xpreprocessor"

# homebrew
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
export HOMEBREW_API_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles/api"

export EDITOR=nvim
export PATH=/usr/local/Caskroom/miniconda/base/bin:/usr/local/Caskroom/miniconda/base/condabin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Applications/kitty.app/Contents/MacOS:/Users/bindo1118/go/bin/

export PATH=/usr/local/Cellar/go@1.20/1.20.14/bin/:$PATH
# grep 优化， 查代码，加速
#

cgrep() {
  for item in $(ls -p); do
    #   echo $item;
    if [[ ! $item == *vendor/* ]]; then
      LANG_ALL=C egrep -n -r -i --color "$1" $item
    fi
  done
}
export PATH="/usr/local/opt/openjdk/bin:~/sh:$PATH"
alias bash=/usr/local/bin/bash
export PATH="/usr/local/opt/go@1.23/bin:$PATH"

# 配置 GOPROXY 环境变量
export GOPROXY=https://goproxy.io,direct
# 还可以设置不走 proxy 的私有仓库或组，多个用逗号相隔（可选）
export GOPRIVATE=git.mycompany.com,github.com/my/private,sources.bindo.co
# cd
eval "$(zoxide init bash)"
# pdf text search by fzf
p() {
  local open
  open=open # on OSX, "open" opens a pdf in preview
  ag -U -g ".pdf$" |
    fast-p |
    fzf --read0 --reverse -e -d $'\t' \
      --preview-window down:80% --preview '
            v=$(echo {q} | gtr " " "|"); 
            echo -e {1}"\n"{2} | ggrep -E "^|$v" -i --color=always;
        ' |
    gcut -z -f 1 -d $'\t' | gtr -d '\n' | gxargs -r --null $open >/dev/null 2>/dev/null
}
