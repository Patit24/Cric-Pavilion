#!/usr/bin/env python3
"""
CricPavilion Central Sync & Web Server
Provides Flutter Web static hosting and centralized multi-device JSON synchronization.
Enables real-time syncing of matches, scorecards, and tournaments across mobile and desktop.
"""

import sys
import os
import json
import mimetypes
from pathlib import Path
from http.server import SimpleHTTPRequestHandler, HTTPServer
import urllib.parse
from datetime import datetime

# Configure base paths
PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8080
BASE_DIR = Path(__file__).resolve().parent
BUILD_WEB_DIR = BASE_DIR / "build" / "web"
DATA_DIR = BASE_DIR / "data"
DB_FILE = DATA_DIR / "cricpavilion_server_db.json"

# Ensure data directory exists
DATA_DIR.mkdir(parents=True, exist_ok=True)

# MIME types
mimetypes.add_type("application/wasm", ".wasm")
mimetypes.add_type("text/javascript", ".js")
mimetypes.add_type("application/json", ".json")
mimetypes.add_type("image/svg+xml", ".svg")
mimetypes.add_type("font/ttf", ".ttf")
mimetypes.add_type("font/woff2", ".woff2")


def load_server_db():
    if not DB_FILE.exists():
        return {
            "version": 1,
            "updatedAt": datetime.now().isoformat(),
            "users": [],
            "matches": [],
            "tournaments": [],
            "teams": [],
            "players": [],
            "innings": [],
            "deliveries": [],
            "battingScorecards": [],
            "bowlingScorecards": [],
            "auditLogs": [],
        }
    try:
        with open(DB_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception as e:
        print(f"[ERROR] Failed to read {DB_FILE}: {e}")
        return {}


def save_server_db(data):
    data["updatedAt"] = datetime.now().isoformat()
    temp_file = DB_FILE.with_suffix(".tmp")
    with open(temp_file, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    temp_file.replace(DB_FILE)


def merge_list_by_id(existing_list, incoming_list, prefer_incoming=True):
    lookup = {item["id"]: item for item in existing_list if isinstance(item, dict) and "id" in item}
    for item in incoming_list:
        if not isinstance(item, dict) or "id" not in item:
            continue
        iid = item["id"]
        if iid not in lookup:
            lookup[iid] = item
        else:
            if prefer_incoming:
                merged = dict(lookup[iid])
                merged.update(item)
                lookup[iid] = merged
    return list(lookup.values())


def merge_matches(existing_matches, incoming_matches):
    lookup = {m["id"]: m for m in existing_matches if isinstance(m, dict) and "id" in m}
    for m in incoming_matches:
        if not isinstance(m, dict) or "id" not in m:
            continue
        mid = m["id"]
        if mid not in lookup:
            lookup[mid] = m
        else:
            prev = lookup[mid]
            # If incoming is completed or has later updated stage, update
            status_order = {"scheduled": 1, "toss": 2, "live": 3, "inningsBreak": 4, "completed": 5, "abandoned": 5}
            p_score = status_order.get(prev.get("status", ""), 0)
            i_score = status_order.get(m.get("status", ""), 0)
            if i_score >= p_score:
                merged = dict(prev)
                merged.update(m)
                lookup[mid] = merged
    return list(lookup.values())


def merge_database(server_db, incoming_db):
    if not isinstance(incoming_db, dict):
        return server_db

    server_db["matches"] = merge_matches(server_db.get("matches", []), incoming_db.get("matches", []))
    server_db["tournaments"] = merge_list_by_id(server_db.get("tournaments", []), incoming_db.get("tournaments", []))
    server_db["teams"] = merge_list_by_id(server_db.get("teams", []), incoming_db.get("teams", []))
    server_db["players"] = merge_list_by_id(server_db.get("players", []), incoming_db.get("players", []))
    server_db["innings"] = merge_list_by_id(server_db.get("innings", []), incoming_db.get("innings", []))
    server_db["deliveries"] = merge_list_by_id(server_db.get("deliveries", []), incoming_db.get("deliveries", []))
    server_db["battingScorecards"] = merge_list_by_id(server_db.get("battingScorecards", []), incoming_db.get("battingScorecards", []))
    server_db["bowlingScorecards"] = merge_list_by_id(server_db.get("bowlingScorecards", []), incoming_db.get("bowlingScorecards", []))
    server_db["users"] = merge_list_by_id(server_db.get("users", []), incoming_db.get("users", []))
    server_db["auditLogs"] = merge_list_by_id(server_db.get("auditLogs", []), incoming_db.get("auditLogs", []))

    save_server_db(server_db)
    return server_db


class CricPavilionHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(BUILD_WEB_DIR), **kwargs)

    def end_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS, PUT, DELETE")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Requested-With, Accept")
        self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(200)
        self.end_headers()

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path

        if path == "/api/sync" or path == "/api/export":
            db = load_server_db()
            payload = json.dumps(db, ensure_ascii=False).encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(payload)))
            self.end_headers()
            self.wfile.write(payload)
            return

        if path == "/api/status":
            db = load_server_db()
            status = {
                "status": "online",
                "updatedAt": db.get("updatedAt", datetime.now().isoformat()),
                "totalMatches": len(db.get("matches", [])),
                "totalTournaments": len(db.get("tournaments", [])),
                "totalPlayers": len(db.get("players", [])),
                "totalDeliveries": len(db.get("deliveries", [])),
            }
            payload = json.dumps(status).encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(payload)))
            self.end_headers()
            self.wfile.write(payload)
            return

        # Check if requesting a static file from build/web
        req_file = (BUILD_WEB_DIR / path.lstrip("/")).resolve()
        try:
            req_file.relative_to(BUILD_WEB_DIR)
        except ValueError:
            req_file = BUILD_WEB_DIR / "index.html"

        if not req_file.exists() or req_file.is_dir():
            if (BUILD_WEB_DIR / "index.html").exists():
                self.path = "/index.html"

        return super().do_GET()

    def do_POST(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path

        if path in ("/api/sync", "/api/import"):
            content_len = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(content_len)
            try:
                incoming_data = json.loads(body.decode("utf-8"))
            except Exception as e:
                self.send_response(400)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                self.wfile.write(json.dumps({"error": f"Invalid JSON: {e}"}).encode("utf-8"))
                return

            server_db = load_server_db()
            merged = merge_database(server_db, incoming_data)
            print(f"[SYNC] Merged incoming data: {len(merged.get('matches', []))} matches, {len(merged.get('deliveries', []))} deliveries in DB.")

            response_payload = json.dumps(merged, ensure_ascii=False).encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(response_payload)))
            self.end_headers()
            self.wfile.write(response_payload)
            return

        self.send_response(404)
        self.end_headers()


def run():
    server_address = ("", PORT)
    httpd = HTTPServer(server_address, CricPavilionHandler)
    print(f"=================================================")
    print(f" CricPavilion Multi-Device Sync Server Online")
    print(f" Port: {PORT}")
    print(f" Web Root: {BUILD_WEB_DIR}")
    print(f" Database: {DB_FILE}")
    print(f" Endpoints: /api/sync, /api/status, /api/export")
    print(f"=================================================")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        httpd.server_close()


if __name__ == "__main__":
    run()
