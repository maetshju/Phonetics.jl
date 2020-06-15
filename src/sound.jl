using WAV

struct Sound
  samples
  sr
end

"""
  Constructor for a `Sound` object
    Sound(fname)

  # Args
  * **fname** The filename of the wav file to load

  # Returns
  A `Sound` object containing the samples and the the sampling rate

  Examples
  =========

  s = Sound("sound.wav")
"""
function Sound(fname)
  s, sr = wavread(fname)
  s = vec(s)
  return Sound(s, sr)
end