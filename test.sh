#!/bin/bash

result=0
for suite in *.test.sh; do
    echo ":: $suite ::"
    bash "$suite" || result=1
done
exit $result
