###   competitive programming   ###

# Load the competition environment
alias compete='loadenv compete;cd ~/code/cp'

# Prepare archive files for a Codeforces problem

function cfprob(){
	python3 ~/dotfiles/tools/prepare_cf_problem.py $1
}

# Problem checker (Currently only supports java)
function checker(){
	PROB=${1:r}
	MAIN=${2:-Main}
	echo ":: Checking Problem '$PROB' ::"
	for F in $PROB.*.in
	do
		OUT=$(java $MAIN < $F)
		if cmp -s <(echo $OUT) ${F:r}.out
			then RES="\\u2713"
			else RES="\\u2717"
		fi
		echo "Test #${F:r:e}: $RES"
	done
}

# Dump file to clipboard

function clip(){
	cat $1 | xclip -selection c
}

#Get the latest arena and open it
topcoder(){
    curl http://community.topcoder.com/contest/arena/ContestAppletProd.jnlp >> ~/Desktop/arena.jnlp
    open ~/Desktop/arena.jnlp
}

# Virtualenvs

function loadenv(){
	ENVS_HOME=~/envs
	
	if [[ -z $1 ]]
	then
		echo "Supply an environment name"
		return -1
	fi
	
	TARGET_ENV="$ENVS_HOME/$1"
	
	if [[ -d $TARGET_ENV ]]
	then
		source $TARGET_ENV/bin/activate
	else
		echo "Environment $1 not found"
		return -1
	fi
}


function createenv(){
	ENVS_HOME=~/envs
	
	if [[ -z $1 ]]
	then
		echo "Supply an environment name"
		return -1
	fi
	
	TARGET_ENV="$ENVS_HOME/$1"
	
	if [[ -d $TARGET_ENV ]]
	then
		echo "Environment $1 already exists!"
	else
		pushd $ENVS_HOME
		python3 -m venv $1
		source $1/bin/activate
		popd
		echo "Created new environment $1"
		return -1
	fi
}
