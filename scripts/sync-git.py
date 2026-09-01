#!/usr/bin/env python3
"""
sync-git.py
Sincroniza e clona repositorios Git organizados por manifesto YAML declarativo.

Uso:
  python3 sync-git.py [caminho_do_manifesto.yaml]
  python3 sync-git.py --update [caminho_do_manifesto.yaml]
  python3 sync-git.py --status [caminho_do_manifesto.yaml]
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

def run_git(args, cwd=None):
    return subprocess.run(["git"] + args, cwd=cwd, capture_output=True, text=True)

def sync_manifest(manifest_path, action="clone"):
    manifest_file = Path(manifest_path).expanduser().resolve()
    if not manifest_file.exists():
        print(f"[ERRO] Arquivo de manifesto nao encontrado: {manifest_file}")
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
    print(f"Acao: {action.upper()}")
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
                    print(f"[OK] Ja existe: {rel_display}")
            else:
                if action in ["clone", "update"]:
                    print(f"[CLONANDO] {git_url} -> {rel_display}...", end=" ", flush=True)
                    res = subprocess.run(["git", "clone", git_url, str(repo_path)], capture_output=True, text=True)
                    if res.returncode == 0:
                        print("OK")
                        cloned += 1
                    else:
                        err_msg = res.stderr.strip()
                        print(f"ERRO: {err_msg}")
                        errors += 1

    print("-" * 60)
    print(f"Resumo: Total: {total_repos} | Novos clonados: {cloned} | Atualizados: {updated} | Falhas: {errors}")

if __name__ == "__main__":
    action = "clone"
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
        default_manifest = Path.home() / ".dotfiles-uerj" / "workspaces" / "manifests" / "git-uerj-manifest.yaml"
        manifest = str(default_manifest)

    sync_manifest(manifest, action=action)
