class Probe
  attr :executionCommand, true
  attr :rows, true
  attr :cols, true
  attr :nthreads, true
  attr :nprocs, true
  attr :numGhostZones, true
  attr :execute, true
  attr :executionCommandTemplate, true
  attr :indexes, true
  
  def initialize
  	@execute = true
  	@indexes = Hash.new
  	@executionCommand = nil
  end
  
  def probeInfo
  	"r="+@rows.to_s+" c="+@cols.to_s+" t="+@nthreads.to_s+" p="+@nprocs.to_s+" idx[t]="+@indexes[:nthreads].to_s+" idx[r]="+@indexes[:rows].to_s+" idx[c]="+@indexes[:cols].to_s+" idx[p]="+@indexes[:nprocs].to_s+" exec="+@executionCommand
  end
  
  def execute?
  	@execute
  end
end
