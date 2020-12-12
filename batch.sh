#!/usr/bin/bash

CMD=./bin/start_hands_ev.rb
OPTS="-- -j16 -n 100M"
BASE=data/start_hands/start_hands_100M

$CMD $OPTS --ahc --s17 --das -d6 >${BASE}_ahc_s17_das_d6.json
$CMD $OPTS --ahc --s17 --no-das -d6 >${BASE}_ahc_s17_nodas_d6.json
$CMD $OPTS --ahc --h17 --das -d6 >${BASE}_ahc_h17_das_d6.json
$CMD $OPTS --ahc --h17 --no-das -d6 >${BASE}_ahc_h17_nodas_d6.json
$CMD $OPTS --enhc --s17 --das -d6 >${BASE}_enhc_s17_das_d6.json
$CMD $OPTS --enhc --s17 --no-das -d6 >${BASE}_enhc_s17_nodas_d6.json
$CMD $OPTS --enhc --h17 --das -d6 >${BASE}_enhc_h17_das_d6.json
$CMD $OPTS --enhc --h17 --no-das -d6 >${BASE}_enhc_h17_nodas_d6.json
