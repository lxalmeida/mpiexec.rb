#!/usr/bin/env ruby1.9

require './parse_exec_arguments'
require './GenProbes'
require './Probe'
require './GenSamples'
require './Xml'
require './XmlExplorer'

def createDataDir(applicationName)
	if not Dir.exist? "./data"
		Dir.mkdir("./data")
	end
	
	if not Dir.exist? "./data/" + applicationName
		Dir.mkdir("./data/" + applicationName)
	end
end

def executeAutoTuner?(applicationName)
	not File.exists? "./data/" + applicationName + "/samples.xml"
end

def extractSize(executionCommandTemplate)
	rows = executionCommandTemplate.match(/[rR]\[\d+\]/)[0].gsub(/[Rr\[\]]/,'')
	cols = executionCommandTemplate.match(/[cC]\[\d+\]/)[0].gsub(/[Cc\[\]]/,'')
	{:rows=>rows, :cols=>cols}
end

def buildExecutionCommand(executionCommandTemplate, sample)
	sizes = extractSize(executionCommandTemplate)

	executionCommand = executionCommandTemplate.gsub(/[Pp]\[(\d+((,\d+)+)?)?\]/, sample.nprocs.to_s)
	executionCommand = executionCommand.gsub(/[Rr]\[\d+\]/, sizes[:rows])
	executionCommand = executionCommand.gsub(/[Cc]\[\d+\]/, sizes[:cols])
	executionCommand = executionCommand.gsub(/[Tt]\[(\d+((,\d+)+)?)?\]/, sample.nthreads.to_s)
	executionCommand = executionCommand.gsub(/ngz\[(\d+((,\d+)+)?)?\]/, sample.numGhostZones.to_s)
end

if not system("which mpiexec.hydra > /dev/null")
  puts "mpiexec.hydra is mandatory and was not found in your PATH"
  raise
end

executionCommandTemplate = "mpiexec.hydra " + ARGV.join(" ")

applicationName = executionCommandTemplate.match(/\s\.\/\w+/)[0].strip!.gsub!(/\.\//,"")

puts "Application name: " + applicationName

createDataDir(applicationName)

if executeAutoTuner?(applicationName)
	initialParallelProgramProbe = Probe.new
	initialParallelProgramProbe.executionCommandTemplate = executionCommandTemplate
	initialParallelProgramProbe.executionCommandTemplate = executionCommandTemplate.split
	
	searchSpace = genProbes(initialParallelProgramProbe)
	searchSpace = trimSearchSpace(searchSpace)
	searchSpace = sortSearchSpace(searchSpace)
	
	puts "Search space:"
	searchSpace.each do |p|
	  #puts p.probeInfo
	  puts p.executionCommandTemplate
	end
	
	#samples = genSamples(searchSpace, applicationName)
	samples = genSamples2(searchSpace, applicationName)
	
	#searchSpace = nil
	#samples = nil
else
	sizes = extractSize(executionCommandTemplate)

	sample = findSmallestSample("./data/" + applicationName + "/samples.xml", sizes[:rows].to_i)
	executionCommand = buildExecutionCommand(executionCommandTemplate, sample)
	puts executionCommand
	#Process.spawn(executionCommand)
	#Process.wait
end