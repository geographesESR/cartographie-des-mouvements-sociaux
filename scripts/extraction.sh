curl "https://framaforms.org/inventaire-des-mouvements-sociaux-1578921708/public-results?items_per_page=999999" 2>/dev/null | grep -i -e '</\?TD\|</\?TR' | sed 's/^[\ \t]*//g' | tr -d '\n\r' | sed 's/<\/TR[^>]*>/\n/Ig' | sed 's/<TR[^>]*>//Ig' | sed 's/"/\\"/Ig' | sed 's/<TD[^>]*>/"/Ig'  | sed 's/<\/TD[^>]*>/",/Ig' | sed 's/<a[^>]*>//Ig' | sed 's/<\/a>//Ig' | sed 's/<span[^>]*>//Ig' | sed 's/<\/span>//Ig' | sed 's/          //Ig' > data.csv
echo "Data from FramaForm extracted."

data=''
firstLine=true
idIndex=0
subDateIndex=1
userIndex=2
sectorIndex=3
titleIndex=4
descriptionIndex=5
latIndex=6
lonIndex=7
typeIndex=8
motifIndex=9
startIndex=10
endIndex=11
sourceIndex=12
i=0
lastIndex=""

typeset -i indexFramaform=$(cat scripts/index.framaform)
echo $indexFramaform

#Write data from interurgences
echo `sed '$ s/..$//' sante.geojson` > sante.geojson
curl "https://www.google.com/maps/d/kml?mid=1QuZ2EogIgvffjcNC_-w4C22LUsgsUPoM&forcekml=1" > "INTER_URGENCES.kml" 
bash apache-groovy-binary-3.0.0-rc-3/groovy-3.0.0-rc-3/bin/groovy scripts/interurgences.groovy
echo "]}" >> sante.geojson
rm "INTER URGENCES.kml"

#Read data.csv and put each line in the good geojson file
while IFS= read -r line
do	
	if $firstLine
	then
		firstLine=false	
	else
		
		i=0
		lat=0
		lon=0
		properties=""
		export IFS=","
		file=""
		#For each values, get the parameter, the latitude and the longitude and write it as geojson
		oldVal=
		write=false
		for val in $line
		do
			export IFS=
			if [ "\"" != "${val: -1}" ]
			then
				oldVal=$oldVal','$val
				export IFS=","
				continue
			fi
			if [ "" != "$oldVal" ]
			then
				val=${oldVal:1}','$val
			fi
			val=${val:1:-1}
			export IFS=
			if [ "$i" = "$idIndex" ]; then
				properties=$properties'"Id":"'${val:1}'",'
				typeset -i index="${val:1}"
				if [ "$indexFramaform" -lt "$index" ]; then
					write=true
					if [ "$lastIndex" = "" ]; then
						lastIndex=${val:1}
					fi
					echo $lastIndex
				fi
			fi
			if [ "$i" = "$sectorIndex" ]; then
				properties=$properties'"Secteur":"'$val'",'
				#Get from the 'Secteur' the file where the data should be written
				if [ "$val" = "Multi-secteur" ]; then
					file=multi.geojson
				elif [ "$val" = "Enseignement Supérieur et Recherche" ]; then
					file=esr.geojson
				elif [ "$val" = "Education" ]; then
					file=education.geojson
				elif [ "$val" = "Santé" ]; then
					file=sante.geojson
				elif [ "$val" = "Culture" ]; then
					file=culture.geojson
				elif [ "$val" = "Transport" ]; then
					file=transport.geojson
				elif [ "$val" = "Justice" ]; then
					file=justice.geojson
				elif [ "$val" = "Sécurité civile" ]; then
					file=securite.geojson
				elif [ "$val" = "Industrie / Energie" ]; then
					file=indus_energie.geojson
				elif [ "$val" = "Autre" ]; then
					file=autres.geojson
				else
					echo "sector not found : $val"
				fi
			fi
			if [ "$i" = "$titleIndex" ]; then
				properties=$properties'"Titre":"'$val'",'
			fi
			if [ "$i" = "$descriptionIndex" ]; then
				properties=$properties'"Description":"'$val'",'
			fi
			if [ "$i" = "$latIndex" ]; then
				lat=$val
			fi
			if [ "$i" = "$lonIndex" ]; then
				lon=$val
			fi
			if [ "$i" = "$typeIndex" ]; then
				properties=$properties'"Type":"'$val'",'
			fi
			if [ "$i" = "$motifIndex" ]; then
				properties=$properties'"Motif":"'$val'",'
			fi
			if [ "$i" = "$startIndex" ]; then
				properties=$properties'"Debut":"'$val'",'
			fi
			if [ "$i" = "$endIndex" ]; then
				properties=$properties'"Fin":"'$val'",'
			fi
			if [ "$i" = "$sourceIndex" ]; then
				properties=$properties'"Source":"'$val'"'
			fi
			i=$(($i+1))
			export IFS=","
			oldVal=""
		done
		export IFS=
		if [ $write = true ]
		then
			echo `sed '$ s/..$//' $file` > $file
			echo ',{"type":"Feature","properties":{'$properties'},"geometry":{"type":"Point","coordinates":['$lon','$lat']}}]}' >> $file
		fi
		export IFS=","
	fi
	export IFS=
done < data.csv
echo "Data converted to geojson."

rm data.csv
if [ "$lastIndex" = "" ]; then
	echo $indexFramaform > scripts/index.framaform
else
	echo $lastIndex > scripts/index.framaform
fi
echo "Result files closed."
