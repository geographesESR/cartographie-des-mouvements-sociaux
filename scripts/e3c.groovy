import groovy.util.XmlParser
import groovy.util.XmlSlurper
import groovy.json.JsonSlurper

//Remove old data
def geojsonEducation = new File("education.geojson")
def clean = ""
for (line in geojsonEducation){
	if(!line.contains('"Id":"mobilisatione3c_')){
		clean += line+"\n"
	}
}
geojsonEducation.text = clean - "\n]}"

//Adds new data
def empty = false
if(geojsonEducation.text == '{"type":"FeatureCollection","features":[\n'){
	empty = true
}
def file = new File("MOBILISATION_E3C.kml")
def kml = new XmlSlurper().parse(file)
assert kml
assert kml.Document
assert kml.Document.Folder.size() >= 1

def folder
for(int i=0; i<kml.Document.Folder.size();i++){
	if(kml.Document.Folder[i].name.text() == "Lycées mobilisés contre les E3C"){
		folder = kml.Document.Folder[i]
		parseLycee(folder, geojsonEducation, empty)
	}
	else{
		folder = kml.Document.Folder[i]
		println kml.Document.Folder[i].name.text().split()[0].toLowerCase()
		parseOther(folder, geojsonEducation, empty, kml.Document.Folder[i].name.text().split()[0].toLowerCase())
	}
}
geojsonEducation << "]}\n"

def parseOther(def folder, def geojsonEducation, def empty, def prefix){
	assert folder
	assert folder.Placemark.size() > 0

	def i=1
	for(placemark in folder.Placemark) {
		println placemark.name.text()
		def geojsonStr = ''
		if(empty){
			empty = false
		}
		else{
			geojsonStr += ','
		}
		def coordinates = placemark.Point.coordinates.text().trim()

		geojsonStr += '{"type":"Feature","properties":{'
		geojsonStr += '"Id":"mobilisatione3c_' + prefix + '_' + i + '",'
		geojsonStr += '"Secteur":"Education",'
		geojsonStr += '"Titre":"Mobilisation E3C : ' + placemark.name.text().trim() + '",'
		geojsonStr += '"Description":"' + placemark.description.text().trim() + '",'
		geojsonStr += '"Type":"Mobilisation",'
		geojsonStr += '"Motif":"E3C",'
		geojsonStr += '"Debut":"",'
		geojsonStr += '"Fin":"",'
		geojsonStr += '"Source":"Pour en savoir plus, consultez le site https://frama.link/carte-resistances-e3c du collectif \\\"Stop Bac Blanquer - Stop E3C\\\" dont sont issues les données"'
		geojsonStr += '},"geometry":{"type":"Point","coordinates":['
		geojsonStr += coordinates
		geojsonStr += ']}}\n'
		geojsonEducation << geojsonStr
		i++
	}
}

def parseLycee(def folder, def geojsonEducation, def empty){
	assert folder
	assert folder.Placemark.size() > 0

	def i=1
	for(placemark in folder.Placemark) {
		def geojsonStr = ''
		if(empty){
			empty = false
		}
		else{
			geojsonStr += ','
		}
		def name = placemark.name.text().toLowerCase()
		name.replaceAll("francais", "français")
		def addr = (name+", "+placemark.ExtendedData.Data[2].value.text()).toLowerCase().replaceAll("([0-9] ?){5}", "").replaceAll(" d ", " d'").replaceAll("lycée hôtelier ", "lycée ").replaceAll("lycées ", "lycée ").replaceAll("lycee ", "lycée ").replaceAll("lycée international ", "lycée ").replaceAll("lgt ", "lycée ").replaceAll("lpo ", "lycée ").replaceAll("lyc ", "lycée ")
		if(!addr.startsWith("lycée") && !addr.startsWith("cité scolaire")){
			addr = "lycée "+addr
		}
		if(!name.contains("français")){
			addr += ", France"
		}
		features = query(addr.replaceAll(" ", "%20"))
		if(!features){
			features = query(addr.replaceAll("lycée", "lycée polyvalent").replaceAll(" ", "%20"))
			if(!features){
				features = query(addr.replaceAll("lycée", "lycée technique").replaceAll(" ", "%20"))
				if(!features){
					features = query(addr.replaceAll("lycée", "lycée professionnel").replaceAll(" ", "%20"))
					if(!features){
						features = query(addr.replaceAll("lycée", "lycée polyvalent et professionnel").replaceAll(" ", "%20"))
						if(!features){
							features = query(addr.replaceAll("lycée", "lycée professionnel et polyvalent").replaceAll(" ", "%20"))
							if(!features){
								features = query(addr.replaceAll("lycée", "lycée général et technologique").replaceAll(" ", "%20"))
								if(!features){
									features = query(addr.replaceAll("lycée", "lycée international").replaceAll(" ", "%20"))
									if(!features){
										features = query(addr.replaceAll("lycée", "cité scolaire").replaceAll(" ", "%20"))
										if(!features){
											features = query(addr.replaceAll("\\(.*\\)", "").replaceAll(" ", "%20"))
											if(!features){
												println "Error on : "+addr
												continue
											}
										}
									}
								}
							}
						}
					}
				}
			}
		}
		def f = features[0]
		def geometry = f.geometry
		def bbox = f.bbox[2]
		def coordinates
		if(geometry.type == "Point"){
			coordinates = geometry.coordinates[0]+","+geometry.coordinates[1]
		}
		else if(geometry.type == "Polygon"){
			coordinates = ((bbox[0]-bbox[2])/2)+","+((bbox[1]-bbox[3])/2)
		}

		geojsonStr += '{"type":"Feature","properties":{'
		geojsonStr += '"Id":"mobilisatione3c_' + i + '",'
		geojsonStr += '"Secteur":"Education",'
		geojsonStr += '"Titre":"Mobilisation E3C : ' + placemark.name.text().trim() + '",'
		geojsonStr += '"Description":"' + placemark.ExtendedData.Data[6].value.text().trim() + '",'
		geojsonStr += '"Type":"Mobilisation",'
		geojsonStr += '"Motif":"E3C",'
		geojsonStr += '"Debut":"' + placemark.ExtendedData.Data[3].value.text().trim() + '",'
		geojsonStr += '"Fin":"",'
		geojsonStr += '"Source":"Pour en savoir plus, consultez le site https://frama.link/carte-resistances-e3c du collectif \\\"Stop Bac Blanquer - Stop E3C\\\" dont sont issues les données"'
		geojsonStr += '},"geometry":{"type":"Point","coordinates":['
		geojsonStr += coordinates
		geojsonStr += ']}}\n'
		geojsonEducation << geojsonStr
		i++
	}
}

def query(def data){
	def jsonSlurper = new JsonSlurper()
	command = [ 'bash', '-c', "curl \"https://nominatim.openstreetmap.org/search?q=$data&format=geojson\""]
	process = command.execute()
	process.waitFor()
	text = process.text
	if(!text){
		println "error on : "+data
		return
	}
	root = jsonSlurper.parseText(text)
	return root.features
}
