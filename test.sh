#!/bin/bash

# Shellcheck all the scripts.
for file in scripts/bash/*
do
  shellcheck "$file"
done