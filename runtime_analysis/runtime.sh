#!/bin/bash
while getopts tpd:h flag
do
    case "$flag" in
        d) dataset=$OPTARG ;;
        p) predict=1 ;;
        t) train=1 ;;
        h)  	echo ""
		echo "-d [DATASET]	: dataset wanting to simulate: [NYX] OR [SCALE]"
		echo "-p		: time measurement for simulating the prediction model for specified dataset"
		echo "-t		: time measurement for simulating the training model for specified dataset"	
            	echo "-h 		: help"
            	exit 1 ;;
    esac
done
