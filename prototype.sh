#!/bin/bash

formID="1FAIpQLSdIZJcxSr4IabqjdE9Wq23JNMxwfCvrx6ToqRAfCTKBNUNWNw"
nameID="entry.1123956260"
phoneID="entry.30705284"
locationID="entry.1016469063"
secretID="entry.163974192"


baseURL="https://docs.google.com/forms/d/e/${formID}/formResponse?${locationID}=urlBasedLocation"


curl --request POST "$baseURL" \
	-d usp=pp_url \
	-d submit=Submit \
	-d "${nameID}=John Smith" \
	-d "${phoneID}=01255553456789" \
	-d "${secretID}=MySuperSecret" \
	> /dev/null
