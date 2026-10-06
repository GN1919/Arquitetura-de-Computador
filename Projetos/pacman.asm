; ============================================
; ARQUITECTURA DE COMPUTADORES
; PAC-MAN SIMPLIFICADO PARA O PEPE-16
; GRUPO - 12
; AUTORES: HÉLVIO SANTANA, GOLDWYN NARCISO, HAMILTON ZUA, ANDRÉ GUNZA
; DOCENTE: JOÃO JOSÉ DA COSTA 
; ============================================

; --------------------------------------------------
; CONSTANTES
; --------------------------------------------------
BUFFER	EQU	4000H        ; endereço de memória onde se guarda a tecla
PIN     EQU 0E000H       ; Endereço do porto de entrada do teclado
POUT    EQU 0C000H       ; Endereço do porto de saida do teclado
pixelsMatriz EQU 8000H   ; inicio do endereço do ecrã

; Constantes dos Display
displays 	EQU	0A000H	  ; endereço do porto dos displays hexadecimais
nibble_3_0	EQU	000FH     ; máscara para isolar os 4 bits de menor peso
nibble_7_4	EQU	00F0H	  ; máscara para isolar os bits 7 a 4

; CONSTANTES PARA COR VERMELHA
; --------------------------------------------------
pixelsVermelho EQU 9000H   ; Camada vermelha (endereço separado) - Indica qual bit da matriz será acendido

; --------------------------------------------------
; VARIÁVEIS DO CONTADOR DE SEGUNDOS
; --------------------------------------------------
PLACE 3250H                 ; endereço onde começa os contadores
segundo_atual:    WORD 0    ; contador de ciclos para 1 segundo
contador_decimal: WORD 0    ; valor decimal (0-99) a mostrar nos displays

; --------------------------------------------------
; PILHA
; --------------------------------------------------
stackSize  EQU 100H    ; endereço da pilha
PLACE 2000H            ; endereço da base da pilha
pilha: TABLE stackSize ; criação da pilha
stackBase:             ; rotulo para a base da pilha

; --------------------------------------------------
; TABELA DE BITS PARA PIXELS
; --------------------------------------------------
PLACE 2200H ; endereço para a tabela dos bits
ptable: STRING 80H, 40H, 20H, 10H, 08H, 04H, 02H, 01H ; mapeamento da tabela dos bits

; --------------------------------------------------
; VARIÁVEIS DO PAC-MAN
; --------------------------------------------------
PLACE 3200H ; endereço do pac-man

; Posições do Pac-Man
linha_pac:      WORD 15  ; linha do pac-man
coluna_pac:     WORD 7   ; coluna do pac-man

; Posições do Fantasma 1
fantasma_linha:  WORD 14      ; Nasce na caixa central
fantasma_coluna: WORD 14
fantasma_dir:    WORD 3       ; Responsável por fazer a busca do pac-man

; Posições do Fantasma 2 (NOVO)
fantasma2_linha:  WORD 14     ; Também nasce na caixa central
fantasma2_coluna: WORD 14
fantasma2_ativa:  WORD 0      ; 0 = inativo, 1 = ativo (após 4 segundos a caixa gera o novo fantasma)
fantasma2_timer:  WORD 0      ; Timer para movimento lento

; Caixa central
caixa_linha:    WORD 14       ; Linha da caixa central
caixa_coluna:   WORD 14       ; Coluna da caixa central

; Outras variáveis
tecla_atual:    WORD 0FFH     ; Armazena o valor actual da tecla
pontuacao:      WORD 0
vidas:          WORD 3
game_active:    WORD 1        ; 1 = jogo ativo, 0 = game over - Estado de activação do jogo

; Variaveis para Fantasma Lento
fantasma_timer: WORD 0        ; Timer usado para o movimento do fantasma já gerado
fantasma_velocidade: WORD 2   ; Velociade do movimento do fantasma


; --------------------------------------------------
; VARIÁVEIS DOS OBJETOS DOS CANTOS
; --------------------------------------------------
objetos_coletados:  WORD 0      ; contador de objetos coletados (0-4)

; Estados dos objetos (0 = não coletado, 1 = coletado)
objeto_0:          WORD 0      ; canto (2,2)   ; coordenadas dos objecto 0 nos cantos
objeto_1:          WORD 0      ; canto (2,27)  ; coordenadas dos objecto 1 nos cantos
objeto_2:          WORD 0      ; canto (27,2)  ; coordenadas dos objecto 2 nos cantos
objeto_3:          WORD 0      ; canto (27,27) ; coordenadas dos objecto 3 nos cantos 

; --------------------------------------------------
; SPRITES 3x3 CONFORME ENUNCIADO
; --------------------------------------------------
PLACE 3500H

; Sprite Pac-Man (3x3 - "C" virada para direita)
sprite_pacman:
    STRING 1, 1, 0    ; ● ● ○
    STRING 1, 0, 0    ; ● ○ ○  
    STRING 1, 1, 0    ; ● ● ○

; Sprite Fantasma (3x3 - "X")
sprite_fantasma:
    STRING 1, 0, 1    ; ● ○ ●
    STRING 0, 1, 0    ; ○ ● ○
    STRING 1, 0, 1    ; ● ○ ●

; Sprite Canto (3x3 - "+")
sprite_canto:
    STRING 0, 1, 0    ; ○ ● ○
    STRING 1, 1, 1    ; ● ● ●
    STRING 0, 1, 0    ; ○ ● ○

; Sprite Caixa Centro (3x3 - quadrado)
sprite_caixa:
    STRING 1, 1, 1    ; ● ● ●
    STRING 1, 0, 1    ; ● ○ ●
    STRING 1, 1, 1    ; ● ● ●

    ; Estas sprites são tabela de bits onde estão os pixeis que definem como os objectos são desenhados

; --------------------------------------------------
; PROGRAMA PRINCIPAL (COM CONTADOR DE SEGUNDOS)
; --------------------------------------------------
PLACE 0

inicio:
    MOV SP, stackBase     ; Inicialização do registro da pilha
    CALL Carregamento     ; preprocessamento

; Ciclo principal do jogo
main_loop:
    CALL pTeclado         ; Chama o processo do teclado
    
    ; Verificar se jogo está ativo
    MOV R1, game_active ; O registrador recebe o endereço flag do jogo
    MOV R1, [R1]        ; O registrador le o conteudo da memória
    CMP R1, 0           ; Compara para saber se o jogo está ativo ou não
    JNZ jogo_ativo      ; Se não for zero vai para a rotina que mantêm o jogo activo
    JMP main_loop       ; 

jogo_ativo:
    MOV R1, BUFFER        ; Manda o endereço do teclado para o registrador
    MOVB R2, [R1]         ; Valor da tecla pressionada
    
    ; Processar teclas de direção
    MOV R3, R2
    CMP R2, 1H            ; Tecla 1 (CIMA)
    JZ mover_cima         ; Caso seja a tecla 1 move pra cima

    MOV R4, 9H
    CMP R2, R4            ; Tecla 9 (BAIXO)
    JZ mover_baixo        ; Se for a 9 move pra baixo

    CMP R2, 4H            ; Tecla 4 (ESQUERDA)
    JZ mover_esquerda     ; Se for a 4 pra esquerda  

    CMP R2, 6H            ; Tecla 6 (DIREITA)
    JZ mover_direita      ; Se for 6 move pra direita

    MOV R4, 0FH
    CMP R2, R4           ; Tecla F (sair)
    JZ terminar_programa ; Se for F termina o jogo
    
    JMP continuar_jogo    ; Caso nenhuma tecla seja premida

mover_cima:
    CALL mover_pac_cima ; Chama a rotina pra mover o pac-man pra cima
    JMP continuar_jogo  ; Depois continua o jogo

mover_baixo:
    CALL mover_pac_baixo ; Chama a rotina pra mover o pac-man pra baixo
    JMP continuar_jogo   ; Depois continua o jogo

mover_esquerda:
    CALL mover_pac_esquerda ; Chama a rotina pra mover o pac-man pra esquerda
    JMP continuar_jogo      ; Depois continua o jogo

mover_direita:
    CALL mover_pac_direita ; Chama a rotina pra mover o pac-man a direita
    JMP continuar_jogo     ; Depois continua o jogo

continuar_jogo:

    ; Verificar se jogo ainda está ativo
    MOV R1, game_active ; Recebe o endereço da flag do jogo
    MOV R1, [R1]        ; Le a flag do jogo
    CMP R1, 0           ; Verifica se o jogo continua activo ou não
    JZ main_loop

    CALL mover_fantasma_lento     ; MOVIMENTO DO PRIMEIRO FANTASMA
    CALL mover_fantasma2_lento    ; MOVIMENTO DO SEGUNDO FANTASMA
    CALL verificar_colisao        ; VERIFICA A COLISÃO COM O PRIMEIRO FANTASMA
    CALL verificar_colisao2       ; VERIFICA A COLISÃO COM O SEGUNDO FANTASMA
    CALL verificar_colisao_objetos
    
    ; Verificar se todos objetos foram coletados
    CALL verificar_vitoria_global ; Se forem colectados chama a rotina que indica a vitoria
    
    ; Se vitoria foi detectada, pular o resto
    MOV R1, game_active
    MOV R1, [R1]
    CMP R1, 0
    JZ main_loop
    
    ; Atualizar contador de segundos
    CALL atualizar_contador_segundos ; Rotina para actualizar o contador de segundos
    
    ; ATIVAR SEGUNDO FANTASMA APÓS 4 SEGUNDOS
    CALL ativar_segundo_fantasma ; Chama a rotina que activa o segundo fantasma
    
    CALL delay                   ; Muda a velocidade do pac-man
    
    JMP main_loop
    
terminar_programa:
    ;desativar o jogo
    MOV R1, game_active ; Recebe o endereço do estado do jogo
    MOV R2, 0           ; O registrador 2 recebe o valor 0
    MOV [R1], R2        ; Muda o jogo para desactivado

    ; Limpar tela
    CALL mostrar_game_over
    ; Loop infinito para parar execução

fim_programa:
    JMP fim_programa 

; --------------------------------------------------
; ATIVAR SEGUNDO FANTASMA APÓS 4 SEGUNDOS
; --------------------------------------------------
ativar_segundo_fantasma:
    ; Manda o valor original dos registradores na pilha 
    PUSH R1
    PUSH R2
    PUSH R3
    
    ; Verificar se já está ativo
    MOV R1, fantasma2_ativa
    MOV R2, [R1] ; Le o estado do fantasma2 na memória
    CMP R2, 1    ; Compara, se for 1 está activo
    JZ fim_ativar_fantasma2
    
    ; Verificar se passaram 1 segundos
    MOV R1, contador_decimal
    MOV R2, [R1]
    MOV R3, 1
    CMP R2, R3 ; Compara com o valor de R2 para saber se já se passou 1s
    JLT fim_ativar_fantasma2
    
    ; Ativar segundo fantasma
    MOV R1, fantasma2_ativa
    MOV R2, 1
    MOV [R1], R2 ; Manda para o endereço o valor do R2 para activar o fantasma
    
    ; Desenhar o segundo fantasma
    CALL desenhar_fantasma2 ; Chama a rotina para desenhar o fantasma2
    
fim_ativar_fantasma2:
    POP R3
    POP R2
    POP R1
    ; Remove o valor dos registradores da pilha
    RET

; --------------------------------------------------
; DESENHAR SEGUNDO FANTASMA
; --------------------------------------------------
desenhar_fantasma2:
    PUSH R1
    PUSH R2
    PUSH R3
                         ; Manda o valor dos registradores na pilha

    MOV R1, fantasma2_linha
    MOV R1, [R1]
    MOV R2, fantasma2_coluna
    MOV R2, [R2]
    MOV R3, sprite_fantasma
                         ; Manda os valores da linhas, colunas e a sprite do fantasma2 para os registradores

    CALL desenhar_sprite_3x3 ; Chama a rotina que desenha a sprite de pixeis
    
    POP R3
    POP R2
    POP R1
                        ; Remove o valor dos registradores da pilha
    RET

; --------------------------------------------------
; MOVER SEGUNDO FANTASMA LENTO
; --------------------------------------------------
mover_fantasma2_lento:
    PUSH R1
    PUSH R2
    PUSH R3
    
    ; Verificar se está ativo
    MOV R1, fantasma2_ativa
    MOV R2, [R1]
    CMP R2, 0
    JZ fim_mover_fantasma2_lento

    ; Incrementar timer do fantasma 2
    MOV R1, fantasma2_timer
    MOV R2, [R1]
    ADD R2, 1     ; Adiciona 1s ao timer até o fantasma ser chamado
    MOV [R1], R2

    
    ; Verificar se pode mover (a cada 3 ciclos)
    MOV R3, 3
    CMP R2, R3  
    JLT fim_mover_fantasma2_lento

    ; Reset timer
    MOV R1, fantasma2_timer
    MOV R2, 0
    MOV [R1], R2 ; Reseta o valor do timer

    CALL mover_fantasma2

fim_mover_fantasma2_lento:
    POP R3
    POP R2
    POP R1
    RET

; --------------------------------------------------
; MOVER SEGUNDO FANTASMA (PERSEGUIR PAC-MAN)
; --------------------------------------------------
mover_fantasma2:
    PUSH R1
    PUSH R2
    PUSH R3
    PUSH R4
    PUSH R5
    PUSH R6
    
    ; Apagar fantasma na posição atual
    MOV R1, fantasma2_linha
    MOV R1, [R1]
    MOV R2, fantasma2_coluna
    MOV R2, [R2]
    CALL apagar_sprite_3x3 ; Apaga o fantasma da posição actual
    
    ; Obter posição do Pac-Man
    MOV R3, linha_pac
    MOV R3, [R3]        ; R3 = linha do Pac-Man
    MOV R4, coluna_pac
    MOV R4, [R4]        ; R4 = coluna do Pac-Man
    
    ; Obter posição atual do fantasma 2
    MOV R1, fantasma2_linha
    MOV R5, [R1]        ; R5 = linha do fantasma 2
    MOV R2, fantasma2_coluna
    MOV R6, [R2]        ; R6 = coluna do fantasma 2
    
    ; Calcular diferenças
    MOV R1, R3
    SUB R1, R5          ; Diferença de linha (Pac-Man - Fantasma2)
    
    MOV R2, R4
    SUB R2, R6          ; Diferença de coluna (Pac-Man - Fantasma2)
    
    ; Decidir movimento: mover na direção com maior diferença
    ; Primeiro verificar diferença absoluta de linha vs coluna
    
    ; Calcular valor absoluto das diferenças
    MOV R7, R1
    JN linha_negativa2 
    JMP linha_positiva2

linha_negativa2:
    NEG R7              ; Tornar positivo para comparação
linha_positiva2:
    
    MOV R8, R2
    JN coluna_negativa2
    JMP coluna_positiva2

coluna_negativa2:
    NEG R8            ; Torna o valor positivo para comparação
coluna_positiva2:
    
    ; Comparar |diferença linha| com |diferença coluna|
    CMP R7, R8
    JGT mover_vertical2  ; Se |linha| > |coluna|, mover verticalmente
    
    ; Mover horizontalmente
    CMP R2, 0
    JGT mover_direita_f2  ; Se coluna Pac-Man > coluna fantasma
    JLT mover_esquerda_f2 ; Se coluna Pac-Man < coluna fantasma
    
    ; Se diferença coluna = 0, mover verticalmente
    JMP mover_vertical2

mover_vertical2:
    CMP R1, 0
    JGT mover_baixo_f2    ; Se linha Pac-Man > linha fantasma
    JLT mover_cima_f2     ; Se linha Pac-Man < linha fantasma
    
    ; Se ambas diferenças = 0
    JMP fim_mover_fantasma2_2

; Sub-rotinas de movimento do fantasma 2
mover_cima_f2:
    ; Verificar se pode mover para cima (linha > 0)
    MOV R1, fantasma2_linha
    MOV R5, [R1]
    CMP R5, 0
    JZ nao_pode_cima2
    
    ; Mover para cima
    SUB R5, 1
    MOV [R1], R5
    JMP fim_mover_fantasma2_2

nao_pode_cima2:
    ; Tentar movimento alternativo
    CMP R2, 0
    JGT mover_direita_f2
    JMP mover_esquerda_f2

mover_baixo_f2:
    ; Verificar se pode mover para baixo (linha < 28)
    MOV R1, fantasma2_linha
    MOV R5, [R1]
    MOV R9, 28
    CMP R5, R9
    JZ nao_pode_baixo2
    
    ; Mover para baixo
    ADD R5, 1
    MOV [R1], R5
    JMP fim_mover_fantasma2_2

nao_pode_baixo2:
    ; Tentar movimento alternativo
    CMP R2, 0
    JGT mover_direita_f2
    JMP mover_esquerda_f2

mover_esquerda_f2:
    ; Verificar se pode mover para esquerda (coluna > 0)
    MOV R1, fantasma2_coluna
    MOV R6, [R1]
    CMP R6, 0
    JZ nao_pode_esquerda2
    
    ; Mover para esquerda
    SUB R6, 1
    MOV [R1], R6
    JMP fim_mover_fantasma2_2

nao_pode_esquerda2:
    ; Tentar movimento vertical alternativo
    CMP R1, 0
    JGT mover_baixo_f2
    JMP mover_cima_f2

mover_direita_f2:
    ; Verificar se pode mover para direita (coluna < 28)
    MOV R1, fantasma2_coluna
    MOV R6, [R1]
    MOV R9, 28
    CMP R6, R9
    JZ nao_pode_direita2
    
    ; Mover para direita
    ADD R6, 1
    MOV [R1], R6
    JMP fim_mover_fantasma2_2

nao_pode_direita2:
    ; Tentar movimento vertical alternativo
    CMP R1, 0
    JGT mover_baixo_f2
    JMP mover_cima_f2

fim_mover_fantasma2_2:
    ; Desenhar fantasma 2 na nova posição
    CALL desenhar_fantasma2
    
    POP R6
    POP R5
    POP R4
    POP R3
    POP R2
    POP R1
    RET

; --------------------------------------------------
; VERIFICAR COLISÃO COM SEGUNDO FANTASMA
; --------------------------------------------------
verificar_colisao2:
    PUSH R1
    PUSH R2
    PUSH R3
    PUSH R4
    PUSH R5
    
    ; Verificar se segundo fantasma está ativo
    MOV R1, fantasma2_ativa
    MOV R1, [R1]
    CMP R1, 0
    JZ sem_colisao2
    
    ; Obter posições
    MOV R1, linha_pac
    MOV R1, [R1]
    MOV R2, coluna_pac
    MOV R2, [R2]
    MOV R3, fantasma2_linha
    MOV R3, [R3]
    MOV R4, fantasma2_coluna
    MOV R4, [R4]
    
    ; Verificar se posições são iguais
    MOV R5, R1
    SUB R5, R3          ; Comparar linhas
    JNZ sem_colisao2    ; Se diferente, sem colisão
    
    MOV R5, R2
    SUB R5, R4          ; Comparar colunas
    JNZ sem_colisao2    ; Se diferente, sem colisão
    
    ; COLISÃO DETECTADA
    CALL perder_vida    ; Chama a rotina que decrementa a vida
    
sem_colisao2:
    POP R5
    POP R4
    POP R3
    POP R2
    POP R1
    RET

; --------------------------------------------------
; FUNÇÃO PIXEL_XY (SIMPLIFICADA)
; --------------------------------------------------
pixel_xy: 
    PUSH R1
    PUSH R2
    PUSH R3
    PUSH R4
    PUSH R5
    PUSH R6
    PUSH R7
    
    ; R1 = linha, R2 = coluna
    
    ; Calcular endereço: endereço = 8000H + 4*linha + coluna/8
    MOV R4, R1          ; Copiar linha
    SHL R4, 2           ; R4 = 4 * linha
    
    MOV R5, R2          ; Copiar coluna
    SHR R5, 3           ; R5 = coluna / 8
    
    ADD R4, R5          ; R4 = 4*linha + coluna/8
    MOV R5, pixelsMatriz
    ADD R4, R5          ; R4 = endereço do byte
    
    ; Calcular bit dentro do byte (0-7) sem AND
    ; R5 = coluna mod 8
    MOV R5, R2          ; Copiar coluna
    
calc_mod:
    MOV R6, 8           ; Divisor
mod_loop:
    SUB R5, R6          ; Subtrair 8 ao resultado da divisão
    JN mod_done         ; Se negativo, terminou
    JZ mod_done         ; Se zero, terminou
    JMP mod_loop        ; Continue
mod_done:
    ADD R5, R6          ; Adicionar 8 de volta (última subtração foi demais)
    
    ; Obter máscara da tabela ptable
    MOV R6, ptable
    ADD R6, R5          ; R6 = endereço da máscara
    MOVB R7, [R6]       ; R7 = máscara do bit
    
    ; Ativar o pixel
    MOVB R5, [R4]       ; Ler byte atual
    OR R5, R7           ; Ativar o bit
    MOVB [R4], R5       ; Escrever byte atualizado
    
    POP R7
    POP R6
    POP R5
    POP R4
    POP R3
    POP R2
    POP R1
    RET

; --------------------------------------------------
; ATUALIZAR CONTADOR DE SEGUNDOS
; --------------------------------------------------
atualizar_contador_segundos:
    PUSH R1
    PUSH R2
    PUSH R3
    PUSH R4
    
    ; Incrementar contador de ciclos
    MOV R1, segundo_atual
    MOV R2, [R1]
    ADD R2, 1
    MOV [R1], R2
    
    ; Verificar se passou 1 segundo
    MOV R3, 60           ; Ajustar conforme velocidade do jogo
    CMP R2, R3
    JLT fim_atualizar_contador
    
    ; Resetar contador de ciclos
    MOV R2, 0
    MOV [R1], R2
    
    ; Incrementar contador decimal (0-99)
    MOV R1, contador_decimal
    MOV R2, [R1]
    ADD R2, 1
    
    ; Verificar se chegou a 100
    MOV R3, 100
    CMP R2, R3
    JLT atualizar_display
    
    ; Resetar para 0 se chegou a 100
    MOV R2, 0
    
atualizar_display:
    MOV [R1], R2
    
    ; Converter para BCD e mostrar nos displays
    CALL mostrar_contador_display
    
fim_atualizar_contador:
    POP R4
    POP R3
    POP R2
    POP R1
    RET

; --------------------------------------------------
; MOSTRAR CONTADOR NOS DISPLAYS (DECIMAL)
; --------------------------------------------------
mostrar_contador_display:
    PUSH R1
    PUSH R2
    PUSH R3
    PUSH R4
    PUSH R5
    
    ; Obter valor do contador (0-99)
    MOV R1, contador_decimal
    MOV R2, [R1]
    
    ; Separar dígitos (dezenas e unidades)
    MOV R3, R2            ; Copiar valor
    
    ; Calcular dezenas: valor / 10
    MOV R4, 0             ; Contador de dezenas, começa em 0
calcular_dezenas:
    MOV R5, 10  ; Recebe 10
    CMP R3, R5  ; Compara para saber se é maior que 10
    JLT unidades_pronto ; Se for menor calcula as unidades diretamente
    MOV R5, 10  
    SUB R3, R5          ; Subtrai-se 10 ao R3 pois ele vai armazenar as unidades
    ADD R4, 1           ; Adiciona-se 1 ao R4 caso se trate de uma dezena
    JMP calcular_dezenas ; Se ainda for maior ou igual a 10 vai se calculando a dezena
    
unidades_pronto:
    ; R4 = dezenas, R3 = unidades
    
    ; Formatar para display: dezenas nos bits 4-7, unidades nos bits 0-3
    SHL R4, 4            ; Mover dezenas para bits 4-7
    OR R4, R3            ; Combinar com unidades nos bits 0-3
    
    ; Escrever nos displays
    MOV R5, displays     ; Pega o endereço do display
    MOVB [R5], R4        ; Escreve na memoria o valor
    
    POP R5
    POP R4
    POP R3
    POP R2
    POP R1
    RET

; --------------------------------------------------
; DESENHAR PIXEL VERMELHO
; --------------------------------------------------
desenhar_pixel_vermelho:
    PUSH R1
    PUSH R2
    PUSH R3
    PUSH R4
    PUSH R5
    PUSH R6
    PUSH R7
    
    ; MESMO CÁLCULO QUE pixel_xy, mas para camada vermelha
    MOV R4, R1          ; Copiar linha
    SHL R4, 2           ; R4 = 4 * linha
    
    MOV R5, R2          ; Copiar coluna
    SHR R5, 3           ; R5 = coluna / 8
    
    ADD R4, R5          ; R4 = 4*linha + coluna/8
    MOV R5, pixelsVermelho
    ADD R4, R5          ; R4 = endereço do byte na camada vermelha
    
    ; Calcular bit
    MOV R5, R2          ; Copiar coluna
    
calc_mod_vermelho:
    MOV R6, 8           ; Divisor
mod_loop_vermelho:
    SUB R5, R6          ; Subtrair 8
    JN mod_done_vermelho
    JZ mod_done_vermelho
    JMP mod_loop_vermelho
mod_done_vermelho:
    ADD R5, R6
    
    ; Obter máscara da tabela ptable
    MOV R6, ptable
    ADD R6, R5
    MOVB R7, [R6]       ; Pegou o endereço da mascara
    
    ; Ativar o pixel na camada vermelha
    MOVB R5, [R4]
    OR R5, R7
    MOVB [R4], R5       ; O byte com o bit activo
    
    POP R7
    POP R6
    POP R5
    POP R4
    POP R3
    POP R2
    POP R1
    RET

; --------------------------------------------------
; LIMPAR CAMADA VERMELHA
; --------------------------------------------------
limpar_camada_vermelha:
    PUSH R1
    PUSH R2
    PUSH R3
    PUSH R4

    MOV R1, pixelsVermelho
    MOV R2, R1
    MOV R4, 80H
    ADD R2, R4
    MOV R3, 0
    
limpar_vermelho_loop:
    MOVB [R1], R3
    ADD R1, 1
    CMP R1, R2
    JLT limpar_vermelho_loop

    POP R4
    POP R3
    POP R2
    POP R1
    RET

; --------------------------------------------------
; DESENHAR BORDAS VERMELHAS SIMPLES
; --------------------------------------------------
desenhar_bordas_vermelhas:
    PUSH R1
    PUSH R2
    PUSH R3 ; Será usado como contador de pixeis pintados
    
    ; BORDA SUPERIOR
    MOV R1, 0
    MOV R2, 0
    MOV R3, 32
    
borda_superior:
    CALL desenhar_pixel_vermelho
    ADD R2, 1
    SUB R3, 1
    JNZ borda_superior
    
    ; BORDA INFERIOR
    MOV R1, 31
    MOV R2, 0
    MOV R3, 32
    
borda_inferior:
    CALL desenhar_pixel_vermelho
    ADD R2, 1
    SUB R3, 1
    JNZ borda_inferior
    
    ; BORDA ESQUERDA
    MOV R2, 0
    MOV R1, 1
    MOV R3, 30
    
borda_esquerda:
    CALL desenhar_pixel_vermelho
    ADD R1, 1
    SUB R3, 1
    JNZ borda_esquerda
    
    ; BORDA DIREITA
    MOV R2, 31
    MOV R1, 1
    MOV R3, 30
    
borda_direita:
    CALL desenhar_pixel_vermelho
    ADD R1, 1
    SUB R3, 1
    JNZ borda_direita
    
    POP R3
    POP R2
    POP R1
    RET

; --------------------------------------------------
; FUNÇÃO APAGAR PIXEL ESPECÍFICO
; --------------------------------------------------
apagar_pixel_xy:
    PUSH R1
    PUSH R2
    PUSH R3
    PUSH R4
    PUSH R5
    PUSH R6
    PUSH R7
    
    ; Mesmo cálculo que pixel_xy
    MOV R4, R1
    SHL R4, 2
    
    MOV R5, R2
    SHR R5, 3
    
    ADD R4, R5
    MOV R5, pixelsMatriz
    ADD R4, R5
    
    ; Calcular bit
    MOV R5, R2
    
calc_mod2:
    MOV R6, 8
mod_loop2:
    SUB R5, R6
    JN mod_done2
    JZ mod_done2
    JMP mod_loop2
mod_done2:
    ADD R5, R6
    
    ; Obter máscara
    MOV R6, ptable
    ADD R6, R5     ; soma o modulo ao deslocamento(em pixel vermelho e pixel é a mesma coisa)
    MOVB R7, [R6]
    NOT R7         ; nega para apagar o bit
    
    ; Apagar o pixel
    MOVB R5, [R4]  ; pega o valor do byte
    AND R5, R7     ; compara bit a bit 
    MOVB [R4], R5  ; adiciona o novo valor do byte ao registrador
    
    POP R7
    POP R6
    POP R5
    POP R4
    POP R3
    POP R2
    POP R1
    RET

; --------------------------------------------------
; DESENHAR SPRITE 3x3 (SIMPLIFICADA)
; --------------------------------------------------
desenhar_sprite_3x3:
    PUSH R1
    PUSH R2
    PUSH R3 ; Será usado como o endereço de definição da sprite
    PUSH R4
    PUSH R5
    PUSH R6
    
    MOV R5, R1
    MOV R6, R2
    
    ; Ler todos os pixels
    MOVB R4, [R3] ; Le o primeiro byte da sprite
    MOV R1, R4    ; Recebe o endereço e copia o valor
    SUB R1, 0     ; Subtrai por zero
    JZ sprite_01  ; Se for 0, pula e não desenha
    MOV R1, R5    ; Restaura a linha original
    MOV R2, R6    ; Restaura a coluna original
    CALL pixel_xy
    
sprite_01:
    ADD R3, 1
    MOVB R4, [R3]
    MOV R1, R4
    SUB R1, 0
    JZ sprite_02
    MOV R1, R5
    MOV R2, R6
    ADD R2, 1
    CALL pixel_xy
    
sprite_02:
    ADD R3, 1
    MOVB R4, [R3]
    MOV R1, R4
    SUB R1, 0
    JZ sprite_10
    MOV R1, R5
    MOV R2, R6
    ADD R2, 2
    CALL pixel_xy
    
sprite_10:
    ADD R3, 1
    MOVB R4, [R3]
    MOV R1, R4
    SUB R1, 0
    JZ sprite_11
    MOV R1, R5
    ADD R1, 1
    MOV R2, R6
    CALL pixel_xy
    
sprite_11:
    ADD R3, 1
    MOVB R4, [R3]
    MOV R1, R4
    SUB R1, 0
    JZ sprite_12
    MOV R1, R5
    ADD R1, 1
    MOV R2, R6
    ADD R2, 1
    CALL pixel_xy
    
sprite_12:
    ADD R3, 1
    MOVB R4, [R3]
    MOV R1, R4
    SUB R1, 0
    JZ sprite_20
    MOV R1, R5
    ADD R1, 1
    MOV R2, R6
    ADD R2, 2
    CALL pixel_xy
    
sprite_20:
    ADD R3, 1
    MOVB R4, [R3]
    MOV R1, R4
    SUB R1, 0
    JZ sprite_21
    MOV R1, R5
    ADD R1, 2
    MOV R2, R6
    CALL pixel_xy
    
sprite_21:
    ADD R3, 1
    MOVB R4, [R3]
    MOV R1, R4
    SUB R1, 0
    JZ sprite_22
    MOV R1, R5
    ADD R1, 2
    MOV R2, R6
    ADD R2, 1
    CALL pixel_xy
    
sprite_22:
    ADD R3, 1
    MOVB R4, [R3]
    MOV R1, R4
    SUB R1, 0
    JZ fim_desenhar_sprite
    MOV R1, R5
    ADD R1, 2
    MOV R2, R6
    ADD R2, 2
    CALL pixel_xy
    
fim_desenhar_sprite:
    POP R6
    POP R5
    POP R4
    POP R3
    POP R2
    POP R1
    RET

; --------------------------------------------------
; DESENHAR PAC-MAN
; --------------------------------------------------
desenhar_pacman:
    PUSH R1
    PUSH R2
    PUSH R3
    
    MOV R1, linha_pac
    MOV R1, [R1]
    MOV R2, coluna_pac
    MOV R2, [R2]
    MOV R3, sprite_pacman
    
    CALL desenhar_sprite_3x3
    
    POP R3
    POP R2
    POP R1
    RET

; --------------------------------------------------
; DESENHAR FANTASMA
; --------------------------------------------------
desenhar_fantasma:
    PUSH R1
    PUSH R2
    PUSH R3
    
    MOV R1, fantasma_linha
    MOV R1, [R1]
    MOV R2, fantasma_coluna
    MOV R2, [R2]
    MOV R3, sprite_fantasma
    
    CALL desenhar_sprite_3x3
    
    POP R3
    POP R2
    POP R1
    RET

; --------------------------------------------------
; DESENHAR CANTOS
; --------------------------------------------------
desenhar_cantos:
    PUSH R1
    PUSH R2
    PUSH R3
    PUSH R4
    
    ; Canto 0 (2,2)
    MOV R1, objeto_0      ; variável de estado do objecto
    MOV R1, [R1]          ; pega o valor na memória
    CMP R1, 0             ; Se for 0 não coletado
    JNZ ver_objeto1_novo  ; Se for diferente de 0 pula
    
    MOV R1, 2
    MOV R2, 2
    MOV R3, sprite_canto
    CALL desenhar_sprite_3x3
    
ver_objeto1_novo:
    ; Canto 1 (2,27)
    MOV R1, objeto_1
    MOV R1, [R1]
    CMP R1, 0
    JNZ ver_objeto2_novo
    
    MOV R1, 2
    MOV R2, 27
    MOV R3, sprite_canto
    CALL desenhar_sprite_3x3
    
ver_objeto2_novo:
    ; Canto 2 (27,2)
    MOV R1, objeto_2
    MOV R1, [R1]
    CMP R1, 0
    JNZ ver_objeto3_novo
    
    MOV R1, 27
    MOV R2, 2
    MOV R3, sprite_canto
    CALL desenhar_sprite_3x3
    
ver_objeto3_novo:
    ; Canto 3 (27,27)
    MOV R1, objeto_3
    MOV R1, [R1]
    CMP R1, 0
    JNZ fim_desenhar_cantos_novo
    
    MOV R1, 27
    MOV R2, 27
    MOV R3, sprite_canto
    CALL desenhar_sprite_3x3
    
fim_desenhar_cantos_novo:
    POP R4
    POP R3
    POP R2
    POP R1
    RET

; --------------------------------------------------
; APAGAR SPRITE 3x3 (SIMPLIFICADA)
; --------------------------------------------------
apagar_sprite_3x3:
    PUSH R1
    PUSH R2
    PUSH R3
    
    MOV R3, R1 ; Recebe a linha original pois o R1 pode ser modificado pelas rotinas
    
    ; Apagar 3x3 área

    CALL apagar_pixel_xy
    
    ADD R2, 1
    CALL apagar_pixel_xy
    
    ADD R2, 1
    CALL apagar_pixel_xy
    
    SUB R2, 2
    MOV R1, R3
    ADD R1, 1
    CALL apagar_pixel_xy
    
    ADD R2, 1
    CALL apagar_pixel_xy
    
    ADD R2, 1
    CALL apagar_pixel_xy
    
    SUB R2, 2
    MOV R1, R3
    ADD R1, 2
    CALL apagar_pixel_xy
    
    ADD R2, 1
    CALL apagar_pixel_xy
    
    ADD R2, 1
    CALL apagar_pixel_xy
    
    POP R3
    POP R2
    POP R1
    RET

;------------------------------------------------
;MOVER FANTASMA LENTO
;------------------------------------------------
mover_fantasma_lento:
    PUSH R1
    PUSH R2
    PUSH R3

    ; Incrementar timer do fantasma
    MOV R1, fantasma_timer
    MOV R2, [R1]
    ADD R2, 1
    MOV [R1], R2
    
    ; Verificar se pode mover
    MOV R3, 2 ; Verifica se o fantasma pode mover a cada dois ciclos
    CMP R2, R3
    JLT fim_mover_fantasma_lento

    ; Reset timer
    MOV R1, fantasma_timer
    MOV R2, 0
    MOV [R1], R2

    CALL mover_fantasma

fim_mover_fantasma_lento:
    POP R3
    POP R2
    POP R1
    RET

; --------------------------------------------------
; MOVER PAC-MAN PARA CIMA
; --------------------------------------------------
mover_pac_cima:
    PUSH R1
    PUSH R2
    
    ; Apagar na posição atual
    MOV R1, linha_pac
    MOV R1, [R1]
    MOV R2, coluna_pac
    MOV R2, [R2]
    CALL apagar_sprite_3x3
    
    ; Atualizar posição
    MOV R1, linha_pac
    MOV R2, [R1]
    CMP R2, 0
    JZ fim_mover_cima
    
    SUB R2, 1
    MOV [R1], R2
    
    ; Desenhar na nova posição
    CALL desenhar_pacman
    
fim_mover_cima:
    POP R2
    POP R1
    RET

; --------------------------------------------------
; MOVER PAC-MAN PARA BAIXO
; --------------------------------------------------
mover_pac_baixo:
    PUSH R1
    PUSH R2
    
    ; Apagar na posição atual
    MOV R1, linha_pac
    MOV R1, [R1]
    MOV R2, coluna_pac
    MOV R2, [R2]
    CALL apagar_sprite_3x3
    
    ; Atualizar posição
    MOV R1, linha_pac
    MOV R2, [R1]
    MOV R3, 28
    CMP R2, R3
    JZ fim_mover_baixo
    
    ADD R2, 1
    MOV [R1], R2
    
    ; Desenhar na nova posição
    CALL desenhar_pacman
    
fim_mover_baixo:
    POP R2
    POP R1
    RET

; --------------------------------------------------
; MOVER PAC-MAN PARA ESQUERDA
; --------------------------------------------------
mover_pac_esquerda:
    PUSH R1
    PUSH R2
    
    ; Apagar na posição atual
    MOV R1, linha_pac
    MOV R1, [R1]
    MOV R2, coluna_pac
    MOV R2, [R2]
    CALL apagar_sprite_3x3
    
    ; Atualizar posição
    MOV R1, coluna_pac
    MOV R2, [R1]
    CMP R2, 0
    JZ fim_mover_esquerda
    
    SUB R2, 1
    MOV [R1], R2
    
    ; Desenhar na nova posição
    CALL desenhar_pacman
    
fim_mover_esquerda:
    POP R2
    POP R1
    RET

; --------------------------------------------------
; MOVER PAC-MAN PARA DIREITA
; --------------------------------------------------
mover_pac_direita:
    PUSH R1
    PUSH R2
    
    ; Apagar na posição atual
    MOV R1, linha_pac
    MOV R1, [R1]
    MOV R2, coluna_pac
    MOV R2, [R2]
    CALL apagar_sprite_3x3
    
    ; Atualizar posição
    MOV R1, coluna_pac
    MOV R2, [R1]
    MOV R3, 28
    CMP R2, R3
    JZ fim_mover_direita
    
    ADD R2, 1
    MOV [R1], R2
    
    ; Desenhar na nova posição
    CALL desenhar_pacman
    
fim_mover_direita:
    POP R2
    POP R1
    RET

; --------------------------------------------------
; MOVER FANTASMA (PERSEGUIR PAC-MAN)
; --------------------------------------------------
mover_fantasma:
    PUSH R1
    PUSH R2
    PUSH R3
    PUSH R4
    PUSH R5
    PUSH R6
    
    ; Apagar fantasma na posição atual
    MOV R1, fantasma_linha
    MOV R1, [R1]
    MOV R2, fantasma_coluna
    MOV R2, [R2]
    CALL apagar_sprite_3x3
    
    ; Obter posição do Pac-Man
    MOV R3, linha_pac
    MOV R3, [R3]
    MOV R4, coluna_pac
    MOV R4, [R4]
    
    ; Obter posição atual do fantasma
    MOV R1, fantasma_linha
    MOV R5, [R1]
    MOV R2, fantasma_coluna
    MOV R6, [R2]
    
    ; Calcular diferenças
    MOV R1, R3
    SUB R1, R5
    
    MOV R2, R4
    SUB R2, R6
    
    ; Decidir movimento
    CMP R1, 0
    JGT mover_baixo_f
    JLT mover_cima_f
    
    ; Se linha igual, verificar coluna
    CMP R2, 0
    JGT mover_direita_f
    JLT mover_esquerda_f
    
    JMP fim_mover_fantasma2

mover_cima_f:
    ; Verificar se pode mover para cima
    MOV R1, fantasma_linha
    MOV R5, [R1]
    CMP R5, 0
    JZ nao_pode_cima
    
    SUB R5, 1
    MOV [R1], R5
    JMP fim_mover_fantasma2

nao_pode_cima:
    ; Tentar movimento alternativo
    CMP R2, 0
    JGT mover_direita_f
    JMP mover_esquerda_f

mover_baixo_f:
    ; Verificar se pode mover para baixo
    MOV R1, fantasma_linha
    MOV R5, [R1]
    MOV R9, 28
    CMP R5, R9
    JZ nao_pode_baixo
    
    ADD R5, 1
    MOV [R1], R5
    JMP fim_mover_fantasma2

nao_pode_baixo:
    ; Tentar movimento alternativo
    CMP R2, 0
    JGT mover_direita_f
    JMP mover_esquerda_f

mover_esquerda_f:
    ; Verificar se pode mover para esquerda
    MOV R1, fantasma_coluna
    MOV R6, [R1]
    CMP R6, 0
    JZ nao_pode_esquerda
    
    SUB R6, 1
    MOV [R1], R6
    JMP fim_mover_fantasma2

nao_pode_esquerda:
    ; Tentar movimento alternativo
    CMP R1, 0
    JGT mover_baixo_f
    JMP mover_cima_f

mover_direita_f:
    ; Verificar se pode mover para direita
    MOV R1, fantasma_coluna
    MOV R6, [R1]
    MOV R9, 28
    CMP R6, R9
    JZ nao_pode_direita
    
    ADD R6, 1
    MOV [R1], R6
    JMP fim_mover_fantasma2

nao_pode_direita:
    ; Tentar movimento alternativo
    CMP R1, 0
    JGT mover_baixo_f
    JMP mover_cima_f

fim_mover_fantasma2:
    ; Desenhar fantasma na nova posição
    CALL desenhar_fantasma
    
    POP R6
    POP R5
    POP R4
    POP R3
    POP R2
    POP R1
    RET

; --------------------------------------------------
; VERIFICAR COLISÃO COM OBJETOS DOS CANTOS
; --------------------------------------------------
verificar_colisao_objetos:
    PUSH R1
    PUSH R2
    PUSH R3
    PUSH R4
    PUSH R5
    
    ; Posição do Pac-Man
    MOV R1, linha_pac
    MOV R1, [R1]
    MOV R2, coluna_pac
    MOV R2, [R2]
    
    ; Verificar cada canto
    CALL verificar_objeto_0
    CALL verificar_objeto_1
    CALL verificar_objeto_2
    CALL verificar_objeto_3
    
    POP R5
    POP R4
    POP R3
    POP R2
    POP R1
    RET

; --------------------------------------------------
; VERIFICAR SE TODOS OBJETOS FORAM COLETADOS
; --------------------------------------------------
verificar_vitoria_global:
    PUSH R1
    PUSH R2
    PUSH R3
    
    MOV R1, objetos_coletados
    MOV R2, [R1]
    MOV R3, 4
    CMP R2, R3
    JNZ fim_verificar_vitoria
    
    ; Se chegou aqui, todos objetos foram coletados
    CALL vitoria
    
fim_verificar_vitoria:
    POP R3
    POP R2
    POP R1
    RET

; --------------------------------------------------
; VERIFICAR OBJETO 0 (2,2)
; --------------------------------------------------
verificar_objeto_0:
    PUSH R1
    PUSH R2
    PUSH R3
    PUSH R4
    PUSH R5
    
    ; Verificar se já foi coletado
    MOV R3, objeto_0
    MOV R4, [R3]
    CMP R4, 0
    JNZ fim_verificar_0
    
    ; Pegar posição atual do Pac-Man
    MOV R1, linha_pac
    MOV R1, [R1]
    MOV R2, coluna_pac
    MOV R2, [R2]
    
    ; Verificar linha: 2 ou 3
    MOV R5, 2
    CMP R1, R5
    JZ linha_ok_0
    MOV R5, 3
    CMP R1, R5
    JZ linha_ok_0
    JMP fim_verificar_0
    
linha_ok_0:
    ; Verificar coluna: 2 ou 3
    MOV R5, 2
    CMP R2, R5
    JZ colisao_0
    MOV R5, 3
    CMP R2, R5
    JZ colisao_0
    JMP fim_verificar_0
    
colisao_0:
    ; COLISÃO DETECTADA!
    MOV R3, objeto_0
    MOV R4, 1
    MOV [R3], R4
    
    ; Incrementar contador
    MOV R3, objetos_coletados
    MOV R4, [R3]
    ADD R4, 1
    MOV [R3], R4
    
    ; Apagar objeto
    MOV R1, 2
    MOV R2, 2
    CALL apagar_sprite_3x3
    
fim_verificar_0:
    POP R5
    POP R4
    POP R3
    POP R2
    POP R1
    RET

; --------------------------------------------------
; VERIFICAR OBJETO 1 (2,27)
; --------------------------------------------------
verificar_objeto_1:
    PUSH R1
    PUSH R2
    PUSH R3
    PUSH R4
    PUSH R5
    
    ; Verificar se já foi coletado
    MOV R3, objeto_1
    MOV R4, [R3]
    CMP R4, 0
    JNZ fim_verificar_1
    
    ; Pegar posição atual do Pac-Man
    MOV R1, linha_pac
    MOV R1, [R1]
    MOV R2, coluna_pac
    MOV R2, [R2]
    
    ; Verificar linha: 2 ou 3
    MOV R5, 2
    CMP R1, R5
    JZ linha_ok_1
    MOV R5, 3
    CMP R1, R5
    JZ linha_ok_1
    JMP fim_verificar_1
    
linha_ok_1:
    ; Verificar coluna: 27 ou 28
    MOV R5, 27
    CMP R2, R5
    JZ colisao_1
    MOV R5, 28
    CMP R2, R5
    JZ colisao_1
    JMP fim_verificar_1
    
colisao_1:
    ; COLISÃO DETECTADA
    MOV R3, objeto_1
    MOV R4, 1
    MOV [R3], R4
    
    MOV R3, objetos_coletados
    MOV R4, [R3]
    ADD R4, 1
    MOV [R3], R4
    
    ; Apagar objeto
    MOV R1, 2
    MOV R2, 27
    CALL apagar_sprite_3x3
    
fim_verificar_1:
    POP R5
    POP R4
    POP R3
    POP R2
    POP R1
    RET

; --------------------------------------------------
; VERIFICAR OBJETO 2 (27,2)
; --------------------------------------------------
verificar_objeto_2:
    PUSH R1
    PUSH R2
    PUSH R3
    PUSH R4
    PUSH R5
    
    ; Verificar se já foi coletado
    MOV R3, objeto_2
    MOV R4, [R3]
    CMP R4, 0
    JNZ fim_verificar_2
    
    ; Pegar posição atual do Pac-Man
    MOV R1, linha_pac
    MOV R1, [R1]
    MOV R2, coluna_pac
    MOV R2, [R2]
    
    ; Verificar linha: 27 ou 28
    MOV R5, 27
    CMP R1, R5
    JZ linha_ok_2
    MOV R5, 28
    CMP R1, R5
    JZ linha_ok_2
    JMP fim_verificar_2
    
linha_ok_2:
    ; Verificar coluna: 2 ou 3
    MOV R5, 2
    CMP R2, R5
    JZ colisao_2
    MOV R5, 3
    CMP R2, R5
    JZ colisao_2
    JMP fim_verificar_2
    
colisao_2:
    ; COLISÃO DETECTADA
    MOV R3, objeto_2
    MOV R4, 1
    MOV [R3], R4
    
    MOV R3, objetos_coletados
    MOV R4, [R3]
    ADD R4, 1
    MOV [R3], R4
    
    ; Apagar objeto
    MOV R1, 27
    MOV R2, 2
    CALL apagar_sprite_3x3
    
fim_verificar_2:
    POP R5
    POP R4
    POP R3
    POP R2
    POP R1
    RET

; --------------------------------------------------
; VERIFICAR OBJETO 3 (27,27)
; --------------------------------------------------
verificar_objeto_3:
    PUSH R1
    PUSH R2
    PUSH R3
    PUSH R4
    PUSH R5
    
    ; Verificar se já foi coletado
    MOV R3, objeto_3
    MOV R4, [R3]
    CMP R4, 0
    JNZ fim_verificar_3
    
    ; Pegar posição atual do Pac-Man
    MOV R1, linha_pac
    MOV R1, [R1]
    MOV R2, coluna_pac
    MOV R2, [R2]
    
    ; Verificar linha: 27 ou 28
    MOV R5, 27
    CMP R1, R5
    JZ linha_ok_3
    MOV R5, 28
    CMP R1, R5
    JZ linha_ok_3
    JMP fim_verificar_3
    
linha_ok_3:
    ; Verificar coluna: 27 ou 28
    MOV R5, 27
    CMP R2, R5
    JZ colisao_3
    MOV R5, 28
    CMP R2, R5
    JZ colisao_3
    JMP fim_verificar_3
    
colisao_3:
    ; COLISÃO DETECTADA
    MOV R3, objeto_3
    MOV R4, 1
    MOV [R3], R4
    
    MOV R3, objetos_coletados
    MOV R4, [R3]
    ADD R4, 1
    MOV [R3], R4
    
    ; Apagar objeto
    MOV R1, 27
    MOV R2, 27
    CALL apagar_sprite_3x3
    
fim_verificar_3:
    POP R5
    POP R4
    POP R3
    POP R2
    POP R1
    RET

; --------------------------------------------------
; VERIFICAR COLISÃO COM FANTASMA 1
; --------------------------------------------------
verificar_colisao:
    PUSH R1
    PUSH R2
    PUSH R3
    PUSH R4
    
    ; Obter posições
    MOV R1, linha_pac
    MOV R1, [R1]
    MOV R2, coluna_pac
    MOV R2, [R2]
    MOV R3, fantasma_linha
    MOV R3, [R3]
    MOV R4, fantasma_coluna
    MOV R4, [R4]
    
    ; Verificar se posições são iguais
    MOV R5, R1
    SUB R5, R3
    JNZ sem_colisao
    
    MOV R5, R2
    SUB R5, R4
    JNZ sem_colisao
    
    ; COLISÃO DETECTADA
    CALL perder_vida
    
sem_colisao:
    POP R4
    POP R3
    POP R2
    POP R1
    RET

; --------------------------------------------------
; PERDER VIDA
; --------------------------------------------------
perder_vida:
    PUSH R1
    PUSH R2
    PUSH R3
    
    MOV R1, vidas
    MOV R2, [R1]
    CMP R2, 0
    JZ game_over_screen
    
    SUB R2, 1
    MOV [R1], R2
    
    ; Apagar Pac-Man
    MOV R1, linha_pac
    MOV R1, [R1]
    MOV R2, coluna_pac
    MOV R2, [R2]
    CALL apagar_sprite_3x3
    
    ; Reposicionar Pac-Man
    MOV R1, linha_pac
    MOV R2, 15
    MOV [R1], R2
    MOV R1, coluna_pac
    MOV [R1], R2
    
    ; Desenhar Pac-Man
    CALL desenhar_pacman
    
    POP R3
    POP R2
    POP R1
    RET

;===========================================
; GAME_OVER_SCREEN
;===========================================
game_over_screen:
    ; Desativar jogo
    MOV R1, game_active
    MOV R2, 0
    MOV [R1], R2
    
    CALL mostrar_game_over
    RET

; --------------------------------------------------
; VITÓRIA
; --------------------------------------------------
vitoria:
    PUSH R1
    PUSH R2
    
    ; Desativar jogo
    MOV R1, game_active
    MOV R2, 0
    MOV [R1], R2
    
    ; Mostrar mensagem de vitória
    CALL mostrar_vitoria
    
    POP R2
    POP R1
    RET

; --------------------------------------------------
; MOSTRAR VITÓRIA
; --------------------------------------------------
mostrar_vitoria:
    PUSH R1
    PUSH R2
    PUSH R3
    PUSH R4
    
    ; Limpar tela
    MOV R1, 8000h
    MOV R2, 8080h
    MOV R3, 0H
    
limpar_tela_vitoria:
    MOVB [R1], R3
    ADD R1, 1H
    MOV R4, R1
    SUB R4, R2
    JN limpar_tela_vitoria
    
    ; Mostrar "VIT" no centro
    ; Desenhar 'V' (15,13)
    MOV R1, 15
    MOV R2, 13
    CALL desenhar_V
    
    ; Desenhar 'I' (15,17)
    MOV R1, 15
    MOV R2, 17
    CALL desenhar_I
    
    ; Desenhar 'T' (15,21)
    MOV R1, 15
    MOV R2, 21
    CALL desenhar_T
    
    POP R4
    POP R3
    POP R2
    POP R1
    RET

; Letras para VITÓRIA
desenhar_V:
    ; Linha 1: #   #
    MOV R3, R1
    MOV R4, R2
    CALL pixel_xy
    ADD R4, 4
    CALL pixel_xy
    
    ; Linha 2: #   #
    ADD R3, 1
    MOV R4, R2
    CALL pixel_xy
    ADD R4, 4
    CALL pixel_xy
    
    ; Linha 3: #   #
    ADD R3, 1
    MOV R4, R2
    CALL pixel_xy
    ADD R4, 4
    CALL pixel_xy
    
    ; Linha 4:  # #
    ADD R3, 1
    MOV R4, R2
    ADD R4, 1
    CALL pixel_xy
    ADD R4, 2
    CALL pixel_xy
    
    ; Linha 5:   #
    ADD R3, 1
    MOV R4, R2
    ADD R4, 2
    CALL pixel_xy
    RET

desenhar_I:
    ; Linha 1: #####
    MOV R3, R1
    MOV R4, R2
    CALL pixel_xy
    ADD R4, 1
    CALL pixel_xy
    ADD R4, 1
    CALL pixel_xy
    ADD R4, 1
    CALL pixel_xy
    ADD R4, 1
    CALL pixel_xy
    
    ; Linha 2:   #
    ADD R3, 1
    MOV R4, R2
    ADD R4, 2
    CALL pixel_xy
    
    ; Linha 3:   #
    ADD R3, 1
    MOV R4, R2
    ADD R4, 2
    CALL pixel_xy
    
    ; Linha 4:   #
    ADD R3, 1
    MOV R4, R2
    ADD R4, 2
    CALL pixel_xy
    
    ; Linha 5: #####
    ADD R3, 1
    MOV R4, R2
    CALL pixel_xy
    ADD R4, 1
    CALL pixel_xy
    ADD R4, 1
    CALL pixel_xy
    ADD R4, 1
    CALL pixel_xy
    ADD R4, 1
    CALL pixel_xy
    RET

desenhar_T:
    ; Linha 1: #####
    MOV R3, R1
    MOV R4, R2
    CALL pixel_xy
    ADD R4, 1
    CALL pixel_xy
    ADD R4, 1
    CALL pixel_xy
    ADD R4, 1
    CALL pixel_xy
    ADD R4, 1
    CALL pixel_xy
    
    ; Linha 2-5:   #
    MOV R3, R1
    ADD R3, 1
    MOV R4, R2
    ADD R4, 2
    CALL pixel_xy
    
    ADD R3, 1
    CALL pixel_xy
    
    ADD R3, 1
    CALL pixel_xy
    
    ADD R3, 1
    CALL pixel_xy
    RET

; --------------------------------------------------
; MOSTRAR GAME OVER
; --------------------------------------------------
mostrar_game_over:
    PUSH R1
    PUSH R2
    PUSH R3
    
    ; Limpar tela
    MOV R1, 8000h
    MOV R2, 8080h
    MOV R3, 0H
    
limpar_tela_loop:
    MOVB [R1], R3
    ADD R1, 1H
    MOV R4, R1
    SUB R4, R2
    JN limpar_tela_loop
    
    ; Desenhar 'F' no centro
    MOV R1, 15
    MOV R2, 13
    
    ; Desenhar F (3x5 pixels)
    MOV R3, R1
    MOV R4, R2
    CALL pixel_xy
    ADD R4, 1
    CALL pixel_xy
    ADD R4, 1
    CALL pixel_xy
    
    MOV R3, R1
    ADD R3, 1
    MOV R4, R2
    CALL pixel_xy
    
    MOV R3, R1
    ADD R3, 2
    MOV R4, R2
    CALL pixel_xy
    ADD R4, 1
    CALL pixel_xy
    ADD R4, 1
    CALL pixel_xy
    
    MOV R3, R1
    ADD R3, 3
    MOV R4, R2
    CALL pixel_xy
    
    MOV R3, R1
    ADD R3, 4
    MOV R4, R2
    CALL pixel_xy
    
    POP R3
    POP R2
    POP R1
    RET

;---------------------------------------------
;DESENHAR Caixa central
;---------------------------------------------
desenhar_caixa_central:
PUSH R1
PUSH R2
PUSH R3

MOV R1, 14
MOV R2, 14
MOV R3, sprite_caixa

CALL desenhar_sprite_3x3

POP R3
POP R2
POP R1
RET

; --------------------------------------------------
; CARREGAMENTO INICIAL
; --------------------------------------------------
Carregamento:
    PUSH R1
    PUSH R2
    
    ; Limpar buffer do teclado
    MOV R1, BUFFER
    MOV R2, 0
    MOVB [R1], R2
    
    ; Ativar jogo
    MOV R1, game_active
    MOV R2, 1
    MOV [R1], R2
    
    ; Inicializar posições do Pac-Man
    MOV R1, linha_pac
    MOV R2, 15
    MOV R1, [R1]
    MOV R1, coluna_pac
    MOV R1, [R1]
    
    ; Fantasma 1 nasce na caixa central
    MOV R1, fantasma_linha
    MOV [R1], R2
    MOV R1, fantasma_coluna
    MOV [R1], R2
    
    ; Fantasma 2 também nasce na caixa central (mas inativo)
    MOV R1, fantasma2_linha
    MOV [R1], R2
    MOV R1, fantasma2_coluna
    MOV [R1], R2
    MOV R1, fantasma2_ativa
    MOV R2, 0
    MOV [R1], R2
    
    MOV R1, fantasma_dir
    MOV R2, 3
    MOV [R1], R2
    
    ; Inicializar vidas e pontuação
    MOV R1, vidas
    MOV R2, 3
    MOV [R1], R2
    
    MOV R1, pontuacao
    MOV R2, 0
    MOV [R1], R2
    
    ; Inicializar objetos dos cantos
    MOV R1, objetos_coletados
    MOV [R1], R2
    
    MOV R1, objeto_0
    MOV [R1], R2
    
    MOV R1, objeto_1
    MOV [R1], R2
    
    MOV R1, objeto_2
    MOV [R1], R2
    
    MOV R1, objeto_3
    MOV [R1], R2
    
    ; INICIALIZAR CONTADOR DE SEGUNDOS
    MOV R1, segundo_atual
    MOV [R1], R2
    
    MOV R1, contador_decimal
    MOV [R1], R2
    
    ; Mostrar 00 nos displays inicialmente
    CALL mostrar_contador_display

    ; Limpar tela
    CALL mostrar_game_over

    ; LIMPAR CAMADA VERMELHA
    CALL limpar_camada_vermelha
    
    ; DESENHAR BORDAS VERMELHAS
    CALL desenhar_bordas_vermelhas
    
    ; Desenhar elementos do jogo
    CALL desenhar_cantos
    CALL desenhar_caixa_central
    CALL desenhar_pacman
    CALL desenhar_fantasma
    ; Fantasma 2 não é desenhado ainda (fica inativo até 4 segundos)
    
    POP R2
    POP R1
    RET

; --------------------------------------------------
; DELAY
; --------------------------------------------------
delay:
    PUSH R1
    PUSH R2
    PUSH R3
    MOV R1, 100
delay_externo:
    MOV R2, 100
delay_loop:
    MOV R3, 100
delay_interno:
    SUB R3, 1
    JNZ delay_interno
    SUB R2, 1
    JNZ delay_loop
    SUB R1, 1

    POP R3
    POP R2
    POP R1
    RET

; --------------------------------------------------
; TECLADO
; --------------------------------------------------
pTeclado:
    PUSH R1
    PUSH R2
    PUSH R3
    PUSH R4
    PUSH R5
    PUSH R6
    PUSH R8
    PUSH R10
    
    MOV R5, BUFFER
    MOV R1, 1
    MOV R6, PIN
    MOV R2, POUT

ciclo:
    MOVB [R2], R1
    MOVB R3, [R6]
    AND R3, R3
    JZ inicializarLinha
    
    MOV R8, 1
    CMP R8, R1
    JZ linha1
    MOV R8, 2
    CMP R8, R1
    JZ linha2
    MOV R8, 4
    CMP R8, R1
    JZ linha3
    MOV R8, 8
    CMP R8, R1
    JZ linha4
    JMP fim_teclado_nenhuma

linha4:
    linha4C1:
        MOV R8, 1
        CMP R8, R3
        JZ EC
        JNZ linha4C2
    linha4C2:
        MOV R8, 2
        CMP R8, R3
        JZ ED
        JNZ linha4C3
    linha4C3:
        MOV R8, 4
        CMP R8, R3
        JZ EE
        JNZ linha4C4
    linha4C4:
        MOV R8, 8
        CMP R8, R3
        JZ EF
        JMP fim_teclado_nenhuma

linha3:
    linha3C1:
        MOV R8, 1
        CMP R8, R3
        JZ Esete
        JNZ linha3C2
    linha3C2:
        MOV R8, 2
        CMP R8, R3
        JZ Eoito
        JNZ linha3C3
    linha3C3:
        MOV R8, 4
        CMP R8, R3
        JZ Enove
        JNZ linha3C4
    linha3C4:
        MOV R8, 8
        CMP R8, R3
        JZ EA
        JMP fim_teclado_nenhuma

linha2:
    linha2C1:
        MOV R8, 1
        CMP R8, R3
        JZ Equatro
        JNZ linha2C2
    linha2C2:
        MOV R8, 2
        CMP R8, R3
        JZ Ecinco
        JNZ linha2C3
    linha2C3:
        MOV R8, 4
        CMP R8, R3
        JZ Eseis
        JNZ linha2C4
    linha2C4:
        MOV R8, 8
        CMP R8, R3
        JZ Ezero
        JMP fim_teclado_nenhuma

linha1:
    linha1C1:
        MOV R8, 1
        CMP R8, R3
        JZ Eum
        JNZ linha1C2
    linha1C2:
        MOV R8, 2
        CMP R8, R3
        JZ Edois
        JNZ linha1C3
    linha1C3:
        MOV R8, 4
        CMP R8, R3
        JZ Etres
        JNZ linha1C4
    linha1C4:
        MOV R8, 8
        CMP R8, R3
        JZ EF
        JMP fim_teclado_nenhuma

Ezero:
    MOV R10, 0H
    JMP armazena
Eum:
    MOV R10, 1H
    JMP armazena
Edois:
    MOV R10, 2H
    JMP armazena
Etres:
    MOV R10, 3H
    JMP armazena
Equatro:
    MOV R10, 4H
    JMP armazena
Ecinco:
    MOV R10, 5H
    JMP armazena
Eseis:
    MOV R10, 6H
    JMP armazena
Esete:
    MOV R10, 7H
    JMP armazena
Eoito:
    MOV R10, 8H
    JMP armazena
Enove:
    MOV R10, 9H
    JMP armazena
EA:
    MOV R10, 0AH
    JMP armazena
EB:
    MOV R10, 0BH
    JMP armazena
EC:
    MOV R10, 0CH
    JMP armazena
ED:
    MOV R10, 0DH
    JMP armazena
EE:
    MOV R10, 0EH
    JMP armazena
EF:
    MOV R10, 0FH

armazena:
    MOVB [R5], R10
    JMP fim_teclado

inicializarLinha:
    MOV R8, 2
    MUL R1, R8
    MOV R8, 16
    CMP R1, R8
    JLT ciclo
    
    MOV R10, 0FFH
    MOVB [R5], R10
    JMP fim_teclado

fim_teclado_nenhuma:
    MOV R10, 0FFH
    MOVB [R5], R10

fim_teclado:
    POP R10
    POP R8
    POP R6
    POP R5
    POP R4
    POP R3
    POP R2
    POP R1
    RET

; --------------------------------------------------
; FIM DO PROGRAMA
; --------------------------------------------------