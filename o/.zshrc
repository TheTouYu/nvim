alias proxy='export all_proxy=socks5://127.0.0.1:7897'
alias unproxy='unset all_proxy'
# conda
eval "$(conda "shell.$(basename "${SHELL}")" hook)"

alias vim='nvim'

# export PATH="/usr/local/opt/imagemagick@6/bin:$PATH"
# export LDFLAGS="-L/usr/local/opt/imagemagick@6/lib"
# export CPPFLAGS="-I/usr/local/opt/imagemagick@6/include"
# export PKG_CONFIG_PATH="/usr/local/opt/imagemagick@6/lib/pkgconfig"
# export CGO_CFLAGS_ALLOW="-Xpreprocessor"

# homebrew
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
export HOMEBREW_API_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles/api"

export EDITOR=nvim
export PATH=/usr/local/Caskroom/miniconda/base/bin:/usr/local/Caskroom/miniconda/base/condabin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Applications/kitty.app/Contents/MacOS:/Users/jack/go/bin

export PATH=/usr/local/Cellar/go@1.20/1.20.14/bin/:$PATH
# grep 优化， 查代码，加速
cgrep() {
  for item in $(ls -p); do
    #   echo $item;
    if [[ ! $item == *vendor/* ]]; then
      LANG_ALL=C egrep -n -r -i --color "$1" $item
    fi
  done
}
export PATH="/usr/local/opt/openjdk/bin:$PATH"
alias bash=/usr/local/bin/bash
export PATH="/usr/local/opt/imagemagick@6/bin:$PATH"
export LDFLAGS="-L/usr/local/opt/imagemagick@6/lib"
export CPPFLAGS="-I/usr/local/opt/imagemagick@6/include"
export PKG_CONFIG_PATH="/usr/local/opt/imagemagick@6/lib/pkgconfig"
export CGO_CFLAGS_ALLOW="-Xpreprocessor"
