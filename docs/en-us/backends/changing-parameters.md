<!--
+++
date = "2020-05-13T20:10:31+08:00"
title = "Changing Parameters"
description = """
This page describes how to change the hidden parameters on the fly using the
URL parameters.
"""
keywords = ["changing", "parameters"]
authors = ["ZORALab Team"]
draft = false
type = ""
layout = "single"
# thumbnailURL = "#"

[menu.main]
parent = "Backends"
# name = "Changing Parameters"
weight = 1
+++
-->

# Changing Parameters
Hound does supply URL parameters for changes "on-the-fly". All you need to do
is to make good use of URL Parameters. Here are the supported list of parameters
available to change on-the-fly.




## Location
To alter location on-the-fly, all you need to do is append `location` URL
parameter such as `?location="someKindOfID`.

Try submit your information again using the following link and observe the
backend submitted location. It will be changed into `LocationIsNowURLParameter`
instead of the default.

> [{{< absLangLink "?location=LocationIsNowURLParameter" >}}]({{< absLangLink "?location=LocationIsNowURLParameter" >}})




## PID
Password ID is the recongizable filter phrase for valid submission. This can
be altered on-the-fly by appending `pid` URL parameter such as
`?pid=MySecretPhrase`.

Try submit your information again using the following link and observe the
backend submitted location. It will be changed into `MySecret---Phra234se`
instead of the default.

> [{{< absLangLink "?pid=MySecret---Phra234se" >}}]({{< absLangLink "?pid=MySecret---Phra234se" >}})
