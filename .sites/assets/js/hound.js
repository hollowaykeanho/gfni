// submodules
function _parseURLParams(keyword) {
	url = new URL(location.href);
	return url.searchParams.get(keyword);
}

function _clearConsole() {
	console.clear();
}

function _loadingSubmission() {
	console.log("submission is loading")
}

function _successSubmission(resp) {
	exitSubmission();
}

function _exitSubmission() {
	var url = document.getElementById('hound-input-form').dataset.redirect;
	setTimeout(_clearConsole, 1500);

	if (url == '' || url == null) {
		return
	}

	window.location.replace(url);
}

function _submitGoogleForm() {
	var url = document.getElementById('hound-input-form').action;
	var data = new FormData();

	// parse fullname field
	x = document.getElementById('form-fullname');
	data.append(x.name, x.value);

	// parse phone number
	x = document.getElementById('form-phone');
	data.append(x.name, x.value);

	// parse pid
	x = document.getElementById('form-pid');
	ret = _parseURLParams("pid");
	if (ret == '' || ret == null) {
		ret = x.value;
	}
	data.append(x.name, ret);

	// parse location
	x = document.getElementById('form-location');
	ret = _parseURLParams("location");
	if (ret == '' || ret == null) {
		ret = x.value;
	}
	data.append(x.name, ret);

	// send request
	var request = new XMLHttpRequest();
	request.open('POST', url, true);
	request.withCredentials = true;
	request.onload = function() {
		_loadingSubmission();
		if (this.status >= 200 && this.status < 400) {
			_successSubmission(this.response);
		} else {
			_exitSubmission();
		}
	}
	request.onerror = _exitSubmission();

	// clear the console
	request.send(data);
}

// HTML Interfaces
function SubmitHound(e) {
	e.preventDefault(); // stop conventional HTML submission
	_submitGoogleForm();
	return false; // stop double submission
}
