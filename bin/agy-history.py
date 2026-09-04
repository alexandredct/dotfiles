#!/usr/bin/env python3
import os
import sys
import glob
import json
import argparse
from datetime import datetime

BRAIN_DIR = os.path.expanduser("~/.gemini/antigravity-ide/brain")

def get_conversations(query=None):
    results = []
    if not os.path.isdir(BRAIN_DIR):
        return results

    for path in glob.glob(os.path.join(BRAIN_DIR, "*")):
        transcript_path = os.path.join(path, ".system_generated", "logs", "transcript.jsonl")
        if not os.path.isfile(transcript_path):
            continue

        conv_id = os.path.basename(path)
        mtime = os.path.getmtime(path)
        created_at = None
        user_requests = []
        full_text_matches = False
        active_doc = ""

        try:
            with open(transcript_path, "r", encoding="utf-8", errors="ignore") as f:
                for line in f:
                    if query and query.lower() in line.lower():
                        full_text_matches = True
                    if not active_doc and "Active Document:" in line:
                        try:
                            active_doc = line.split("Active Document:")[1].split("(")[0].strip()
                        except Exception:
                            pass
                    try:
                        data = json.loads(line)
                        if not created_at and "created_at" in data:
                            created_at = data["created_at"]
                        if data.get("type") == "USER_INPUT":
                            content = data.get("content", "")
                            if "<USER_REQUEST>" in content:
                                req = content.split("<USER_REQUEST>")[1].split("</USER_REQUEST>")[0].strip()
                            else:
                                req = content.strip()
                            if req:
                                user_requests.append(req)
                    except Exception:
                        pass
        except Exception:
            continue

        if query and not full_text_matches:
            continue

        first_req = user_requests[0] if user_requests else "(Sem mensagem inicial)"
        date_str = ""
        if created_at:
            try:
                dt = datetime.fromisoformat(created_at.replace("Z", "+00:00"))
                date_str = dt.astimezone().strftime("%Y-%m-%d %H:%M")
            except Exception:
                date_str = created_at[:16]
        else:
            date_str = datetime.fromtimestamp(mtime).strftime("%Y-%m-%d %H:%M")

        results.append({
            "id": conv_id,
            "path": path,
            "mtime": mtime,
            "date": date_str,
            "first_req": first_req,
            "active_doc": active_doc,
            "requests": user_requests
        })

    results.sort(key=lambda x: x["mtime"], reverse=True)
    return results

def show_conversation(conv_id):
    conv_dir = os.path.join(BRAIN_DIR, conv_id)
    if not os.path.isdir(conv_dir):
        cands = glob.glob(os.path.join(BRAIN_DIR, f"{conv_id}*"))
        if cands:
            conv_dir = cands[0]
            conv_id = os.path.basename(conv_dir)
        else:
            print(f"\033[1;31mConversa {conv_id} não encontrada.\033[0m")
            return 1

    transcript_path = os.path.join(conv_dir, ".system_generated", "logs", "transcript.jsonl")
    print(f"\033[1;34m=== Conversa: {conv_id} ===\033[0m")
    print(f"Diretório: {conv_dir}\n")

    plans = glob.glob(os.path.join(conv_dir, "*.md"))
    if plans:
        print("\033[1;33mArtefatos disponíveis:\033[0m")
        for p in plans:
            print(f"  - {os.path.basename(p)}")
        print()

    print("\033[1;32mMensagens do Usuário:\033[0m")
    idx = 1
    if os.path.isfile(transcript_path):
        with open(transcript_path, "r", encoding="utf-8", errors="ignore") as f:
            for line in f:
                try:
                    data = json.loads(line)
                    if data.get("type") == "USER_INPUT":
                        content = data.get("content", "")
                        req = content
                        if "<USER_REQUEST>" in content:
                            req = content.split("<USER_REQUEST>")[1].split("</USER_REQUEST>")[0].strip()
                        c_date = data.get("created_at", "")
                        print(f"\n\033[1;36m[{idx}] ({c_date}):\033[0m")
                        print(req)
                        idx += 1
                except Exception:
                    pass

def main():
    parser = argparse.ArgumentParser(description="Consulta histórico do Antigravity IDE")
    parser.add_argument("query", nargs="?", default=None, help="Termo de busca")
    parser.add_argument("-s", "--show", metavar="ID", help="Exibe mensagens completas da conversa")
    parser.add_argument("-p", "--path", metavar="ID", help="Imprime o caminho absoluto da conversa")
    parser.add_argument("-n", "--limit", type=int, default=25, help="Limite de listagem (padrão: 25)")
    parser.add_argument("--fzf-lines", action="store_true", help="Gera linhas tabulares para fzf")

    args = parser.parse_args()

    if args.show:
        return show_conversation(args.show)

    if args.path:
        conv_dir = os.path.join(BRAIN_DIR, args.path)
        if not os.path.isdir(conv_dir):
            cands = glob.glob(os.path.join(BRAIN_DIR, f"{args.path}*"))
            if cands:
                conv_dir = cands[0]
        print(conv_dir)
        return 0

    convs = get_conversations(args.query)
    if not convs:
        if not args.fzf_lines:
            if args.query:
                print(f"Nenhuma conversa encontrada contendo '{args.query}'.")
            else:
                print("Nenhuma conversa encontrada.")
        return 0

    if args.fzf_lines:
        for c in convs:
            summary = " ".join(c["first_req"].split())
            print(f"{c['date']} | {c['id']} | {summary}")
        return 0

    header = f"{'DATA':<16} | {'ID':<36} | {'RESUMO / PRIMEIRO PROMPT'}"
    print(f"\033[1;34m{header}\033[0m")
    print("-" * 110)

    for c in convs[:args.limit]:
        summary = " ".join(c["first_req"].split())
        if len(summary) > 52:
            summary = summary[:49] + "..."
        print(f"\033[1;32m{c['date']:<16}\033[0m | \033[1;33m{c['id']:<36}\033[0m | {summary}")

if __name__ == "__main__":
    main()
