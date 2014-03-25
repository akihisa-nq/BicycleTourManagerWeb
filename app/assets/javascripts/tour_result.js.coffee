# loadgpx.4.js
#
# Javascript object to load GPX-format GPS data into Google Maps.
#
# Copyright (C) 2006 Kaz Okuda (http://notions.okuda.ca)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# If you use this script or have any questions please leave a comment
# at http://notions.okuda.ca/geotagging/projects-im-working-on/gpx-viewer/
# A link to the GPL license can also be found there.
#
#
# History:
#    revision 1 - Initial implementation
#    revision 2 - Removed LoadGPXFileIntoGoogleMap and made it the callers
#                 responsibility.  Added more options (colour, width, delta).
#    revision 3 - Waypoint parsing now compatible with Firefox.
#    revision 4 - Upgraded to Google Maps API version 2.  Tried changing the way
#               that the map calculated the way the center and zoom level, but
#               GMAP API 2 requires that you center and zoom the map first.
#               I have left the bounding box calculations commented out in case
#               they might come in handy in the future.
#
#    5/28/2010 - Upgraded to Google Maps API v3 and refactored the file a bit.
#                          (Chris Peplin)
#
# Author: Kaz Okuda
# URI: http://notions.okuda.ca/geotagging/projects-im-working-on/gpx-viewer/
#
# Updated for Google Maps API v3 by Chris Peplin
# Fork moved to GitHub: https://github.com/peplin/gpxviewer
#

GPXParser = (xmlDoc, map) ->
	this.xmlDoc = xmlDoc
	this.map = map
	this.trackcolour = "#ff00ff" # red
	this.trackwidth = 5
	this.mintrackpointdelta = 0.0001

# Set the colour of the track line segements.
GPXParser.prototype.setTrackColour = (colour) ->
	this.trackcolour = colour

# Set the width of the track line segements
GPXParser.prototype.setTrackWidth = (width) ->
	this.trackwidth = width

# Set the minimum distance between trackpoints.
# Used to cull unneeded trackpoints from map.
GPXParser.prototype.setMinTrackPointDelta = (delta) ->
	this.mintrackpointdelta = delta;

GPXParser.prototype.translateName = (name) ->
	if name == "wpt"
		"Waypoint"
	else if name == "trkpt"
		"Track Point";

GPXParser.prototype.createMarker = (point) ->
	lon = parseFloat(point.getAttribute("lon"))
	lat = parseFloat(point.getAttribute("lat"))
	html = ""
	
	pointElements = point.getElementsByTagName("html")
	if pointElements.length > 0
		for item in pointElements.item(0).childNodes
			html += item.nodeValue
	else
		# Create the html if it does not exist in the point.
		html = "<b>" + this.translateName(point.nodeName) + "</b><br>"
		attributes = point.attributes
		for item in attributes
			html += item.name + " = " + item.nodeValue + "<br>"
		
		if point.hasChildNodes
			children = point.childNodes;
			for child in children
				# Ignore empty nodes
				if child.nodeType != 1
					continue
				if child.firstChild == null
					continue
				html += child.nodeName + " = " + child.firstChild.nodeValue + "<br>";
	
	marker = new google.maps.Marker({
		position: new google.maps.LatLng(lat,lon),
		map: this.map
	})
	
	infowindow = new google.maps.InfoWindow({
		content: html,
		size: new google.maps.Size(50,50)
	})
	
	google.maps.event.addListener(
		marker,
		"click",
		() -> infowindow.open(this.map, marker)
		)

GPXParser.prototype.addTrackSegmentToMap = (trackSegment, colour, width) ->
	trackpoints = trackSegment.getElementsByTagName("trkpt")
	if trackpoints.length == 0
		return
	
	pointarray = []
	
	# process first point
	lastlon = parseFloat(trackpoints[0].getAttribute("lon"))
	lastlat = parseFloat(trackpoints[0].getAttribute("lat"))
	latlng = new google.maps.LatLng(lastlat,lastlon)
	pointarray.push(latlng)
	
	for tp in trackpoints[1...trackpoints.length]
		lon = parseFloat(tp.getAttribute("lon"))
		lat = parseFloat(tp.getAttribute("lat"))
		
		# Verify that this is far enough away from the last point to be used.
		latdiff = lat - lastlat
		londiff = lon - lastlon
		if Math.sqrt(latdiff*latdiff + londiff*londiff) > this.mintrackpointdelta
			lastlon = lon
			lastlat = lat
			latlng = new google.maps.LatLng(lat,lon)
			pointarray.push(latlng)
	
	polyline = new google.maps.Polyline({
		path: pointarray,
		strokeColor: colour,
		strokeWeight: width,
		map: this.map
	})

GPXParser.prototype.addTrackToMap = (track, colour, width) ->
	segments = track.getElementsByTagName("trkseg")
	for seg in segments
		segmentlatlngbounds = this.addTrackSegmentToMap(seg, colour, width)

GPXParser.prototype.centerAndZoom = (trackSegment) ->
	pointlist = new Array("trkpt", "wpt")
	minlat = 0
	maxlat = 0
	minlon = 0
	maxlon = 0
	
	for pointtype in pointlist.length
		# Center the map and zoom on the given segment.
		trackpoints = trackSegment.getElementsByTagName(pointtype)
		
		# If the min and max are uninitialized then initialize them.
		if (trackpoints.length > 0) && (minlat == maxlat) && (minlat == 0)
			minlat = parseFloat(trackpoints[0].getAttribute("lat"))
			maxlat = parseFloat(trackpoints[0].getAttribute("lat"))
			minlon = parseFloat(trackpoints[0].getAttribute("lon"))
			maxlon = parseFloat(trackpoints[0].getAttribute("lon"))
		
		for tp in trackpoints
			lon = parseFloat(tp.getAttribute("lon"))
			lat = parseFloat(tp.getAttribute("lat"))
			
			if lon < minlon
				minlon = lon
			if lon > maxlon
				maxlon = lon
			if lat < minlat
				minlat = lat
			if lat > maxlat
				maxlat = lat
	
	if minlat == maxlat && minlat == 0
		this.map.setCenter(new google.maps.LatLng(49.327667, -122.942333), 14)
		return
	
	# Center around the middle of the points
	centerlon = (maxlon + minlon) / 2
	centerlat = (maxlat + minlat) / 2
	
	bounds = new google.maps.LatLngBounds(
		new google.maps.LatLng(minlat, minlon),
		new google.maps.LatLng(maxlat, maxlon))
	this.map.setCenter(new google.maps.LatLng(centerlat, centerlon))
	this.map.fitBounds(bounds)

GPXParser.prototype.centerAndZoomToLatLngBounds = (latlngboundsarray) ->
	boundingbox = new google.maps.LatLngBounds();
	for latlngbound in latlngboundsarray
		if ! latlngbound.isEmpty()
			boundingbox.extend(latlngbound.getSouthWest())
			boundingbox.extend(latlngbound.getNorthEast())
	
	centerlat = (boundingbox.getNorthEast().lat() + boundingbox.getSouthWest().lat()) / 2
	centerlng = (boundingbox.getNorthEast().lng() + boundingbox.getSouthWest().lng()) / 2
	this.map.setCenter(new google.maps.LatLng(centerlat, centerlng), this.map.getBoundsZoomLevel(boundingbox))

GPXParser.prototype.addTrackpointsToMap = () ->
	tracks = this.xmlDoc.documentElement.getElementsByTagName("trk");
	for track in tracks
		this.addTrackToMap(track, this.trackcolour, this.trackwidth)

GPXParser.prototype.addWaypointsToMap = () ->
	waypoints = this.xmlDoc.documentElement.getElementsByTagName("wpt")
	for wp in waypoints
		this.createMarker(wp)

