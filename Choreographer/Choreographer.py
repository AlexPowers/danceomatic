import pyen
import sys
import pprint, json, copy
import time
import urllib2


en = pyen.Pyen()
en.trace = False


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

def FindActorsForKey(index):
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

def FindActorsKey(segment):
	loudness_max = segment[u'loudness_max']
	index = int(abs(round(loudness_max)))
	#print loudness_max, "\t", (loudness_max + 6) / 6
	return index
	#return FindActorsForKey(index)

def FindMovement(segment, index, maxTimbre, minTimbre):
	# makes movement based one timbre and group of people acting
	timbre = segment[u'timbre']

	targetTimbre = timbre[index % len(timbre)]
	normalizedTimbre = (targetTimbre - minTimbre) / (maxTimbre - minTimbre)
	#print normalizedTimbre, targetTimbre, index, index % len(timbre)

#	stageRangeX = [-0.5, 1.5]	# the area of the stage on x includes offstage left and right

	moveX = (normalizedTimbre * 2) - 0.5

#	stageRangeY = [ 0, 1.0 ]
	targetTimbre = timbre[(index + 3) % len(timbre)]		# art $ - y coord is a few tembre's over
	normalizedTimbre = (targetTimbre - minTimbre) / (maxTimbre - minTimbre)

	moveY = normalizedTimbre
	speed = 0.1 / 0.25
	# first actor in group is reference for coordinates
	return { 'x': moveX, 'y': moveY, 'speed': speed }

def Choreograph(analysisDataRaw, tempo):
#	inputFile = open(analysisFile)
#	analysisDataRaw = inputFile.read()
	analysisData = json.loads(analysisDataRaw)

	dance = [ ]

	segments = analysisData[u'segments']
	#pprint.pprint(analysisData)

	#determine light fade in and out
	found_light_fade_in = False
	start_of_fade_out = analysisData[u'track'][u'start_of_fade_out']
	end_of_fade_out = analysisData[u'track'][u'duration']
	
	# make one starting gesture
	# art $ - we pick an arbitrary starting set based on the tempo
	startingSeed = int(abs(round((tempo - 50) / 15)))
	startingTarget = FindActorsForKey(startingSeed)
	# $$$ set up non starting actors split off stage left and right
	startingPos = [ 0.5, 0.5 ] # art $ - those who start on stage start right in the middle

	# compute the range of the timbres so we can use them to compute position
	maxTimbres = []
	minTimbres = []
	for i in segments:
		timbre = i[u'timbre']
		#print timbre
		maxTimbres.append(max(timbre))
		minTimbres.append(min(timbre))
	maxTimbre = max(maxTimbres)
	minTimbre = min(minTimbres)

	for i in segments:
		confidence = i[u'confidence']
		if confidence > 0.5:		# art $ - which should segments to follow?

			start = i[u'start']
			if not found_light_fade_in:
				found_light_fade_in = True
				light_fade_in = start	# art $ - lights end fade in at first move after opening

			currentAction = {}
			index = FindActorsKey(i)
			target = FindActorsForKey(index)
			movement = FindMovement(i, index, maxTimbre, minTimbre)

			pitches = i[u'pitches']
			action = pitches.index(1.0)

			currentAction['action'] = action
			currentAction['time'] = start
			currentAction['target'] = target
			currentAction['moveto'] = movement
			dance.append(currentAction)	#copy.deepcopy(currentAction))

	results = { 'tempo' : tempo, 'dance': dance,
		'light_fade_out_start':start_of_fade_out,
		'light_fade_out_end':end_of_fade_out,
		'light_fade_in_start':0,
		'light_fade_in_end':light_fade_in,
		'starting_target':startingTarget
		}
	print json.dumps(results)
	#pprint.pprint(results)


def wait_for_analysis(id):
	while True:
		response = en.get('track/profile', id=id, bucket=['audio_summary'])
		if response['track']['status'] <> 'pending':
			break
		time.sleep(1)

	tempo = response['track']['audio_summary']['tempo']
	analysis_url = response['track']['audio_summary']['analysis_url']

	response = urllib2.urlopen(analysis_url)
	analysisJSON = response.read()

	#print analysisJSON
	Choreograph(analysisJSON, tempo)		#"/Users/alex/Development/Hack Day 2013/She Gets Remote-analysis.json")



if len(sys.argv) > 2:
	mp3 = sys.argv[1]
	type = sys.argv[2]

	f = open(mp3, 'rb')
	response = en.post('track/upload', track=f, filetype=type)
	trid = response['track']['id']
	#print 'track id is', trid
	wait_for_analysis(trid)
else:
	print "usage: python Choreographer.py path-audio audio-type"





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