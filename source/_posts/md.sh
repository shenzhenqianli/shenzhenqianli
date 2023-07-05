#!/bin/bash

if [ $# -lt 1 ]; then
  title=$(date +%s%3N)
  filename=$(date +%s%3N.md)
else
  title=$1
  filename=$(date +%s%3N-$1.md)
fi

ls_date=$(date +%Y-%m-%d)

echo "创建新的文件路径为: $(pwd)/source/_posts/$filename 文章标题为: $title"

cat >$(pwd)/source/_posts/$filename <<EOF
---
title: $title
description: 亚马逊运营的方方面面。旨在打造亚马逊卖家的私密圈子，帮助卖家搭建完整的企业内训体系。
keywords: 亚马逊卖家,亚马逊论坛,亚马逊卖家论坛,亚马逊培训,亚马逊资料,亚马逊工具,亚马逊跨境电商,跨境电商卖家,跨境电商平台,跨境电商培训,跨境电商知识
author: Mr.APIS
date: $ls_date
publisher: Mr.APIS
---
EOF
