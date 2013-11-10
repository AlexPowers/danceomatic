({
	shim: {
		'three': {
            'exports': 'THREE'
		}
	},
	paths: {
	},
    baseUrl: "src",
    dir: "build/src",
    stubModules: ['cs'],
    modules: [
        {
            name: "main",
            exclude: ["coffee-script"]
        }
    ]
})
