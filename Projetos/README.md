# 🎮 Pac-Man Simplificado - PEPE-16

**ARQUITECTURA DE COMPUTADORES**  
**DOCENTE: JOÃO JOSÉ DA COSTA**  
**GRUPO 12**

---

## 👥 INTEGRANTES

- **HÉLVIO SANTANA**
- **GOLDWYN NARCISO**
- **HAMILTON ZUA**
- **ANDRÉ GUNZA**

---

## 🚀 COMO EXECUTAR O PROJECTO

### Pré-requisitos
1. **Java 8** (versão disponibilizada pelo docente)
2. **Simulador PEPE-16** (fornecido pelo docente)
3. **Ficheiros do projeto**:
   - `circuito.cmod` (circuito do simulador)
   - `pacman.asm` (código assembly)

### Passos de Execução

1. **Iniciar o Simulador**
   - Abrir o simulador PEPE-16

2. **Carregar o Circuito**
   - Clicar em **File** → **Load**
   - Selecionar o arquivo `circuito.cmod`

3. **Configurar Periféricos**
   - No painel lateral esquerdo, clicar em **Simulação**
   - Clicar em **PixelScreen** para abrir a tela gráfica
   - Clicar em **Teclado** para abrir o teclado virtual
   - Clicar em **Dezenas** e **Unidades** para abrir os contadores

4. **Carregar o Programa**
   - Clicar no componente **PEPE** (processador)
   - Clicar no ícone **Pasta com Seta Verde** (Compile and Load)
   - Selecionar o arquivo `pacman.asm`

5. **Executar a Simulação**
   - No painel lateral, clicar em **Next Step** para avançar passo a passo
   - Ou clicar em **Run Simulation** para execução contínua

---

## 🎮 CONTROLES DO JOGO

| TECLA | AÇÃO |
|-------|------|
| **1** | Move para **CIMA** |
| **A** | Move para **BAIXO** |
| **4** | Move para **ESQUERDA** |
| **6** | Move para **DIREITA** |
| **F** | **FINALIZA** o jogo |

---

## 🎯 OBJETIVO DO JOGO

1. Controlar o **Pac-Man** (sprite amarelo) pelo labirinto
2. Coletar os **4 objetos** localizados nos cantos do mapa
3. Evitar colisões com os **fantasmas** (sprites vermelhos)
4. **Vitória**: Coletar todos os 4 objetos
5. **Derrota**: Perder todas as 3 vidas por colisões com fantasmas

---

## ⚙️ CARACTERÍSTICAS TÉCNICAS

- **Processador**: PEPE-16
- **Display**: 32×32 pixels (com camada de cor vermelha)
- **Teclado**: Matricial 4×4
- **Displays**: 2 dígitos hexadecimais para contador de tempo
- **Sprites**: 3×3 pixels (Pac-Man, fantasmas, objetos, caixa central)

---

## 📁 FICHEIROS DO PROJECTO

- `pacman.asm` - Código fonte em Assembly PEPE-16
- `circuito.cmod` - Configuração do circuito no simulador
- `README.md` - Este documento

---

## ℹ️ INFORMAÇÕES ADICIONAIS

- O **contador de tempo** mostra segundos decorridos
- **Bordas vermelhas** delimitam a área de jogo
- **Caixa central** (14,14) é o ponto de nascimento dos fantasmas

---

## 🆘 TROUBLESHOOTING

- **Problema**: Tela não atualiza
  - Solução: Verificar se o PixelScreen está aberto e visível

- **Problema**: Teclado não responde
  - Solução: Clicar no teclado virtual para dar foco

- **Problema**: Programa não carrega
  - Solução: Verificar se o arquivo `.asm` está no formato correto

---

**Desenvolvido para a disciplina de Arquitectura de Computadores - 2025/2026**
