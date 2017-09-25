#!/bin/bash
#
# source all scripts.
#
LIB_ROOT=$(unset CDPATH && cd $(dirname "${BASH_SOURCE[0]}") && pwd)
source "${LIB_ROOT}/grains.sh"
source "${LIB_ROOT}/utils.sh"
source "${LIB_ROOT}/logging.sh"
