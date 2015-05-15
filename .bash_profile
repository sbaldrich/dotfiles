###   fixes   ###

#Locale conflicts (IPython)
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
#Java home is sometimes a pain in the ass on OS X
#export JAVA_HOME=$(/usr/libexec/java_home)




###   aliases   ###

alias ls="ls -G"
alias ll="ls -alhpTG"
alias ...="cd ../.."
alias ~="cd ~"
alias q="ll | wc -l"
alias qq="find . | wc -l"




###   masks    ###
# Masks are 'profiles' that define functions you can use on specific
# contexts, e.g. competitive programming, teaching, hacking, etc.

mask(){
        if [ -z "$1" ]; then
                echo "No mask given"
                return
        fi
        if [ ! -f ~/bin/masks/$1.sh ]; then
			echo "Mask $1 does not exist"
		else
			. ~/bin/masks/$1.sh
		fi
}




###   competitive programming   ###

#Get latest Topcoder arena (this should go in a mask :P)
tcarena(){
	curl http://community.topcoder.com/contest/arena/ContestAppletProd.jnlp >> ~/Desktop/arena.jnlp
	open ~/Desktop/arena.jnlp
}




###   git   ###

#Use hub 
#alias git=hub

# git completion and prompt utility scripts
. ~/.git-completion.bash
. ~/.git-prompt.sh
export GIT PS1 SHOWDIRTYSTATE=1


###   misc   ###

export PS1='\[\e[0;32m\]\u@\h:\W $(__git_ps1 " (%s)") \$ \[\e[0m\]'

# go up n directories using this function
cust_cd(){
	for i in `eval echo range{1..$1}`; do
		cd ..
	done
}
alias ..="cust_cd"

# make possible to 'cd' to variables. Use .routes to define these vars.
shopt -s cdable_vars
source ~/.routes #useful routes for quick moving. Remember tilde expansion does not work with cdable_vars

#source ~/.profile
#source ~/.bashrc
