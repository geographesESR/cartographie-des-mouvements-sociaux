curl "https://framaforms.org/inventaire-des-mouvements-sociaux-1578921708/public-results" 2>/dev/null | grep -i -e '</\?TD\|</\?TR' | sed 's/^[\ \t]*//g' | tr -d '\n\r' | sed 's/<\/TR[^>]*>/\n/Ig' | sed 's/<TR[^>]*>//Ig' | sed 's/<TD[^>]*>/"/Ig'  | sed 's/<\/TD[^>]*>/",/Ig' | sed 's/<a[^>]*>//Ig' | sed 's/<\/a>//Ig' | sed 's/<span[^>]*>//Ig' | sed 's/<\/span>//Ig' | sed 's/          //Ig' > data.csv
echo "Data from FramaForm extracted."

data=''
firstLine=true
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

#Prepare files
echo '{"type":"FeatureCollection","features":[' > multi.geojson
echo '{"type":"FeatureCollection","features":[' > esr.geojson
echo '{"type":"FeatureCollection","features":[' > education.geojson
echo '{"type":"FeatureCollection","features":[' > sante.geojson
echo '{"type":"FeatureCollection","features":[' > culture.geojson
echo '{"type":"FeatureCollection","features":[' > transport.geojson
echo '{"type":"FeatureCollection","features":[' > justice.geojson
echo '{"type":"FeatureCollection","features":[' > securite.geojson
echo '{"type":"FeatureCollection","features":[' > indus_energie.geojson
echo '{"type":"FeatureCollection","features":[' > autres.geojson
echo "Result file prepared."

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
				elif [ "$val" = "Autres" ]; then
					file=securite.geojson
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
				properties=$properties'"Date de début":"'$val'",'
			fi
			if [ "$i" = "$endIndex" ]; then
				properties=$properties'"Date de fin":"'$val'",'
			fi
			if [ "$i" = "$sourceIndex" ]; then
				properties=$properties'"Source":"'$val'"'
			fi
			i=$(($i+1))
			export IFS=","
			oldVal=""
		done
		export IFS=
		echo '{"type":"Feature","properties":{'$properties'},"geometry":{"type":"Point","coordinates":['$lon','$lat']}},' >> $file
		export IFS=","
	fi
	export IFS=
done < data.csv
echo "Data converted to geojson."

#remove las comma if needed
if [ `tail -c 2 multi.geojson` = "," ]
then
	truncate -s-2 multi.geojson
fi
if [ `tail -c 2 esr.geojson` = "," ]
then
	truncate -s-2 esr.geojson
fi
if [ `tail -c 2 education.geojson` = "," ]
then
	truncate -s-2 education.geojson
fi
if [ `tail -c 2 sante.geojson` = "," ]
then
	truncate -s-2 sante.geojson
fi
if [ `tail -c 2 culture.geojson` = "," ]
then
	truncate -s-2 culture.geojson
fi
if [ `tail -c 2 transport.geojson` = "," ]
then
	truncate -s-2 transport.geojson
fi
if [ `tail -c 2 justice.geojson` = "," ]
then
	truncate -s-2 justice.geojson
fi
if [ `tail -c 2 securite.geojson` = "," ]
then
	truncate -s-2 securite.geojson
fi
if [ `tail -c 2 indus_energie.geojson` = "," ]
then
	truncate -s-2 indus_energie.geojson
fi
if [ `tail -c 2 autres.geojson` = "," ]
then
	truncate -s-2 autres.geojson
fi

#Close files
echo ']}' >> multi.geojson
echo ']}' >> esr.geojson
echo ']}' >> education.geojson
echo ']}' >> sante.geojson
echo ']}' >> culture.geojson
echo ']}' >> transport.geojson
echo ']}' >> justice.geojson
echo ']}' >> securite.geojson
echo ']}' >> indus_energie.geojson
echo ']}' >> autres.geojson
rm data.csv
echo "Result files closed."
