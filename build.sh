#!/usr/bin/env bash
# Gera o parser com o JavaCC e compila as classes Java.
set -e
cd "$(dirname "$0")"

VERSAO=7.0.13
JAR="lib/javacc-$VERSAO.jar"

if [ ! -f "$JAR" ]; then
  echo ">> Baixando JavaCC $VERSAO..."
  mkdir -p lib
  curl -fsSL -o "$JAR" \
    "https://repo1.maven.org/maven2/net/java/dev/javacc/javacc/$VERSAO/javacc-$VERSAO.jar"
fi

echo ">> Gerando o analisador com o JavaCC..."
rm -rf build
mkdir -p build/src build/classes
java -cp "$JAR" javacc -OUTPUT_DIRECTORY=build/src src/Cleber.jj

echo ">> Compilando o Java gerado..."
javac -encoding UTF-8 -d build/classes build/src/*.java

echo ">> Pronto! Rode: ./cleber.sh exemplos/atribuicao.clb"
