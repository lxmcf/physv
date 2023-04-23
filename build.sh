#!/bin/bash

meson setup build
meson compile -C build

build/physv
