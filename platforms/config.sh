#!/bin/bash

set -e

SDL_SHA=829a65d769d935c4852f8159e964312c0957260a
VPINBALL_SHA=a07eb9ee98cf68890b3fa4ca45b1e56c5a7b559d
PINMAME_SHA=5386aa17fbed2cf41470cea252c38ed77eac64e5

if [ -z "${BUILD_TYPE}" ]; then
   BUILD_TYPE="Release"
fi

echo "Build type: ${BUILD_TYPE}"
echo ""
