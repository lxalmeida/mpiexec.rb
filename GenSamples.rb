require './Probe'
require './Xml'

def genSamples(probes, applicationName)
  xml = Xml.new("./data/" + applicationName + "/samples.xml")
  
  numberOfSamples = 5
  
  currentInputSize = 0
  
  probes.each do |probe|
    if probe.execute?    
		executionTimesFilename = "./data/" + probe.executionCommand.split.join("_").gsub(/\.\//, "") + ".dat"
		spawnOptions = {:out => [executionTimesFilename, "a+"]}
		puts "Executando " + probe.executionCommand + "; saida para " + executionTimesFilename
		1.upto(numberOfSamples) do |i|
		  puts "  obtendo amostra de tempo " + i.to_s + " de " + numberOfSamples.to_s 
		  Process.spawn(probe.executionCommand, spawnOptions)
		  Process.wait
		end
		avg = calculateAverage(executionTimesFilename)
		
		puts "Average = " + avg.to_s
		
		if findLeastValues(xml, avg, 0.15, probe).size > 0
			puts "Found 1 value lower than " + avg.to_s + "(-15%); flagging the remainder of probes for this input size as ignored"
			ignoreExecution(probes, probe.rows, probe.nprocs)
		else
			xml.pushElement(probe, avg)
			xml.flushToFile
		end
	else
		puts "Ignorando " + probe.executionCommand
	end
  end
end

def genSamples2(probes, applicationName)
  xml = Xml.new("./data/" + applicationName + "/samples.xml")
  fileSamples = File.new("./data/" + applicationName + "/allAppExecTime.dat", "w")
  
  fileSamples.write("rows;nprocs;nthreads;ngz;time")
  
  inputSizes = Hash.new
  nprocs = Hash.new
  
  probes.each do |p|
  	inputSizes[p.rows] = true
  	nprocs[p.nprocs] = true
  end
  
  timesInputSizeNprocs = Hash.new
  ignoreNprocsInputSize = Hash.new
  
  inputSizes.each do |inputSize, v|
  	if ignoreNprocsInputSize[inputSize].nil?
	  strike = 0
	  nprocs.each do |nprocs, v|
		  xmlNprocs = Xml.new(nil)
	  	  
	  	  puts "=== Trying inputSize = " + inputSize.to_s + "; nprocs = " + nprocs.to_s + " ==="
	  	  
		  time = execProbesNprocs(probes, inputSize, nprocs, xmlNprocs, fileSamples, applicationName)
		  
		  if timesInputSizeNprocs[inputSize].nil? || time < timesInputSizeNprocs[inputSize]
		  	  puts "Time obtained is min time: " + time.to_s + "; flushing to XML"
		  	  puts ""
		  	  timesInputSizeNprocs[inputSize] = time
		  else
			  strike += 1
			  puts "Time obtained is not is smaller than " + timesInputSizeNprocs[inputSize].to_s
			  puts "Strike " + strike.to_s
			  puts ""
		  end
		  
		  xml.appendElements(xmlNprocs)
		  xml.flushToFile
		  
		  if strike == 2
			  puts "Setting probes as ignored for inputSize " + inputSize.to_s
			  puts ""
			  #ignoreExecution(probes, inputSize, nprocs)
			  ignoreNprocsInputSize[inputSize] = true
			  break
		  end
	  end
  	else
  		puts "Ignoring execution for inputSize " + inputSize.to_s
  		puts ""
  	end
  end
  
  fileSamples.close
end

def execProbesNprocs(probes, inputSize, nprocs, xml, fileSamples, applicationName)
	numberOfSamples = 2
	
	minProbe = nil
	
	samples = Array.new
	
	probes.each do |probe|
		if probe.rows == inputSize && probe.nprocs == nprocs
		  executionTimesFilename = "./data/" + applicationName + "/" + probe.executionCommand.split.join("_").gsub(/\.\//, "") + ".dat"
		  spawnOptions = {:out => [executionTimesFilename, "a+"]}
		  puts "Executando " + probe.executionCommand + "; saida para " + executionTimesFilename
		  1.upto(numberOfSamples) do |i|
			puts "  obtendo amostra de tempo " + i.to_s + " de " + numberOfSamples.to_s 
			Process.spawn(probe.executionCommand, spawnOptions)
			Process.wait
		  end
		  avg = calculateAverage(executionTimesFilename)
		  
		  samples.push(avg)
		  
		  puts "Average = " + avg.to_s
		  
		  fileSamples.write(probe.rows.to_s + ";" + probe.nprocs.to_s + ";" + probe.nthreads.to_s + ";" + probe.numGhostZones.to_s + ";" + avg.to_s)
		  
		  #if samples.min == avg
		  #	minProbe = probe
		  #end
		  xml.pushElement(probe, avg)
		end
	end
	
    #xml.pushElement(minProbe, samples.min)
	
	puts ""
	
	samples.min
end

def calculateAverage(executionTimesFilename)
	f = File.open(executionTimesFilename, "r")
	
	x = 0.0
	i = 0
	
	until f.eof? do
		x += f.gets.to_f
		i += 1
	end
	
	x/i
end

def isNewTimeTheSmallest(xml, newAvgTime, probe)
	searchStatement = "//sample[avgTime < " + newAvgTime.to_s + " and rows = " + probe.rows.to_s + "]"	
	puts searchStatement
	
	xml.search(searchStatement).size == 0
end

def findLeastValues(xml, newAvgTime, rangeFactor, probe)
	newAvgTime = newAvgTime - (newAvgTime * rangeFactor)
	
	searchStatement = "//sample[avgTime < " + newAvgTime.to_s + " and rows = " + probe.rows.to_s + "]"
	puts searchStatement
	xml.search(searchStatement)
end

def ignoreExecution(probes, inputSize, nprocs)
	probes.each do |p|
		if p.rows == inputSize && p.nprocs <= nprocs
			p.execute = false
		end
	end
end
