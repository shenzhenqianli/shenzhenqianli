---
title: 什么是内网穿透
description: 什么是内网穿透
keywords: ['内网穿透','frp']
date: null
stats: paragraph=44 sentences=59, words=853
---

什么是内网穿透

**内网穿透**作为程序员常用的调试手段之一，我们可以通过在个人电脑上运行花生壳或者 frp 等方式，让他人访问我们本地启动的服务，而且这种访问可以不受局域网的限制，当我们使用 [**ngrok**](https://ngrok.com/), [**frp**](https://github.com/fatedier/frp)等开源框架时，你是否有好奇过它神奇的作用？明明没有将服务部署到服务器，程序员们究竟是怎么通过这种特殊方式让所有人访问自己的主机的？本文将以 **frp 开源框架**为例，介绍内网穿透的原理。

## 公网 IP 与内网 IP

能否在公网中访问服务器的决定性因素：公网 IP

众所周知， IP 地址是每一位使用互联网的网民都会拥有的标识， IP 地址在互联网中起到的作用是定位，通过 IP 地址我们可以精确的定位到所需资源所在的服务器，这是对于一般用户来讲的，而对于程序员而言，我们需要的则是让用户通过 IP 地址定位到我们部署的资源，既然每个互联网用户都拥有 IP 地址，为什么用户无法直接访问部署在个人 PC 上的服务呢？

事实上，IP 地址分为两种：公网 IP 和内网 IP

**内网 IP ：**内网 IP 是用户在使用局域网时，由局域网的网关所分配的 IP 地址，每一个内网 IP 实际上都可以映射到当前所在局域网网关的某一端口（ IPV4 地址通过 NAT 与端口映射方式实现，具体原理下文详解），拥有内网 IP 可以被同一局域网下的其他设备所访问到；

**公网 IP ：**内网的设备想要访问非同一局域网下的资源则必须通过公网 IP ，公网 IP 是没有经过 NAT 转换的由互联网供应商（ISP）提供的最原始的 IP 地址，每一个公网 IP 都可以直接在互联网中被直接定位到。

**一个最简单的例子（以前端开发为例）**：

当我们使用 webpack-dev-server 来启动一个 node 项目时，我们除了通过 `localhost:[&#x7AEF;&#x53E3;&#x53F7;]`的方式以外，与我们的开发设备处于同一局域网下的设备可以通过 `&#x5185;&#x7F51; IP :[&#x7AEF;&#x53E3;&#x53F7;]`的方式对我们的项目进行访问，但当我们使用自己的流量或者连接其他非当前开发设备所在局域网的设备使用 `&#x5185;&#x7F51; IP :[&#x7AEF;&#x53E3;&#x53F7;]`的方式进行进行访问时，则无法访问。

原因：

内网 IP 地址仅在当前局域网下可以被定位并访问到，而当我们想要跨局域网访问时，我们的访问请求则需要先映射为公网 IP 然后访问到另一局域网的公网 IP ，最后由另一局域网的网关将其映射到相应的局域网设备，但我们访问的地址属于局域网中的内网 IP ，因此无法定位到其相应的公网 IP

综上所述，当我们想要让处于其他局域网下的设备访问到我们本地资源，必不可缺的就是 **公网 IP**。

相较于内网 IP ，公网 IP 明显比内网 IP 更加有用，为什么不可以人手一个公网 IP 呢？

尽管 IPV6 的概念在几年前已经被提出，但实际的普及程度并没有很高，现在大部分网络用户使用的依旧是 IPV4 的 IP 地址，这也是限制公网 IP 个数的最大原因。

**IPV4：** IPV4 由 32 位二进制数组成，一共有 2^32 个不同的 IPV4 地址

**IPV6**：IPV6 由 128 位二进制数组成，理论上共有 2^128 个不同的 IPV6 地址

由此可见， IPV4 地址的个数并不足以满足当前全世界网络用户的人手一个 IP 地址的需求，那么当前的网络为什么可以让这么多用户同时在网络上冲浪呢？

网络地址转化技术的核心作用在于实现对公网 IP 地址的复用，即所有的内网主机共用同一个 IP 地址，NAT 的实现方式共有三种：

- 静态转换：将内网 IP 直接转换为公网 IP 地址，形成一一对应的方式

- 动态转换：将内网 IP 地址转换为公网 IP 地址，与静态转换不同的是动态转换会在 IP 池中选择空闲 IP 地址进行转换，即每次同一个内网 IP 对应的公网 IP 会发生改变

- 端口多路复用(PAT 技术)：将内网 IP 与公网 IP 的某一端口进行映射，通过公网 IP 的某一端口访问公网

可以看出以上三种形式中 **端口多路复用(PAT)技术**可以最大程度上缓解 IPV4 地址紧张的现状，也是最为广泛使用的实现方式，三种 NAT 实现方式共同点在于：对于内网用户来说自己对应的公网 IP 是不可知的，就好像我们可以知道自己的门牌号但无法知道自己所在的小区，因此无法准确告诉别人我们的具体地址。

## 内网穿透

在已知了当前内外网工作方式后，我们再来看一看作为程序员常用的技术手段 **内网穿透**

在此之前或许很多人都曾使用过如 **花生壳、ngrok、frp** 等方式在没有服务器的情况下将一些服务部署到网络上让别人使用

那么内网穿透的原理究竟是怎么样的呢？

目前市面上主流的内网穿透工具实现的原理如下：

可见，内网穿透的核心原理在于将外网 IP 地址与内网 IP 地址建立联系，市面上常用的如花生壳工具其核心原理就是依靠一台具有公网 IP 的服务器作为请求的中转站以此来达到从公网访问内网主机的目的。

当我们启动花生壳的服务时，花生壳会将本地配置好的端口和服务器上的端口进行映射，告知服务器请求转发的路径，花生壳的公网服务器则会监听相应端口的请求，当用户访问花生壳提供的 IP 地址时，花生壳的对应 IP 地址的公网主机将会根据访问的端口映射到相应的内网主机，并通过预先配置好的服务端口将请求转发，以达到访问内网主机相应服务的效果。

花生壳作为一款商业产品，对于配置端口等一系列工作进行了封装，使得用户可以更快捷的使用内网穿透，但我们在了解原理后完全可以通过一些开源的框架以及一台公网服务器实现对应的内网穿透功能，我们以 **frp** 为例。

```
&#x670D;&#x52A1;&#x7AEF;&#x8BBE;&#x7F6E;(frps.ini)&#xFF1A;<br>[common]<br>bind_port&#xA0;=&#xA0;7000&#xA0;&#xA0;&#xA0;&#xA0;&#xA0;&#xA0;&#xA0;//&#x6B64;&#x5904;&#x586B;&#x5199;&#x5BA2;&#x6237;&#x7AEF;&#x76D1;&#x542C;&#x7684;&#x670D;&#x52A1;&#x7AEF;&#x7AEF;&#x53E3;&#x53F7;<br>vhost_http_port&#xA0;=&#xA0;8080&#xA0;//&#x6B64;&#x5904;&#x586B;&#x5199;&#x7528;&#x6237;&#x8BBF;&#x95EE;&#x7684;&#x7AEF;&#x53E3;&#x53F7;<br><br>&#x5BA2;&#x6237;&#x7AEF;&#x914D;&#x7F6E;(frpc.ini)&#xFF1A;<br>[common]<br>server_addr&#xA0;=&#xA0;x.x.x.x&#xA0;//&#x6B64;&#x5904;&#x586B;&#x5199;&#x670D;&#x52A1;&#x7AEF;&#xA0;IP&#xA0;&#x5730;&#x5740;<br>server_port&#xA0;=&#xA0;7000&#xA0;&#xA0;&#xA0;&#xA0;//&#x6B64;&#x5904;&#x586B;&#x5199;&#x670D;&#x52A1;&#x7AEF;&#x914D;&#x7F6E;&#x7684;bind_port<br><br>[web]<br><span>type</span>&#xA0;=&#xA0;http&#xA0;&#xA0;&#xA0;&#xA0;&#xA0;&#xA0;&#xA0;&#xA0;&#xA0;//&#x6B64;&#x5904;&#x89C4;&#x5B9A;&#x8F6C;&#x53D1;&#x8BF7;&#x6C42;&#x7684;&#x534F;&#x8BAE;&#x7C7B;&#x578B;<br>local_port&#xA0;=&#xA0;80&#xA0;&#xA0;&#xA0;&#xA0;&#xA0;//&#x6B64;&#x5904;&#x89C4;&#x5B9A;&#x672C;&#x5730;&#x670D;&#x52A1;&#x542F;&#x52A8;&#x7684;&#x5730;&#x5740;<br>custom_domains&#xA0;=&#xA0;www.example.com&#xA0;&#xA0;&#xA0;//&#x6B64;&#x5904;&#x53EF;&#x4EE5;&#x586B;&#x5199;&#x81EA;&#x5B9A;&#x4E49;&#x57DF;&#x540D;&#xFF08;&#x9700;&#x8981;&#x5728;&#xA0;IP&#xA0;&#x5730;&#x5740;&#x4E0B;&#x914D;&#x7F6E;&#x57DF;&#x540D;&#x89E3;&#x6790;&#xFF09;
```

当我们配置完上述的文件后，用户的访问请求将会经过如下的步骤：

用户的请求将会经过域名解析，公网端口的转发以及内网主机的监听三个步骤成功将请求发送到对应的内网服务，当然 frp 相较于花生壳提供了更多的自定义配置项，此处不做详细讲解，有兴趣的读者可以访问：frp 中文文档(https://gofrp.org/docs/examples/)

当我们使用 frp 去配置我们自己的内网穿透服务时，我们可以使用一台服务器为大量的内网主机提供公网访问的功能，以此来实现公网 IP 的复用，其原理与上文提到的 PAT 端口多路复用技术相类似，当我们临时需要使用服务器时，只需要向拥有公网服务器的朋友申请两个闲置端口即可。

## frp 核心代码解析

本文以 http 请求为例解析当一个公网请求发送到 frp 服务器后究竟会经过哪些步骤

```
<span><span>func</span>&#xA0;<span>runServer</span><span>(cfg&#xA0;config.ServerCommonConf)</span>&#xA0;<span>(err&#xA0;error)</span></span>&#xA0;{<br>&#xA0;log.InitLog(cfg.LogWay,&#xA0;cfg.LogFile,&#xA0;cfg.LogLevel,&#xA0;cfg.LogMaxDays,&#xA0;cfg.DisableLogColor)<br><br>&#xA0;<span>if</span>&#xA0;cfgFile&#xA0;!=&#xA0;<span>""</span>&#xA0;{<br>&#xA0;&#xA0;log.Info(<span>"frps&#xA0;uses&#xA0;config&#xA0;file:&#xA0;%s"</span>,&#xA0;cfgFile)<br>&#xA0;}&#xA0;<span>else</span>&#xA0;{<br>&#xA0;&#xA0;log.Info(<span>"frps&#xA0;uses&#xA0;command&#xA0;line&#xA0;arguments&#xA0;for&#xA0;config"</span>)<br>&#xA0;}<br>&#xA0;&#xA0;<br>&#xA0;&#xA0;<span>//&#xA0;!important&#xA0;&#x6838;&#x5FC3;&#x4EE3;&#x7801;1</span><br>&#xA0;svr,&#xA0;err&#xA0;:=&#xA0;server.NewService(cfg)<br>&#xA0;<span>if</span>&#xA0;err&#xA0;!=&#xA0;<span>nil</span>&#xA0;{<br>&#xA0;&#xA0;<span>return</span>&#xA0;err<br>&#xA0;}<br>&#xA0;log.Info(<span>"frps&#xA0;started&#xA0;successfully"</span>)<br>&#xA0;&#xA0;<span>//&#xA0;!important&#xA0;&#x6838;&#x5FC3;&#x4EE3;&#x7801;2</span><br>&#xA0;svr.Run()<br>&#xA0;<span>return</span><br>}
```

在 `frp/cmd/frps/root.go`中

- 核心代码 1: server.NewService() 方法对我们在 `frps` 中的配置进行解析，初始化 frp 服务端
- 核心代码 2: serever.Run() 方法启动 frp 服务

```
<span>for</span>{&#xA0;&#xA0;<br>&#xA0;&#xA0;<span>//&#xA0;!important&#xA0;&#x6838;&#x5FC3;&#x4EE3;&#x7801;3</span><br>conn,&#xA0;session,&#xA0;err&#xA0;:=&#xA0;svr.login()<br>&#xA0;&#xA0;<span>if</span>&#xA0;err&#xA0;!=&#xA0;<span>nil</span>&#xA0;{<br>&#xA0;&#xA0;&#xA0;xl.Warn(<span>"login&#xA0;to&#xA0;server&#xA0;failed:&#xA0;%v"</span>,&#xA0;err)<br><br>&#xA0;&#xA0;&#xA0;<span>//&#xA0;if&#xA0;login_fail_exit&#xA0;is&#xA0;true,&#xA0;just&#xA0;exit&#xA0;this&#xA0;program</span><br>&#xA0;&#xA0;&#xA0;<span>//&#xA0;otherwise&#xA0;sleep&#xA0;a&#xA0;while&#xA0;and&#xA0;try&#xA0;again&#xA0;to&#xA0;connect&#xA0;to&#xA0;server</span><br>&#xA0;&#xA0;&#xA0;<span>if</span>&#xA0;svr.cfg.LoginFailExit&#xA0;{<br>&#xA0;&#xA0;&#xA0;&#xA0;<span>return</span>&#xA0;err<br>&#xA0;&#xA0;&#xA0;}<br>&#xA0;&#xA0;&#xA0;util.RandomSleep(<span>10</span>*time.Second,&#xA0;<span>0.9</span>,&#xA0;<span>1.1</span>)<br>&#xA0;&#xA0;}&#xA0;<span>else</span>&#xA0;{<br>&#xA0;&#xA0;&#xA0;<span>//&#xA0;login&#xA0;success</span><br>&#xA0;&#xA0;&#xA0;&#xA0;&#xA0;&#xA0;<span>//&#xA0;!important&#xA0;&#x6838;&#x5FC3;&#x4EE3;&#x7801;4</span><br>&#xA0;&#xA0;&#xA0;ctl&#xA0;:=&#xA0;NewControl(svr.ctx,&#xA0;svr.runID,&#xA0;conn,&#xA0;session,&#xA0;svr.cfg,&#xA0;svr.pxyCfgs,&#xA0;svr.visitorCfgs,&#xA0;svr.serverUDPPort,&#xA0;svr.authSetter)<br>&#xA0;&#xA0;&#xA0;ctl.Run()<br>&#xA0;&#xA0;&#xA0;svr.ctlMu.Lock()<br>&#xA0;&#xA0;&#xA0;svr.ctl&#xA0;=&#xA0;ctl<br>&#xA0;&#xA0;&#xA0;svr.ctlMu.Unlock()<br>&#xA0;&#xA0;&#xA0;<span>break</span><br>&#xA0;&#xA0;}<br>}
```

在 `frp/cmd/client/service.go`中

- 核心代码 3: for 循环不断去发起和服务端的连接，失败后会再次发起
- 核心代码 4: 连接成功后，客户端会使用连接的信息调用 NewControl()

**frps 发起连接**

```
<span><span>func</span>&#xA0;<span>(pxy&#xA0;*BaseProxy)</span>&#xA0;<span>GetWorkConnFromPool</span><span>(src,&#xA0;dst&#xA0;net.Addr)</span>&#xA0;<span>(workConn&#xA0;net.Conn,&#xA0;err&#xA0;error)</span></span>&#xA0;{<br>&#xA0;xl&#xA0;:=&#xA0;xlog.FromContextSafe(pxy.ctx)<br>&#xA0;<span>//&#xA0;try&#xA0;all&#xA0;connections&#xA0;from&#xA0;the&#xA0;pool</span><br>&#xA0;<span>for</span>&#xA0;i&#xA0;:=&#xA0;<span>0</span>;&#xA0;i&#xA0;< pxy.poolcount+<span>1;&#xA0;i++&#xA0;{<br>&#xA0;&#xA0;&#xA0;&#xA0;<span>//&#xA0;!important&#xA0;&#x6838;&#x5FC3;&#x4EE3;&#x7801;5</span><br>&#xA0;&#xA0;<span>if</span>&#xA0;workConn,&#xA0;err&#xA0;=&#xA0;pxy.getWorkConnFn();&#xA0;err&#xA0;!=&#xA0;<span>nil</span>&#xA0;{<br>&#xA0;&#xA0;&#xA0;xl.Warn(<span>"failed&#xA0;to&#xA0;get&#xA0;work&#xA0;connection:&#xA0;%v"</span>,&#xA0;err)<br>&#xA0;&#xA0;&#xA0;<span>return</span><br>&#xA0;&#xA0;}<br>&#xA0;&#xA0;xl.Debug(<span>"get&#xA0;a&#xA0;new&#xA0;work&#xA0;connection:&#xA0;[%s]"</span>,&#xA0;workConn.RemoteAddr().String())<br>&#xA0;&#xA0;xl.Spawn().AppendPrefix(pxy.GetName())<br>&#xA0;&#xA0;workConn&#xA0;=&#xA0;frpNet.NewContextConn(pxy.ctx,&#xA0;workConn)<br>&#xA0;&#xA0;&#xA0;&#xA0;......<br>&#xA0;&#xA0;&#xA0;&#xA0;<span>//&#xA0;!important&#xA0;&#x6838;&#x5FC3;&#x4EE3;&#x7801;6</span><br>&#xA0;&#xA0;&#xA0;&#xA0;err&#xA0;:=&#xA0;msg.WriteMsg(workConn,&#xA0;&msg.StartWorkConn{<br>&#xA0;&#xA0;&#xA0;ProxyName:&#xA0;pxy.GetName(),<br>&#xA0;&#xA0;&#xA0;SrcAddr:&#xA0;&#xA0;&#xA0;srcAddr,<br>&#xA0;&#xA0;&#xA0;SrcPort:&#xA0;&#xA0;&#xA0;<span>uint16</span>(srcPort),<br>&#xA0;&#xA0;&#xA0;DstAddr:&#xA0;&#xA0;&#xA0;dstAddr,<br>&#xA0;&#xA0;&#xA0;DstPort:&#xA0;&#xA0;&#xA0;<span>uint16</span>(dstPort),<br>&#xA0;&#xA0;&#xA0;Error:&#xA0;&#xA0;&#xA0;&#xA0;&#xA0;<span>""</span>,<br>&#xA0;&#xA0;})<br>&#xA0;&#xA0;}<br>}<br></ pxy.poolcount+<span>
```

在 `frp/server/proxy.go`中

- 核心代码 5: `frps` 从多个连接中通过依次遍历的方式来获取第一个成功获取到的连接
- 核心代码 6: `frps` 通过获取到的连接向 frpc 发出 &msg.StartWorkConn 的消息，告诉 `frpc` 建立连接的相应信息

**frpc 响应连接**

```
<span><span>func</span>&#xA0;<span>(pxy&#xA0;*TCPProxy)</span>&#xA0;<span>InWorkConn</span><span>(conn&#xA0;net.Conn,&#xA0;m&#xA0;*msg.StartWorkConn)</span></span>&#xA0;{<br>&#xA0;&#xA0;<span>//&#xA0;!important&#xA0;&#x6838;&#x5FC3;&#x4EE3;&#x7801;7</span><br>&#xA0;HandleTCPWorkConnection(pxy.ctx,&#xA0;&pxy.cfg.LocalSvrConf,&#xA0;pxy.proxyPlugin,&#xA0;pxy.cfg.GetBaseInfo(),&#xA0;pxy.limiter,<br>&#xA0;&#xA0;conn,&#xA0;[]<span>byte</span>(pxy.clientCfg.Token),&#xA0;m)<br>}
```

在 `frp/client/proxy/proxy.go`中

- 核心代码 7: ` frpc` 接收到 `frps` 的信息后发起 TCP 连接

**frps 发送消息**

```
<span><span>func</span>&#xA0;<span>(ctl&#xA0;*Control)</span>&#xA0;<span>writer</span><span>()</span></span>&#xA0;{<br>&#xA0;xl&#xA0;:=&#xA0;ctl.xl<br>&#xA0;<span>defer</span>&#xA0;<span><span>func</span><span>()</span></span>&#xA0;{<br>&#xA0;&#xA0;<span>if</span>&#xA0;err&#xA0;:=&#xA0;<span>recover</span>();&#xA0;err&#xA0;!=&#xA0;<span>nil</span>&#xA0;{<br>&#xA0;&#xA0;&#xA0;xl.Error(<span>"panic&#xA0;error:&#xA0;%v"</span>,&#xA0;err)<br>&#xA0;&#xA0;&#xA0;xl.Error(<span>string</span>(debug.Stack()))<br>&#xA0;&#xA0;}<br>&#xA0;}()<br><br>&#xA0;<span>defer</span>&#xA0;ctl.allShutdown.Start()<br>&#xA0;<span>defer</span>&#xA0;ctl.writerShutdown.Done()<br><br>&#xA0;encWriter,&#xA0;err&#xA0;:=&#xA0;crypto.NewWriter(ctl.conn,&#xA0;[]<span>byte</span>(ctl.serverCfg.Token))<br>&#xA0;<span>if</span>&#xA0;err&#xA0;!=&#xA0;<span>nil</span>&#xA0;{<br>&#xA0;&#xA0;xl.Error(<span>"crypto&#xA0;new&#xA0;writer&#xA0;error:&#xA0;%v"</span>,&#xA0;err)<br>&#xA0;&#xA0;ctl.allShutdown.Start()<br>&#xA0;&#xA0;<span>return</span><br>&#xA0;}<br>&#xA0;<span>for</span>&#xA0;{<br>&#xA0;&#xA0;m,&#xA0;ok&#xA0;:=&#xA0;<-ctl.sendch<br>&#xA0;&#xA0;<span>if</span>&#xA0;!ok&#xA0;{<br>&#xA0;&#xA0;&#xA0;xl.Info(<span>"control&#xA0;writer&#xA0;is&#xA0;closing"</span>)<br>&#xA0;&#xA0;&#xA0;<span>return</span><br>&#xA0;&#xA0;}<br>&#xA0;&#xA0;&#xA0;&#xA0;<span>//&#xA0;!important&#xA0;&#x6838;&#x5FC3;&#x4EE3;&#x7801;8</span><br>&#xA0;&#xA0;<span>if</span>&#xA0;err&#xA0;:=&#xA0;msg.WriteMsg(encWriter,&#xA0;m);&#xA0;err&#xA0;!=&#xA0;<span>nil</span>&#xA0;{<br>&#xA0;&#xA0;&#xA0;xl.Warn(<span>"write&#xA0;message&#xA0;to&#xA0;control&#xA0;connection&#xA0;error:&#xA0;%v"</span>,&#xA0;err)<br>&#xA0;&#xA0;&#xA0;<span>return</span><br>&#xA0;&#xA0;}<br>&#xA0;}<br>}<br></-ctl.sendch
```

在 `frp/server/control.go`中

- 核心代码 8: `frps` 发送信息到 crypto.NewWriter() 创建的 writer 中

**frpc 接收和响应**

```
<span>//&#xA0;!important&#xA0;&#x6838;&#x5FC3;&#x4EE3;&#x7801;9</span><br><span><span>func</span>&#xA0;<span>(ctl&#xA0;*Control)</span>&#xA0;<span>reader</span><span>()</span></span>&#xA0;{<br>&#xA0;xl&#xA0;:=&#xA0;ctl.xl<br>&#xA0;<span>defer</span>&#xA0;<span><span>func</span><span>()</span></span>&#xA0;{<br>&#xA0;&#xA0;<span>if</span>&#xA0;err&#xA0;:=&#xA0;<span>recover</span>();&#xA0;err&#xA0;!=&#xA0;<span>nil</span>&#xA0;{<br>&#xA0;&#xA0;&#xA0;xl.Error(<span>"panic&#xA0;error:&#xA0;%v"</span>,&#xA0;err)<br>&#xA0;&#xA0;&#xA0;xl.Error(<span>string</span>(debug.Stack()))<br>&#xA0;&#xA0;}<br>&#xA0;}()<br>&#xA0;<span>defer</span>&#xA0;ctl.readerShutdown.Done()<br>&#xA0;<span>defer</span>&#xA0;<span>close</span>(ctl.closedCh)<br><br>&#xA0;encReader&#xA0;:=&#xA0;crypto.NewReader(ctl.conn,&#xA0;[]<span>byte</span>(ctl.clientCfg.Token))<br>&#xA0;<span>for</span>&#xA0;{<br>&#xA0;&#xA0;m,&#xA0;err&#xA0;:=&#xA0;msg.ReadMsg(encReader)<br>&#xA0;&#xA0;<span>if</span>&#xA0;err&#xA0;!=&#xA0;<span>nil</span>&#xA0;{<br>&#xA0;&#xA0;&#xA0;<span>if</span>&#xA0;err&#xA0;==&#xA0;io.EOF&#xA0;{<br>&#xA0;&#xA0;&#xA0;&#xA0;xl.Debug(<span>"read&#xA0;from&#xA0;control&#xA0;connection&#xA0;EOF"</span>)<br>&#xA0;&#xA0;&#xA0;&#xA0;<span>return</span><br>&#xA0;&#xA0;&#xA0;}<br>&#xA0;&#xA0;&#xA0;xl.Warn(<span>"read&#xA0;error:&#xA0;%v"</span>,&#xA0;err)<br>&#xA0;&#xA0;&#xA0;ctl.conn.Close()<br>&#xA0;&#xA0;&#xA0;<span>return</span><br>&#xA0;&#xA0;}<br>&#xA0;&#xA0;ctl.readCh&#xA0;<- m<br>&#xA0;}<br>}<br></- m
```

- 核心代码 9: `frpc` 读取 `frps` 转发的信息

到这里，我们的 `frps` 已经成功将公网中接收到的请求转发到 `frpc` 相应的端口了，这就是一个最简单的请求通过 frp 进行代理转发的流程。

本文所介绍的内网穿透技术相关的实现方式其实在我们的日常开发生活中有更多的使用场景，当我们深入了解了当前 IP 地址以及内外网的实现方式后，我们不难发现，当我们将内网穿透的图片稍加修改后就成为了我们常用的另一种功能的实现方式(VPN 实现原理)：

## 参考文献

> [frp 源码地址](https://github.com/fatedier/frp)
> [frp 源码阅读与分析(二)：TCP 内网穿透的实现](https://jiajunhuang.com/articles/2019_06_19-frp_source_code_part2.md.html)
