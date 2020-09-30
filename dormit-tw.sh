#!/bin/bash

# àngel "mussol" bosch - muzzol@gmail.com
# this tool needs oysttyer installed and configured: https://github.com/oysttyer/oysttyer
# it will create a data subdir on the script dir

TW_ACCOUNT=""
INTERACT=""

# when listing this will be the maximum retrieved number of entries
# setting it too high can give problmes
MAX_LIST="1000"

# how many likes per account (picked randomnly from last 20 + this number)
ACCOUNT_LIKES="2"

# total amount of interactions. it'll be split equally between interacted accounts
# for now just likes are supported
MAX_INTERACTIONS="1000"

########################################
# don't touch anything below this line #
########################################
V="0.3.2"
COUNT_MAX="0"
TIME_START=`date +%s`

mes1(){
    # simple message function
    echo "`date '+%Y%m%d_%H%M%S'` - $*"
}

mes2(){
    # simple message function without carriage return
    echo -n "`date '+%Y%m%d_%H%M%S'` - $*"
}

end_runtime(){
    # function to track runtime
    TIME_START="$1"
    TIME_END=`date +%s`
    RUN_SECS=$((TIME_END-TIME_START))
    mes2 "finishing - runtime: "
    printf '%dh:%dm:%ds\n' $(($RUN_SECS/3600)) $(($RUN_SECS%3600/60)) $(($RUN_SECS%60))
    exit 0
}

mes1 "$0 - Ver: $V"

S_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
DATA_DIR="${S_DIR}/dormit_data"

# wait a random number of time between 1.000 and 4.000 seconds "
waitrand(){
    RANDSECS=`shuf -i 1000-4000 -n 1`
    RSMILI="${RANDSECS:0:1}.${RANDSECS:1}"
    mes1 "	waiting $RSMILI seconds"
    sleep $RSMILI
}

t_checks(){
    # check for twitter client binary
    type oysttyer >/dev/null 2>&1
    if [ "$?" != "0" ]; then
	mes1 "ERROR: oysttyer binary not found"
	mes1 "please, install it on you path - https://github.com/oysttyer/oysttyer"
	mes1 "hint: ln -s /opt/oysttyer-master/oysttyer.pl /usr/local/bin/oysttyer"
	exit 1
    fi
}

t_conf(){
    # some configuration checks
    if [ "$INTERACT" == "" ] || [ "$TW_ACCOUNT" == "" ]; then
	mes1 "ERROR: missing configuration. check TW_ACCOUNT and INTERACT parameters"
	exit 1
    fi
}

run_oysttyer(){
    PARAMS="$*"
    # echo "DEBUG: PARAMS [$PARAMS] RUN_OYST [$RUN_OYST]"
    # we try to execute it once and if we catch an error we do it again with -hold
    RUN_OYST=`oysttyer -verbose -runcommand="$PARAMS"`
    # echo "DEBUG: RUN_OYST [$RUN_OYST]"
    if [ "$?" != "0" ]; then
	# waitrand
	# mes2 "problems executing oysttyer: "
	SERV_ERROR=`echo "$RUN_OYST" | grep '*** server reports:' | cut -d":" -f2-`

	>&2 echo -n "$SERV_ERROR - retrying (can take a while) - "
	RUN_OYST=`oysttyer -verbose -hold=120 -runcommand="$PARAMS"`
    fi
    echo "$RUN_OYST"
}

t_info(){
    mes2 "checking own account: "
    TW_PROFILE=`run_oysttyer "/whois $TW_ACCOUNT"`

    SN=`echo "$TW_PROFILE" | grep '(f:' | cut -d"(" -f2 | cut -d")" -f1`
    if [ "$SN" == "${TW_ACCOUNT}" ]; then
	TW_FOLLOWING=`echo "$TW_PROFILE" | grep '(f:' | cut -d"(" -f3 | cut -d":" -f2 | cut -d"/" -f1`
	TW_FOLLOWERS=`echo "$TW_PROFILE" | grep '(f:' | cut -d"(" -f3 | cut -d":" -f2 | cut -d"/" -f2 | cut -d")" -f1`
	echo "$TW_ACCOUNT - Followers $TW_FOLLOWERS - Following $TW_FOLLOWING"
	# waitrand
    else
	echo "ERROR"
	mes1 "can't find account [$TW_ACCOUNT]"
	exit 1
    fi
}

account_interaction(){
    ACC="$1"
    let "GET_N_TW=20+${ACCOUNT_LIKES}"
    LAST_TWEETS=`run_oysttyer "/again +${GET_N_TW} $ACC" | grep "^.{again,"`
    # waitrand
    # if user don't have enough original tweets we skip it
    NO_RTS=`echo "$LAST_TWEETS" | grep "<.${ACC}>" | grep -v "<%${ACC}> RT"`
    NO_RTS_NUM=`echo "$NO_RTS" | wc -l`
    if [ "$NO_RTS_NUM" -ge "$ACCOUNT_LIKES" ]; then
	RAND_TWEETS=`echo "$NO_RTS" | cut -d"}" -f1 | cut -d"," -f2 | shuf | head -n$ACCOUNT_LIKES`
    else
	mes1 "	skip ${ACC}: not enough original content"
	return 1
	# echo "DEBUG: LAST_TWEETS [$LAST_TWEETS] NO_RTS ($NO_RTS_NUM) [$NO_RTS] RAND_TWEETS [$RAND_TWEETS]"
    fi
    # echo "DEBUG: NO_RTS ($NO_RTS_NUM) [$NO_RTS] RAND_TWEETS [$RAND_TWEETS]"
    if [ "$RAND_TWEETS" = "" ]; then
	mes1 "	skip ${ACC}: no tweets or protected account"
	return 1
    fi
    for t in $RAND_TWEETS ; do
	# let "COUNT_MAX+=1"
	export COUNT_SPLIT=$((COUNT_SPLIT+1))
	export COUNT_MAX=$((COUNT_MAX+1))
	TFULL=`echo "$LAST_TWEETS" | grep "again,${t}"`
	mes1 "[$COUNT_MAX/$MAX_INTERACTIONS] - random like: [$TFULL]"
	run_oysttyer "/like $t" > /dev/null
	# waitrand
    done
    if [ "$COUNT_MAX" -ge "$MAX_INTERACTIONS" ]; then
	mes1 "[$COUNT_MAX/$MAX_INTERACTIONS] - maximum interactions reached. exiting"
	end_runtime $TIME_START
    fi
}

t_gather(){
    I_ACCOUNTS="$*"
    cd "$S_DIR"
    mkdir -p "$DATA_DIR"
    cd "$DATA_DIR"

    # we split activity between interacted accounts
    INTERACT_NUM=`echo "$INTERACT" | tr " " "\n" | grep . | wc -l`
    let "SPLIT_INTERACTIONS=${MAX_INTERACTIONS}/${INTERACT_NUM}"

    # first we update our current followers list
    mes1 "listing $TW_ACCOUNT followers (my take some time, aprox 1m per 500 accounts)"
    run_oysttyer "/followers +${MAX_LIST}" | grep '(f.' | cut -d"(" -f2 | cut -d")" -f1 > "${TW_ACCOUNT}_current_followers.list"
    # waitrand
    TW_ACCOUNT_FOLLOWERS=`cat "${TW_ACCOUNT}_current_followers.list"`

    # interacted users file
    if [ ! -e "${TW_ACCOUNT}_interacted.list" ]; then
	echo "$TW_ACCOUNT - `date '+%Y%m%d_%H%M%S'`" > "${TW_ACCOUNT}_interacted.list"
    fi
    INTERACTED=`cat "${TW_ACCOUNT}_interacted.list"`

    # then we gather info for all interaction accounts and parse them
    for i in $I_ACCOUNTS ; do
	export COUNT_SPLIT="0"
	mes2 "gathering data from ${i}: "
	I_PROFILE=`run_oysttyer "/whois ${i}"`
	IN=`echo "$I_PROFILE" | grep '(f:' | cut -d"(" -f2 | cut -d")" -f1`
	if [ "$IN" != "${i}" ]; then
	    echo "ERROR"
	    mes1 "ERROR: can't find account $i"
	    continue
	fi
	I_FOLLOWING=`echo "$I_PROFILE" | grep '(f:' | cut -d"(" -f3 | cut -d":" -f2 | cut -d"/" -f1`
	I_FOLLOWERS=`echo "$I_PROFILE" | grep '(f:' | cut -d"(" -f3 | cut -d":" -f2 | cut -d"/" -f2 | cut -d")" -f1`
	echo "Followers $I_FOLLOWERS - Following $I_FOLLOWING"
	# waitrand
	mes1 "listing current followers for user $i (my take some time, aprox 1m per 500 accounts)"
	run_oysttyer "/followers +${MAX_LIST} $i" | grep '(f.' | cut -d"(" -f2 | cut -d")" -f1 > "${i}_current_followers.list"
	# waitrand
	I_CURRENT_FOLLOWERS=`cat "${i}_current_followers.list"`
	CF_NUM=`echo "$I_CURRENT_FOLLOWERS" | wc -l`
	mes1 "parsing $CF_NUM followers of $i"
	for c in $I_CURRENT_FOLLOWERS ; do
	    # if user already follows us skip it
	    echo "$TW_ACCOUNT_FOLLOWERS" | grep -q "^${c}$"
	    if [ "$?" == "0" ]; then
		mes1 "	skip $c: already follows us"
		continue
	    fi
	    # checking if already interacted
	    echo "$INTERACTED" | grep -q "^${c} - "
	    if [ "$?" == "0" ]; then
		mes1 "	skip $c: already interacted"
		continue
	    fi
	    mes1 "$c (follower of $i) - interacting"
	    account_interaction $c
	    echo "$c - `date '+%Y%m%d_%H%M%S'`" >> "${TW_ACCOUNT}_interacted.list"
	    if [ "$COUNT_SPLIT" -ge "$SPLIT_INTERACTIONS" ]; then
		mes1 "max interactions reached for $i [$COUNT_SPLIT/$SPLIT_INTERACTIONS]"
		break
	    fi
	    # echo "DEBUG: parsing $c" && read a
	done

	# echo "DEBUG: IN [$IN]" && read a
    done
}

t_checks
t_conf
t_info
t_gather "$INTERACT"

# we should never reach this exit
exit 0
