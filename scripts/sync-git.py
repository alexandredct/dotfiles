#!/usr/bin/env python3
"""
sync-git.py
Sincroniza e clona repositórios Git organizados por manifesto YAML declarativo.

Uso:
  python3 sync-git.py [caminho_do_manifesto.yaml]
  python3 sync-git.py --update [caminho_do_manifesto.yaml]
  python3 sync-git.py --status [caminho_do_manifesto.yaml]
  python3 sync-git.py --help
"""

import sys
import os
import subprocess
from pathlib import Path

try:
    import yaml
except ImportError:
    print("[AVISO] PyYAML não instalado. Instalando...")
    subprocess.run([sys.executable, "-m", "pip", "install", "--user", "pyyaml"], check=True)
    import yaml

def print_help():
    help_text = """
================================================================================
sync-git.py - Gerenciador de Workspaces Git Declarativos
================================================================================

USO:
  python3 sync-git.py [OPÇÕES] [ARQUIVO_MANIFESTO.yaml]

AÇÕES DISPONÍVEIS:
  (sem flags)     Clona repositórios que ainda não existem localmente.
  --update        Executa 'git pull --ff-only' em todos os repositórios existentes.
  --status        Exibe o estado de cada repositório (limpo ou com modificações locais).
  -h, --help      Exibe esta tela de ajuda detalhada.

PADRÕES / DEFAULTS:
  Se nenhum arquivo for especificado, utiliza:
  ~/.dotfiles-uerj/workspaces/manifests/git-uerj-manifest.yaml

GARANTIAS DE CODIFICAÇÃO E EOL:
  Em novos clones, o script configura automaticamente:
    - core.eol = lf
    - core.autocrlf = input
    - core.quotepath = false (preserva caracteres acentuados)
    - core.filemode = false (ignora permissões falsas do WSL)

EXEMPLOS:
  python3 sync-git.py
  python3 sync-git.py --status
  python3 sync-git.py --update ~/.dotfiles-uerj/workspaces/manifests/git-uerj-manifest.yaml
================================================================================
"""
    print(help_text)

def run_git(args, cwd=None):
    env = os.environ.copy()
    env["LC_ALL"] = "C.UTF-8"
    return subprocess.run(["git"] + args, cwd=cwd, capture_output=True, text=True, env=env)

def configure_repo_defaults(repo_path):
    """Garante configurações essenciais de EOL (LF), UTF-8 e permissões para evitar problemas no WSL/Linux."""
    run_git(["config", "core.eol", "lf"], cwd=repo_path)
    run_git(["config", "core.autocrlf", "input"], cwd=repo_path)
    run_git(["config", "core.quotepath", "false"], cwd=repo_path)
    run_git(["config", "core.filemode", "false"], cwd=repo_path)

def sync_manifest(manifest_path, action="clone"):
    manifest_file = Path(manifest_path).expanduser().resolve()
    if not manifest_file.exists():
        print(f"[ERRO] Arquivo de manifesto não encontrado: {manifest_file}")
        return

    with open(manifest_file, "r", encoding="utf-8") as f:
        config = yaml.safe_load(f)

    base_dir = Path(os.path.expanduser(config.get("base_dir", "~/workspace/uerj/git")))
    gitlab_host = config.get("gitlab_host", "git.dgti.uerj.br")
    default_group = config.get("default_group", "depsen")
    protocol = config.get("protocol", "ssh")

    print("=" * 60)
    print(f"Sincronizando Workspace Git: {manifest_file.name}")
    print(f"Destino Base: {base_dir}")
    print(f"Host: {gitlab_host}")
    print(f"Ação: {action.upper()}")
    print("=" * 60)

    trees = config.get("trees", {})
    total_repos = 0
    cloned = 0
    updated = 0
    errors = 0

    for target_rel_path, repos_data in trees.items():
        target_dir = base_dir / target_rel_path
        target_dir.mkdir(parents=True, exist_ok=True)

        if isinstance(repos_data, dict):
            group = repos_data.get("_group", default_group)
            repo_list = repos_data.get("repos", [])
        elif isinstance(repos_data, list):
            group = default_group
            repo_list = repos_data
        else:
            continue

        for repo_name in repo_list:
            total_repos += 1
            repo_path = target_dir / repo_name

            if protocol == "ssh":
                git_url = f"git@{gitlab_host}:{group}/{repo_name}.git"
            else:
                git_url = f"https://{gitlab_host}/{group}/{repo_name}.git"

            rel_display = f"{target_rel_path}/{repo_name}"

            if (repo_path / ".git").exists():
                if action == "update":
                    print(f"[ATUALIZANDO] {rel_display}...", end=" ", flush=True)
                    res = run_git(["pull", "--ff-only"], cwd=repo_path)
                    if res.returncode == 0:
                        print("OK")
                        updated += 1
                    else:
                        err_msg = res.stderr.strip()
                        print(f"FALHA ({err_msg})")
                        errors += 1
                elif action == "status":
                    res = run_git(["status", "--porcelain"], cwd=repo_path)
                    changes = res.stdout.strip()
                    if changes:
                        print(f"[MODIFICADO] {rel_display}")
                    else:
                        print(f"[LIMPO]      {rel_display}")
                else:
                    print(f"[OK] Já existe: {rel_display}")
            else:
                if action in ["clone", "update"]:
                    print(f"[CLONANDO] {git_url} -> {rel_display}...", end=" ", flush=True)
                    env = os.environ.copy()
                    env["LC_ALL"] = "C.UTF-8"
                    res = subprocess.run(["git", "clone", git_url, str(repo_path)], capture_output=True, text=True, env=env)
                    if res.returncode == 0:
                        configure_repo_defaults(repo_path)
                        print("OK")
                        cloned += 1
                    else:
                        err_msg = res.stderr.strip()
                        print(f"ERRO: {err_msg}")
                        errors += 1

    print("-" * 60)
    print(f"Resumo: Total: {total_repos} | Novos clonados: {cloned} | Atualizados: {updated} | Falhas: {errors}")

if __name__ == "__main__":
    args = sys.argv[1:]

    if "-h" in args or "--help" in args:
        print_help()
        sys.exit(0)

    action = "clone"
    if "--update" in args:
        action = "update"
        args.remove("--update")
    elif "--status" in args:
        action = "status"
        args.remove("--status")

    if args:
        manifest = args[0]
    else:
        default_manifest = Path.home() / ".dotfiles-uerj" / "workspaces" / "manifests" / "git-uerj-manifest.yaml"
        manifest = str(default_manifest)

    sync_manifest(manifest, action=action)
