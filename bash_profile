###   competitive programming   ###

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
