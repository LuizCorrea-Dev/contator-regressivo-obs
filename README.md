# ⏱️ Temporizador Regressivo Avançado para OBS Studio (PT-BR)

Script Lua otimizado e traduzido para o **OBS Studio**, projetado especialmente para criadores de conteúdo e streamers que precisam de um contador de início de live, intervalo ("BRB") ou eventos com **automação por cena**, criação automática de texto e recursos visuais modernos.

Desenvolvido e customizado por **[Rootszera](https://github.com/LuizCorrea-Dev)**.

---

## ✨ Principais Funcionalidades

- 🇧🇷 **100% em Português do Brasil**: Menus, opções e descrições claras e intuitivas.
- 🧙‍♂️ **Assistente em 2 Etapas**:
  - **Etapa 1**: Selecione qualquer cena do seu OBS e clique no botão para criar a fonte **Texto (GDI+)** automaticamente dentro dela.
  - **Etapa 2**: Redirecionamento automático imediato para a tela de configurações completas do contador.
- 🔄 **Automação por Cena (Padrão)**:
  - Inicia a contagem regressiva automaticamente ao carregar/entrar na cena.
  - Pausa e reseta automaticamente ao sair da cena.
  - Reinicia do início sempre que você voltar para a cena.
- 💬 **Mensagem Final Personalizada**: Exibe uma mensagem na tela assim que o contador zera (ex: *"Começando em instantes!"*).
- 👻 **Ocultar da Tela Automaticamente**: Opção com caixa configurável para ocultar o texto após **X minutos** do término da contagem (ex: 1 minuto).
- 🕒 **Formatação Inteligente**: Suporta `%0m:%0s` (padrão `05:00`), `%0H:%0M:%0S`, dias, milésimos de segundo e muito mais.
- 🎬 **Troca de Cena Automática (Opcional)**: Transita automaticamente para outra cena quando a contagem terminar.

---

## 📥 Como Instalar no OBS Studio

1. Abra o seu **OBS Studio**.
2. No menu superior, clique em **Ferramentas** > **Scripts**.
3. Na janela de Scripts que se abrir:
   - Clique no ícone de **`+`** (canto inferior esquerdo).
   - Navegue até a pasta onde este repositório está salvo e selecione o arquivo **`timer-obs.lua`** (ou `advanced-timer.lua`).
   - Clique em **Abrir**.
4. O script será carregado imediatamente na lista com o painel de configurações à direita.

---

## 🚀 Como Usar (Passo a Passo)

### Etapa 1: Selecionar a Cena e Criar o Texto
1. No campo **"1. Escolha a Cena para o Contador"**, selecione a cena onde você quer que o temporizador apareça (ex: *Tela de Início*, *Intervalo*, *Aguarde*).
2. Se quiser, personalize o **"Nome da Fonte de Texto (GDI+)"** (por padrão é `Temporizador Rootszera`).
3. Clique no botão **`➡️ Criar Texto e Avançar para Configuração`**.
   - O OBS criará a fonte de texto dentro da cena selecionada e abrirá instantaneamente a **Etapa 2**.

---

### Etapa 2: Configurar o Temporizador
Nesta tela, personalize as preferências:

- **Modo do Temporizador**: Deixe em `Contagem Regressiva (Countdown)`.
- **Duração da contagem (segundos)**: Tempo em segundos (ex: `300` para 5 minutos, `600` para 10 minutos).
- **Formato de Exibição**: Padrão `%0m:%0s` (ex: `05:00`).
- **Mensagem ao finalizar a contagem**: Texto que substituirá os números quando zerar (ex: `Começando em instantes!`).
- **Ocultar da tela após o término**: Marque a caixa e defina o tempo em minutos (ex: `1,00` minuto) para que o texto suma da tela sozinho após o término.
- **Modo de Ativação**: Mantido em `Iniciar/Resetar ao carregar a cena` para automatizar com as suas transições de tela.

---

## 🔠 Tags de Formatação de Exibição

Você pode formatar o texto como quiser no campo **Formato de Exibição**:

| Tag | Descrição | Exemplo |
| :--- | :--- | :--- |
| `%0m` | Minutos com 2 dígitos (00 a 59) | `05` |
| `%m` | Minutos simples (0 a 59) | `5` |
| `%0s` | Segundos com 2 dígitos (00 a 59) | `09` |
| `%s` | Segundos simples (0 a 59) | `9` |
| `%0H` | Horas totais com 2 dígitos | `01` |
| `%0M` | Minutos totais acumulados | `65` |
| `%d` | Dias | `0` |
| `%t` / `%2t` / `%3t` | Décimos, centésimos ou milésimos de segundo | `3`, `35`, `350` |

---

## ⌨️ Teclas de Atalho (Hotkeys)

Você também pode controlar o temporizador pelo teclado ou Stream Deck:
1. No OBS, vá em **Configurações** > **Teclas de Atalho**.
2. Procure por:
   - **Iniciar/Pausar Temporizador**
   - **Resetar Temporizador**
3. Defina os atalhos que preferir.

---

## 👨‍💻 Autor e Créditos

Desenvolvido e aprimorado por:
- **Rootszera**
- GitHub: [https://github.com/LuizCorrea-Dev](https://github.com/LuizCorrea-Dev)

---
*Gostou do script? Deixe uma estrela ⭐ no repositório!*
