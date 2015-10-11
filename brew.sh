#!/usr/bin/env bash

# install brew
if [ `which brew | grep 'brew$'` = "" ]; then
	ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" 
fi

brew tap homebrew/versions
brew tap homebrew/science

brew update
brew upgrade

brew install tree
brew install openssl
brew install wget
brew install curl
brew install ack
brew install git
brew install hub
brew install node
#brew install postgresql
brew install --build-from-source pgcli 
#brew install byobu => down.
brew install fish
brew install bash
brew install siege
brew install vim --override-system-vi
brew install pyenv
brew install youtube-dl
brew install gifsicle
brew install dos2unix
brew install r
brew install maven32

# cask
brew install caskroom/cask/brew-cask

brew cask install google-chrome
brew cask install skype
brew cask install iterm2
brew cask install vlc
brew cask install utorrent
brew cask install firefox
brew cask install the-unarchiver
brew cask install lighttable
brew cask install atom
brew cask install brackets
brew cask install virtualbox
brew cask install openemu
brew cask install spotify
brew cask install flux
brew cask install wireshark
brew cask install torbrowser
brew cask install rstudio
brew cask install licecap
brew cask install keepassx
brew cask install hipchat
brew cask install google-drive
brew cask install dropbox
brew cask install gimp
brew cask install calibre
brew cask install xquartz
brew cask install wireshark

brew cask install java
brew install maven32
brew install jenv

brew cask install eclipse-installer

brew cleanup

# Atom
apm install linter
pip install flake8
pip install flake8-docstrings
apm install linter-flake8
apm install script
