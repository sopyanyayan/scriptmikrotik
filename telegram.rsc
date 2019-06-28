/system script
add dont-require-permissions=no name=tg_config owner=admin policy=read \
    source=":put \"tg: Load config\"\r\
    \n\r\
    \n:local config {\r\
    \n\r\
    \n\"botAPI\"=\"(GANTI)\";\r\
    \n\"defaultChatID\"=\"(GANTI)\";\r\
    \n\"trusted\"=\"(GANTI)\";\r\
    \n\"storage\"=\"\";\r\
    \n\"timeout\"=1;\r\
    \n}\r\
    \n\r\
    \nreturn \$config"
add dont-require-permissions=no name=tg_getUpdates owner=admin policy=read \
    source=":global TGLASTMSGID\r\
    \n:global TGLASTUPDID\r\
    \n\r\
    \n:local fconfig [:parse [/system script get tg_config source]]\r\
    \n:local http [:parse [/system script get func_fetch source]]\r\
    \n:local gkey [:parse [/system script get tg_getkey source]]\r\
    \n:local send [:parse [/system script get tg_sendMessage source]]\r\
    \n\r\
    \n:local cfg [\$fconfig]\r\
    \n:local trusted [:toarray (\$cfg->\"trusted\")]\r\
    \n:local botID (\$cfg->\"botAPI\")\r\
    \n:local storage (\$cfg->\"storage\")\r\
    \n:local timeout (\$cfg->\"timeout\")\r\
    \n\r\
    \n:put \"cfg=\$cfg\"\r\
    \n:put \"trusted=\$trusted\"\r\
    \n:put \"botID=\$botID\"\r\
    \n:put \"storage=\$storage\"\r\
    \n:put \"timeout=\$timeout\"\r\
    \n\r\
    \n:local file (\$storage.\"tg_get_updates.txt\")\r\
    \n:local logfile (\$storage.\"tg_fetch_log.txt\")\r\
    \n#get 1 message per time\r\
    \n:local url (\"https://api.telegram.org/bot\".\$botID.\"/getUpdates\?time\
    out=\$timeout&limit=1\")\r\
    \n:if ([:len \$TGLASTUPDID]>0) do={\r\
    \n  :set url \"\$url&offset=\$(\$TGLASTUPDID+1)\"\r\
    \n}\r\
    \n\r\
    \n:put \"Reading updates...\"\r\
    \n:local res [\$http dst-path=\$file url=\$url resfile=\$logfile]\r\
    \n:if (\$res!=\"success\") do={\r\
    \n  :put \"Error getting updates\"\r\
    \n  return \"Failed get updates\"\r\
    \n}\r\
    \n:put \"Finished to read updates.\"\r\
    \n\r\
    \n:local content [/file get [/file find name=\$file] contents]\r\
    \n\r\
    \n:local msgid [\$gkey key=\"message_id\" text=\$content]\r\
    \n:if (\$msgid=\"\") do={ \r\
    \n :put \"No new updates\"\r\
    \n :return 0 \r\
    \n}\r\
    \n:set TGLASTMSGID \$msgid\r\
    \n\r\
    \n:local updid [\$gkey key=\"update_id\" text=\$content]\r\
    \n:set TGLASTUPDID \$updid\r\
    \n\r\
    \n:local fromid [\$gkey block=\"from\" key=\"id\" text=\$content]\r\
    \n:local username [\$gkey block=\"from\" key=\"username\" text=\$content]\
    \r\
    \n:local firstname [\$gkey block=\"from\" key=\"first_name\" text=\$conten\
    t]\r\
    \n:local lastname [\$gkey block=\"from\" key=\"last_name\" text=\$content]\
    \r\
    \n:local chatid [\$gkey block=\"chat\" key=\"id\" text=\$content]\r\
    \n:local chattext [\$gkey block=\"chat\" key=\"text\" text=\$content]\r\
    \n\r\
    \n:put \"message id=\$msgid\"\r\
    \n:put \"update id=\$updid\"\r\
    \n:put \"from id=\$fromid\"\r\
    \n:put \"first name=\$firstname\"\r\
    \n:put \"last name=\$lastname\"\r\
    \n:put \"username=\$username\"\r\
    \n:local name \"\$firstname \$lastname\"\r\
    \n:if ([:len \$name]<2) do {\r\
    \n :set name \$username\r\
    \n}\r\
    \n\r\
    \n:put \"in chat=\$chatid\"\r\
    \n:put \"command=\$chattext\"\r\
    \n\r\
    \n:local allowed ( [:type [:find \$trusted \$fromid]]!=\"nil\" or [:type [\
    :find \$trusted \$chatid]]!=\"nil\")\r\
    \n:if (!\$allowed) do={\r\
    \n :put \"Unknown sender, keep silence\"\r\
    \n :return -1\r\
    \n}\r\
    \n\r\
    \n:local cmd \"\"\r\
    \n:local params \"\"\r\
    \n:local ltext [:len \$chattext]\r\
    \n\r\
    \n:local pos [:find \$chattext \" \"]\r\
    \n:if ([:type \$pos]=\"nil\") do={\r\
    \n :set cmd [:pick \$chattext 1 \$ltext]\r\
    \n} else={\r\
    \n :set cmd [:pick \$chattext 1 \$pos]\r\
    \n :set params [:pick \$chattext (\$pos+1) \$ltext]\r\
    \n}\r\
    \n\r\
    \n:local pos [:find \$cmd \"@\"]\r\
    \n:if ([:type \$pos]!=\"nil\") do={\r\
    \n :set cmd [:pick \$cmd 0 \$pos]\r\
    \n}\r\
    \n\r\
    \n:put \"cmd=<\$cmd>\"\r\
    \n:put \"params=<\$params>\"\r\
    \n\r\
    \n:global TGLASTCMD \$cmd\r\
    \n\r\
    \n:put \"Try to invoke external script tg_cmd_\$cmd\"\r\
    \n:local script [:parse [/system script get \"tg_cmd_\$cmd\" source]]\r\
    \n\$script params=\$params chatid=\$chatid from=\$name"
add dont-require-permissions=no name=func_fetch owner=admin policy=\
    ftp,read,write,policy,test source="#######################################\
    ##################\r\
    \n# Wrapper for /tools fetch\r\
    \n#  Input:\r\
    \n#    mode\r\
    \n#    upload=yes/no\r\
    \n#    user\r\
    \n#    password\r\
    \n#    address\r\
    \n#    host\r\
    \n#    httpdata\r\
    \n#    httpmethod\r\
    \n#    check-certificate\r\
    \n#    src-path\r\
    \n#    dst-path\r\
    \n#    ascii=yes/no\r\
    \n#    url\r\
    \n#    resfile\r\
    \n\r\
    \n:local res \"fetchresult.txt\"\r\
    \n:if ([:len \$resfile]>0) do={:set res \$resfile}\r\
    \n#:put \$res\r\
    \n\r\
    \n:local cmd \"/tool fetch\"\r\
    \n:if ([:len \$mode]>0) do={:set cmd \"\$cmd mode=\$mode\"}\r\
    \n:if ([:len \$upload]>0) do={:set cmd \"\$cmd upload=\$upload\"}\r\
    \n:if ([:len \$user]>0) do={:set cmd \"\$cmd user=\\\"\$user\\\"\"}\r\
    \n:if ([:len \$password]>0) do={:set cmd \"\$cmd password=\\\"\$password\\\
    \"\"}\r\
    \n:if ([:len \$address]>0) do={:set cmd \"\$cmd address=\\\"\$address\\\"\
    \"}\r\
    \n:if ([:len \$host]>0) do={:set cmd \"\$cmd host=\\\"\$host\\\"\"}\r\
    \n:if ([:len \$\"http-data\"]>0) do={:set cmd \"\$cmd http-data=\\\"\$\"ht\
    tp-data\"\\\"\"}\r\
    \n:if ([:len \$\"http-method\"]>0) do={:set cmd \"\$cmd http-method=\\\"\$\
    \"http-method\"\\\"\"}\r\
    \n:if ([:len \$\"check-certificate\"]>0) do={:set cmd \"\$cmd check-certif\
    icate=\\\"\$\"check-certificate\"\\\"\"}\r\
    \n:if ([:len \$\"src-path\"]>0) do={:set cmd \"\$cmd src-path=\\\"\$\"src-\
    path\"\\\"\"}\r\
    \n:if ([:len \$\"dst-path\"]>0) do={:set cmd \"\$cmd dst-path=\\\"\$\"dst-\
    path\"\\\"\"}\r\
    \n:if ([:len \$ascii]>0) do={:set cmd \"\$cmd ascii=\\\"\$ascii\\\"\"}\r\
    \n:if ([:len \$url]>0) do={:set cmd \"\$cmd url=\\\"\$url\\\"\"}\r\
    \n\r\
    \n:put \">> \$cmd\"\r\
    \n\r\
    \n:global FETCHRESULT\r\
    \n:set FETCHRESULT \"none\"\r\
    \n\r\
    \n:local script \"\\\r\
    \n :global FETCHRESULT;\\\r\
    \n :do {\\\r\
    \n   \$cmd;\\\r\
    \n   :set FETCHRESULT \\\"success\\\";\\\r\
    \n } on-error={\\\r\
    \n  :set FETCHRESULT \\\"failed\\\";\\\r\
    \n }\\\r\
    \n\"\r\
    \n:execute script=\$script file=\$res\r\
    \n:local cnt 0\r\
    \n#:put \"\$cnt -> \$FETCHRESULT\"\r\
    \n:while (\$cnt<100 and \$FETCHRESULT=\"none\") do={ \r\
    \n :delay 1s\r\
    \n :set \$cnt (\$cnt+1)\r\
    \n #:put \"\$cnt -> \$FETCHRESULT\"\r\
    \n}\r\
    \n:local content [/file get [find name=\$res] content]\r\
    \n#:put \$content\r\
    \nif (\$content~\"finished\") do={:return \"success\"}\r\
    \n:return \$FETCHRESULT"
add dont-require-permissions=no name=tg_getkey owner=admin policy=read \
    source=":local cur 0\r\
    \n:local lkey [:len \$key]\r\
    \n:local res \"\"\r\
    \n:local p\r\
    \n\r\
    \n:if ([:len \$block]>0) do={\r\
    \n :set p [:find \$text \$block \$cur]\r\
    \n :if ([:type \$p]=\"nil\") do={\r\
    \n  :return \$res\r\
    \n }\r\
    \n :set cur (\$p+[:len \$block]+2)\r\
    \n}\r\
    \n\r\
    \n:set p [:find \$text \$key \$cur]\r\
    \n:if ([:type \$p]!=\"nil\") do={\r\
    \n :set cur (\$p+lkey+2)\r\
    \n :set p [:find \$text \",\" \$cur]\r\
    \n :if ([:type \$p]!=\"nil\") do={\r\
    \n   if ([:pick \$text \$cur]=\"\\\"\") do={\r\
    \n    :set res [:pick \$text (\$cur+1) (\$p-1)]\r\
    \n   } else={\r\
    \n    :set res [:pick \$text \$cur \$p]\r\
    \n   }\r\
    \n } \r\
    \n}\r\
    \n:return \$res"
add dont-require-permissions=no name=tg_sendMessage owner=admin policy=read \
    source=":local fconfig [:parse [/system script get tg_config source]]\r\
    \n\r\
    \n:local cfg [\$fconfig]\r\
    \n:local chatID (\$cfg->\"defaultChatID\")\r\
    \n:local botID (\$cfg->\"botAPI\")\r\
    \n:local storage (\$cfg->\"storage\")\r\
    \n\r\
    \n:if ([:len \$chat]>0) do={:set chatID \$chat}\r\
    \n\r\
    \n:local url \"https://api.telegram.org/bot\$botID/sendmessage\?chat_id=\$\
    chatID&text=\$text\"\r\
    \n:if ([:len \$mode]>0) do={:set url (\$url.\"&parse_mode=\$mode\")}\r\
    \n\r\
    \n:local file (\$tgStorage.\"tg_get_updates.txt\")\r\
    \n:local logfile (\$tgStorage.\"tg_fetch_log.txt\")\r\
    \n\r\
    \n/tool fetch url=\$url keep-result=no"
add dont-require-permissions=no name=tg_cmd_cpu owner=admin policy=read \
    source=":local send [:parse [/system script get tg_sendMessage source]]\r\
    \n:local hotspot [:len [/ip hotspot active find]]\r\
    \n\r\
    \n:put \$params\r\
    \n:put \$chatid\r\
    \n:put \$from\r\
    \n \r\
    \n:local text \"Router Id:* \$[/system identity get name] * %0A\\\r\
    \nUptime: _\$[/system resource get uptime]_%0A\\\r\
    \nCPU Load: _\$[/system resource get cpu-load]%_%0A \\\r\
    \nRAM: _\$(([/system resource get total-memory]-[/system resource get free\
    -memory])/(1024*1024))M/\$([/system resource get total-memory]/(1024*1024)\
    )M_%0A\\\r\
    \nVoltage: _\$[:pick [/system health get voltage] 0 2]V_%0A\\\r\
    \nTemp: _\$[ /system health get temperature]C_\"\r\
    \n \r\
    \n\$send chat=\$chatid text=\$text mode=\"Markdown\"\r\
    \n:return true"
add dont-require-permissions=no name=tg_cmd_hi owner=admin policy=read \
    source=":local send [:parse [/system script get tg_sendMessage source]]\r\
    \n\r\
    \n:put \$params\r\
    \n:put \$chatid\r\
    \n:put \$from\r\
    \n\r\
    \n:local text \"Router Id:* \$[/system identity get name] * %0A\\\r\
    \n==================%0A\\\r\
    \nMENU TERSEDIA%0A\\\r\
    \n==================%0A\\\r\
    \n/cpu%0A\\\r\
    \n/hotspot%0A\\\r\
    \n/ping%0A\\\r\
    \n/public%0A\\\r\
    \n/PoeAdd%0A\\\r\
    \n/dialing%0A\\\r\
    \n/eHotspot%0A\\\r\
    \n/dHotspot%0A\\\r\
    \n/force%0A\\\r\
    \n/reboot\"\r\
    \n \r\
    \n\$send chat=\$chatid text=\$text mode=\"Markdown\"\r\
    \n:return true"
add dont-require-permissions=no name=tg_cmd_hotspot owner=admin policy=read \
    source=":local send [:parse [/system script get tg_sendMessage source]]\r\
    \n:local hotspot [:len [/ip hotspot active find]]\r\
    \n\r\
    \n:put \$params\r\
    \n:put \$chatid\r\
    \n:put \$from\r\
    \n \r\
    \n:local text \"Router Id:* \$[/system identity get name] * %0A\\\r\
    \nHotspot users: _\$hotspot online_\"\r\
    \n \r\
    \n\$send chat=\$chatid text=\$text mode=\"Markdown\"\r\
    \n:return true"
add dont-require-permissions=no name=tg_cmd_public owner=admin policy=read \
    source=":local public;\r\
    \n\
    \n:local status;\
    \n\r\
    \n:local ddns;\r\
    \n\
    \n:set public [/ip cloud get public-address];\r\
    \n\
    \n:set ddns [/ip cloud get dns-name];\r\
    \n\
    \n/tool fetch url=\"https://api.telegram.org/bot(GANTI)/sendMessage\?chat_\
    id=(GANTI)&text=DDNS : \$ddns : IP Public : \$public \" keep-result=no"
add dont-require-permissions=no name=tg_cmd_ping owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source=":\
    local send [:parse [/system script get tg_sendMessage source]]\r\
    \n:put \$params\r\
    \n:put \$chatid\r\
    \n:put \$from\r\
    \n#Ping Variables\r\
    \n:local avgRtt;\r\
    \n:local pin\r\
    \n:local pout\r\
    \n:local datetime \"\$[/system clock get date] \$[/system clock get time]\
    \"\r\
    \n#Ping it real good\r\
    \n/tool flood-ping 8.8.8.8 count=10 do={\r\
    \n  \r\
    \n:if (\$sent = 10) do={\r\
    \n    \r\
    \n:set avgRtt \$\"avg-rtt\"\r\
    \n    \r\
    \n:set pout \$sent\r\
    \n    \r\
    \n:set pin \$received\r\
    \n  }\r\
    \n\r\
    \n}\r\
    \n\r\
    \n:local ploss (100 - ((\$pin * 100) / \$pout))\r\
    \n\r\
    \n:local logmsg (\"Ping Average for 8.8.8.8 - \".[:tostr \$avgRtt].\"ms - \
    packet loss: \".[:tostr \$ploss].\"%\")\r\
    \n\r\
    \n:log info \$logmsg\r\
    \n\r\
    \n:local text \"Router Id:* \$[/system identity get name] * %0A\\\r\
    \nTanggal : _\$datetime_%0A\\\r\
    \nPing : _8.8.8.8_%0A\\\r\
    \nLog : _\$logmsg_\"\r\
    \n\$send chat=\$chatid text=\$text mode=\"Markdown\"\r\
    \n:return true"
add dont-require-permissions=no name=tg_cmd_dialing owner=admin policy=\
    read,write source="/tool fetch url=\"https://api.telegram.org/bot(GANTI)/s\
    endMessage\?chat_id=(GANTI)&text=Dialing....\" keep-result=no\r\
    \n:delay 1\r\
    \n/interface pppoe-client enable pppoe-indihome\r\
    \n:delay 5\r\
    \n/ip cloud force-update"
add dont-require-permissions=no name=tg_cmd_dHotspot owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="/\
    ip hotspot disable hotspot\r\
    \n/tool fetch url=\"https://api.telegram.org/bot(GANTI)/sendMessage\?chat_\
    id=(GANTI)&text=Hotspot Disable\" keep-result=no"
add dont-require-permissions=no name=tg_cmd_eHotspot owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="/\
    ip hotspot enable hotspot\r\
    \n/tool fetch url=\"https://api.telegram.org/bot(GANTI)/sendMessage\?chat_\
    id=(GANTI)&text=Hotspot Enable\" keep-result=no"
add dont-require-permissions=no name=tg_cmd_force owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="/\
    ip cloud force-update\r\
    \n/tool fetch url=\"https://api.telegram.org/bot(GANTI)/sendMessage\?chat_\
    id=(GANTI)&text=Force Update DDNS\" keep-result=no"
add dont-require-permissions=no name=tg_cmd_PoeAdd owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source=":\
    local satu ([/interface pppoe-client monitor pppoe-indihome as-value]-> st\
    atus);\r\
    \n/tool fetch url=\"https://api.telegram.org/bot(GANTI)/sendMessage\?chat_\
    id=(GANTI)&text=\$satu\" keep-result=no\r\
    \n\r\
    \n\r\
    \n"
/system scheduler
add interval=20s name=Telegram on-event="/system script run tg_getUpdates" \
    policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-time=startup
