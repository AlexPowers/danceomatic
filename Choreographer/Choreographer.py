import pyen
import sys
import pprint, json, copy

en = pyen.Pyen()

#if len(sys.argv) < 2:
#	print 'Usage: python playlist.py seed artist name'
#else:
#	artist_name = ' '.join(sys.argv[1:])
#    response = en.get('playlist/static', artist=artist_name, type='artist-radio' )

#'SOBBYDX12A8C138D55'
def Cranky():
	response = en.get('track/profile', id='TRTLKZV12E5AC92E11', format='json', bucket='audio_summary' )

	pprint.pprint(response)
#    for i, song in enumerate(response['songs']):
#    	print song
        #print "%d %-32.32s %s" % (i, song['artist_name'], song['title'])

#print json.dumps(['foo', {'bar': ('baz', None, 1.0, 2)}])



def FindActors(segment):
	loudness_max = segment[u'loudness_max']
	index = int(abs(round(loudness_max)))
	#print loudness_max, "\t", (loudness_max + 6) / 6
	if index < 0:
		index = 7
	if index > 6:
		index = 6
	# art $  - we're just picking actors based on the volume
	playerChoices = [
		[6],
		[1, 2, 3],
		[4, 5],
		[7, 8],
		[9, 10, 11],
		[1, 2, 3, 4, 5, 7, 8, 9, 10, 11],
		[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
		[2, 4, 6, 8]
		]
#	print index
	return playerChoices[index]


def Choreograph(analysisFile):
	inputFile = open(analysisFile)
	analysisDataRaw = inputFile.read()
	analysisData = json.loads(analysisDataRaw)

	dance = []

	segments = analysisData[u'segments']
	#pprint.pprint(segments)

	for i in segments:
		confidence = i[u'confidence']
		if confidence > 0.5:		# art $ - which should segments to follow?
			#pprint.pprint(i)
			start = i[u'start']
			currentAction = {}
			target = FindActors(i)

			pitches = i[u'pitches']
			action = pitches.index(1.0)

			currentAction['action'] = action
			currentAction['time'] = start
			currentAction['target'] = target
			dance.append(currentAction)	#copy.deepcopy(currentAction))

	pprint.pprint(dance)
	
			



Choreograph("/Users/alex/Development/Hack Day 2013/She Gets Remote-analysis.json")


dance = [
	{ 'time': 0.2, 'target': [ 1, 3, 5 ], 'action': "XXX" },
	{ 'time': 0.5, 'target': [ 3, 5 ], 'action': "XXX" }
	]

#print json.dumps(dance)


"""

# what anim, what tempo
actions:
moveto - first one bleams
#movepart: { part:

grouping vs addressing 1 dancer
	addressing sub parts of person
	
array of times

Dancer1:{ { x: 10, y: 10 },		where do they start
moveTo{ { x: 120, y: 30, duration: 0.2 }


"""