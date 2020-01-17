import groovy.json.JsonSlurper
import java.io.File 

def issueFile = new File("eventWithoutEnd.md")
issueFile.text = "List of the id of event without end date : \n"
def jsonSlurper = new JsonSlurper()
def count = 0
def files = ["autres.geojson", "culture.geojson", "education.geojson", "esr.geojson", "indus_energie.geojson", "justice.geojson", "multi.geojson", "sante.geojson", "securite.geojson", "transport.geojson"]
for(file in files){
	issueFile << " - ${file}\n"
	def json = jsonSlurper.parse(new File(file))
	for(feature in json.features){
		if(feature != null && feature.properties != null && feature.properties.Fin == ""){
			count ++
			issueFile << "   - ${feature.properties.Id}\n"
		}
	}
}
