#!/bin/env ruby1.9

require './Sample'
require 'rexml/document'

include REXML

def xmlToObject(fileSamplePath, xpathExpression)
	doc = Document.new(File.new(fileSamplePath))
	
	samples = XPath.match(doc, xpathExpression)
	
	sampleObjects = Array.new
	
	samples.each do |sample|
		s = Sample.new
		sample.each_element do |element|
			elementName = element.name.strip
			elementValue = element.text.strip
			
			s.rows = elementValue.to_i if elementName == "rows"
			s.cols = elementValue.to_i if elementName == "cols"
			s.nthreads = elementValue.to_i if elementName == "nthreads"
			s.nprocs = elementValue.to_i if elementName == "nprocs"
			s.numGhostZones = elementValue.to_i if elementName == "ngz"
			s.avgTime = elementValue.to_f if elementName == "avgTime"
			
			sampleObjects.push(s)
		end
	end
	sampleObjects
end

def findSmallestSample(fileSamplePath, size)
	samples = xmlToObject(fileSamplePath, "//sample")
	
	knownSize = 0
	distance = 2**32
	
	samples.each do |s|
		d = (s.rows - size).abs
		if d < distance
			knownSize = s.rows
			distance = d
		end
	end

	samples = xmlToObject(fileSamplePath, "//sample[rows="+knownSize.to_s+"]")
	samples = samples.sort_by{|a| [a.avgTime]}
	samples[0]
end
