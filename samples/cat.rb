require 'soundwave.rb'

w1 = Wave.new("samples/wav/chimes.wav")
w2 = Wave.new("samples/wav/chord.wav")
new_w = w1.cat(w2)
new_w.save('new.wav')
