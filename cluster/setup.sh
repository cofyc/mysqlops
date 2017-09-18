#!/bin/bash

ROOT=$(unset CDPATH && cd $(dirname "${BASH_SOURCE[0]}")/.. && pwd)
cd $ROOT

source "${ROOT}/cluster/lib/init.sh"

if [[ "$GRAIN_OS" == "Ubuntu" ]]; then
    # key: 1C4CBDCDCD2EFD2A
    sudo apt-key add - <<'EOD'
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1.4.11 (GNU/Linux)

mQGiBEsm3aERBACyB1E9ixebIMRGtmD45c6c/wi2IVIa6O3G1f6cyHH4ump6ejOi
AX63hhEs4MUCGO7KnON1hpjuNN7MQZtGTJC0iX97X2Mk+IwB1KmBYN9sS/OqhA5C
itj2RAkug4PFHR9dy21v0flj66KjBS3GpuOadpcrZ/k0g7Zi6t7kDWV0hwCgxCa2
f/ESC2MN3q3j9hfMTBhhDCsD/3+iOxtDAUlPMIH50MdK5yqagdj8V/sxaHJ5u/zw
YQunRlhB9f9QUFfhfnjRn8wjeYasMARDctCde5nbx3Pc+nRIXoB4D1Z1ZxRzR/lb
7S4i8KRr9xhommFnDv/egkx+7X1aFp1f2wN2DQ4ecGF4EAAVHwFz8H4eQgsbLsa6
7DV3BACj1cBwCf8tckWsvFtQfCP4CiBB50Ku49MU2Nfwq7durfIiePF4IIYRDZgg
kHKSfP3oUZBGJx00BujtTobERraaV7lIRIwETZao76MqGt9K1uIqw4NT/jAbi9ce
rFaOmAkaujbcB11HYIyjtkAGq9mXxaVqCC3RPWGr+fqAx/akBLQ2UGVyY29uYSBN
eVNRTCBEZXZlbG9wbWVudCBUZWFtIDxteXNxbC1kZXZAcGVyY29uYS5jb20+iGAE
ExECACAFAksm3aECGwMGCwkIBwMCBBUCCAMEFgIDAQIeAQIXgAAKCRAcTL3NzS79
Kpk/AKCQKSEgwX9r8jR+6tAnCVpzyUFOQwCfX+fw3OAoYeFZB3eu2oT8OBTiVYu5
Ag0ESybdoRAIAKKUV8rbqlB8qwZdWlmrwQqg3o7OpoAJ53/QOIySDmqy5TmNEPLm
lHkwGqEqfbFYoTbOCEEJi2yFLg9UJCSBM/sfPaqb2jGP7fc0nZBgUBnFuA9USX72
O0PzVAF7rCnWaIz76iY+AMI6xKeRy91TxYo/yenF1nRSJ+rExwlPcHgI685GNuFG
chAExMTgbnoPx1ka1Vqbe6iza+FnJq3f4p9luGbZdSParGdlKhGqvVUJ3FLeLTqt
caOn5cN2ZsdakE07GzdSktVtdYPT5BNMKgOAxhXKy11IPLj2Z5C33iVYSXjpTelJ
b2qHvcg9XDMhmYJyE3O4AWFh2no3Jf4ypIcABA0IAJO8ms9ov6bFqFTqA0UW2gWQ
cKFN4Q6NPV6IW0rV61ONLUc0VFXvYDtwsRbUmUYkB/L/R9fHj4lRUDbGEQrLCoE+
/HyYvr2rxP94PT6Bkjk/aiCCPAKZRj5CFUKRpShfDIiow9qxtqv7yVd514Qqmjb4
eEihtcjltGAoS54+6C3lbjrHUQhLwPGqlAh8uZKzfSZq0C06kTxiEqsG6VDDYWy6
L7qaMwOqWdQtdekKiCk8w/FoovsMYED2qlWEt0i52G+0CjoRFx2zNsN3v4dWiIhk
ZSL00Mx+g3NA7pQ1Yo5Vhok034mP8L2fBLhhWaK3LG63jYvd0HLkUFhNG+xjkpeI
SQQYEQIACQUCSybdoQIbDAAKCRAcTL3NzS79KlacAJ9H6emL/8dsoquhE9PNnKCI
eMTmmQCfXRLIoNjJa20VEwJDzR7YVdBEiQI=
=AD5m
-----END PGP PUBLIC KEY BLOCK-----
EOD
    # key: 9334A25F8507EFA5
    sudo apt-key add - <<'EOD'
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: SKS 1.1.5
Comment: Hostname: keyserver.ubuntu.com

mQINBFd0veABEADyFa8jPHXhhX1XS9W7Og4p+jLxB0aowElk4Kt6lb/mYjwKmQ779ZKUAvb1
xRYFU1/NEaykEl/jxE7RA/fqlqheZzBblB3WLIPM0sMfh/D4fyFCaKKFk2CSwXtYfhk9DOsB
P2K+ZEg0PoLqMbLIBUxPl61ZIy2tnF3G+gCfGu6pMHK7WTtInnruMKk51s9Itc9vUeUvRGDc
FIiEEq0xJhEX/7J/WAReD5Am/kD4CvkkunSqbhhuB6DV9tAeEFtDppEHdFDzfHfTOwlHLgTv
gVETDgLgTRXzztgBVKl7Gdvc3ulbtowBuBtbuRr49+QIlcBdFZmM6gA4V5P9/qrkUaarvuIk
XWQYs9/8oCd3SRluhdxXs3xX1/gQQXYHUhcdAWrqS56txncXf0cnO2v5kO5rlOX1ovpNQsc6
9R52LJKOLA1KmjcaJNtC+4e+SF2upK14gtXK384z7owXYUA4NRZOEu+UAw7wAoiIWPUfzMEH
Yi8I3RszEtpVyOQC5YyYgwzIdt4YxlVJ0CUoinvtIygies8LkA5GQvaGJHYG1aQ3i9WDddCX
wtoV1uA4EZlEWjTXlSRc92jhSKut/EWbmYHEUhmvcfFErrxUPqirpVZHSaXY5RdhKVFyx9Jc
RuIQ0SJxeHQPlaEkyhKpTDN5Cw7USLwoXfIu2w0w0W06LdXZ7wARAQABtEZQZXJjb25hIE15
U1FMIERldmVsb3BtZW50IFRlYW0gKFBhY2thZ2luZyBrZXkpIDxteXNxbC1kZXZAcGVyY29u
YS5jb20+iQI3BBMBCgAhBQJXdL3gAhsDBQsJCAcDBRUKCQgLBRYCAwEAAh4BAheAAAoJEJM0
ol+FB++l4koQAKkrRP+K/p/TGlnqlbNyS5gdSIB1hxT3iFwIdF9EPZq0U+msh8OY7omV/82r
Jp4T5cIJFvivtWQpEwpUjJtqBzVrQlF+12D1RFPSoXkmk6t4opAmCsAmAtRHaXIzU9WGJETa
Hl57Trv5IPMv15X3TmLnk1mDMSImJoxWJMyUHzA37BlPjvqQZv5meuweLCbL4qJS015s7Uz+
1f/FsiDLsrlE0iYCAScfBeRSKF4MSnk5huIGgncaltKJPnNYppXUb2wt+4X2dpY3/V0BoiG8
YBxV6N7sA7lC/OoYF6+H3DMlSxGBQEb1i9b6ypwZIbG6CnM2abLqO67D3XGx559/FtAgxrDB
X1f63MQKlu+tQ9mOrCvSbt+bMGT6frFopgH6XiSOhOiMmjUazVRBsXRK/HM5qIk5MK0tGPSg
pc5tr9NbMDmp58OQZYQscslKhx0EDDYHQyHfYFS2qoduRwQG4BgpZm2xjGM/auCvdZ+pxjqy
7dnEXvMVf0i1BylkyW4p+oK5nEwY3KHljsRxuJ0+gjfyj64ihNMSqDX5k38T2GPSXm5XAN+/
iazlIuiqPQKLZWUjTOwr2/AA6AztU/fmsXV2swz8WekqT2fphvWKUOISr3tEGG+HF1iIY43B
oAMHYYOcdSI1ZODZq3Wic+zlN1WzPshDB+d3acxeV5JhstvPiQQcBBABCAAGBQJYCWSTAAoJ
EHpjgJ3lEnYiM40gALkOg65HOAOGkBV6WG9BTpQgnhsmrvC/2ozZ6dV5577/zYCf6ZB5hMO3
mSwcrjTGX5+yD1CyVQEayWuUxoV2By+N9an98660hWAIYTSNiRwSFITDbLVqXOp7t/B7Bddh
j3ZrzA3Eo5bV/QyS/zyKGF1tMkA64IJkQ3292g1L7RYfNG5h1IBB/xY2xCVcKNT2XcFbAPOc
t30bqMyT4mdT39WdYg0l4U3zOutemFYs4uyObzrVNOKln0thZpfNJdRq+OfkE6XwW2UwhTK0
/GM5l1Y3NJW64DGPyM7KKcE4FTgq1MRaWepw5sAZr6pTqasWuWUf20la1M9fIdyxJsAbWn1b
hpPIOl3NZ88dRK6XI8Ly36fRa2as/lPeG7ql2ymaOVFDBHqfB+gAWMzkwF7TS+02er4kg9vn
pErPc/aA0lMKmyXHkMANLAnWBA7tx+7sEKck8XcY4e1OiwpUXRxC+UlSaJYQtE/kmoC2NPQB
0FhhvC/VQ0sBOYOAbJ5GukEJVDB7QqqGKjzaKE0LUADCXJFcLY4yMA9bP9U+Ex/G62YcYn0g
1amriKAAkEBRvBOp/qUFSj6b+EqEC5w2my3cLBnATrzskGm32XNOFdpwR469rOqxomtVedH7
2vW3sS1etcGw/SHBSplDYTzcnAJQbHvD6LEeOQeWPbA77PD9ASlx7jGZj3GCq0tc7dndjTLy
iL+A4EsRxEUDrH30d8TLaYd1WSD6v5i/xa0r3rXQUmPviBBzRpJxl0CFB/db2L6a/A2EHkOW
jpcL2XSJgcgIVlYZCgM1OEuDGURbLUM9qNiFogdBNCkGTkqjIFES0iq4lBA4vphcXR8C34OP
+7DeT1RthyPjmvi/ErXIQLTpR2Yuwl9/nI2gx6ddZFqkoHFcPSyE152uJRsYdtL9iIeEIPH/
/WZ0Fz+h6hhfLiPh6AN1LH3wxKqLW4hAAZ8ytUqANNZT+7o6EVQHI6VyoigS5TJ34h36jKjR
vfUaP4FfkGaPRpfR/cKUiNaCIJRaIFlvlUdbN+biQO3WRxwdyUdgDSETZnLiym6pKuCpLsic
/3+fOyBuWuIxxvGGm3XUt3Lmtvlkey/sSCwInioxn0drYosq+FZP/ocBQ9aeyxZ5Fqyxqg0B
InrusfthXA35WUExVsjwidFPeftz2VbV9gD1Og3JN2Rhd7FzxH0lrLghxh129R1QVPZiDOia
JQO4QObsC5YXmzF0A/25qJ9Y8UJrsnWrPvjpH41p70Sl6iDWKigdxi6LD9NrwOnw9qBkIlmj
bJL6WKrvjxgVoCo4iP8jtHUx0jwn2qsMkGqO3NM2xWb6MBVzU7nZsyGpH5OzlrHYoYziw8v6
zCLZj8eg3EgFxe+5Ag0EV3S94AEQAJ+4dVt7Lmobk/qtGEBfal139/uLAd1xbX56/EJ8JHl8
fOw7UtHCUcz0ZGqXO0rODHMAh+BRep0xdSzq9bxqB+S7nneHyAGquF2r00frn9h6fNX9K/1z
8QbOwFC6tq7VELiB8niOAB527gVApm9Wv//Q1Na4mbd6XeithjPisurv1q9KAPtD+4rz+PvX
OAImLGwXOMLx6FGU60x1609NjfrNzYuNBIxNKkTtK8RuuTrIMqlC9lpuXd2aQSQG+gWlq3vH
6Ldm0ELNEVPHasf/0NYoI75K4ZUFezy+Eu0C8oqNtYYZT0uuYRJlxqEjp+WIfnDbw2+k64mW
vxGf/qNCYkMM8o7nRcozyGlPoMGogT31ipgtTNcAp/hjzwXIe+U7qSJVtdo5jPU5OoJZWqNo
xgVuI9bo2ANfSHIT24bSV80D0/l52rI9IRpM36SkP05WobpHS48EIVjy7bk2s1GEyogVB28j
nh4S03SS0U/QWuUUWSDpL6X7dCyv2wwMoJRVMn8GQrCqR2FO/ldjgqIgQlCO8wqvS8fmViI8
MZf/cqwkv6vEmMD77haHjRYEtgNINZIB8I9KiSDWVGM5owOGcflidR4SToyHLrUNBGwf7ESl
4v8XUvTq7RaH7SJeopckDiO9ThfAZKTODfJppuWRie6fmbKEhBizAh0LIQfhaXdJABEBAAGJ
Ah8EGAEKAAkFAld0veACGwwACgkQkzSiX4UH76XGqRAAgLuPPUJa361sqC60tEVzF7E1BmhM
AA9OTc6Oqp4ItY7VyYe2aM1JdNzmulfvy88RhCPNCkABFnECmkB14kcHOb1Ct+LKjtNbw/QZ
/1z2nWY9S2XaDQE29FTvNjOAIXVojAq1L5c7ZR1NPnobLm9rF3UGJODwn3K2QgZKS5JdI4BJ
4YLlGY3dJoPrKiZVrjzeT2RWGFI5TMrBgr1/ZaAaEjXHGlUXktttGEKgTPiJr9OomhZ0f9qC
6XfgAZY6A9GEy74USlv+eiezvddPBC1xeJkB73PhmW1WxJyKiWBHM/CRfEyZZUyZ71jKZUI9
OvPE+LqdzqelJnMTbvmbTa7zpXaG3APYxtK4aZxN2YA899eBDlcznsQsSUNs0DV43WNkCHNg
Eu/rdf6c07LrKy5pzlDujPIE4ik2SwuV4DT4XOydiY+UarNi2cPqcWCUOfz3yOT8taTCK0vj
vZ+HxFFsNh9+xd5qWLLpbZNgqtCXnZqMtXsPk9RRL3FKUA9x09K5cDOHsaE4oOiaZbAt8+jS
5g3deNr4CRbXfly3Ph68Km9mOQFN+iDTsUaW6Z25Qrl8e8liJLJXU/lIqvjvbYLyNYKjZhxL
4ixmBUUW5jVsboe2Iiak/vkgzQbeDW7J3Y6EX2cYNLGOniQpadSgZ1XQ/VtRdoBu9dHOUhzH
t04Pu1k=
=5SzL
-----END PGP PUBLIC KEY BLOCK-----
EOD
    # import from keys.gnupg.net is unstable
    # run_with_retries 3 apt-key adv --keyserver keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A
    # new key: https://www.percona.com/blog/2016/10/13/new-signing-key-for-percona-debian-and-ubuntu-packages/
    # run_with_retries 3 apt-key adv --keyserver keys.gnupg.net --recv-keys 9334A25F8507EFA5
    codename=$(lsb_release -c | awk -F ':\t+' '{print $2}')
    url=https://mirrors.tuna.tsinghua.edu.cn/percona # mirror of repo.percona.com
    cat <<EOF > /etc/apt/sources.list.d/percona.list
deb ${url}/apt $codename main
EOF
    apt-get update
elif [[ "$GRAIN_OS" == "CentOS" ]]; then
    # https://www.percona.com/doc/percona-server/LATEST/installation/yum_repo.html
    if yum list installed percona-release-0.1-4 &>/dev/null; then
        echo "Package percona-release-0.1-4 already installed, skipped."
    else
        yum install http://www.percona.com/downloads/percona-release/redhat/0.1-4/percona-release-0.1-4.noarch.rpm
        sed -i -r 's#http(s)?://repo.percona.com#https://mirrors.tuna.tsinghua.edu.cn\/percona#g'  /etc/yum.repos.d/percona-release.repo
    fi
fi