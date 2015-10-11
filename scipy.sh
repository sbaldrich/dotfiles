#!/bin/eash

brew tap homebrew/python
brew install python
pip install --upgrade pip setuptools
brew linkapps python

pip install virtualenv
pip install virtualenvwrapper
pip install numpy
brew install gcc
pip install scipy
brew install freetype
pip install matplotlib
pip install ipython

# Get QT from http://qt.io
brew install pyqt
brew install zmq
pip install pyzmq
pip install pygments
