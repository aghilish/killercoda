#!/bin/bash

FILE=/ks/wait-init.sh; while ! test -f ${FILE}; do clear; sleep 0.1; done; bash ${FILE}