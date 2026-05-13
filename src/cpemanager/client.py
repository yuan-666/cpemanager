"""Reusable Huawei CPE API client."""

from __future__ import annotations

import hashlib
import hmac
import secrets
from dataclasses import dataclass
from urllib.parse import urlparse

import requests

from . import endpoints
from .xmlutil import XMLParseError, join_xml, parse_flat, parse_root, tag_text, xml_text


class CPEError(RuntimeError):
    """Base exception for CPE manager failures."""


class LoginError(CPEError):
    """Raised when the CPE login flow fails."""


@dataclass(frozen=True)
class CellInfo:
    earfcn: str
    band: str
    pci: str
    rsrp: str
    rsrq: str
    rssi: str
    sinr: str
    bw: str = ""

    def as_dict(self) -> dict[str, str]:
        data = {
            "earfcn": self.earfcn,
            "band": self.band,
            "pci": self.pci,
            "rsrp": self.rsrp,
            "rsrq": self.rsrq,
            "rssi": self.rssi,
            "sinr": self.sinr,
        }
        if self.bw:
            data["bw"] = self.bw
        return data


class HuaweiCPE:
    def __init__(
        self,
        host: str = "192.168.8.1",
        username: str = "admin",
        password: str = "",
        timeout: float = 10,
    ) -> None:
        parsed = urlparse(host if "://" in host else f"http://{host}")
        if not parsed.hostname:
            raise ValueError(f"Invalid host: {host}")
        self.base = f"{parsed.scheme}://{parsed.netloc}".rstrip("/")
        self.host = parsed.netloc
        self.username = username
        self.password = password
        self.timeout = timeout
        self.logged_in = False
        self.session = requests.Session()
        # Local CPE addresses must bypass desktop HTTP proxy environment vars.
        self.session.trust_env = False
        self.session.headers.update(
            {
                "User-Agent": (
                    "Dalvik/2.1.0 (Linux; U; Android 13; "
                    "M2012K11AC Build/TKQ1.221114.001)"
                ),
                "Referer": f"{self.base}/?origin=cpemanager",
                "X-Requested-With": "XMLHttpRequest",
                "Cache-Control": "no-cache",
                "Pragma": "no-cache",
            }
        )

    @property
    def session_id(self) -> str:
        cookie = self.session.cookies.get("SessionID", domain=self.host, path="/")
        if cookie:
            return cookie
        return self.session.cookies.get("SessionID", "")

    def login(self) -> bool:
        try:
            try:
                self._request("GET", "/html/content.html")
            except requests.RequestException:
                self._request("GET", "/")
            try:
                self._request("GET", "/api/user/state-login")
            except requests.RequestException:
                self._request("GET", endpoints.STATUS)
            initial_session = self.session_id

            self.session.headers["__RequestVerificationToken"] = self.request_token()
            initial_session = self.session_id
            if not initial_session:
                raise LoginError("无法获取初始 SessionID")
            first_nonce = secrets.token_hex(32)
            challenge = self._request(
                "POST",
                endpoints.CHALLENGE_LOGIN,
                data=(
                    "<request>"
                    f"<username>{xml_text(self.username)}</username>"
                    f"<firstnonce>{first_nonce}</firstnonce>"
                    "<mode>1</mode><loginflag>2</loginflag>"
                    "</request>"
                ),
                headers=self._xml_headers(),
            )
            self._raise_for_api_code(challenge.text, "challenge_login")
            try:
                self.session.headers["__RequestVerificationToken"] = self.request_token()
            except CPEError:
                pass
            challenge_root = parse_root(challenge.text)
            salt = tag_text(challenge_root, "salt")
            iterations_text = tag_text(challenge_root, "iterations")
            server_nonce = tag_text(challenge_root, "servernonce")
            if not salt or not iterations_text or not server_nonce:
                raise LoginError("登录挑战响应缺少 salt/iterations/servernonce")

            token = challenge.headers.get("__RequestVerificationToken")
            if token:
                self.session.headers["__RequestVerificationToken"] = token

            client_proof = self.compute_client_proof(
                self.password,
                first_nonce,
                salt,
                int(iterations_text),
                server_nonce,
            )
            auth = self._request(
                "POST",
                endpoints.AUTHENTICATION_LOGIN,
                data=(
                    "<request>"
                    f"<clientproof>{client_proof}</clientproof>"
                    f"<finalnonce>{xml_text(server_nonce)}</finalnonce>"
                    "<loginflag>2</loginflag>"
                    "</request>"
                ),
                headers=self._xml_headers(),
            )
            self._raise_for_api_code(auth.text, "authentication_login")
            if not self.session_id:
                raise LoginError("认证完成后未获取到 SessionID")
            self.logged_in = True
            return True
        except (requests.RequestException, XMLParseError, ValueError) as exc:
            raise LoginError(f"登录失败: {exc}") from exc

    @staticmethod
    def compute_client_proof(
        password: str,
        first_nonce: str,
        salt_hex: str,
        iterations: int,
        server_nonce: str,
    ) -> str:
        salt = bytes.fromhex(salt_hex)
        salted_password = hashlib.pbkdf2_hmac(
            "sha256", password.encode(), salt, iterations
        )
        client_key = hmac.new(b"Client Key", salted_password, hashlib.sha256).digest()
        stored_key = hashlib.sha256(client_key).digest()
        signature = hmac.new(
            f"{first_nonce},{server_nonce},{server_nonce}".encode(),
            stored_key,
            hashlib.sha256,
        ).digest()
        return bytes(a ^ b for a, b in zip(client_key, signature)).hex()

    def request_token(self) -> str:
        try:
            response = self._request("GET", endpoints.SES_TOK_INFO)
            root = parse_root(response.text)
            session_id = tag_text(root, "SesInfo")
            token = tag_text(root, "TokInfo")
            if session_id:
                self.session.cookies.set("SessionID", session_id, path="/")
            if token:
                return token
        except (requests.RequestException, XMLParseError):
            pass
        response = self._request("GET", endpoints.TOKEN)
        root = parse_root(response.text)
        token = tag_text(root, "token")
        if not token:
            raise CPEError("无法获取请求 token")
        return token[32:] if len(token) > 32 else token

    def device_info(self) -> dict[str, str]:
        return self.get_flat(endpoints.BASIC_INFORMATION)

    def device_signal(self) -> dict[str, str]:
        return self.get_flat(endpoints.SIGNAL)

    def monitoring_status(self) -> dict[str, str]:
        return self.get_flat(endpoints.STATUS)

    def traffic_statistics(self) -> dict[str, str]:
        return self.get_flat(endpoints.TRAFFIC_STATISTICS)

    def current_plmn(self) -> dict[str, str]:
        return self.get_flat(endpoints.CURRENT_PLMN)

    def sec_cell_info(self) -> dict[str, list[dict[str, str]]]:
        data = self.get_flat(endpoints.SEC_CELL_INFO)
        return {
            "nr": self.parse_cell_list(data.get("nrseccell_list", ""), is_sec_cell=True),
            "lte": self.parse_cell_list(data.get("lteseccell_list", ""), is_sec_cell=True),
        }

    def nbr_cell_info(self) -> dict[str, list[dict[str, str]]]:
        data = self.get_flat(endpoints.NBR_CELL_INFO)
        return {
            "nr": self.parse_cell_list(data.get("nbrcell_nrlist", "")),
            "lte": self.parse_cell_list(data.get("nbrcell_ltelist", "")),
        }

    def status_snapshot(self) -> dict[str, object]:
        return {
            "device": self.device_info(),
            "signal": self.device_signal(),
            "plmn": self.current_plmn(),
            "sec_cell": self.sec_cell_info(),
            "nbr_cell": self.nbr_cell_info(),
            "traffic": self.traffic_statistics(),
            "status": self.monitoring_status(),
        }

    def antenna_type(self) -> dict[str, str]:
        return self.get_flat(endpoints.ANTENNA_TYPE)

    def antenna_set_type(self, type_value: str) -> str:
        body = (
            '<?xml version="1.0" encoding="UTF-8"?>'
            "<request>"
            f"<antennasettype>{xml_text(type_value)}</antennasettype>"
            "</request>"
        )
        return self.post_xml(endpoints.ANTENNA_SET_TYPE, body)

    def net_mode(self) -> dict[str, str]:
        return self.get_flat(endpoints.NET_MODE)

    def set_net_mode(
        self,
        network_mode: str = "00",
        lte_bands_hex: str = "7FFFFFFFFFFFFFFF",
        network_band_hex: str = "3FFFFFFF",
        network_option: str = "",
    ) -> str:
        body = (
            "<request>"
            f"<NetworkMode>{xml_text(network_mode)}</NetworkMode>"
            f"<NetworkBand>{xml_text(network_band_hex)}</NetworkBand>"
            f"<LTEBand>{xml_text(lte_bands_hex)}</LTEBand>"
        )
        if network_option:
            body += f"<networkOption>{xml_text(network_option)}</networkOption>"
        body += "</request>"
        return self.post_xml(endpoints.NET_MODE, body)

    def lock_freq(self) -> dict[str, object]:
        root = parse_root(self.get_xml(endpoints.LOCK_FREQ))
        result: dict[str, object] = {
            "lte_lock_mode": "",
            "lte_bands": [],
            "nr_lock_mode": "",
            "nr_bands": [],
        }
        for prefix, tag in (("lte", "lte_info"), ("nr", "nr_info")):
            section = root.find(f".//{tag}")
            result[f"{prefix}_lock_mode"] = tag_text(section, "lock_mode")
            result[f"{prefix}_bands"] = [
                tag_text(freq_info, "band")
                for freq_info in section.findall(".//freq_info")
                if tag_text(freq_info, "band")
            ] if section is not None else []
        return result

    def band_freq_list(self) -> dict[str, object]:
        root = parse_root(self.get_xml(endpoints.BAND_FREQ_LIST))
        return {
            "lte_bands": self._parse_supported_bands(root.find(".//lte_mode")),
            "nr_bands": self._parse_supported_bands(root.find(".//nr_mode")),
            "lte_support": tag_text(root, "lte_support_band_list"),
            "nr_support": tag_text(root, "nr_support_band_list"),
        }

    @staticmethod
    def hex_to_bands(hex_str: str) -> list[int]:
        if not hex_str:
            return []
        mask = int(hex_str, 16)
        bands: list[int] = []
        bit = 0
        while mask:
            if mask & 1:
                bands.append(bit + 1)
            mask >>= 1
            bit += 1
        return bands

    def lock_nr_band(self, bands: str) -> str:
        return self._post_lock_freq(self._build_lock_info("0"), self._build_lock_info("3", bands))

    def lock_nr_arfcn(self, band: str, freq: str) -> str:
        return self._post_lock_freq(self._build_lock_info("0"), self._build_lock_info("1", band, freq=freq))

    def lock_nr_pci(self, band: str, freq: str, pci: str) -> str:
        return self._post_lock_freq(self._build_lock_info("0"), self._build_lock_info("2", band, freq=freq, pci=pci))

    def lock_lte_band(self, bands: str) -> str:
        return self._post_lock_freq(self._build_lock_info("3", bands), self._build_lock_info("0"))

    def lock_lte_arfcn(self, band: str, freq: str) -> str:
        return self._post_lock_freq(self._build_lock_info("1", band, freq=freq), self._build_lock_info("0"))

    def lock_lte_pci(self, band: str, freq: str, pci: str) -> str:
        return self._post_lock_freq(self._build_lock_info("2", band, freq=freq, pci=pci), self._build_lock_info("0"))

    def lock_nr_lte_band(self, nr_bands: str, lte_bands: str) -> str:
        return self._post_lock_freq(
            self._build_lock_info("3", lte_bands) if lte_bands else self._build_lock_info("0"),
            self._build_lock_info("3", nr_bands) if nr_bands else self._build_lock_info("0"),
        )

    def unlock_all(self) -> str:
        return self._post_lock_freq(self._build_lock_info("0"), self._build_lock_info("0"))

    def get_xml(self, endpoint: str) -> str:
        return self._request("GET", endpoint).text

    def get_flat(self, endpoint: str) -> dict[str, str]:
        return parse_flat(self.get_xml(endpoint))

    def post_xml(self, endpoint: str, body: str) -> str:
        headers = self._xml_headers({"__RequestVerificationToken": self.request_token()})
        return self._request("POST", endpoint, data=body, headers=headers).text

    def _post_lock_freq(self, lte_info: str, nr_info: str) -> str:
        body = (
            '<?xml version="1.0" encoding="UTF-8"?>'
            "<request>"
            f"<lte_info>{lte_info}</lte_info>"
            f"<nr_info>{nr_info}</nr_info>"
            "</request>"
        )
        return self.post_xml(endpoints.LOCK_FREQ, body)

    def _build_lock_info(
        self, lock_mode: str, bands: str = "", freq: str = "", pci: str = ""
    ) -> str:
        if lock_mode == "0":
            return "<lock_mode>0</lock_mode><freq_infos></freq_infos><all_bands></all_bands>"

        bands_list = [band.strip() for band in bands.split(",") if band.strip()]
        freq_infos: list[str] = []
        for band in bands_list:
            info = [f"<freq_info><band>{xml_text(band)}</band>"]
            if freq:
                info.append(f"<freq>{xml_text(freq)}</freq>")
            if pci:
                info.append(f"<pci>{xml_text(pci)}</pci>")
            info.append("</freq_info>")
            freq_infos.append(join_xml(info))

        return (
            f"<lock_mode>{xml_text(lock_mode)}</lock_mode>"
            f"<freq_infos>{join_xml(freq_infos)}</freq_infos>"
            f"<all_bands>{xml_text(','.join(bands_list))}</all_bands>"
        )

    @staticmethod
    def parse_cell_list(text: str, is_sec_cell: bool = False) -> list[dict[str, str]]:
        if not text:
            return []
        cells: list[dict[str, str]] = []
        for item in text.split(";"):
            parts = [part.strip() for part in item.split(",")]
            if is_sec_cell and len(parts) >= 8:
                cells.append(
                    CellInfo(
                        earfcn=parts[0],
                        band=parts[1],
                        bw=parts[2],
                        pci=parts[3],
                        rsrp=parts[4],
                        rsrq=parts[5],
                        rssi=parts[6],
                        sinr=parts[7],
                    ).as_dict()
                )
            elif not is_sec_cell and len(parts) >= 7:
                cells.append(
                    CellInfo(
                        earfcn=parts[0],
                        band=parts[1],
                        pci=parts[2],
                        rsrp=parts[3],
                        rsrq=parts[4],
                        rssi=parts[5],
                        sinr=parts[6],
                    ).as_dict()
                )
        return cells

    @staticmethod
    def format_bytes(value: int) -> str:
        if value >= 1_073_741_824:
            return f"{value / 1_073_741_824:.2f} GB"
        if value >= 1_048_576:
            return f"{value / 1_048_576:.2f} MB"
        if value >= 1024:
            return f"{value / 1024:.2f} KB"
        return f"{value} B"

    def format_status_summary(self) -> str:
        snapshot = self.status_snapshot()
        dev = snapshot["device"]
        sig = snapshot["signal"]
        plmn = snapshot["plmn"]
        traffic = snapshot["traffic"]
        status = snapshot["status"]
        sec = snapshot["sec_cell"]
        nbr = snapshot["nbr_cell"]
        assert isinstance(dev, dict)
        assert isinstance(sig, dict)
        assert isinstance(plmn, dict)
        assert isinstance(traffic, dict)
        assert isinstance(status, dict)
        assert isinstance(sec, dict)
        assert isinstance(nbr, dict)

        lines = ["=" * 50]
        lines.append(f"  {dev.get('devicename', 'CPE')} ({dev.get('spreadname_zh', '')})")
        lines.append("=" * 50)
        lines.append(f"运营商: {plmn.get('FullName', 'N/A')} ({plmn.get('Numeric', 'N/A')})")
        lines.append(f"网络模式: {sig.get('mode', 'N/A')} | 频段: {sig.get('band', 'N/A')} ({sig.get('bandInfo', 'N/A')})")
        lines.append("")
        lines.append("--- 5G NR 信号 ---")
        for label, key in [
            ("PCI", "pci"),
            ("NR-ARFCN", "nrearfcn"),
            ("NR频宽", "nrulbandwidth"),
            ("NR-RSRP", "nrrsrp"),
            ("NR-RSRQ", "nrrsrq"),
            ("NR-SINR", "nrsinr"),
            ("NR-RSSI", "nrrssi"),
            ("TAC", "tac"),
            ("eNB ID", "enodeb_id"),
            ("Cell ID", "cell_id"),
            ("NR rank", "nrrank"),
            ("NR BLER", "nrbler"),
            ("NR 上行MCS", "nrulmcs"),
            ("NR 下行MCS", "nrdlmcs"),
            ("NR 发射功率", "nrtxpower"),
        ]:
            lines.append(f"  {label}: {sig.get(key, 'N/A')}")

        nr_sec = sec.get("nr", [])
        if nr_sec:
            lines.append("")
            lines.append("--- 服务小区 (NR) ---")
            for cell in nr_sec:
                lines.append(
                    "  PCI={pci} EARFCN={earfcn} BAND={band} BW={bw} "
                    "RSRP={rsrp} RSRQ={rsrq} SINR={sinr}".format(**cell)
                )

        nr_nbr = nbr.get("nr", [])
        if nr_nbr:
            lines.append("")
            lines.append("--- NR 邻区 (按RSRP排序) ---")
            for cell in sorted(nr_nbr, key=_rsrp_sort_key, reverse=True):
                lines.append(
                    "  PCI={pci} EARFCN={earfcn} BAND={band} "
                    "RSRP={rsrp} RSRQ={rsrq} SINR={sinr}".format(**cell)
                )

        current_dl = int(traffic.get("CurrentDownload", 0) or 0)
        current_ul = int(traffic.get("CurrentUpload", 0) or 0)
        total_dl = int(traffic.get("TotalDownload", 0) or 0)
        total_ul = int(traffic.get("TotalUpload", 0) or 0)
        lines.append("")
        lines.append("--- 流量统计 ---")
        lines.append(f"  本次下载: {self.format_bytes(current_dl)}")
        lines.append(f"  本次上传: {self.format_bytes(current_ul)}")
        lines.append(f"  累计下载: {self.format_bytes(total_dl)}")
        lines.append(f"  累计上传: {self.format_bytes(total_ul)}")
        lines.append(f"  本次连接时长: {int(traffic.get('CurrentConnectTime', 0) or 0)}秒")
        lines.append(f"  累计连接时长: {int(traffic.get('TotalConnectTime', 0) or 0)}秒")
        lines.append("")
        lines.append("--- 设备状态 ---")
        lines.append(f"  WiFi连接设备: {status.get('CurrentWifiUser', 'N/A')} / {status.get('TotalWifiUser', 'N/A')}")
        lines.append(f"  信号图标: {status.get('SignalIconNr', 'N/A')} / {status.get('maxsignal', 'N/A')}")
        lines.append("=" * 50)
        return "\n".join(lines)

    @staticmethod
    def _parse_supported_bands(section) -> list[dict[str, str]]:
        if section is None:
            return []
        bands: list[dict[str, str]] = []
        for band in section.findall(".//band"):
            value = tag_text(band, "value")
            freq = tag_text(band, "freq")
            if value:
                bands.append({"band": value, "freq": freq})
        return bands

    def _request(self, method: str, endpoint: str, **kwargs) -> requests.Response:
        url = endpoint if endpoint.startswith("http") else f"{self.base}{endpoint}"
        kwargs.setdefault("timeout", self.timeout)
        response = self.session.request(method, url, **kwargs)
        response.raise_for_status()
        return response

    @staticmethod
    def _xml_headers(extra: dict[str, str] | None = None) -> dict[str, str]:
        headers = {"Content-Type": "application/x-www-form-urlencoded; charset=UTF-8"}
        if extra:
            headers.update(extra)
        return headers

    @staticmethod
    def _raise_for_api_code(xml_text_value: str, step: str) -> None:
        root = parse_root(xml_text_value)
        code = tag_text(root, "code")
        if code:
            raise LoginError(f"{step} 返回错误码 {code}")


def _rsrp_sort_key(cell: dict[str, str]) -> float:
    raw = cell.get("rsrp", "")
    try:
        return float(raw.replace("dBm", "").strip())
    except ValueError:
        return -999.0
