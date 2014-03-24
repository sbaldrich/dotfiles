source ~/.routes #useful routes for quick moving. Remember tilde expansion does not work with cdable_vars

export JAVA_HOME=$(/usr/libexec/java_home)
export PATH=$PATH

#Locale conflicts (IPython)
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

#Useful alias
alias ls="ls -G"
alias ll="ls -alhpTG"
alias ...="cd ../.."
alias ~="cd ~"
alias q="ll | wc -l"
alias qq="find . | wc -l"

mask(){
        if [ -z "$1" ]; then
                echo "No mask given"
                return
        fi
        if [ ! -f ~/sbaldrich/bin/$1.sh ]; then
			echo "Mask $1 does not exist"
		else
			. ~/sbaldrich/bin/$1.sh
		fi
}

#Get Topcoder arena
tcarena(){
	curl http://community.topcoder.com/contest/arena/ContestAppletProd.jnlp >> $CP/arena.jnlp
	open $CP/arena.jnlp
}
#Use hub 
#alias git=hub

#Custom cd
cust_cd(){
	for i in `eval echo range{1..$1}`; do
		cd ..
	done
}

alias ..="cust_cd"
#Customize command line
export PS1="\[\e[0;32m\]\u@\h:\W $ \[\e[0m\]"

shopt -s cdable_vars

source ~/.profile
source ~/.bashrc
