"""Command-line interface for CPE Manager."""

from __future__ import annotations

import argparse
import getpass
import json
import os
import sys
from collections.abc import Sequence

from . import endpoints
from .client import CPEError, HuaweiCPE, _rsrp_sort_key


def main(argv: Sequence[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    if not hasattr(args, "handler"):
        parser.print_help()
        return 2
    try:
        return args.handler(args)
    except CPEError as exc:
        print(f"错误: {exc}", file=sys.stderr)
        return 1


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="cpemanager",
        description="华为 CPE 管理工具",
    )
    subparsers = parser.add_subparsers(dest="command")

    register_login(subparsers)
    register_signal(subparsers)
    register_nbr(subparsers)
    register_netmode(subparsers)
    register_antenna(subparsers)
    register_lock(subparsers)
    register_raw(subparsers)
    return parser


def add_common(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--host", default="192.168.8.1", help="CPE 地址，默认 192.168.8.1")
    parser.add_argument("--username", default="admin", help="登录用户名，默认 admin")
    parser.add_argument("--password", default="", help="登录密码；也可用 CPE_PASSWORD 环境变量")
    parser.add_argument("--timeout", type=float, default=10, help="请求超时时间，单位秒")


def register_login(subparsers) -> None:
    parser = subparsers.add_parser("login", help="测试登录")
    add_common(parser)
    parser.set_defaults(handler=handle_login)


def register_signal(subparsers) -> None:
    parser = subparsers.add_parser("signal", help="查看信号、流量和设备状态")
    add_common(parser)
    parser.add_argument("--json", action="store_true", help="输出 JSON")
    parser.set_defaults(handler=handle_signal)


def register_nbr(subparsers) -> None:
    parser = subparsers.add_parser("nbr", help="查看 LTE/NR 邻区")
    add_common(parser)
    parser.add_argument("--json", action="store_true", help="输出 JSON")
    parser.set_defaults(handler=handle_nbr)


def register_netmode(subparsers) -> None:
    parser = subparsers.add_parser("netmode", help="查看或设置网络模式")
    add_common(parser)
    parser.add_argument("--net-mode", default="", help="网络模式：00=自动，03=仅4G，08=仅5G")
    parser.add_argument("--net-option", default="", help="网络首选：0=NSA，1=SA，2=SA+NSA")
    parser.add_argument("--lte-bands-hex", default="7FFFFFFFFFFFFFFF", help="LTEBand 十六进制掩码")
    parser.add_argument("--network-band-hex", default="3FFFFFFF", help="NetworkBand 十六进制掩码")
    parser.add_argument("--auto-mode", action="store_true", help="恢复自动+SA+NSA")
    parser.set_defaults(handler=handle_netmode)


def register_antenna(subparsers) -> None:
    parser = subparsers.add_parser("antenna", help="查看或设置天线类型")
    add_common(parser)
    parser.add_argument(
        "--set",
        "--antenna",
        dest="antenna",
        default="",
        help="天线类型：0=自动，1=外置，2=内置，3=混合",
    )
    parser.set_defaults(handler=handle_antenna)


def register_lock(subparsers) -> None:
    parser = subparsers.add_parser("lock", help="查看或设置锁频")
    add_common(parser)
    parser.add_argument("--nr-band", default="", help="NR 锁 band，逗号分隔，如 41,78")
    parser.add_argument("--nr-arfcn", default="", help="NR 锁 ARFCN，如 78:633984")
    parser.add_argument("--nr-pci", default="", help="NR 锁 PCI，如 78:633984:360")
    parser.add_argument("--lte-band", default="", help="LTE 锁 band，逗号分隔，如 1,3,28")
    parser.add_argument("--lte-arfcn", default="", help="LTE 锁 ARFCN，如 1:100")
    parser.add_argument("--lte-pci", default="", help="LTE 锁 PCI，如 1:100:308")
    parser.add_argument("--mix-band", nargs=2, metavar=("NR_BANDS", "LTE_BANDS"), help="混合锁 NR/LTE")
    parser.add_argument("--unlock", action="store_true", help="解除所有锁频")
    parser.add_argument("--bands", action="store_true", help="查看可锁频段列表")
    parser.set_defaults(handler=handle_lock)


def register_raw(subparsers) -> None:
    parser = subparsers.add_parser("raw", help="登录后读取一个原始 API endpoint")
    add_common(parser)
    parser.add_argument("endpoint", help="要读取的 endpoint，可传 /api/... 或完整 http URL")
    parser.set_defaults(handler=handle_raw)


def client_from_args(args) -> HuaweiCPE:
    password = args.password or os.environ.get("CPE_PASSWORD", "")
    if not password:
        password = getpass.getpass("密码: ").strip()
    return HuaweiCPE(
        host=args.host,
        username=args.username,
        password=password,
        timeout=args.timeout,
    )


def login_client(args) -> HuaweiCPE:
    cpe = client_from_args(args)
    cpe.login()
    return cpe


def handle_login(args) -> int:
    cpe = login_client(args)
    print(f"登录成功: {cpe.base}")
    return 0


def handle_signal(args) -> int:
    cpe = login_client(args)
    if args.json:
        print(json.dumps(cpe.status_snapshot(), ensure_ascii=False, indent=2))
    else:
        print(cpe.format_status_summary())
    return 0


def handle_nbr(args) -> int:
    cpe = login_client(args)
    nbr = cpe.nbr_cell_info()
    sig = cpe.device_signal()
    if args.json:
        print(json.dumps({"nbr_cell": nbr, "signal": sig}, ensure_ascii=False, indent=2))
        return 0

    print("\n--- LTE 邻区 ---")
    print_cells(nbr["lte"])
    print("\n--- NR 邻区 (按RSRP排序) ---")
    print_cells(nbr["nr"])
    print(f"\n当前服务 NR PCI: {sig.get('pci', 'N/A')}")
    return 0


def handle_netmode(args) -> int:
    cpe = login_client(args)
    should_set = args.auto_mode or args.net_mode or args.net_option
    if should_set:
        network_mode = "00" if args.auto_mode else (args.net_mode or "00")
        network_option = "2" if args.auto_mode else (args.net_option or "2")
        print(f"NetworkMode={network_mode} networkOption={network_option}")
        print(
            cpe.set_net_mode(
                network_mode=network_mode,
                network_option=network_option,
                lte_bands_hex=args.lte_bands_hex,
                network_band_hex=args.network_band_hex,
            )
        )
        return 0

    mode = cpe.net_mode()
    print("\n--- 网络模式 ---")
    print(f"  NetworkMode: {mode.get('NetworkMode', 'N/A')}")
    print(f"  NetworkBand: {mode.get('NetworkBand', 'N/A')}")
    print(f"  LTEBand: {mode.get('LTEBand', 'N/A')}")
    print(f"  networkOption: {mode.get('networkOption', 'N/A')}")
    return 0


def handle_antenna(args) -> int:
    cpe = login_client(args)
    if args.antenna:
        print(cpe.antenna_set_type(args.antenna))
        return 0

    antenna = cpe.antenna_type()
    print("\n--- 天线配置 ---")
    print(f"  天线1类型: {antenna.get('antenna1type', 'N/A')} (插入状态: {antenna.get('antenna1insertstatus', 'N/A')})")
    print(f"  天线2类型: {antenna.get('antenna2type', 'N/A')} (插入状态: {antenna.get('antenna2insertstatus', 'N/A')})")
    return 0


def handle_lock(args) -> int:
    cpe = login_client(args)
    if args.unlock:
        print(cpe.unlock_all())
    elif args.nr_band:
        print(cpe.lock_nr_band(args.nr_band))
    elif args.nr_arfcn:
        band, freq = split_exact(args.nr_arfcn, 2, "--nr-arfcn")
        print(cpe.lock_nr_arfcn(band, freq))
    elif args.nr_pci:
        band, freq, pci = split_exact(args.nr_pci, 3, "--nr-pci")
        print(cpe.lock_nr_pci(band, freq, pci))
    elif args.lte_band:
        print(cpe.lock_lte_band(args.lte_band))
    elif args.lte_arfcn:
        band, freq = split_exact(args.lte_arfcn, 2, "--lte-arfcn")
        print(cpe.lock_lte_arfcn(band, freq))
    elif args.lte_pci:
        band, freq, pci = split_exact(args.lte_pci, 3, "--lte-pci")
        print(cpe.lock_lte_pci(band, freq, pci))
    elif args.mix_band:
        nr, lte = args.mix_band
        print(cpe.lock_nr_lte_band(nr, lte))
    elif args.bands:
        print_band_freq_list(cpe)
    else:
        print_lock_status(cpe)
    return 0


def handle_raw(args) -> int:
    cpe = login_client(args)
    print(cpe.get_xml(normalize_raw_endpoint(args.endpoint)))
    return 0


def normalize_raw_endpoint(endpoint: str) -> str:
    if endpoint in endpoints.READ_ENDPOINTS:
        return endpoint
    if endpoint.startswith("http://") or endpoint.startswith("https://"):
        return endpoint
    raise CPEError(f"未知或不支持的读取 endpoint: {endpoint}")


def split_exact(value: str, count: int, option: str) -> list[str]:
    parts = value.split(":")
    if len(parts) != count:
        raise CPEError(f"{option} 格式错误: {value}")
    return parts


def print_cells(cells: list[dict[str, str]]) -> None:
    if not cells:
        print("  (无)")
        return
    for cell in sorted(cells, key=_rsrp_sort_key, reverse=True):
        print(
            "  PCI={pci} EARFCN={earfcn} BAND={band} "
            "RSRP={rsrp} RSRQ={rsrq} SINR={sinr}".format(**cell)
        )


def print_band_freq_list(cpe: HuaweiCPE) -> None:
    band_list = cpe.band_freq_list()
    print("\n--- 支持频段 ---")
    print(f"LTE ({band_list['lte_support']}):")
    for band in band_list["lte_bands"]:
        print(f"  band{band['band']}: {band['freq']}")
    print(f"\nNR ({band_list['nr_support']}):")
    for band in band_list["nr_bands"]:
        print(f"  band{band['band']}: {band['freq']}")


def print_lock_status(cpe: HuaweiCPE) -> None:
    lock_freq = cpe.lock_freq()
    print("\n--- 锁频配置 ---")
    print(f"  NR lock_mode: {lock_freq['nr_lock_mode']}  bands: {lock_freq['nr_bands']}")
    print(f"  LTE lock_mode: {lock_freq['lte_lock_mode']}  bands: {lock_freq['lte_bands']}")
    mode = cpe.net_mode()
    print("\n--- 网络模式 ---")
    print(f"  NetworkMode: {mode.get('NetworkMode', 'N/A')}")
    lte_hex = mode.get("LTEBand", "")
    if lte_hex:
        print(f"  LTEBand(hex): {lte_hex} -> bands: {HuaweiCPE.hex_to_bands(lte_hex)}")


if __name__ == "__main__":
    raise SystemExit(main())
