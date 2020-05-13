<!--
+++
date = "2020-05-13T19:57:48+08:00"
title = "Backend Server"
description = """
This page explains the backend server for Hound to work using Google Forms.
"""
keywords = ["server"]
authors = ["ZORALab Team"]
draft = false
type = ""
layout = "single"
# thumbnailURL = "#"

[menu.main]
parent = "Backends"
# name = "Server"
weight = 1
+++
-->

# Backend Server
For running Hound, there are 2 backend elements:

1. Google Forms / Data API server
2. Static Site Generator (for presenting Hound web form)



## Google Forms + Google Sheet Integrations
As starter, Hound is fully integratable with Google Form and its corresponding
Google Sheet. For this demo you may visit:

1. Google Form: https://forms.gle/UZZgSRhVSQM1RwPw6
2. Google Sheet: https://docs.google.com/spreadsheets/d/1jwRz9UaivDH_Fn27IjvD3d6fcsZNV-GmkNFmkh324pg/view

with this demo, you can witness the changes and test out Hound's performance.



## Static Site Generator
Hound is actually a frondend web product. It is designed to operate using
client browser alone.

For this demo, Hound is hosted using
[GitLab Pages](https://gitlab.com/zoralab/hound-demo) boosted with Cloudflare
CDN. This keeps the website performance high across the world and reduces
stress to the GitLab Pages origin server.
