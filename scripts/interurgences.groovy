import groovy.util.XmlParser
import groovy.util.XmlSlurper

//Remove old interurgences data
def geojsonSante = new File("sante.geojson")
def clean = ""
for (line in geojsonSante){
	if(!line.contains('"Id":"interurgence_')){
		clean += line+"\n"
	}
}
geojsonSante.text = clean - "\n]}"

//Adds new interurgences data
def empty = false
if(geojsonSante.text == '{"type":"FeatureCollection","features":[\n'){
	empty = true
}
def file = new File("INTER_URGENCES.kml")
def kml = new XmlSlurper().parse(file)
assert kml
assert kml.Document
assert kml.Document.Folder.size() >= 1

def folder = kml.Document.Folder[0]
assert folder.name.text().startsWith("SAU en grève")
assert folder.Placemark.size() > 0

for(placemark in folder.Placemark) {
	def geojsonStr = ''
	if(empty){
		empty = false
	}
	else{
		geojsonStr += ','
	}
	geojsonStr += '{"type":"Feature","properties":{'
	geojsonStr += '"Id":"interurgence_' + (placemark.ExtendedData.Data[0].value.text().trim()-".0") + '",'
	geojsonStr += '"Secteur":"Santé",'
	geojsonStr += '"Titre":"Urgences en grève : ' + placemark.name.text().trim() + '",'
	geojsonStr += '"Description":"' + placemark.ExtendedData.Data[1].value.text().trim() + '",'
	geojsonStr += '"Type":"Grève",'
	geojsonStr += '"Motif":"Hôpital en danger",'
	geojsonStr += '"Debut":"",'
	geojsonStr += '"Fin":"",'
	geojsonStr += '"Source":"https://www.interurgences.fr/carte-de-france/"'
	geojsonStr += '},"geometry":{"type":"Point","coordinates":['
	geojsonStr += placemark.Point.coordinates.text().trim()
	geojsonStr += ']}}\n'
	geojsonSante << geojsonStr
}
geojsonSante << "]}\n"
