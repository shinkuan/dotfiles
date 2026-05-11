#!/bin/bash

# 檢查是否有線連接 (Ethernet)
ETH_CONNECTED=$(nmcli -t -f TYPE,STATE dev 2>/dev/null | grep '^ethernet:connected')

if [ -n "$ETH_CONNECTED" ]; then
    echo "󰈀   Ethernet"
    exit 0
fi

# 取得目前 Wi-Fi 連線狀態 (包含 SSID 與訊號強度)
WIFI_INFO=$(nmcli -t -f active,ssid,signal dev wifi 2>/dev/null | grep '^yes' | head -n 1)

if [ -n "$WIFI_INFO" ]; then
    WIFI_SSID=$(echo "$WIFI_INFO" | cut -d: -f2)
    WIFI_SIGNAL=$(echo "$WIFI_INFO" | cut -d: -f3)

    # 根據訊號強度切換 icon
    if [ "$WIFI_SIGNAL" -le 20 ]; then
        ICON="󰤯"
    elif [ "$WIFI_SIGNAL" -le 40 ]; then
        ICON="󰤟"
    elif [ "$WIFI_SIGNAL" -le 60 ]; then
        ICON="󰤢"
    elif [ "$WIFI_SIGNAL" -le 80 ]; then
        ICON="󰤥"
    else
        ICON="󰤨"
    fi

    echo "$ICON   $WIFI_SSID"
else
    # 未連接任何網路
    echo "󰤭   Disconnected"
fi
