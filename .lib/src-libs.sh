#!/usr/bin/env bash

local -r wai=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd);

# I could do something fancy here to scan the lib dir....but im
# going to be lazy and define each statically.

# NOTE: Order of the below list may be important. Due to inter-
#       dependencies used within functions.
source ${wai}/logger.sh
source ${wai}/os.sh
source ${wai}/common.sh
source ${wai}/docker.sh
# ...
