#!/usr/bin/env bash

# -- Find the offending Inode directories
for i in /*; do echo $i; find $i |wc -l; done
