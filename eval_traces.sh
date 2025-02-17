#!/bin/bash

# MIT License
#
# Copyright (c) 2024 David Schall and EASE lab
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Execute this script using
#   ./eval_all.sh

set -e

TRACE_DIR="/home/anusheelnand/Documents/sn850/traces/gapbs"

# Find all trace files recursively in all subdirectories and extract their base names
TRACES=$(find "$TRACE_DIR" -type f -name "*.champsim.trace.gz" -exec basename {} .champsim.trace.gz \;)

# Debug output
echo "Found the following traces:"
echo "$TRACES"
echo "------------------------"

cmake --build ./build --target predictor -j $(nproc)

OUT=results/
POSTFIX="ae"

d1M=1000000

N_WARM=$(( 1612 * $d1M ))
N_SIM=$(( 5000 * $d1M ))

FLAGS=""
# FLAGS="${FLAGS} --tabledump"
FLAGS="${FLAGS} --simulate-btb"

BRMODELS=""
BRMODELS="${BRMODELS} llbp"
BRMODELS="${BRMODELS} llbp-timing"
BRMODELS="${BRMODELS} tage64k"
BRMODELS="${BRMODELS} tage64kscl"
BRMODELS="${BRMODELS} tage512kscl"

commands=()

for model in $BRMODELS; do
    for trace in $TRACES; do
        # Find the trace file recursively, including in subdirectories
        TRACE_PATH=$(find "$TRACE_DIR" -type f -name "${trace}.champsim.trace.gz")
        
        # Create output directory
        OUTDIR="${OUT}/${trace}/"
        mkdir -p "$OUTDIR"

        CMD="\
            ./build/predictor $TRACE_PATH \
                --model ${model} \
                ${FLAGS} \
                -w ${N_WARM} -n ${N_SIM} \
                --output \"${OUTDIR}/${model}-${POSTFIX}\" \
                > $OUTDIR/${model}-${POSTFIX}.txt 2>&1"

        commands+=("$CMD")
    done
done

echo "Running ${#commands[@]} simulations"

parallel --jobs $(nproc) ::: "${commands[@]}"

wait
echo "Simulation complete."