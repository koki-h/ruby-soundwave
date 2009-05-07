require 'soundwave.rb'

file1 = open("samples/wav/wav1.wav")
w1 = Wave.new(file1)
w1.save('wav1_new.wav')
