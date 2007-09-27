#!/bin/bash

# Copyright (C) 2007 SSH Communications Security, Helsinki, Finland
#
# This code is released under the MLton license, a BSD-style license.
# See the LICENSE file or http://mlton.org/License for details.

set -e
set -x

eb=../../extended-basis/unstable

time \
echo '' | \
sml -m test.cm \
    $eb/public/export/{open-top-level.sml,infixes.sml}  \
    $(find test/ -name '*.sml' -a -not -name 'generic.sml')
