#!/usr/bin/env bash
set -euo pipefail

# ssh が SSH_ASKPASS として本スクリプトをプロンプト引数付きで呼び出す
if [ "$#" -ge 1 ]; then
    printf '%s\n' "${TF_VAR_ssh_password}"
    exit 0
fi

eval "$(python3 -c '
import json, shlex, sys
q = json.load(sys.stdin)
print("\n".join(f"{k}={shlex.quote(v)}" for k, v in q.items()))
')"

# 実ハッシュを返すと assume_hosts_unchanged の切替だけで偽の replace が出る
if [ "${enabled}" != "true" ]; then
    printf '{"drift":"none"}'
    exit 0
fi

: "${TF_VAR_ssh_password:?環境変数 TF_VAR_ssh_password を設定してください}"
export SSH_ASKPASS
SSH_ASKPASS="$(realpath "${BASH_SOURCE[0]}")"
export SSH_ASKPASS_REQUIRE=force

remote=$(ssh -o ConnectTimeout=5 -o NumberOfPasswordPrompts=1 \
        -o StrictHostKeyChecking=accept-new "${ssh_user}@${host}" '
    frr=$(sha256sum /etc/frr/frr.conf 2>/dev/null | cut -d" " -f1)
    ospfd=$(grep -c "^ospfd=yes" /etc/frr/daemons 2>/dev/null || true)
    dnsmasq=$(systemctl is-enabled dnsmasq 2>/dev/null || true)
    fwd=$(sysctl -n net.ipv4.ip_forward 2>/dev/null || true)
    echo "${frr} ${ospfd} ${dnsmasq} ${fwd}"
') || {
    echo "Error: ${host} に SSH 到達できません。ホストを触らず API のみ適用する場合は assume_hosts_unchanged=true を指定してください。" >&2
    exit 1
}

read -r frr ospfd dnsmasq fwd <<<"${remote}"
if [ "${frr}" = "${desired}" ] && [ "${ospfd}" = "1" ] \
        && [ "${dnsmasq}" = "disabled" ] && [ "${fwd}" = "1" ]; then
    printf '{"drift":"none"}'
else
    printf '{"drift":"drift:%s"}' "$(echo "${remote}" | sha256sum | cut -d" " -f1)"
fi
