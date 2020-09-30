# dormit
### twitter tool to automate interactions ###

this script uses twitter API to generate interactions with configured accounts to generate activity from your own account.

### installation ###

dormit requires only perl (oysttyer) and standard bash tools, any modern distribution should have all you need.

dormit uses **oysttyer** to query twitter so you need to download and **configure it** before executing this tool.

https://github.com/oysttyer/oysttyer

be sure that you can execute oysttyer as binary/link in your path:

    ln -s /opt/oysttyer-master/oysttyer.pl /usr/local/bin/oysttyer

then just download the script and make it executable

    wget https://raw.githubusercontent.com/muzzol/dormit/master/dormit-tw.sh
    chmod +x dormit-tw.sh


## configuration ##
edit the first lines of script to customize your session.
there's two mandatory settings you should modify:
* TW_ACCOUNT : you own twitter account
* INTERACT : all accounts you'll use followers to create activity

you can also create a conf file to prevent losing your settgins when updating.
the file must be named **dormit-tw.conf** and must be in the same directory as the script.

here is a sample:
```
# basic settings
#################

# your twitter account
TW_ACCOUNT="metacorc"

# accounts you want to interact with
INTERACT="nirvana foofighters mudhoney soundgarden"


# advanced settings: don't touch if you don't know what are you doing
######################################################################

# when listing this will be the maximum retrieved number of entries
# setting it too high can give problems
MAX_LIST="1000"

# how many likes per account (picked randomnly from last 20 + this number)
ACCOUNT_LIKES="2"

# total amount of interactions. it'll be split equally between interacted accounts
# for now just likes are supported
MAX_INTERACTIONS="1000"


```


### API limitations ###
twitter don't want tools acting like humans and their API is focused on enterprise management.
they limit the number of actions you can perform so don't expect this tool to be fast.
the good news is you can run it 24/7 because oysttyer takes care of waiting when you exceed limits, and you don't have to turn it off at night to mimic human behaviour.

from my tests it takes 3 hours to perform 100 interactions.

### support and community ###

this tool is completely unsupported. use it at your own risk!
* https://t.me/dormit_xat - telegram discussion group
* https://www.patreon.com/mussol - Patreon so I can continue working on this tool


### credits ###
* https://github.com/oysttyer/oysttyer Twitter client
* https://github.com/alexal1/Insomniac Instagram bot that heavely inspired the creation of this tool

### what's with the name? ###
* Dormit is the catalan word for Asleep (http://trdkk.com/iusn)
