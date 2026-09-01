#!/usr/bin/env python3
"""
sync-svn.py
Sincroniza e executa checkout do trunk de repositórios SVN via manifesto YAML.

Uso:
  python3 sync-svn.py [caminho_do_manifesto.yaml]
  python3 sync-svn.py --update [caminho_do_manifesto.yaml]
  python3 sync-svn.py --status [caminho_do_manifesto.yaml]
  python3 sync-svn.py --help
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
sync-svn.py - Gerenciador de Workspaces SVN Declarativos
================================================================================

USO:
  python3 sync-svn.py [OPÇÕES] [ARQUIVO_MANIFESTO.yaml]

AÇÕES DISPONÍVEIS:
  (sem flags)     Realiza checkout dos repositórios/pastas que ainda não existem.
  --update        Executa 'svn update' em todos os repositórios existentes.
  --status        Exibe o estado de cada repositório ('svn status -q').
  -h, --help      Exibe esta tela de ajuda detalhada.

PADRÕES / DEFAULTS:
  Se nenhum arquivo for especificado, utiliza:
  ~/.dotfiles-uerj/workspaces/manifests/svn-uerj-manifest.yaml

RESILIÊNCIA E TRATAMENTO DE AMBIENTE:
  - Força LC_ALL=C.UTF-8 para evitar problemas de codificação e acentuação.
  - Utiliza flags para aceitar certificados SSL corporativos sem travar a CLI:
    --non-interactive --trust-server-cert-failures=unknown-ca,cn-mismatch,expired,not-yet-valid,other

EXEMPLOS:
  python3 sync-svn.py
  python3 sync-svn.py --status
  python3 sync-svn.py --update ~/.dotfiles-uerj/workspaces/manifests/svn-uerj-manifest.yaml
================================================================================
"""
    print(help_text)

def run_svn(args, cwd=None):
    env = os.environ.copy()
    env["LC_ALL"] = "C.UTF-8"
    base_cmd = ["svn", "--non-interactive", "--trust-server-cert-failures=unknown-ca,cn-mismatch,expired,not-yet-valid,other"]
    return subprocess.run(base_cmd + args, cwd=cwd, capture_output=True, text=True, env=env)

def sync_svn_manifest(manifest_path, action="checkout"):
    manifest_file = Path(manifest_path).expanduser().resolve()
    if not manifest_file.exists():
        print(f"[ERRO] Arquivo de manifesto não encontrado: {manifest_file}")
        return

    with open(manifest_file, "r", encoding="utf-8") as f:
        config = yaml.safe_load(f)

    base_dir = Path(os.path.expanduser(config.get("base_dir", "~/workspace/uerj/svn")))
    svn_base_url = config.get("svn_base_url", "http://www.svn.dinfo.uerj.br/svn")
    branch = config.get("branch", "trunk")
    username = config.get("username", "")

    print("=" * 60)
    print(f"Sincronizando Workspace SVN: {manifest_file.name}")
    print(f"Destino Base: {base_dir}")
    print(f"SVN Base URL: {svn_base_url}")
    print(f"Branch/Alvo: {branch}")
    print(f"Ação: {action.upper()}")
    print("=" * 60)

    base_dir.mkdir(parents=True, exist_ok=True)
    repositories = config.get("repositories", [])

    total_repos = 0
    checked_out = 0
    updated = 0
    errors = 0

    for repo_item in repositories:
        if isinstance(repo_item, dict):
            repo_name = repo_item.get("name")
            target_folder = repo_item.get("folder", repo_name)
            repo_url = repo_item.get("url", f"{svn_base_url}/{repo_name}/{branch}")
        else:
            repo_name = repo_item
            target_folder = repo_name
            repo_url = f"{svn_base_url}/{repo_name}/{branch}"

        total_repos += 1
        dest_path = base_dir / target_folder

        if (dest_path / ".svn").exists():
            if action == "update":
                print(f"[ATUALIZANDO] {target_folder}...", end=" ", flush=True)
                res = run_svn(["update"], cwd=dest_path)
                if res.returncode == 0:
                    print("OK")
                    updated += 1
                else:
                    err_msg = res.stderr.strip()
                    print(f"FALHA ({err_msg})")
                    errors += 1
            elif action == "status":
                res = run_svn(["status", "-q"], cwd=dest_path)
                changes = res.stdout.strip()
                if changes:
                    print(f"[MODIFICADO] {target_folder}")
                else:
                    print(f"[LIMPO]      {target_folder}")
            else:
                print(f"[OK] Já existe: {target_folder}")
        else:
            if action in ["checkout", "update"]:
                print(f"[CHECKOUT] {repo_url} -> {target_folder}...", end=" ", flush=True)
                cmd_args = ["checkout", repo_url, str(dest_path)]
                if username:
                    cmd_args.extend(["--username", username])
                res = run_svn(cmd_args)
                if res.returncode == 0:
                    print("OK")
                    checked_out += 1
                else:
                    err_msg = res.stderr.strip()
                    print(f"ERRO: {err_msg}")
                    errors += 1

    print("-" * 60)
    print(f"Resumo: Total: {total_repos} | Novos checkout: {checked_out} | Atualizados: {updated} | Falhas: {errors}")

if __name__ == "__main__":
    args = sys.argv[1:]

    if "-h" in args or "--help" in args:
        print_help()
        sys.exit(0)

    action = "checkout"
    if "--update" in args:
        action = "update"
        args.remove("--update")
    elif "--status" in args:
        action = "status"
        args.remove("--status")

    if args:
        manifest = args[0]
    else:
        default_manifest = Path.home() / ".dotfiles-uerj" / "workspaces" / "manifests" / "svn-uerj-manifest.yaml"
        manifest = str(default_manifest)

    sync_svn_manifest(manifest, action=action)
