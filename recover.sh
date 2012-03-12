#!/bin/bash

# Script to restore deleted files matching a pattern on an NTFS filesystem
#  * numbers files consecutively
#  * uses ntfsundelete

# Copyright (c) 2012 Andreas Lauser
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
# associated documentation files (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge, publish, distribute,
# sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or
# substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
# NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
# OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


# Device to work on
DEVICE=/dev/sdb1

# file name patterns to recover. Each is a regular expression.
PATTERNS=".*\.pdf .*\.doc.* .*\.xls.* .*\.txt bookmarks\.htm.*"


FILENUM=1

ALLFILES=$(ntfsundelete "$DEVICE")

function restorePattern()
{
    PATTERN=$1

    LINES=$(echo "$ALLFILES" | grep -iE "$PATTERN")
    INODE_LIST=$(echo "$LINES" | cut -d" " -f1)

    echo "recovering pattern '$PATTERN'"
    for INODE in $INODE_LIST; do
        FILE_NAME=$(echo "$LINES" | grep -E "^$INODE ")
        FILE_NAME=$(echo $FILE_NAME | sed "s/[0-9]\+ .... [0-9]\+% [0-9\\-]\+ [0-9]\+ \(.*\)/\1/" )
        DESTFILE=$(printf "%06d" $FILENUM)-"$FILE_NAME"
        echo "recovering file '$FILE_NAME' as '$DESTFILE'"
        STATUS=$(ntfsundelete -i $INODE -u "$DEVICE" -o "$DESTFILE")
        if ! echo "$STATUS" | grep -q "successfully"; then
            echo "FAILED:"
            echo "$STATUS"
        else
            FILENUM=$(($FILENUM + 1))
        fi
    done
}

for PATTERN in $PATTERNS; do
    restorePattern "$PATTERN" 
done
