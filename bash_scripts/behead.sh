#!/usr/bin/env bash

# the stratup banner changed (linebreak-y before 'something new'?); #lines not constant over versions -> need to 'grep -v' more aggressively..

grep -v 'Now starting' \
| grep -v 'Welcome to' \
| grep -v 'You are running' \
| grep -v 'Read the official' \
| grep -v 'Hint: Type' \
| grep -v 'something new.' \
| grep -v '_____' \
| grep -v '|  |  |' \
| grep -v '^$'


#| tail -n +0

