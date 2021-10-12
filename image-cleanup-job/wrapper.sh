#!/bin/bash

# This is a wrapper script to ensure the container stops in an infinite loop after execution, no matter if there was an error or not
# We also print out a standardized statement we can use to detect run to completion regardless of success.

pwsh /job/Run-ImageCleanup.ps1 2> /tmp/error.out

echo ""
echo "Error output:"
echo ""
cat /tmp/error.out

echo ""
echo "Exit status: $?"

echo "END OF EXECUTION"

# sleep for 5min to not immediately terminate pod
sleep 300;
