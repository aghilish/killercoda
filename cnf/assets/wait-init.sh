#!/bin/bash

# waits for background init to finish

rm $0

clear

echo -n "Initialising Prerequisites..."
while [ ! -f /ks/.initfinished ]; do
    echo -n '.'
    sleep 1;
done;
echo " done"

echo