"""Small desktop GUI for CPE Manager."""

from __future__ import annotations

import argparse
import json
import threading
import tkinter as tk
from tkinter import messagebox, ttk
from collections.abc import Sequence

from . import __version__
from .client import CPEError, HuaweiCPE


class CPEManagerApp(tk.Tk):
    def __init__(self) -> None:
        super().__init__()
        self.title("CPE Manager")
        self.geometry("980x680")
        self.minsize(840, 560)

        self.host_var = tk.StringVar(value="192.168.8.1")
        self.username_var = tk.StringVar(value="admin")
        self.password_var = tk.StringVar()
        self.timeout_var = tk.StringVar(value="10")
        self.raw_endpoint_var = tk.StringVar(value="/api/device/signal")
        self.status_var = tk.StringVar(value="Ready")

        self._build_layout()

    def _build_layout(self) -> None:
        root = ttk.Frame(self, padding=12)
        root.grid(row=0, column=0, sticky="nsew")
        self.columnconfigure(0, weight=1)
        self.rowconfigure(0, weight=1)
        root.columnconfigure(0, weight=1)
        root.rowconfigure(2, weight=1)

        connection = ttk.LabelFrame(root, text="Connection", padding=10)
        connection.grid(row=0, column=0, sticky="ew")
        for index in range(8):
            connection.columnconfigure(index, weight=1 if index in {1, 3, 5, 7} else 0)

        ttk.Label(connection, text="Host").grid(row=0, column=0, padx=(0, 6), sticky="w")
        ttk.Entry(connection, textvariable=self.host_var).grid(row=0, column=1, padx=(0, 12), sticky="ew")
        ttk.Label(connection, text="User").grid(row=0, column=2, padx=(0, 6), sticky="w")
        ttk.Entry(connection, textvariable=self.username_var).grid(row=0, column=3, padx=(0, 12), sticky="ew")
        ttk.Label(connection, text="Password").grid(row=0, column=4, padx=(0, 6), sticky="w")
        ttk.Entry(connection, textvariable=self.password_var, show="*").grid(row=0, column=5, padx=(0, 12), sticky="ew")
        ttk.Label(connection, text="Timeout").grid(row=0, column=6, padx=(0, 6), sticky="w")
        ttk.Entry(connection, textvariable=self.timeout_var, width=6).grid(row=0, column=7, sticky="ew")

        actions = ttk.Frame(root)
        actions.grid(row=1, column=0, sticky="ew", pady=(12, 10))
        for index in range(8):
            actions.columnconfigure(index, weight=1)

        buttons = [
            ("Login", self.login),
            ("Signal", self.signal),
            ("Snapshot JSON", self.snapshot_json),
            ("Neighbors", self.neighbors),
            ("Lock Status", self.lock_status),
            ("Bands", self.bands),
            ("Antenna", self.antenna),
            ("Auto SA+NSA", self.auto_mode),
        ]
        for index, (label, command) in enumerate(buttons):
            ttk.Button(actions, text=label, command=command).grid(
                row=0, column=index, padx=(0 if index == 0 else 6, 0), sticky="ew"
            )

        mode_actions = ttk.Frame(root)
        mode_actions.grid(row=2, column=0, sticky="new")
        for index in range(6):
            mode_actions.columnconfigure(index, weight=1)
        ttk.Button(mode_actions, text="Only 4G", command=lambda: self.set_net_mode("03")).grid(row=0, column=0, padx=(0, 6), sticky="ew")
        ttk.Button(mode_actions, text="Only 5G", command=lambda: self.set_net_mode("08")).grid(row=0, column=1, padx=(0, 6), sticky="ew")
        ttk.Button(mode_actions, text="Unlock", command=self.unlock).grid(row=0, column=2, padx=(0, 6), sticky="ew")
        ttk.Label(mode_actions, text="Raw").grid(row=0, column=3, padx=(0, 6), sticky="e")
        ttk.Entry(mode_actions, textvariable=self.raw_endpoint_var).grid(row=0, column=4, padx=(0, 6), sticky="ew")
        ttk.Button(mode_actions, text="Fetch", command=self.raw).grid(row=0, column=5, sticky="ew")

        output_frame = ttk.Frame(root)
        output_frame.grid(row=3, column=0, sticky="nsew", pady=(10, 8))
        root.rowconfigure(3, weight=1)
        output_frame.columnconfigure(0, weight=1)
        output_frame.rowconfigure(0, weight=1)

        self.output = tk.Text(output_frame, wrap="word", font=("Menlo", 12), undo=False)
        self.output.grid(row=0, column=0, sticky="nsew")
        scrollbar = ttk.Scrollbar(output_frame, orient="vertical", command=self.output.yview)
        scrollbar.grid(row=0, column=1, sticky="ns")
        self.output.configure(yscrollcommand=scrollbar.set)

        ttk.Label(root, textvariable=self.status_var).grid(row=4, column=0, sticky="ew")

    def login(self) -> None:
        self.run_task("Logging in", lambda cpe: f"登录成功: {cpe.base}")

    def signal(self) -> None:
        self.run_task("Reading signal", lambda cpe: cpe.format_status_summary())

    def snapshot_json(self) -> None:
        self.run_task(
            "Reading snapshot",
            lambda cpe: json.dumps(cpe.status_snapshot(), ensure_ascii=False, indent=2),
        )

    def neighbors(self) -> None:
        def task(cpe: HuaweiCPE) -> str:
            data = cpe.nbr_cell_info()
            return json.dumps(data, ensure_ascii=False, indent=2)

        self.run_task("Reading neighbors", task)

    def lock_status(self) -> None:
        def task(cpe: HuaweiCPE) -> str:
            return json.dumps({"lock_freq": cpe.lock_freq(), "net_mode": cpe.net_mode()}, ensure_ascii=False, indent=2)

        self.run_task("Reading lock status", task)

    def bands(self) -> None:
        self.run_task(
            "Reading supported bands",
            lambda cpe: json.dumps(cpe.band_freq_list(), ensure_ascii=False, indent=2),
        )

    def antenna(self) -> None:
        self.run_task(
            "Reading antenna",
            lambda cpe: json.dumps(cpe.antenna_type(), ensure_ascii=False, indent=2),
        )

    def auto_mode(self) -> None:
        self.run_task("Setting auto mode", lambda cpe: cpe.set_net_mode(network_mode="00", network_option="2"))

    def set_net_mode(self, mode: str) -> None:
        self.run_task(f"Setting net mode {mode}", lambda cpe: cpe.set_net_mode(network_mode=mode, network_option="2"))

    def unlock(self) -> None:
        if messagebox.askyesno("Confirm", "解除所有锁频？"):
            self.run_task("Unlocking all bands", lambda cpe: cpe.unlock_all())

    def raw(self) -> None:
        endpoint = self.raw_endpoint_var.get().strip()
        self.run_task(f"Fetching {endpoint}", lambda cpe: cpe.get_xml(endpoint))

    def run_task(self, label: str, task) -> None:
        self.status_var.set(label)
        self.set_output(f"{label}...\n")

        def worker() -> None:
            try:
                cpe = self.make_client()
                cpe.login()
                result = task(cpe)
            except (CPEError, ValueError) as exc:
                self.after(0, lambda: self.finish_task(f"错误: {exc}", ok=False))
            except Exception as exc:  # Keep GUI alive on unexpected device responses.
                self.after(0, lambda: self.finish_task(f"未知错误: {exc}", ok=False))
            else:
                self.after(0, lambda: self.finish_task(str(result), ok=True))

        threading.Thread(target=worker, daemon=True).start()

    def make_client(self) -> HuaweiCPE:
        password = self.password_var.get()
        if not password:
            raise ValueError("请输入密码")
        return HuaweiCPE(
            host=self.host_var.get().strip() or "192.168.8.1",
            username=self.username_var.get().strip() or "admin",
            password=password,
            timeout=float(self.timeout_var.get() or 10),
        )

    def set_output(self, text: str) -> None:
        self.output.delete("1.0", tk.END)
        self.output.insert(tk.END, text)

    def finish_task(self, text: str, ok: bool) -> None:
        self.set_output(text + "\n")
        self.status_var.set("Done" if ok else "Failed")


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="cpemanager-desktop",
        description="CPE Manager desktop GUI",
    )
    parser.add_argument("--version", action="version", version=f"CPE Manager {__version__}")
    parser.parse_args(argv)
    app = CPEManagerApp()
    app.mainloop()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
