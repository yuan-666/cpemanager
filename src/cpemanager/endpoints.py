"""Known Huawei CPE API endpoints."""

CURRENT_PLMN = "/api/net/current-plmn"
NBR_CELL_INFO = "/api/device/nbrcellinfo"
SEC_CELL_INFO = "/api/device/seccellinfo"
SIGNAL = "/api/device/signal"
TRAFFIC_STATISTICS = "/api/monitoring/traffic-statistics"
AUTHENTICATION_LOGIN = "/api/user/authentication_login"
CHALLENGE_LOGIN = "/api/user/challenge_login"
TOKEN = "/api/webserver/token"
STATUS = "/api/monitoring/status"

BASIC_INFORMATION = "/api/device/basic_information"
ANTENNA_TYPE = "/api/device/antenna_type"
ANTENNA_SET_TYPE = "/api/device/antenna_set_type"
BAND_FREQ_LIST = "/config/network/bandfreqlist.xml"
LOCK_FREQ = "/api/net/lock-freq"
NET_MODE = "/api/net/net-mode"

READ_ENDPOINTS = {
    CURRENT_PLMN,
    NBR_CELL_INFO,
    SEC_CELL_INFO,
    SIGNAL,
    TRAFFIC_STATISTICS,
    TOKEN,
    STATUS,
    BASIC_INFORMATION,
    ANTENNA_TYPE,
    BAND_FREQ_LIST,
    LOCK_FREQ,
    NET_MODE,
}
