#!/bin/bash

# Shellcheck all the scripts.
for file in scripts/*
do
  shellcheck "$file"
done