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
draft = true
type = ""
layout = "single"
# thumbnailURL = "#"

[menu.main]
parent = ""
# name = ""
weight = 1
+++
-->

# Hound Submission
This is the hound submission form. It is hosted on a static site generator
using [ZORALab Bissetii](https://zoralab.gitlab.io/bissetii/en-us/) styling
engine. Check out the side-menu for more information.

> **VERY IMPORTANT NOTE**: Please **DO NOT** submit real data onto this demo
> site.
>
> The Google Form and Google Spreadsheet in the backend are publicly viewable.

{{< renderHTML "html" >}}
<br/>
<br/>

<form	id="hound-input-form"
	onsubmit="return SubmitHound(event);"
	method="POST"
	target="hound-iframe"
	action="https://docs.google.com/forms/d/e/1FAIpQLSdIZJcxSr4IabqjdE9Wq23JNMxwfCvrx6ToqRAfCTKBNUNWNw/formResponse"
>
	<fieldset>
		<label for="form-fullname">Full Name per NRIC</label>
		<input type="text"
			id="form-fullname"
			name="entry.1123956260"
			placeholder="John M. Smith"
			required
		/>
	</fieldset>

	<fieldset>
		<label for="form-phone">Handphone</label>
		<input type="number"
			id="form-phone"
			name="entry.30705284"
			placeholder="0123456789"
			required
		/>
	</fieldset>

	<input type="hidden"
		id="form-location"
		name="entry.1016469063"
		value="randomGeneratedSHA512IDIGuess"
		required
	/>

	<input type="hidden"
		id="form-pid"
		name="entry.163974192"
		value="SecretPhraseForUniquelyID"
		required
	/>

	<fieldset>
		<input type="submit"
		value="Submit" />
	</fieldset>
</form>
{{< /renderHTML >}}
