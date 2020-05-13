// constants
const houndFormLabel = 'hound-input-form';
const houndResponderLabel = 'hound-responder';

// submodules
function _exitSubmission() {
	var url = document.getElementById(houndFormLabel).dataset.redirect;
	setTimeout(function(){ console.clear(); }, 1500);

	if (url == null || url == '') {
		return
	}

	window.location.replace(url);
}

// setup hound form
var form = document.getElementById(houndFormLabel)
if (form) {
	form.target = houndResponderLabel;
}

// set hound responder
var iframe = document.getElementById(houndResponderLabel);
if (iframe) {
	iframe.style.visibility = 'hidden';
	iframe.height = '1px';
	iframe.onload = _exitSubmission;
}
