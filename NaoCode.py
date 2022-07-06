#importing necesary libraries
import naoqi
import numpy
from naoqi import ALProxy
import time
import scipy
import scipy.io
from scipy.io import wavfile
from scipy.signal import butter, lfilter
import paramiko
import matplotlib.pyplot as plt
import numpy as np
import wave
import sys
import math
import contextlib
from pygame import mixer



naoIP= "169.254.72.52"
port=9559
word=[]

#We will be using nao's text to speech functionality to let the user know
# the robot has successfully initialized

tts= ALProxy("ALTextToSpeech", naoIP, port) #initializing the text to speech module
tts.say("The robot is starting to record")  

time.sleep(1)   #waiting to give the user time to interact

# we can choose whether to use ALAudioDevice or ALAudioRecorder
# for this particular subject, we will be using ALAudioDevice
AD= ALProxy("ALAudioDevice", naoIP, port)
AD.startMicrophonesRecording("/data/home/nao/recorings/microphones/record.wav")
time.sleep(5) # we want to record for 5 seconds
AD.stopMicrophonesRecording()

tts.say("The robot has stopped recording")
time.sleep(1)

#automatic file transfer protocol
NAO_IP = naoIP
NAO_USERNAME = "nao"
NAO_PASSWORD = "Quetzal_3"
word=[]
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(NAO_IP, username=NAO_USERNAME, password=NAO_PASSWORD)
sftp = ssh.open_sftp()
localpath = 'D:\\record.wav'
remotepath = '//data//home//nao//recorings//microphones//record.wav'
sftp.get(remotepath, localpath)
sftp.close()

#now we should try a recognition on the sounds, played by nao's internal speakers

#speech recognition module initializations
asr= ALProxy("ALSpeechRecognition", naoIP, port)
asr.pause(True)
asr.setLanguage("English")
vocabulary= ["stand", "sit"]
asr.setVocabulary(vocabulary, False)


#subscribing to the speech recognition module
tts.say("The robot is starting the speech recognition service")
asr.subscribe(naoIP)   #subscribing to the speech recognition module
mem= ALProxy("ALMemory", naoIP, port)
mem.subscribeToEvent('WordRecognized', naoIP, 'wordRecognized')


#playing the file on the host machine
asr.pause(False)
time.sleep(2)
mixer.init()
mixer.music.load('D:\\record.wav')
mixer.music.play()

#the alloted time slot has expired
time.sleep(7)
asr.unsubscribe(naoIP)
word= mem.getData("WordRecognized")
print( "data: %s" % word )
tts.say(" The recognized word is %s" %word[0])
time.sleep(2)
tts.say("Robot finished the speech recognition procedure")
mem.removeData("WordRecognized")
#process it
tts.say("Robot is starting processing")



fname = 'D:\\record.wav'
outname = 'D:\\off_plus_noise_filtered.wav'

fc = 600.0

#calculating the running mean
def running_mean(x, windowSize):
  cumsum = np.cumsum(np.insert(x, 0, 0)) 
  return (cumsum[windowSize:] - cumsum[:-windowSize]) / windowSize

#default recording mode is interleaved ( otherwise channels.shape = (n_channels, n_frames))
def interpret_wav(raw_bytes, n_frames, n_channels, sample_width):
    dtype = np.int16 # signed 2-byte short

    channels = np.fromstring(raw_bytes, dtype=dtype)

    channels.shape = (n_frames, n_channels)
    channels = channels.T

    return channels

with contextlib.closing(wave.open(fname,'rb')) as winfo:
    sampleRate = winfo.getframerate()
    ampWidth = winfo.getsampwidth()
    nChannels = winfo.getnchannels()
    nFrames = winfo.getnframes()

    #get Filter Length
    normFreq = (fc/sampleRate) 
    N = int(math.sqrt(0.196196 + normFreq**2)/normFreq)

    # Extract audio
    signal = winfo.readframes(nFrames*nChannels)
    winfo.close()
    
    channels = interpret_wav(signal, nFrames, nChannels, ampWidth)

    # Use moviung average (only on first channel)
    filtered = running_mean(channels[0], N).astype(channels.dtype)

    wav_file = wave.open(outname, "w")
    wav_file.setparams((1, ampWidth, sampleRate, nFrames, winfo.getcomptype(), winfo.getcompname()))
    wav_file.writeframes(filtered.tobytes('C'))
    wav_file.close()


sftp = ssh.open_sftp()
localpath = 'D:\\off_plus_noise_filtered.wav'
remotepath = '/data/home/nao/recorings/microphones/off_plus_noise_filtered.wav'
sftp.put(localpath, remotepath)
sftp.close()
ssh.close()
#retry recognition
tts.say("The robot is playing audio clip")
asr.subscribe(naoIP)
mem.subscribeToEvent('WordRecognized', naoIP, 'wordRecognized')
time.sleep(2)
mixer.init()
mixer.music.load('D:\\anti_vuvuzela.wav')
mixer.music.play()
time.sleep(7)
asr.unsubscribe(naoIP)
word= mem.getData("WordRecognized")
if word[0]== 'sit':
  pos= ALProxy("ALRobotPosture", naoIP, port)
  pos.goToPosture('Sit', 0.5)
if word[0]== 'stand':
  pos= ALProxy("ALRobotPosture", naoIP, port)
  pos.goToPosture('Stand', 0.5)  
print( "data: %s" % word )
tts.say(" The recognized word is %s" %word[0])
time.sleep(2)
tts.say("Robot finished the speech recognition procedure")








