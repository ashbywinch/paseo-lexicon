"""Set a repository Actions secret from an environment variable.

    .tools/venv/bin/python tools/set_secret.py <owner/repo> <SECRET_NAME> <VALUE_ENV_VAR>

The value is read from the named environment variable and never printed. Encryption is the libsodium
sealed box GitHub requires, provided by PyNaCl inside the project's own venv (see `make tools`), so
the system Python is irrelevant.

With no GITHUB_TOKEN, the token from the gh CLI's hosts file is used, which is what `make secret-set`
relies on on a developer machine.
"""

from __future__ import annotations

import base64
import json
import os
import re
import sys
import urllib.error
import urllib.request

from nacl import encoding, public


def gh_token() -> str | None:
    if token := os.environ.get("GITHUB_TOKEN"):
        return token
    hosts = os.path.expanduser("~/.config/gh/hosts.yml")
    try:
        with open(hosts, encoding="utf-8") as handle:
            match = re.search(r"^\s*oauth_token:\s*(\S+)", handle.read(), re.MULTILINE)
    except OSError:
        return None
    return match.group(1).replace('"', "") if match else None


def api(path: str, data: dict | None = None, method: str | None = None) -> dict:
    body = json.dumps(data).encode() if data is not None else None
    request = urllib.request.Request(
        f"https://api.github.com{path}",
        data=body,
        method=method or ("GET" if data is None else "POST"),
    )
    request.add_header("Authorization", f"Bearer {gh_token()}")
    request.add_header("Accept", "application/vnd.github+json")
    if body is not None:
        request.add_header("Content-Type", "application/json")
    try:
        # A hung endpoint must not hang the release path: 20s is generous for one API call.
        with urllib.request.urlopen(request, timeout=20) as response:
            body = response.read()
            # A secret PUT answers 201 with no body; nothing to parse.
            return json.loads(body) if body else {}
    except urllib.error.HTTPError as error:
        detail = error.read().decode()[:200]
        raise SystemExit(f"{request.get_method()} {path} failed: {error.code} {detail}") from error
    except urllib.error.URLError as error:
        # DNS failure, refused connection, timeout: no status code to report.
        raise SystemExit(f"{request.get_method()} {path} unreachable: {error.reason}") from error


def main(argv: list[str]) -> int:
    if len(argv) != 3:
        print("usage: set_secret.py <owner/repo> <SECRET_NAME> <VALUE_ENV_VAR>", file=sys.stderr)
        return 2
    repo, secret_name, value_var = argv

    value = os.environ.get(value_var)
    if not value:
        print(f"set-secret: {value_var} is empty or unset", file=sys.stderr)
        return 2
    if not gh_token():
        print("set-secret: no GITHUB_TOKEN and no gh oauth token found", file=sys.stderr)
        return 2

    key = api(f"/repos/{repo}/actions/secrets/public-key")
    sealed = public.SealedBox(public.PublicKey(key["key"].encode(), encoding.Base64Encoder)).encrypt(
        value.encode()
    )
    api(
        f"/repos/{repo}/actions/secrets/{secret_name}",
        {"encrypted_value": base64.b64encode(sealed).decode(), "key_id": key["key_id"]},
        method="PUT",
    )
    print(f"set {secret_name} on {repo} from {value_var}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
