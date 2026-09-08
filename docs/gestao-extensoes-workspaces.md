# Gestão de Extensões por Workspace no VS Code e Antigravity IDE

Este documento descreve como configurar, isolar e gerenciar extensões de forma eficiente entre múltiplos workspaces no **Visual Studio Code** e no **Antigravity IDE**, especialmente em ambientes multi-root integrados via WSL.

---

## 1. Desafio da Gestão de Extensões em Projetos Heterogêneos

Em ambientes corporativos ou monorepos que contêm múltiplas linguagens e frameworks (como Java/Spring Boot, PHP/Laravel, React, Python e Nix):
- Carregar todas as extensões globalmente em todos os workspaces causa **alto consumo de memória**, lentidão na inicialização e conflitos entre Language Servers e formatadores.
- Não instalar extensões necessárias degrada a experiência do desenvolvedor e reduz a eficácia de assistentes inteligentes de IA (como o Antigravity IDE), que dependem de definições de símbolos, AST e linting.

---

## 2. Abordagens Técnicas

### A. Recomendações Declarativas no Arquivo de Workspace (`extensions.recommendations`)

O padrão de workspaces multi-root (`.code-workspace`) suporta nativamente a chave `extensions`:

```json
{
  "folders": [
    { "name": "Backend", "path": "../backend" },
    { "name": "Frontend", "path": "../frontend" }
  ],
  "settings": {
    "files.exclude": { "**/target": true }
  },
  "extensions": {
    "recommendations": [
      "vscjava.vscode-java-pack",
      "vscjava.vscode-maven",
      "ms-azuretools.vscode-docker"
    ],
    "unwantedRecommendations": [
      "devsense.phptools-vscode"
    ]
  }
}
```

#### Benefícios:
- **Portabilidade:** As extensões recomendadas ficam versionadas com as definições do workspace no repositório de configuração (`.dotfiles-uerj/workspaces/vscode/`).
- **Sincronização Fácil:** Ao abrir o workspace na IDE, o usuário recebe a notificação para instalar as extensões recomendadas ou pode executar `@recommended` na aba de extensões (`Ctrl+Shift+X`) e clicar em "Install Workspace Extension Recommendations".
- **Transparência:** A equipe e assistentes de IA têm clareza imediata sobre quais ferramentas são necessárias para cada stack.

---

### B. Isolamento Estrito com Perfis de Configuração (`--profile`)

Para isolamento completo (onde apenas as extensões de uma stack específica ficam ativas e instaladas na memória), o VS Code e Antigravity suportam **Perfis** (Profiles).

#### Criação de Perfis Recomendados:
1. **UERJ - Java:** Apenas extensões de desenvolvimento Java e Spring Boot.
2. **UERJ - PHP:** Apenas extensões PHP, Laravel, Blade e Xdebug.
3. **UERJ - Fullstack:** Suíte completa com Java, PHP e ferramentas web.
4. **UERJ - Infra:** Extensões de Nix, Python, Docker e Remote SSH.

#### Invocação pelo Terminal:
Tanto o `code` quanto o `antigravity-ide` aceitam a flag `--profile`:

```bash
# Abrir no VS Code com perfil específico
code --profile "UERJ - Java" ~/.dotfiles-uerj/workspaces/vscode/uerj-assiste.code-workspace

# Abrir no Antigravity IDE com perfil específico
antigravity-ide --profile "UERJ - PHP" --file-uri "vscode-remote://wsl+Ubuntu-26.04/..."
```

---

## 3. Matriz de Extensões por Stack nos Workspaces UERJ

| Stack | Workspaces Principais | Extensões Recomendadas |
| :--- | :--- | :--- |
| **Java / Spring Boot** | `uerj-assiste`, `uerj-sfs`, `uerj-siext`, `uerj-validador-assinaturas`, `uerj-microservicos`, `uerj-springboot-base` | • `vscjava.vscode-java-pack`<br>• `vscjava.vscode-maven`<br>• `vscjava.vscode-java-dependency`<br>• `vscjava.vscode-java-debug`<br>• `ms-azuretools.vscode-docker`<br>• `eamodio.gitlens` |
| **PHP / Laravel / Legados** | `uerj-laravel-base`, `uerj-novo-prematricula`, `uerj-spo`, `uerj-sig`, `uerj-sabm`, `uerj-pessoa`, `uerj-sie` | • `devsense.phptools-vscode`<br>• `xdebug.php-debug`<br>• `laravel.vscode-laravel`<br>• `amiralizadeh9480.laravel-extra-intellisense`<br>• `ms-azuretools.vscode-docker`<br>• `eamodio.gitlens` |
| **Fullstack (Híbrido)** | `uerj-euerj`, `uerj-templates` | Ambas as suítes (Java + PHP) com ferramentas de containers e Git |
| **Infra & Dotfiles** | `dotfiles-uerj` | • `bbenoist.nix`<br>• `ms-azuretools.vscode-docker`<br>• `ms-vscode-remote.remote-ssh`<br>• `eamodio.gitlens`<br>• `ms-python.python` |

---

## 4. Integração com Atalhos Automatizados (`uws`)

A função helper `uws` declarada em `~/.dotfiles/home.nix` gerencia a resolução dos caminhos dos arquivos `.code-workspace` e sua abertura no VS Code ou Antigravity IDE (`uws -a <termo>`).
