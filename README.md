# Zsh

## Install
https://dev.to/equiman/zsh-on-windows-without-wsl-4ah9

1. Install git bash
1. Download zsh: https://packages.msys2.org/package/zsh?repo=msys&variant=x86_64
1. Extract the archive with [PeaZip](https://peazip.github.io/) in `C:\Program Files\Git` to merge `etc` and `usr` folders.


## Configure

Add the following to the start of `.bashrc`

```sh
/c/Windows/System32/chcp.com 65001 > /dev/null 2>&1

if [ -t 1 ]; then
  exec zsh
fi
```

## Install Oh My Zsh

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

## Configure theme

```sh
git clone https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k
```

Relaunch git bash or run `p10k configure`.

## Plugins

```sh
git clone https://github.com/zsh-users/zsh-autosuggestions.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/Pilaton/OhMyZsh-full-autoupdate.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/ohmyzsh-full-autoupdate
git clone https://github.com/jessarcher/zsh-artisan.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/artisan
```
