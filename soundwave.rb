#WAVEファイルを解析する
#dumpした結果を折れ線グラフなどにすれば波形を見ることが出来る
require 'pp'
include Math

class String
  def to_long
    self.unpack("L*")[0]
  end

  def to_short
    self.unpack("S*")[0]
  end
end

class Fixnum
  def pack_long
    [self].pack("L*")
  end

  def pack_short
    [self].pack("S*")
  end
end

class Wave
  #reference : http://www.kk.iij4u.or.jp/~kondo/wave/
  attr_accessor( 
    :riff_header   , #4 byte R' 'I' 'F' 'F'  	RIFFヘッダ  	　
    :file_size     , #4 byte これ以降のファイルサイズ (ファイルサイズ - 8) 	　 	　
    :wave_header   , #4 byte W' 'A' 'V' 'E' 	WAVEヘッダ 	RIFFの種類がWAVEであることをあらわす
    :fmt_difinit   , #4 byte f' 'm' 't' ' ' (←スペースも含む) 	fmt チャンク 	フォーマットの定義
    :fmt_size      , #4 byte バイト数 	fmt チャンクのバイト数 	リニアPCM ならば 16(10 00 00 00)
    :fmt_id        , #2 byte フォーマットID リニアPCM ならば 1(01 00)
    :channel_num   , #2 byte チャンネル数	モノラル ならば 1(01 00) ステレオ ならば 2(02 00)
    :sample_rate   , #4 byte サンプリングレート	Hz 	44.1kHz ならば 44100(44 AC 00 00)
    :data_speed    , #4 byte データ速度 (Byte/sec)44.1kHz 16bit ステレオ ならば 44100×2×2 = 176400(10 B1 02 00)
    :block_size    , #2 byte ブロックサイズ (Byte/sample×チャンネル数)	16bit ステレオ ならば 2×2 = 4(04 00)
    :bit_per_sample, #2 byte サンプルあたりのビット数 (bit/sample)WAV フォーマットでは8bitか16bit 16bit ならば 16(10 00)
    :extent_size   , #2 byte 拡張部分のサイズ リニアPCMならば存在しない
    :extent_body   , #n byte 拡張部分 リニアPCMならば存在しない
    :data_tag      , #4 byte d' 'a' 't' 'a' 	data チャンク
    :data_size     , #4 byte バイト数n 	波形データのバイト数 	　
    :data_body     , #n byte 波形データ
    :time            #再生時間（data_size/data_speed)
               )    

  def initialize(file=nil)
    case file.class.to_s
    when "File"
      read(file) 
    when "String" 
      open(file) {|f| read(f)}
    else
      #fileが与えられないときはヘッダをデフォルト値（16ビットモノラル）で作る。
      #以下のメンバは空
      # @file_size, @extent_size, @extent_body
      @riff_header    = "RIFF"
      @wave_header    = "WAVE"
      @fmt_difinit    = "fmt "
      @fmt_size       = 16
      @fmt_id         = 1
      @channel_num    = 1
      @sample_rate    = 44100
      @data_speed     = 44100
      @block_size     = 2
      @bit_per_sample = 16
      @data_tag       = "data"
      @data_size      = 0
      @data_body      = []
      @time           = 0
    end
  end

  def read(file)
    begin
      file.binmode
      @riff_header    =  file.read(4)
      if @riff_header != "RIFF"
        raise "File Format Wrong. Not RIFF"
      end
      @file_size      =  file.read(4).to_long
      @wave_header    =  file.read(4)
      @fmt_difinit    =  file.read(4)
      if @wave_header + @fmt_difinit != "WAVEfmt "
        raise "File format wrong. Not WAVE"
      end
      @fmt_size       =  file.read(4).to_long
      @fmt_id         =  file.read(2).to_short
      if @fmt_id != 1
        raise "PCM only available."
      end
      @channel_num    =  file.read(2).to_short
      @sample_rate    =  file.read(4).to_long
      @data_speed     =  file.read(4).to_long
      @block_size     =  file.read(2).to_short
      @bit_per_sample =  file.read(2).to_short
      #  @extent_size    =  file.read(2)            #not read
      #  @extent_body    =  file.read(@extent_size) #not read
      @data_tag       =  file.read(4)
      @data_size      =  file.read(4).to_long
      @data_body_raw   =  file.read(@data_size)
      @data_body = []
      if @channel_num == 2
        @data_body = @data_body_raw.unpack("l*")
      elsif @channel_num == 1
        @data_body = @data_body_raw.unpack("s*")
      end
      @time =  @data_size / @data_speed.to_f
    ensure
      file.close
    end
    self
  end

  def copy #自分と同じデータを持つ、新しいWaveを作って返す
    new_w = Wave.new
    new_w.riff_header    = @riff_header    
    new_w.file_size      = @file_size
    new_w.wave_header    = @wave_header   
    new_w.fmt_difinit    = @fmt_difinit   
    new_w.fmt_size       = @fmt_size      
    new_w.fmt_id         = @fmt_id        
    new_w.channel_num    = @channel_num   
    new_w.sample_rate    = @sample_rate   
    new_w.data_speed     = @data_speed    
    new_w.block_size     = @block_size    
    new_w.bit_per_sample = @bit_per_sample
    new_w.data_tag       = @data_tag       
    new_w.data_size      = @data_size
    new_w.data_body      = @data_body.dup
    new_w.time           = @time
    new_w
  end

  def save(file_name)
    #fileサイズの計算
    @file_size = 4 + #wave_header   
      4 + #fmt_difinit   
      4 + #fmt_size      
      2 + #fmt_id        
      2 + #channel_num   
      4 + #sample_rate   
      4 + #data_speed    
      2 + #block_size    
      2 + #bit_per_sample
      4 + #data_tag      
      4 + #data_size     
      @data_size 
    #データのpack
    if @channel_num == 2
      @data_body_raw = @data_body.pack("l*")
    else @channel_num == 1
      @data_body_raw = @data_body.pack("s*")
    end
    #ファイルオープン・書き込み
    f = File.open(file_name,"w")
    f.binmode
    f.write(@riff_header)
    f.write(@file_size.pack_long)
    f.write(@wave_header)
    f.write(@fmt_difinit)
    f.write(@fmt_size.pack_long)
    f.write(@fmt_id.pack_short)
    f.write(@channel_num.pack_short)
    f.write(@sample_rate.pack_long)
    f.write(@data_speed.pack_long)
    f.write(@block_size.pack_short)
    f.write(@bit_per_sample.pack_short)
    f.write(@data_tag)
    f.write(@data_size.pack_long)
    f.write(@data_body_raw)
    f.close
    self
  end

  def dump
    @data_body.join("\n")
  end

  def add(other) #別のWaveの波形と合成する
    unless other.class == self.class 
      raise "Cannot add. Both files need to be WAVE." 
    end
    new_w = self.copy
    data_arraysize = [@data_body.size,other.data_body.size].max
    new_w.data_body = Array.new(data_arraysize)
    new_w.data_body.each_index do |i|
      val1 = @data_body[i] || 0
      val2 = other.data_body[i] || 0
      new_val = val1 + val2
      new_w.data_body[i] = new_val
    end
    new_w.data_size = new_w.data_body.size * new_w.block_size
    new_w.time      =  new_w.data_size / new_w.data_speed.to_f
    new_w
  end

  def sub(other) #各サンプルの値を別のWaveの対応する値で減算する
    unless other.class == self.class 
      raise "Cannot substruct. Both files need to be WAVE." 
    end
    new_w = self.copy
    data_arraysize = [@data_body.size,other.data_body.size].max
    new_w.data_body = Array.new(data_arraysize)
    new_w.data_body.each_index do |i|
      val1 = @data_body[i] || 0
      val2 = other.data_body[i] || 0
      new_val = val1 - val2
      new_w.data_body[i] = new_val
    end
    new_w.data_size = new_w.data_body.size * new_w.block_size
    new_w.time      =  new_w.data_size / new_w.data_speed.to_f
    new_w
  end

  def cat(other) #otherのデータを自分のデータの後ろにくっつける
    #レートの違う音声ファイルをくっつけると変になるので注意！
    unless other.class == self.class 
      raise "Cannot Concat. Both files need to be WAVE." 
    end
    new_w = self.copy
    new_w.data_body.concat(other.data_body)
    new_w.data_size = new_w.data_body.size * new_w.block_size
    new_w.time      =  new_w.data_size / new_w.data_speed.to_f
    new_w
  end

  def make_sin(freq, amp, time) #データをサイン波にする(周波数、振幅、時間)
    @time = time
    body_size  = time * @sample_rate
    @data_body = Array.new(body_size)
    @data_size = body_size * @block_size
    @data_body.each_index do |i|
      @data_body[i] = amp * sin(2.0 * PI * freq * i / @sample_rate) * 32768 * @channel_num
    end
    self
  end

  def make_saw(freq,amp,time) #データをノコギリ波にする(周波数、振幅、時間)
    @time = time
    body_size  = time * @sample_rate
    @data_body = Array.new(body_size,0)
    @data_size = body_size * @block_size
    @data_body.each_index do |i|
      1.upto(15) do |n|
        @data_body[i] += amp / n * sin(2.0 * PI * freq * i * n / @sample_rate) * 32768 * @channel_num
      end
    end
    self
  end

  def make_square(freq,amp,time) #データを矩形波にする(周波数、振幅、時間)
    @time = time
    body_size  = time * @sample_rate
    @data_body = Array.new(body_size,0)
    @data_size = body_size * @block_size
    sample_per_freq = @sample_rate / freq
    @data_body.each_index do |i| #真の矩形波
      if i % sample_per_freq < sample_per_freq / 2  
        @data_body[i] = amp * 32768 * @channel_num
      else
        @data_body[i] = -amp * 32768 * @channel_num
      end
    end
    self
  end
  
  def make_sin_square(freq,amp,time) #データを矩形波にする(周波数、振幅、時間)
    @time = time
    body_size  = time * @sample_rate
    @data_body = Array.new(body_size,0)
    @data_size = body_size * @block_size
    @data_body.each_index do |i| #sin波を重ね合わせて矩形波にする
      1.upto(15) do |n|
        if n % 2 == 1
          @data_body[i] += amp / n * sin(2.0 * PI * freq * i * n / @sample_rate) * 32768 * @channel_num
        end
      end
    end
    self
  end
end
