require './Probe'
require './constant/ParameterType'

def genProbes(probe)
  arguments = Array.new
  arguments.concat(probe.executionCommand.split(" "))

  parameters = parse_exec_arguments(arguments)
  
  returnProbes = Hash.new
  
  if !parameters.empty?
    probeGroup = Hash.new
    
    parameters.each do |param|
      param.each do |parameter,index|
        if parameter.type != ParameterType::NPROCS_PARAM
          n = parameter.upper_bound
          while n >= parameter.lower_bound do
            temp = arguments[index]
            arguments[index] = n
            
            newProbe = Probe.new
            
            newProbe.executionCommand = arguments.join(" ")
            
            newProbe.nthreads = probe.nthreads
            newProbe.rows = probe.rows
            newProbe.cols = probe.cols
            newProbe.nprocs = probe.nprocs
            newProbe.indexes = probe.indexes
            newProbe.numGhostZones = probe.numGhostZones
            newProbe.executionCommandTemplate = probe.executionCommandTemplate
            
            if parameter.type == ParameterType::NTHREAD_PARAM
            	newProbe.nthreads = n
            	newProbe.indexes.merge!({:nthreads => index})
            elsif parameter.type == ParameterType::NROWS_PARAM
            	newProbe.rows = n
            	newProbe.indexes.merge!({:rows => index})
            elsif parameter.type == ParameterType::NCOLS_PARAM
            	newProbe.cols = n
            	newProbe.indexes.merge!({:cols => index})
            elsif parameter.type == ParameterType::NGHOSTZONES_PARAM
            	newProbe.numGhostZones = n
            	newProbe.indexes.merge!({:ngz => index})
            end
            
            probeGroup[newProbe.executionCommand] = newProbe
            
            arguments[index] = temp
            
            n -= parameter.increment
          end
        else
          temp = arguments[index]
          
          parameter.list.sort.reverse.each do |nprocs|
            arguments[index] = nprocs
            
            newProbe = Probe.new
            
            newProbe.executionCommand = arguments.join(" ")
            
            newProbe.nthreads = probe.nthreads
            newProbe.rows = probe.rows
            newProbe.cols = probe.cols
            newProbe.nprocs = nprocs
            newProbe.indexes = probe.indexes
            newProbe.numGhostZones = probe.numGhostZones
            newProbe.executionCommandTemplate = probe.executionCommandTemplate
            
            newProbe.indexes.merge!({:nprocs => index})
            
            probeGroup[newProbe.executionCommand] = newProbe
          end
          
          arguments[index] = temp
        end
      end
    end
    
    # Chama de novo para substituir os parâmetros que faltam
    probeGroup.each do |k,v|
      returnProbes.merge!(genProbes(v))
    end
  else
    returnProbes[probe.executionCommand] = probe
  end
  
  returnProbes
end

def trimSearchSpace(searchSpace)
	trimmedSearchSpace = Hash.new
	
	searchSpace.each do |key,probe|
		if probe.rows == probe.cols
			trimmedSearchSpace[key] = probe
		end
	end
	
	trimmedSearchSpace
end

def sortSearchSpace(searchSpace)
	searchSpace = searchSpace.values
	searchSpace = searchSpace.sort_by{|a| [a.rows, a.nprocs, a.nthreads]}
	searchSpace.reverse!
	
	searchSpace
end
