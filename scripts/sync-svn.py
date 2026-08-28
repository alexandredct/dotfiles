#!/usr/bin/env python3
"""
sync-svn.py
Sincroniza e executa checkout do trunk de repositorios SVN via manifesto YAML.

Uso:
  python3 sync-svn.py [caminho_do_manifesto.yaml]
  python3 sync-svn.py --update [caminho_do_manifesto.yaml]
  python3 sync-svn.py --status [caminho_do_manifesto.yaml]
"""

import sys
import os
import subprocess
from pathlib import Path

try:
    import yaml
except ImportError:
    print("[AVISO] PyYAML nao instalado. Instalando...")
    subprocess.run([sys.executable, "-m", "pip", "install", "--user", "pyyaml"], check=True)
    import yaml

def run_svn(args, cwd=None):
    return subprocess.run(["svn"] + args, cwd=cwd, capture_output=True, text=True)

def sync_svn_manifest(manifest_path, action="checkout"):
    manifest_file = Path(manifest_path).expanduser().resolve()
    if not manifest_file.exists():
        print(f"[ERRO] Arquivo de manifesto nao encontrado: {manifest_file}")
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
    print(f"Acao: {action.upper()}")
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
                print(f"[OK] Ja existe: {target_folder}")
        else:
            if action in ["checkout", "update"]:
                print(f"[CHECKOUT] {repo_url} -> {target_folder}...", end=" ", flush=True)
                cmd = ["svn", "checkout", repo_url, str(dest_path)]
                if username:
                    cmd.extend(["--username", username])
                res = subprocess.run(cmd, capture_output=True, text=True)
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
    action = "checkout"
    args = sys.argv[1:]

    if "--update" in args:
        action = "update"
        args.remove("--update")
    elif "--status" in args:
        action = "status"
        args.remove("--status")

    if args:
        manifest = args[0]
    else:
        default_manifest = Path.home() / ".dotfiles-uerj" / "workspaces" / "svn-uerj.yaml"
        manifest = str(default_manifest)

    sync_svn_manifest(manifest, action=action)
