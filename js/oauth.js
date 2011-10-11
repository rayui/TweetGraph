var config = {
	consumerKey: 'sHauTttyGZMCdNHWReKbqQ',
	consumerSecret: 'R8hk5ZNvd5Kv3eLvwzX1UPv3Lb9a4Zf2q6dKc7WD8Q',
	accessTokenKey: '19388885-n05mwGkneTEPbTQp1i6fn6DevEGK5btATgZNkWX6w',
	accessTokenSecret: '0pwd7VRRbFOK7061tPpShD7Z1ppZvLaqJHh6E7cico'
}
var oauth = OAuth(config);
function success(data) {
	alert('Success ' + data.text);
}
function failure(data) {
	alert('Something bad happened! :(');
}
oauth.get('#', success, failure);