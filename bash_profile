###   competitive programming   ###

# Prepare archive files for a Codeforces problem

function cfprob(){
	python3 ~/dotfiles/tools/prepare_cf_problem.py $1
}

###   competitive programming   ###

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

#Get the latest arena and open it
topcoder(){
    curl http://community.topcoder.com/contest/arena/ContestAppletProd.jnlp >> ~/Desktop/arena.jnlp
    open ~/Desktop/arena.jnlp
}

#Create a contest README

function init-contest(){
	if [ ! -f ./contest.txt ]; then
cat << EOF >> contest.txt
CONTEST NAME
============
LINK: link-here

Problemset:
- problem a [dp, greedy, dfs, bfs]
- problem b [ad-hoc, binary-search]
EOF
	fi
}
