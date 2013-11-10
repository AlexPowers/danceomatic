require.config({
	shim: {
		'three': {
            'exports': 'THREE'
		}
	},
	paths: {
	}
});


require(["cs!app"], function(app) {app();});
