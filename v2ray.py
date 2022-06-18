#!/usr/bin/env python3
# -*- coding:utf-8 -*-


from urllib.request import urlopen
subscribe_url = 'xxxx'
return_content = urlopen(subscribe_url).read()
print(return_content)

from base64 import b64decode
share_links = b64decode(return_content).decode('utf-8').splitlines()
print(share_links)

from urllib.parse import urlsplit
import json
schemes_allow = ['vmess', 'ss', 'socks']
configs = []
for share_link in share_links:
    url = urlsplit(share_link)
    if url.scheme not in schemes_allow: raise RuntimeError('invalid share link')
    bs = url.netloc
    blen = len(bs)
    if blen % 4 > 0: bs += "=" * (4 - blen % 4)
    configs.append(json.loads(b64decode(bs).decode('utf-8')))
print(configs)