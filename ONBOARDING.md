# Guia de Onboarding do Ambiente (Nix + WSL)

Bem-vindo ao seu novo ambiente de desenvolvimento! 
Ele foi projetado usando **Nix e Home Manager** para ser 100% reprodutível, extremamente rápido e imune a conflitos de versão. 

Este guia explica como usar o arsenal de ferramentas que agora moram no seu terminal.

---

## A Magia Principal: Direnv

O `direnv` (agora com suporte ao `nix-direnv`) é o seu novo melhor amigo. Ele carrega e descarrega variáveis de ambiente automaticamente baseado na pasta em que você está.

**Como usar no dia a dia:**
1. Crie um arquivo `.envrc` na raiz do seu projeto (ex: `echo "export API_KEY=123" > .envrc`).
2. O terminal vai bloquear a execução por segurança e pedir sua permissão.
3. Rode `direnv allow`.
4. Pronto! Sempre que você entrar nessa pasta (via `cd`), a variável `API_KEY` estará disponível. Quando sair da pasta, ela some magicamente.

---

## Aliases do Nix & Home Manager

Você nunca mais precisa digitar comandos longos do Nix. Use os atalhos abaixo de qualquer lugar do sistema:

- **`hms`** (`home-manager switch ...`): O mais importante! Sempre que alterar seu `home.nix`, rode `hms` para aplicar as mudanças.
- **`hmn`** (`home-manager news`): Lê as notas de lançamento e atualizações pendentes do Home Manager.
- **`hmg`** (`home-manager generations`): Mostra o histórico de builds do seu ambiente. Se você instalar algo que quebre o sistema, pode usar o ID exibido aqui para dar rollback.
- **`nfu`** (`nix flake update`): Atualiza a versão travada de todos os pacotes no seu arquivo `flake.lock`.
- **`nix-gc`** (`nix-collect-garbage -d`): Limpeza pesada. Apaga pacotes órfãos e versões antigas do Nix para liberar espaço em disco.

---

## Navegação e Arquivos (As Ferramentas Rust)

Nós trocamos os comandos jurássicos do Linux por versões modernas, coloridas e velozes escritas em Rust:

### Zoxide (`z` no lugar do `cd`)
O Zoxide aprende quais pastas você mais acessa.
- Em vez de: `cd ~/workspace/uerj/git/depsen`
- Faça apenas: `z depsen` (ele vai te teletransportar para lá).

### Eza (`ls` com ícones)
- **`l`**: Lista arquivos formatados em colunas.
- **`ll`**: Lista todos os arquivos (incluindo permissões, datas e ícones) em formato de lista detalhada.
- **`la`**: Mostra os arquivos ocultos.

### Bat (`bat` no lugar do `cat`)
Mostra o conteúdo de arquivos no terminal, mas com *Syntax Highlighting* (cores de código) e numeração de linhas.
- **Uso:** `bat package.json` ou `bat docker-compose.yml`.

---

## Buscas Instantâneas

### Ripgrep (`rg` no lugar do `grep`)
O buscador de texto mais rápido do mundo. Ele respeita seu `.gitignore` por padrão.
- **Uso:** `rg "Auth::user()"` (acha em qual arquivo você chamou essa função).

### Fd (`fd` no lugar do `find`)
Busca arquivos pelo nome em milissegundos.
- **Uso:** `fd ".env"` (acha todos os arquivos de configuração na pasta).

### FZF (Busca Fuzzy)
Aperte **`Ctrl + R`** no terminal para buscar no seu histórico de comandos digitando apenas pedaços do comando!

---

## Teste de APIs com HTTPie

Esqueça as sintaxes complexas do `curl`. O `httpie` é colorido e amigável, como se fosse um Postman no terminal.
- **GET simples:** `http api.seusite.com/users`
- **POST com JSON:** `http POST api.seusite.com/users nome="Alexandre" email="teste@teste.com"`
- **Com Token:** `http api.seusite.com/users "Authorization: Bearer seu_token"`

---

## Docker e Git (Terminal UI)

Em vez de decorar comandos gigantes, use as interfaces de terminal:

- **`lazygit`**: Uma interface completa e interativa para fazer commits, visualizar diffs, gerenciar branches e fazer push/pull. Aperte `?` para ver os atalhos.
- **`lazydocker`**: Veja os logs de todos os seus contêineres, pause, reinicie e monitore o uso de CPU/RAM em uma interface bonita.

### Aliases de Git do dia a dia
- **`st`**: Atalho para `git status`.
- **`gfp`**: Atualiza seu repositório local e já apaga as referências de branches que foram deletadas no Github (`git fetch --prune`).
- **`glog`**: Mostra uma árvore desenhada lindíssima com o histórico dos últimos commits.
- **`gclean-merged`**: Apaga do seu computador todas as branches que já foram mergeadas.

---

## Linguagens e IDE (O Motor Invisível)

Você não precisa se preocupar com dependências globais ou usar instaladores antigos. O Nix já garante que as seguintes ferramentas estejam blindadas no seu sistema:

- **PHP 8.5**: Com o Composer e o Intelephense (Language Server).
- **Node.js**: Com Yarn, PNPM, Prettier e TypeScript Language Server.
- **Java 25 (LTS)**: Com Maven, Gradle, Google Java Format e JDTLS.
- **Python 3**: Com Poetry, Ruff e Pyright.

**Integração com a IDE (VS Code / Antigravity):**
Você não precisa configurar caminhos malucos para LSPs ou Formatters na IDE. Como instalamos eles no Nix (ex: `prettier`, `intelephense`, `pyright`), as extensões oficiais da IDE vão detectá-los magicamente no seu PATH e tudo vai formatar e autocompletar sozinho!
