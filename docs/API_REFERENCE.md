# API Reference

This file records the Huawei CPE API surface currently used by CPE Manager. The first supported device target is `http://192.168.8.1`.

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
