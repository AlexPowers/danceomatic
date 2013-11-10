require.config({
	shim: {
		'three': {
            'exports': 'THREE'
		},
        'underscore' : {
            'exports': '_'
        }
	},
	paths: {
	}
});


require(["cs!app"], function(app) {app();});
