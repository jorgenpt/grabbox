#!/bin/bash

cd "$(dirname "$0")/.."

git subtree push --prefix=pages origin gh-pages
