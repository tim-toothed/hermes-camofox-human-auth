"""Hermes plugin for the local Camofox + noVNC distribution."""
from __future__ import annotations

import json
import os
from urllib.parse import urlsplit, urlunsplit
from urllib.request import urlopen


def _base_url() -> str:
    return os.getenv("CAMOFOX_URL", "http://127.0.0.1:9378").rstrip("/")


def _novnc_url() -> str:
    explicit = os.getenv("CAMOFOX_NOVNC_PUBLIC_URL", "").strip()
    if explicit:
        return explicit.rstrip("/") + "/vnc.html"
    parsed = urlsplit(_base_url())
    host = parsed.hostname or "127.0.0.1"
    port = os.getenv("CAMOFOX_NOVNC_PORT", "6089")
    return urlunsplit((parsed.scheme or "http", f"{host}:{port}", "/vnc.html", "", ""))


def _status(_args=None, **_kwargs):
    result = {"camofox_url": _base_url(), "novnc_url": _novnc_url(), "api_ok": False, "browser_connected": False, "ready": False}
    try:
        with urlopen(_base_url() + "/health", timeout=3) as response:
            result["health"] = json.loads(response.read().decode("utf-8"))
            result["api_ok"] = bool(result["health"].get("ok"))
            result["browser_connected"] = bool(result["health"].get("browserConnected"))
            result["ready"] = result["api_ok"] and result["browser_connected"]
    except Exception as exc:
        result["error"] = f"Camofox is unavailable: {exc}"
    return json.dumps(result, ensure_ascii=False)


def register(ctx) -> None:
    ctx.register_tool(
        name="camofox_vnc_status",
        toolset="browser",
        schema={
            "name": "camofox_vnc_status",
            "description": "Check the local Camofox Docker backend and return the noVNC URL for user-managed login.",
            "parameters": {"type": "object", "properties": {}, "additionalProperties": False},
        },
        handler=_status,
        check_fn=lambda: True,
        description="Check Camofox Docker/noVNC status and obtain the interactive login URL.",
        emoji="🦊",
    )
