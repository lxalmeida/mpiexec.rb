require 'rexml/document'
include REXML

class Xml
	attr :document
	attr :rootElement, true
	attr :element, true
	attr :sampleFilePath
	
	def initialize(sampleFilePath)
		@document = REXML::Document.new
		@rootElement = REXML::Element.new "samples"
		@document.elements << @rootElement
		@sampleFilePath = sampleFilePath
	end
	
	def buildElement(probe, time)
		@element = REXML::Element.new "sample"
		
		child = REXML::Element.new "rows"
		child.add_text probe.rows.to_s
		@element.elements << child
		
		child = REXML::Element.new "cols"
		child.add_text probe.cols.to_s
		@element.elements << child

		child = REXML::Element.new "nthreads"
		child.add_text probe.nthreads.to_s
		@element.elements << child

		child = REXML::Element.new "nprocs"
		child.add_text probe.nprocs.to_s
		@element.elements << child
		
		child = REXML::Element.new "ngz"
		child.add_text probe.numGhostZones.to_s
		@element.elements << child

		child = REXML::Element.new "avgTime"
		child.add_text time.to_s
		@element.elements << child	
	end
	
	def pushElement(probe, time)
		buildElement(probe, time)
		@rootElement.elements << @element
	end
	
	def flushToFile
		if File.exist? @sampleFilePath
			File.delete @sampleFilePath
		end
		
		file = File.new(@sampleFilePath, "w+")
		document.write(file, 3);
		file.close
	end
	
	def search(statement)
		XPath.match(@document, statement)
	end
	
	def appendElements(xmlOrigin)
		xmlOrigin.rootElement.elements.each do |element|
			@rootElement.elements << element
		end
	end
end