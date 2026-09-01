# Scripts Utilitários de Automação de Workspaces

Coleção de scripts Python utilitários voltados para automação, sincronização em lote e gerenciamento declarativo de repositórios **Git** e **SVN**.

---

## Por que os scripts estão na raiz de `scripts/`?

A estrutura plana direta em `scripts/` foi adotada deliberadamente pelos seguintes motivos:

1. **Simplicidade de Execução:** Permite caminhos curtos e fáceis de memorizar no terminal (ex: `python3 ~/.dotfiles/scripts/sync-git.py`).
2. **Separação Clara de Responsabilidades:** O nome de cada script já define sua tecnologia-alvo (`sync-git.py` e `sync-svn.py`), evitando criar níveis adicionais de diretórios (como `scripts/git/` ou `scripts/svn/`) para apenas um arquivo cada.
3. **Escalabilidade:** Caso surjam novos utilitários com dependências e múltiplos submódulos (como backups complexos ou scripts Nix), novas subpastas temáticas poderão ser criadas mantendo a coesão.

---

## Scripts Disponíveis

### 1. `sync-git.py` (Gerenciador Declarativo de Repositórios Git)
Lê manifestos YAML estruturados e gerencia clonagem e atualização em lote de repositórios Git (especialmente GitLab institucional).

#### Funcionalidades:
- **Clonagem declarativa:** Cria automaticamente a árvore de diretórios conforme o arquivo YAML.
- **Auto-Configuração:** Aplica no repositório clonado regras essenciais de compatibilidade para evitar problemas de final de linha e permissões no WSL.
- **Modos de operação:** Clonagem inicial, verificação consolidada de status e atualização em lote (*fast-forward*).

#### Exemplos de Uso:
```bash
# 1. Ajuda e documentação interativa
python3 ~/.dotfiles/scripts/sync-git.py --help

# 2. Clonar todos os repositórios faltantes do manifesto padrão
python3 ~/.dotfiles/scripts/sync-git.py

# 3. Verificar o status de todos os repositórios (modificados vs limpos)
python3 ~/.dotfiles/scripts/sync-git.py --status

# 4. Atualizar todos os repositórios existentes (git pull --ff-only)
python3 ~/.dotfiles/scripts/sync-git.py --update

# 5. Usar um arquivo de manifesto personalizado
python3 ~/.dotfiles/scripts/sync-git.py --status /caminho/para/outro-manifesto.yaml
```

---

### 2. `sync-svn.py` (Gerenciador Declarativo de Repositórios SVN)
Gerencia o checkout do branch padrão (`trunk` ou personalizado) e atualização em lote de projetos hospedados em servidores Subversion legados.

#### Funcionalidades:
- **Checkout declarativo:** Mapeia repositórios remotos para nomes de pastas locais configuráveis.
- **Resiliência SSL Corporativo:** Não trava a CLI aguardando confirmação interativa de certificados autoassinados ou de autoridades internas.
- **Modos de operação:** Checkout inicial, verificação de modificações (`svn status -q`) e atualização (`svn update`).

#### Exemplos de Uso:
```bash
# 1. Ajuda e documentação interativa
python3 ~/.dotfiles/scripts/sync-svn.py --help

# 2. Realizar checkout dos repositórios faltantes do manifesto padrão
python3 ~/.dotfiles/scripts/sync-svn.py

# 3. Verificar arquivos modificados ou não commitados em lote
python3 ~/.dotfiles/scripts/sync-svn.py --status

# 4. Atualizar todos os checkouts (svn update)
python3 ~/.dotfiles/scripts/sync-svn.py --update

# 5. Usar um manifesto personalizado
python3 ~/.dotfiles/scripts/sync-svn.py /caminho/para/outro-svn-manifesto.yaml
```

---

## Prevenção de Falhas Comuns: UTF-8, EOL (LF) e WSL

Ao trabalhar com desenvolvimento em ambiente misto (WSL + Linux + Windows) e múltiplos repositórios heterogêneos, diversos problemas clássicos de ambiente podem ocorrer. Abaixo detalhamos como os scripts e as configurações os mitigam:

| Problema Potencial | Causa Raiz | Solução Aplicada nos Scripts & Config |
| :--- | :--- | :--- |
| **Conversão indesejada de EOL para CRLF** | O Git no Windows converte quebras de linha para `\r\n`. | Configura `core.eol = lf` e `core.autocrlf = input` automaticamente em cada repositório clonado. |
| **Acentos corrompidos no terminal** | Terminal rodando com locale legado (ISO-8859-1 ou ASCII). | Os scripts executam os subprocessos Git/SVN forçando `LC_ALL = "C.UTF-8"`. |
| **Caminhos com acentos virando octais (`\303\241`)** | Comportamento padrão do `core.quotepath` no Git. | É garantido `core.quotepath = false` em nível global e local para manter acentos legíveis. |
| **Permissões falsas de arquivo no WSL (`100644` vs `100755`)** | O sistema de arquivos NTFS/WSL altera flags de execução do arquivo. | Aplica `core.filemode = false`, impedindo que o Git considere alteração de permissão como alteração de código. |
| **Puxadas acidentais de merge commit sujo** | `git pull` padrão cria merges locais quando há divergências. | O modo `--update` utiliza `--ff-only`, abortando de forma segura se houver divergência sem criar commits acidentais. |
| **Bloqueio de CLI por SSL no SVN** | Certificados internos da rede institucional exigem prompt `(R)eject / accept (t)emporarily`. | O script utiliza flags `--non-interactive` e `--trust-server-cert-failures`, garantindo execução sem travar. |

---

## Estrutura dos Manifestos YAML

Os manifestos padrão consumidos por estes scripts ficam localizados no repositório `~/.dotfiles-uerj`:

```
~/.dotfiles-uerj/workspaces/manifests/
├── git-uerj-manifest.yaml   # Declara grupos, hosts e repositórios GitLab
└── svn-uerj-manifest.yaml   # Declara URLs base, branches e repositórios SVN
```

### Exemplo de Manifesto Git (`git-uerj-manifest.yaml`):
```yaml
base_dir: ~/workspace/uerj/git
gitlab_host: git.dgti.uerj.br
default_group: depsen
protocol: ssh

trees:
  monolitos:
    repos:
      - sisaluno
      - sag
  distribuidos/auth:
    _group: depsen-microservices
    repos:
      - auth-service
```

### Exemplo de Manifesto SVN (`svn-uerj-manifest.yaml`):
```yaml
base_dir: ~/workspace/uerj/svn
svn_base_url: http://www.svn.dinfo.uerj.br/svn
branch: trunk
username: alexandre.trindade

repositories:
  - name: siatu
    folder: siatu
  - name: sag-legado
    folder: sag-legado
```
