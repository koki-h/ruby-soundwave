require 'soundwave'
base_note = 440
base_amp  = 0.25
class Wave 
  alias make make_sin
end
sin1 = Wave.new.make(base_note, base_amp, 3)
sin3 = Wave.new.make(base_note * 5/4, base_amp / 3, 2)
sin5 = Wave.new.make(base_note * 3/2, base_amp / 2, 1)
sin1.add(sin3).add(sin5).reverse!.save('harmo.wav')
