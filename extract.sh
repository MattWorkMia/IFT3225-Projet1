#!/bin/bash

if [ $# -lt 1 ] ; then 
	echo "Utilisation : extract [options] <url>"; #si il n'y a pas d'arguments
fi

r=0 i=0 v=0 p=0 h=0 path="" reg="" 

for arg in "$@"; do 

	if [ "$r" -eq 1 ]; then  #si l'option -r est activé on stock le regex
		reg=$arg
		r=0

	elif [ "$p" -eq 1 ]; then #si l'option -p est activé on stock le path
		path=$arg
		p=0

	elif [ "$arg" == '-r' ]; then r=1 #option -r activé

	elif [ "$arg" == '-i' ]; then i=1 #option -i activé

	elif [ "$arg" == '-v' ]; then v=1 #option -v activé

	elif [ "$arg" == '-p' ]; then p=1 #option -p activé

	elif [ "$arg" == '-h' ]; then h=1 #option -h activé

	fi
done

if [ "$h" -eq 1 ]; then	#si l'option -h activé on écrit le help de la fonction
	echo "
	Createurs : Miali Matteo 20308845
	Utilisation : extract [options] <url>

		Options :
		-r <regex>    Liste uniquement les ressources dont le nom matche 
					  l'expression régulière.
		-i            Ne liste pas les éléments <img> (par défaut : les liste).
		-v            Ne liste pas les éléments <video> (par défaut : les liste).
		-p <path>   Liste et copie les ressources <img> et/ou <video> de <url> 
					  dans <path> (par défaut : ne fait que lister).
		-h            Affiche ce message d'aide ainsi que les informations sur les auteurs."
fi

url=${!#} #on stocke l'url qui est le dernier arg
working_directory=$(dirname "$url") #le repertoire pour les paths relatifs

html_content=$(curl -s "$url") #on curl le site

if [ $? -ne 0 ]; then #si le curl fail on exit
    echo "Error fetching URL"
    exit 1
fi

images=""
videos=""

if [ "$i" -eq 0 ]; then #si l'option -i n'est pas activé
	#on itère les balises images dans le html
    images=$(echo "$html_content" | grep -oE '<img[^>]+' | while read -r img_tag; do 
		#on stock le src
        src=$(echo "$img_tag" | grep -oE 'src="[^"]+"' | cut -d '"' -f2)
		if [ -n "$reg" ]; then #on applique le regex si il existe
			if ! grep -q "$reg" <<< "$src"; then
				continue
			fi
		fi
		if [ -n "$path" ]; then #si l'on a un path
			if [[ ${src:0:4} == "http" ]]; then #cas ou le src est un url
				#on télécharge l'image a partir de son url
  				curl -s -o "$path/$(basename "$src")" "$src"

			elif [[ ${src:0:1} == "/" ]]; then #cas ou le src est un chemin absolu
				base_url=$(echo "$url" | awk -F/ '{print $1"//"$3}')
				#on télécharge l'image à partir de la base de l'url
  				curl -s -o "$path/$(basename "$src")" "$base_url""$src"
			else #cas ou le src est un path relatif
				curl -s -o "$path/$(basename "$src")" "$working_directory"/"$src"
			fi
			src=$(basename "$src") #on garde le nom de l'image pour la sortie
		fi
		#on stock eventuellement le alt si il existe
        alt=$(echo "$img_tag" | grep -oE 'alt="[^"]+"' | cut -d '"' -f2) 
        if [ -n "$alt" ]; then #si il y a un alt
            echo "$src \"$alt\""
        else
            echo "$src"
        fi
    done)
fi
#on applatit le html puis a chaque </video> on met un retour a la ligne
#pour pouvoir gérer les <video> sur plusieurs lignes avec des sources.
html_video_flat=$(echo "$html_content" | tr '\n' ' ' | sed 's|</video>|</video>\n|g')

if [ "$v" -eq 0 ]; then #si l'option -v n'est pas activé
	#on itère les balises videos dans le html
    videos=$(echo "$html_video_flat" | grep -oE '<video[^>]*>.*</video>' | while read -r video_tag; do 
		#on stock le src
        src=$(echo "$video_tag" | grep -oE 'src="[^"]+"' | head -n 1 | cut -d '"' -f2)
		if [ -n "$reg" ]; then #on applique le regex si il existe
			if ! grep -q "$reg" <<< "$src"; then
				continue
			fi
		fi
		if [ -n "$path" ]; then #si l'on a un path
			if [[ ${src:0:4} == "http" ]]; then #cas ou le src est un url
  				curl -s -o "$path/$(basename "$src")" "$src"
			elif [[ ${src:0:1} == "/" ]]; then #cas ou le src est un chemin absolu
				base_url=$(echo "$url" | awk -F/ '{print $1"//"$3}')
  				curl -s -o "$path/$(basename "$src")" "$base_url""$src"
			else #cas ou le src est un path relatif
				curl -s -o "$path/$(basename "$src")" "$working_directory""$src"
			fi
			src=$(basename "$src") #on garde le nom de la video pour la sortie
		fi
		echo "$src"
    done)
fi

if [ -n "$path" ]; then #si il y a un path on l'affiche a la place de l'url
	echo "PATH $path"
else
	echo "PATH $working_directory"
fi

if [ -n "$images" ]; then
	while IFS= read -r img; do #on itere chaque ligne
		echo "IMAGE $img"
	done <<< "$images"
fi

if [ -n "$videos" ]; then
	while IFS= read -r vid; do #on itere chaque ligne
		echo "VIDEO $vid"
	done <<< "$videos"
fi
