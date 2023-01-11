#!/bin/bash

sffile=$1

count_a=$(grep RAW ./logs/$sffile | sed -e "s/^.*RAW[[:space:]]//" -e "s/[[:space:]].*$//")
count_b=$(grep FIL ./logs/$sffile | sed -e "s/^.*FIL[[:space:]]//" -e "s/[[:space:]].*$//")
rem="$(($count_a-$count_b))"

echo "$count_a - $count_b: $rem"
