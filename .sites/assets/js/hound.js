/* CONSTANTS */
// form
const houndFormLabel = 'hound-input-form';
const houndResponderLabel = 'hound-responder';
const houndInputLocationLabel = 'hound-location';
const houndInputPIDLabel = 'hound-pid';
const houndInputFullnameLabel = 'hound-fullname';
const houndInputPhoneLabel = 'hound-phone';

// interceptors
const houndURLLocationLabel = 'location';
const houndURLPIDLabel = 'pid';
const houndFullnameLabel = 'fullname';
const houndPhoneLabel = 'phone';



/* SUB-MODULES */
function _parseURLParams(keyword) {
	url = new URL(location.href);
	return url.searchParams.get(keyword);
}

function _setCookie(name, value, days) {
	// determine payload
	var payload = name + "=" + (encodeURIComponent(value) || "");

	// determine age
	var age = "; max-age="
	if (isNaN(days)) {
		age += '259200'; // 3 days as default
	} else {
		age += days*24*60*60; // calculate age
	}

	// determine path
	var path = "; path=/";

	// set cookie
	document.cookie = payload + age + path + "; SameSite=strict; secure";
}

function _getCookie(name) {
	var i = 0;
	var query = name + "=";
	var list = document.cookie.split(';');

	for (i=0; i< list.length; i++) {
		var c = list[i];

		while (c.charAt(0)==' ') {
			c = c.substring(1, c.length);
		}

		if (c.indexOf(query) == 0) {
			return decodeURIComponent(c.substring(query.length,
				c.length));
		}
	}

	return null
}

function _exitSubmission() {
	// 1. process to save cookies
	var expiry = null;
	var x = document.getElementById(houndFormLabel)
	if (x) {
		expiry = x.dataset.expiry;
	}

	x = document.getElementById(houndInputFullnameLabel);
	if (x) {
		_setCookie(houndFullnameLabel, x.value, expiry);
	}

	x = document.getElementById(houndInputPhoneLabel);
	if (x) {
		_setCookie(houndPhoneLabel, x.value, expiry);
	}

	// 2. redirect exit
	var ret = document.getElementById(houndFormLabel).dataset.redirect;
	setTimeout(function(){ console.clear(); }, 1500);

	if (ret == null || ret == '') {
		return
	}

	window.location.replace(ret);
}

/* MAIN */
// 1. setup hound form
var form = document.getElementById(houndFormLabel)
if (form) {
	form.target = houndResponderLabel;

	// 1.1. update location from url parameter
	ret = _parseURLParams(houndURLLocationLabel);
	if (ret && ret != '') {
		x = document.getElementById(houndInputLocationLabel);
		if (x) {
			x.value = ret;
		}
	}

	// 1.2. update pid from url parameter
	ret = _parseURLParams(houndURLPIDLabel);
	if (ret && ret != '') {
		x = document.getElementById(houndInputPIDLabel);
		if (x) {
			x.value = ret;
		}
	}

	// 1.3. update fullname from cookie
	ret = _getCookie(houndFullnameLabel);
	if (ret && ret != '') {
		x = document.getElementById(houndInputFullnameLabel);
		if (x) {
			x.value = ret;
		}
	}

	// 1.4. update phone number from cookie
	ret = _getCookie(houndPhoneLabel);
	if (ret && ret != '') {
		x = document.getElementById(houndInputPhoneLabel);
		if (x) {
			x.value = ret;
		}
	}
}

// 2. setup hound responder
var iframe = document.getElementById(houndResponderLabel);
if (iframe) {
	iframe.style.visibility = 'hidden';
	iframe.height = '1px';
	iframe.onload = _exitSubmission;
}
