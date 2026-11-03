# Cleber 

Projeto A3 da UC **Teoria da Computação e Compiladores**.

Cleber é uma linguagem pequena, com palavras-chave em português, inspirada na TINY. Ela tem variáveis, atribuição, `se/entao/senao`, dois laços (`enquanto` e `repita ... ate`), leitura e escrita, expressões aritméticas com precedência e operadores relacionais. O analisador léxico e o sintático foram gerados com **JavaCC** a partir do arquivo [`src/Cleber.jj`](src/Cleber.jj).

Um programa em Cleber tem esta cara:

```
// Calcula o fatorial de n
cleber fatorial
inicio
    leia(n);
    fat = 1;
    i = 1;
    enquanto (i <= n) faca
        fat = fat * i;
        i = i + 1;
    fimenquanto
    escreva("Fatorial: ", fat);
fim
```

Os arquivos-fonte usam a extensão `.clb`.

---

## 1. Especificação léxica

Espaços, tabulações e quebras de linha são descartados. Comentários também:

 Tipo / Forma 

 Comentário de linha  `// até o fim da linha` 
 Comentário de bloco  `/* pode ocupar várias linhas */` 

**Palavras reservadas:** `cleber`, `inicio`, `fim`, `se`, `entao`, `senao`, `fimse`, `enquanto`, `faca`, `fimenquanto`, `repita`, `ate`, `leia`, `escreva`.

**Operadores e pontuação:**

| Token | Símbolo | Token | Símbolo |
|---|---|---|---|
| `ATRIB` | `=` | `MAIS` | `+` |
| `IGUAL` | `==` | `MENOS` | `-` |
| `DIFERENTE` | `!=` | `VEZES` | `*` |
| `MENOR` | `<` | `DIVIDE` | `/` |
| `MAIOR` | `>` | `APAR` / `FPAR` | `(` `)` |
| `MENOR_IG` | `<=` | `PV` | `;` |
| `MAIOR_IG` | `>=` | `VIRG` | `,` |

**Literais e identificadores** (expressões regulares):

```
LETRA   = [a-zA-Z_]
DIGITO  = [0-9]
ID      = LETRA (LETRA | DIGITO)*
NUM     = DIGITO+ ("." DIGITO+)?
STRING  = '"' (qualquer caractere exceto '"' e quebra de linha)* '"'
```

As palavras reservadas são declaradas antes de `ID` no `.jj`. Como o JavaCC escolhe sempre o casamento mais longo e, no empate, a regra declarada primeiro, `se` vira a palavra reservada, mas `sexo` ou `fimse_x` viram identificadores.

---

## 2. Gramática (EBNF)

Notação: `{ X }` = zero ou mais repetições, `[ X ]` = opcional, `|` = alternativa, terminais entre aspas.

```ebnf
programa          ::= "cleber" ID "inicio" lista_comandos "fim"

lista_comandos    ::= { comando }

comando           ::= atribuicao
                     condicional
                     enquanto
                     repita
                     leitura
                     escrita

atribuicao        ::= ID "=" expressao ";"

condicional       ::= "se" "(" expressao ")" "entao" lista_comandos
                      [ "senao" lista_comandos ]
                      "fimse"

enquanto          ::= "enquanto" "(" expressao ")" "faca" lista_comandos "fimenquanto"

repita            ::= "repita" lista_comandos "ate" "(" expressao ")" ";"

leitura           ::= "leia" "(" ID ")" ";"

escrita           ::= "escreva" "(" item_escrita { "," item_escrita } ")" ";"

item_escrita      ::= STRING | expressao

expressao         ::= expressao_simples [ op_relacional expressao_simples ]

op_relacional     ::= "<" | ">" | "<=" | ">=" | "==" | "!="

expressao_simples ::= termo { ( "+" | "-" ) termo }

termo             ::= fator { ( "*" | "/" ) fator }

fator             ::= "(" expressao ")"
                    | NUM
                    | ID
                    | "-" fator
```

### Por que a gramática foi escrita assim

**Sem recursão à esquerda.** Na TINY a regra é `exp-simples -> exp-simples soma termo | termo`. O JavaCC gera um parser descendente recursivo, e uma regra que chama a si mesma como primeiro passo entraria em loop infinito. Reescrevemos com repetição: `expressao_simples ::= termo { ("+"|"-") termo }`. A linguagem reconhecida é a mesma.

**Precedência pela hierarquia das regras.** `expressao` (relacionais) chama `expressao_simples` (soma e subtração), que chama `termo` (multiplicação e divisão), que chama `fator` (parênteses, números, variáveis). Quanto mais "funda" a regra, maior a precedência. Por isso `a + b * 2` agrupa como `a + (b * 2)`. Os operadores relacionais não se encadeiam (`a < b < c` é erro), igual à TINY.

**Sem ambiguidade e sem LOOKAHEAD extra.** Cada alternativa de `comando` começa com um token diferente (`ID`, `se`, `enquanto`, `repita`, `leia`, `escreva`), então um único token de lookahead basta. O problema clássico do "senão pendurado" não existe porque todo `se` termina obrigatoriamente com `fimse`, e todo `enquanto` com `fimenquanto`. O JavaCC gera o parser sem nenhum aviso de conflito.

---

## 3. Como compilar e executar


1. No repositório, clique em **Code → Codespaces → Create codespace on main**.
2. O arquivo `.devcontainer/devcontainer.json` já instala o Java 21 e roda `./build.sh` sozinho na primeira vez. Espere o terminal terminar.
3. Rode os testes: `./testar.sh`

Se você alterou o `Cleber.jj`, recompile com `./build.sh`.

### Em qualquer máquina com Java 11+ (JDK)

```bash
chmod +x build.sh cleber.sh testar.sh
./build.sh          # baixa o JavaCC, gera o parser e compila
./testar.sh         # roda todos os exemplos
```

O `build.sh` faz, passo a passo:

```bash
# 1. baixa o JavaCC (só na primeira vez) para lib/
curl -o lib/javacc-7.0.13.jar https://repo1.maven.org/maven2/net/java/dev/javacc/javacc/7.0.13/javacc-7.0.13.jar
# 2. gera o analisador léxico e sintático em Java a partir do .jj
java -cp lib/javacc-7.0.13.jar javacc -OUTPUT_DIRECTORY=build/src src/Cleber.jj
# 3. compila o Java gerado
javac -encoding UTF-8 -d build/classes build/src/*.java
```

### Usando o compilador

```bash
./cleber.sh exemplos/validos/03_enquanto_fatorial.clb            # valida o programa
./cleber.sh --tokens exemplos/validos/03_enquanto_fatorial.clb   # mostra os tokens (análise léxica)
./cleber.sh --arvore exemplos/validos/03_enquanto_fatorial.clb   # mostra a árvore sintática
```

Exemplo de erro:

```
$ ./cleber.sh exemplos/invalidos/07_enquanto_sem_faca.clb
Erro sintático na linha 6, coluna 9: encontrado 'i'
  Era esperado: "faca"
```

O programa termina com código `0` quando o arquivo é válido e `1` quando há erro léxico ou sintático. O `testar.sh` usa isso para conferir automaticamente que todo exemplo válido é aceito e todo inválido é rejeitado.

---

## 4. Estrutura do repositório

```
.
├── .devcontainer/devcontainer.json   configuração do Codespaces
├── src/Cleber.jj                     especificação léxica e sintática (JavaCC)
├── exemplos/
│   ├── validos/                      programas que devem ser aceitos
│   └── invalidos/                    programas com erros léxicos e sintáticos
├── build.sh                          gera e compila o parser
├── cleber.sh                         executa o compilador
├── testar.sh                         testes automáticos
└── README.md
```

 Exemplo válido / O que demonstra 

 `01_atribuicao_e_expressoes`  atribuição, precedência, parênteses, menos unário, números decimais 
 `02_condicional`  `se/entao`, `se/entao/senao`, `se` aninhado, `>=`, `==`, `!=`, `>` 
 `03_enquanto_fatorial`  laço `enquanto`, leitura, escrita, `<=` 
 `04_repita_contagem`  laço `repita ... ate`, `<` 
 `05_programa_completo`  todas as estruturas juntas, comentários de linha e de bloco 

Exemplo inválido Tipo de erro 

 `01_falta_ponto_e_virgula`  sintático 
 `02_se_sem_fimse`  sintático 
 `03_caractere_invalido`  léxico (`@`) 
 `04_comentario_nao_fechado` léxico 
 `05_expressao_incompleta`  sintático 
 `06_palavra_reservada_como_variavel`  sintático 
 `07_enquanto_sem_faca`  sintático 
 `08_parentese_nao_fechado`  sintático 

---

## 5. Matriz de Responsabilidade

 Integrante  Responsabilidades e módulos desenvolvidos 

 João Guilherme de Faria Teixeira: Especificação léxica no `.jj` (`SKIP`, `TOKEN`, `MORE`): palavras reservadas, identificadores, números, strings, descarte de espaços e comentários (estado `EM_COMENTARIO`). Modo `--tokens`. Exemplos inválidos léxicos. Regras de expressões: `expressao`, `operadorRelacional`, `expressaoSimples`, `termo`, `fator`. Remoção da recursão à esquerda e precedência de operadores. Modo `--arvore`. Exemplo `01`.  Regras `programa`, `listaComandos`, `comando`, `atribuicao`, `condicional`, `enquanto`, `repita`, `leitura`, `escrita`. Mensagens de erro, scripts `build.sh`/`testar.sh`, Codespaces e exemplos `02` a `05`. 

---

## 6. Cronograma

 Data/Marco/Situação 

 05/11 | Marco 1 — equipe e gramática formal 
 12/11 | Marco 2 — PoC no JavaCC e Matriz de Responsabilidade 
 19/11 | Marco 3 — 50% das regras funcionando 
 26/11 | Entrega final e apresentação 
