# API Reference

This file records the CPE API surface currently used by CPE Manager. Huawei is the first complete target at `http://192.168.8.1`; Fiberhome/烽火 support is an alpha adapter based on the HAR captures in the local workspace.

## Signal

Endpoint:

```text
GET /api/device/signal
```

Known response fields:

| Field | Meaning |
| --- | --- |
| `pci` | NR physical cell ID |
| `cell_id` | NR Cell Identity |
| `mode` | Network mode, commonly `12` for 5G SA and `7` for LTE |
| `rrc_status` | RRC status, commonly `1` for connected |
| `tac` | Tracking area code in hex |
| `band` | Band description, for example `100MHz@633984(N78)` |
| `bandInfo` | Band label, for example `N78` or `N41` |
| `plmn` | PLMN, for example `46011` |
| `enodeb_id` | gNB/eNB ID |
| `nrearfcn` | NR-ARFCN |
| `nrulbandwidth` | NR uplink bandwidth |
| `nrdlbandwidth` | NR downlink bandwidth |
| `nrulmcs` | NR uplink MCS |
| `nrdlmcs` | NR downlink MCS |
| `nrtxpower` | NR transmit power |
| `nrulfreq` | NR uplink frequency |
| `nrdlfreq` | NR downlink frequency |
| `nrsinr` | NR SINR |
| `nrrsrp` | NR RSRP |
| `nrrsrq` | NR RSRQ |
| `nrrssi` | NR RSSI |
| `nrbler` | NR BLER |
| `nrrank` | NR MIMO rank |
| `nrcqi0` | NR CQI |
| `scc_pci` | Secondary carrier PCI in CA scenarios |
| `rsrq` | LTE RSRQ |
| `rsrp` | LTE RSRP |
| `sinr` | LTE SINR |
| `earfcn` | LTE EARFCN |
| `lteulfreq` | LTE uplink frequency |
| `ltedlfreq` | LTE downlink frequency |

Example:

```xml
<response>
  <pci>360</pci>
  <cell_id>0000000759672080</cell_id>
  <mode>12</mode>
  <rrc_status>1</rrc_status>
  <tac>757E07</tac>
  <band>100MHz@633984(N78)</band>
  <bandInfo>N78</bandInfo>
  <plmn>46011</plmn>
  <enodeb_id>0870317</enodeb_id>
  <nrearfcn>633984</nrearfcn>
  <nrulbandwidth>100MHz</nrulbandwidth>
  <nrdlbandwidth>100MHz</nrdlbandwidth>
  <nrsinr>17dB</nrsinr>
  <nrrsrp>-92dBm</nrrsrp>
  <nrrsrq>-10.0dB</nrrsrq>
  <nrrssi>-69dBm</nrrssi>
</response>
```

## Supported Endpoints

Read endpoints:

- `GET /api/net/current-plmn`
- `GET /api/device/nbrcellinfo`
- `GET /api/device/seccellinfo`
- `GET /api/device/signal`
- `GET /api/monitoring/traffic-statistics`
- `GET /api/monitoring/status`
- `GET /api/webserver/token`
- `GET /api/device/basic_information`
- `GET /api/device/antenna_type`
- `GET /api/net/lock-freq`
- `GET /api/net/net-mode`
- `GET /config/network/bandfreqlist.xml`

Write/login endpoints:

- `POST /api/user/challenge_login`
- `POST /api/user/authentication_login`
- `POST /api/net/net-mode`
- `POST /api/net/lock-freq`
- `POST /api/device/antenna_set_type`

## Cell Calculations

The mobile app displays these derived values when the source fields are available:

| Value | Formula |
| --- | --- |
| LTE ECI | `eNB ID * 256 + cell ID` |
| NR GCI | `gNB ID * 4096 + cell ID` |
| TAC decimal | Parse TAC as hex when it contains hex digits, otherwise parse as decimal |

Example conversions now covered by Dart tests:

| Source | Result |
| --- | --- |
| `TAC=757E07` | `7699975` |
| `TAC=86fe01` | `8846849` |
| `eNB=411877`, `cell=0` | `ECI=105440512` |
| `gNB=234295`, `cell=1040` | `GCI=959673360` |

## Fiberhome FHNCAPIS / FHTOOLAPIS

Login/session flow from `烽火(1)/login_v1.py`:

```text
GET /api/tmp/FHNCAPIS?ajaxmethod=get_refresh_sessionid
POST /api/tmp/FHTOOLAPIS
```

Login request shape:

```json
{
  "dataObj": {"username": "admin", "password": "password"},
  "ajaxmethod": "app_do_login",
  "sessionid": "session-from-get_refresh_sessionid"
}
```

The current Fiberhome configuration and status calls use:

```text
POST /api/tmp/FHTOOLAPIS
Content-Type: application/json
Content-Length: <exact utf8 byte length>
```

Important transport detail: the tested Fiberhome device returns HTTP 403 for chunked JSON POST bodies and for POST calls that reuse the login sessionid. Clients should send a fixed-length body, call `get_refresh_sessionid` before each `FHTOOLAPIS` POST, and bypass desktop proxy environment variables for `192.168.8.1`.

Request shape:

```json
{
  "dataObj": null,
  "ajaxmethod": "app_get_network_info",
  "sessionid": "session-from-device-page"
}
```

Confirmed methods:

| Method | Purpose | Captured fields |
| --- | --- | --- |
| `app_do_login` | Login with username/password | optional `ret`, `errmsg`, `sessionid` |
| `app_get_base_info` | Read live status | `RSSI`, `RSRQ`, `SSB_RSRP`, `SSB_SINR`, `PLMN`, `NR_Band`, `TAC`, `NCGI`, `EARFCN_NBR`, `PCI_NBR`, `RSRP_NBR`, `Temperature`, `TxSpeed`, `RxSpeed`, `modelName`, `RRCStatus`, `DlMCS`, `UlMCS`, `CQI`, `DlMimo`, `UlMimo`, `Software_version`, `WorkMode` |
| `app_get_airplane` | Read flight-mode state | `airplaneOn` |
| `app_get_network_info` | Read preferred network mode | `networkMode`, `ENDC` |
| `app_set_network_info` | Write LTE/SA/NSA/Auto preset | `networkMode`, `ENDC` |
| `app_get_lockband` | Read locked Band state | `lockBandEnable`, `LTELockBAND`, `NRLockBAND` |
| `app_set_lockband` | Write locked Band state | `lockBandEnable`, `LTELockBAND`, `NRLockBAND` |
| `app_get_cell_list` | Read lock-cell list | `enable`, `lock_cell[]` |
| `app_set_cell_list` | Write lock-cell list | `enable`, `lock_cell[].act`, `lock_cell[].arfcn`, `lock_cell[].pci` |

Captured network presets:

| Preset | `networkMode` | `ENDC` |
| --- | --- | --- |
| LTE only | `0` | `1` |
| SA only | `2` | `1` |
| NSA preferred | `3` | `2` |
| Auto | `3` | `3` |

Captured lock-cell mapping:

| RAT | `act` |
| --- | --- |
| LTE | `1` |
| NR | `2` |

Known gaps: Fiberhome write operations still need hardware validation after readback. The currently captured `base_info` endpoint provides a combined primary/neighbor/status snapshot rather than separate Huawei-style signal, traffic, and neighbor APIs.

UI field translations used by Simple mode:

| Source field | Simple label | Unit / note |
| --- | --- | --- |
| `UL_AMBR` | 上行签约带宽 | Mbps, converted from Kbps-style integer values |
| `DL_AMBR` | 下行签约带宽 | Mbps, converted from Kbps-style integer values |
| `QCI` | 承载等级 | SIM/default bearer quality class |
| `PUSCH_TX_Power` | PUSCH 发射功率 | dBm |
| `PUCCH_TX_Power` | PUCCH 发射功率 | dBm |
| `DL_Modulation` | 下行调制 | Uses raw field when present; otherwise estimates from `DlMCS` in Simple mode |
| `UL_Modulation` | 上行调制 | Uses raw field when present; otherwise estimates from `UlMCS` in Simple mode |
