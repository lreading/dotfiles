#!/bin/bash

mpstat 1 1 | awk '/Average/ {usage=100-$NF} END {print usage"%"}'

