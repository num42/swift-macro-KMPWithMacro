#!/bin/sh
set -e

cd ..

swift format --recursive --in-place .
