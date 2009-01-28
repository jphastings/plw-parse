# A hacked up class for parsing the PLW data format from PicoTech (for their Oscilloscope data). Its not meant for speed but (constructive :P) criticism and ideas are welcome!
class PLW
  attr_reader :signature,:version,:params,:PLS
  attr_reader :sample_num,:no_samples,:max_samples,:interval,:trigger_sample,:triggered,:first_sample,:sample_length,:setting_byte,:start_date,:start_time,:min_time,:max_time,:notes,:current_time
  attr_accessor :current_sample
  
  # Will take a filename or a file handle (eg. <tt>"filename.plw"</tt> or <tt>open("filename.plw")</tt>)
  def initialize(filename_or_handle)
    if filename_or_handle.is_a?(File)
      @file = filename_or_handle
    elsif filename_or_handle.is_a?(String)
      if File.exists? filename_or_handle
        @file = open(filename_or_handle)
      else
        raise "File does not exist: #{filename_or_handle}"
      end
    else
      raise "You need to pass a filename or a File object"
    end
    
    parseHeader
  end
  
  # Spins the file on to the byte position immediately after the given sample number
  def current_sample=(sample_num)
    if sample_num > @no_samples or sample_num < 0
      return false
    end
    # 4 bytes for each paramter, 4 for the time. This bundle sample_num times,
    # plus the header length is the byte position of the end of that sample 
    position = (@no_params * 4 + 4) * sample_num + @header_length
    
    @file.seek(position)
    @current_sample = sample_num
  end
  
  # Reconstructs the PLS data file used when measuring this data. Parses into a multi-level hash.
  def PLS
    if @pls.nil?
      wasat = @file.pos
      self.current_sample = @no_samples
      @pls = {}
      section = nil
      @file.read.split(/\r\n/).each do |line|
        if line =~ /^\[(.+?)\]$/
          section = {}
          @pls[$1] = section
        elsif line =~ /^(.+)=(.+)$/
          section[$1] = $2
        else
          # Unknown Data format
        end
      end
      @file.seek(wasat)
      @pls
    else
      @pls
    end
  end
  
  # Returns <tt>n</tt> samples as Hashes, each hash containing:
  # * :time : The time offset of this sample, in seconds
  # * :data : The data for each channel as a hash
  def getSamples(n=1)
    if (@current_sample + n > @no_samples)
      n = @no_samples - @current_sample
      if n < 1
        return false
      end
    end
    
    Hash[*(@current_sample+1).upto(@current_sample += n).collect{ |sample_num| [sample_num,{:time => getuint32*@interval_units,:data => @no_params.times.collect { |param_index| getFloat() } }]}.flatten]
  end
  
  # A convenience method that just gives the next sample only
  def getSample
    getSamples(1).to_a[0][1]
  end
  
  private
  
  def getbytes(numbytes)
    data = ""
    numbytes.times do |time|
      data<<@file.getbyte
    end
    data
  end
  
  def getFloat
    getbytes(4).unpack("e4")[0]
  end
  
  def getuint16
    getbytes(2).unpack("v")[0]
  end
  
  def getuint32
    getbytes(4).unpack("V")[0]
  end
  
  def parseHeader
    @header_length = getuint16()
    @signature = getbytes(40).strip
    @version = getuint32()
    @no_params = getuint32()
    @params = {}
    @no_params.times do |param_index|
      @params[param_index] = getuint16
    end
    getbytes(2*(250 - @no_params)) # The remaining params aren't used
    @sample_num  = getuint32() # Same as @no_samples unless wraparound occured
    @no_samples = getuint32() + 415 # Why?! Its not reporting the right length for some reason...
    @max_samples = getuint32()
    @interval = getuint32()
    case getuint16() # next 16 bits are the 'interval unit'
    when 0 # Femtoseconds
      @interval_units = 1e-15
    when 1 # ASSUMED Picosecond
      @interval_units = 1e-12
    when 2 # ASSUMED Nanosecond
      @interval_units = 1e-9
    when 3 # ASSUMED Millisecond
      @interval_units = 1e-6
    when 4 # Milliseconds
      @interval_units = 1e-3
    when 5 # Seconds
      # We're in seconds
    when 6 # Minutes
      @interval_units = 60
    when 7
      @interval_units = 3600
    else
      raise "The units weren't specified correctly in the header file"
    end
    @interval *= @interval_units
    @trigger_sample = getuint32()
    @triggered = getuint16()
    @first_sample = getuint32()
    @sample_length = getuint32()
    @setting_byte = getuint32()
    @start_date = getuint32()
    @start_time = getuint32()
    @min_time = getuint32()
    @max_time = getuint32()
    @notes = getbytes(1000)
    @current_time = getuint32()
    getbytes(78) # Spare
    @current_sample = 0 # We're currently after sample number 0. ie. the first sample is sample '1'
  end
end