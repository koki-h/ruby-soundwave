require 'lib/soundwave.rb'
sin_saw = Wave.new.make_sin_saw(250,0.25,1).save('sin_saw.wav')
