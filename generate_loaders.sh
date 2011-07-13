#! /bin/sh

for name in "$@"
do
    echo "REGISTER_LOADER(\"${name}\", luaopen_$(echo ${name} | sed 's/\./_/'));"
done
