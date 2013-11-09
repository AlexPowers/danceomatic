require.config({
	shim: {
		'gl-matrix-min': {
            'exports': 'mat4'
		},
	},
	paths: {
		'jquery': 'jquery-1.9.0',
		'underscore': 'underscore-1.4.3',
        'lz-string': 'lz-string-1.3.3'
	}
});


require(["cs!app"], function(app) {app();});
