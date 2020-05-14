<!--
+++
date = "2020-05-13T14:25:19+08:00"
title = "Hound Form (Demo)"
description = """
This is a demonstration for ZORALab Hound software to let users to submit
self-tracking information to Google Forms.
"""
keywords = [""]
authors = ["ZORALab Team"]
draft = false
type = ""
layout = "single"
# thumbnailURL = "#"

[menu.main]
parent = ""
# name = ""
weight = 1
+++
-->
{{< renderHTML "html" >}}
<h1 align="center">Hound Demo Form</h1>
<p style="text-align: center">
This is the hound submission form. It is hosted on a static site generator
using <a href="https://zoralab.gitlab.io/bissetii/en-us/">ZORALab Bissetii</a>
styling engine. Check out the side-menu for more information.
</p>

<hr />

<form	id="hound-input-form"
	method="POST"
	target="hound-responder"
	action="https://docs.google.com/forms/d/e/1FAIpQLSdIZJcxSr4IabqjdE9Wq23JNMxwfCvrx6ToqRAfCTKBNUNWNw/formResponse"
	data-redirect="{{< absLangLink "pages/done" >}}"
	data-expiry="1"
>
	<fieldset>
		<label for="hound-fullname">Full Name per NRIC</label>
		<input type="text"
			id="hound-fullname"
			name="entry.1123956260"
			placeholder="John M. Smith"
			required
		/>
	</fieldset>

	<fieldset>
		<label for="hound-phone">Handphone</label>
		<input type="number"
			id="hound-phone"
			name="entry.30705284"
			placeholder="0123456789"
			required
		/>
	</fieldset>

	<fieldset>
		<label for="hound-phone">Temperature</label>
		<input type="number"
			id="hound-temperature"
			name="entry.200307806"
			placeholder="35.5"
			min="33"
			max="40"
			step="0.001"
			required
		/>
	</fieldset>

	<input type="hidden"
		id="hound-location"
		name="entry.1016469063"
		value="randomGeneratedSHA512IDIGuess"
		required
	/>

	<input type="hidden"
		id="hound-pid"
		name="entry.163974192"
		value="SecretPhraseForUniquelyID"
		required
	/>

	<fieldset>
		<input style="display: block; margin: auto" class="pinpoint"
		type="submit"
		value="Submit" />
	</fieldset>
</form>
<iframe id="hound-responder"
	name="hound-responder"
	height="150px"
	width="100%"
	scrolling="no">
</iframe>

<hr />
<br />
{{< /renderHTML >}}

> **VERY IMPORTANT INTERNAL NOTE**
>
> Please **DO NOT** submit real data onto this demo site.
>
> The [Google Form](https://docs.google.com/forms/d/1JxxZQVedoPVQBECIbIiWnmv0Wk17hdq6ew2sWsJflBg/edit?usp=sharing)
> and [Google Spreadsheet](https://docs.google.com/spreadsheets/d/1jwRz9UaivDH_Fn27IjvD3d6fcsZNV-GmkNFmkh324pg/edit?usp=sharing)
> in the backend are publicly viewable.
