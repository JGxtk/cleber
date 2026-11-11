#!/usr/bin/env bash
# Executa o compilador Cleber.
# Uso: ./cleber.sh [--tokens | --arvore] arquivo.clb
cd "$(dirname "$0")"
if [ ! -d build/classes ]; then
  echo "Compile primeiro com ./build.sh"
  exit 2
fi
java -Dfile.encoding=UTF-8 -Dstdout.encoding=UTF-8 -Dstderr.encoding=UTF-8 -cp build/classes Cleber "$@"
