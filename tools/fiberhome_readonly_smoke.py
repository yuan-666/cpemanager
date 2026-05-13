"""Read-only Fiberhome CPE smoke test.

This script intentionally calls only login/session and app_get_* methods.
It never calls app_set_* methods, lock writes, reset, reboot, or airplane writes.
"""

from __future__ import annotations

import argparse
import getpass
import json
import os
from typing import Any

import requests


GET_METHODS = ("app_get_base_info", "app_get_airplane")
POST_METHODS = ("app_get_network_info", "app_get_lockband", "app_get_cell_list")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--host", default=os.getenv("CPE_HOST", "192.168.8.1"))
    parser.add_argument("--username", default=os.getenv("CPE_USERNAME", "admin"))
    parser.add_argument("--password", default=os.getenv("CPE_PASSWORD", ""))
    parser.add_argument("--timeout", type=float, default=8)
    args = parser.parse_args()

    password = args.password or getpass.getpass("Fiberhome password: ")
    base = f"http://{args.host.strip().removeprefix('http://').removeprefix('https://').rstrip('/')}"

    session = requests.Session()
    session.trust_env = False
    session.headers.update(
        {
            "Accept": "application/json, text/javascript, */*; q=0.01",
            "Referer": f"{base}/main.html",
            "User-Agent": "Mozilla/5.0 CPEManager-smoke",
            "Accept-Language": "zh-CN,en,*",
        }
    )

    sid = refresh_session(session, base, args.timeout)
    print_result("get_refresh_sessionid", 200, {"sessionid": mask(sid)})

    login_data = post_tool(
        session,
        base,
        args.timeout,
        sid,
        "app_do_login",
        {"username": args.username, "password": password},
    )
    sid = str(login_data.get("sessionid") or sid)
    print_result("app_do_login", 200, scrub(login_data | {"sessionid": mask(sid)}))

    failures = 0
    for method in GET_METHODS:
        try:
            data = get_tool(session, base, args.timeout, sid, method)
            print_result(method, 200, summarize(data))
        except requests.HTTPError as exc:
            failures += 1
            print_result(method, exc.response.status_code, exc.response.text)

    for method in POST_METHODS:
        try:
            sid = refresh_session(session, base, args.timeout)
            data = post_tool(session, base, args.timeout, sid, method, None)
            print_result(method, 200, summarize(data))
        except requests.HTTPError as exc:
            failures += 1
            print_result(method, exc.response.status_code, exc.response.text)

    return 1 if failures else 0


def refresh_session(session: requests.Session, base: str, timeout: float) -> str:
    response = session.get(
        f"{base}/api/tmp/FHNCAPIS?ajaxmethod=get_refresh_sessionid",
        timeout=timeout,
    )
    response.raise_for_status()
    sid = response.json().get("sessionid", "")
    if not sid:
        raise RuntimeError(f"get_refresh_sessionid did not return sessionid: {response.text}")
    return str(sid)


def get_tool(
    session: requests.Session,
    base: str,
    timeout: float,
    sid: str,
    method: str,
) -> dict[str, Any]:
    response = session.get(
        f"{base}/api/tmp/FHTOOLAPIS",
        params={"ajaxmethod": method, "sessionid": sid},
        timeout=timeout,
    )
    response.raise_for_status()
    return response.json()


def post_tool(
    session: requests.Session,
    base: str,
    timeout: float,
    sid: str,
    method: str,
    data_obj: Any,
) -> dict[str, Any]:
    payload = {
        "dataObj": data_obj,
        "ajaxmethod": method,
        "sessionid": sid,
    }
    body = json.dumps(payload, separators=(",", ":"))
    response = session.post(
        f"{base}/api/tmp/FHTOOLAPIS",
        data=body,
        headers={"Content-Type": "application/json"},
        timeout=timeout,
    )
    response.raise_for_status()
    return response.json() if response.text.strip() else {}


def summarize(data: dict[str, Any]) -> dict[str, Any]:
    if "timeout" in data:
        return data
    keys = list(data)[:12]
    result = {key: scrub_value(data[key]) for key in keys}
    if len(data) > len(keys):
        result["..."] = f"{len(data) - len(keys)} more keys"
    return result


def scrub(data: dict[str, Any]) -> dict[str, Any]:
    return {key: scrub_value(value) for key, value in data.items()}


def scrub_value(value: Any) -> Any:
    if isinstance(value, str) and len(value) >= 24:
        return mask(value)
    return value


def mask(value: str) -> str:
    if len(value) <= 8:
        return "***"
    return f"{value[:4]}...{value[-4:]}"


def print_result(method: str, status: int, data: dict[str, Any] | str) -> None:
    if isinstance(data, str):
        print(f"{method}: HTTP {status} {data[:160]}")
        return
    print(f"{method}: HTTP {status} {json.dumps(data, ensure_ascii=False)}")


if __name__ == "__main__":
    raise SystemExit(main())
