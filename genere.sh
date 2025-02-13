#!/bin/bash

data=$(cat)

cat <<EOF
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Projet1</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
    <div class="container">
        <div class="row pb-1">
            <div class="text-center">
                <h1>Visualisateur</h1>d'images/vidéos
            </div>
        </div>
        <div class="row col-12" id="view">
            <table class="table table-hover" id="table">
                <thead>
                    <tr>
                        <th scope="col">ressource</th>
                        <th scope="col">alt</th>
                    </tr>
                </thead>
                <tbody>
EOF

while IFS=' ' read -r type ressource alt; do
    if [ "$type" == "PATH" ]; then
        path="$ressource"
        continue
    fi
    echo "                     
                    <tr data-type=\"$type\" data-src=\"$path/$ressource\">
                        <td>$path/$ressource</td>
                        <td>$(echo "$alt" | tr -d '"')</td>
                    </tr>"
done <<< "$data"

cat <<EOF
                </tbody>
            </table>
        </div>
        <div class="row" id="button_row"></div>
    </div>
    <div id="popup">
        <img id="popup_img" src="">
        <video id="popup_video" src="">
    </div>
    <script>
        document.addEventListener("DOMContentLoaded", function() {
            const view = document.getElementById("view");
            const table_view_html = view.innerHTML;
            const popup = document.getElementById("popup");
            const button_row = document.getElementById("button_row");

            document.addEventListener("mousedown", function(event) {
                let row = event.target.closest("#table tbody tr");
                if (!row) return;
                if(row.dataset.type == "IMAGE"){
                    popup_img.src = row.dataset.src;
                    popup_img.style.maxWidth = "200px";
                    popup_img.style.maxHeight = "200px";
                }
                else{
                    popup_video.src = row.dataset.src;
                    popup_video.style.maxWidth = "200px";
                    popup_video.style.maxHeight = "200px";
                }
                popup.style.display = "block";
                popup.style.position = "absolute";
                popup.style.top = \`\${event.pageY + 15}px\`;
                popup.style.left = \`\${event.pageX + 15}px\`;
            });

            document.addEventListener("mouseup", function() {
                popup.style.display = "none";
                popup_img.src = "";
                popup_video.src = "";
            });

            function tableView() {
                view.innerHTML = table_view_html;
          
            }

            function showBackButton() {
                button_row.innerHTML = \`
                    <div class="col-12 d-flex justify-content-center pt-3">
                        <button type="button" class="btn btn-primary w-25" id="backButton">Back</button>
                    </div>
                \`;
                document.getElementById("backButton").addEventListener("click", function(){
                    showOriginalButtons();
                    tableView();
                });
            }

            function showOriginalButtons() {
                button_row.innerHTML = \`
                    <div class="col-6 d-flex justify-content-end pe-5">
                        <button type="button" class="btn btn-primary w-25" id="carouselButton">Carousel</button>
                    </div>
                    <div class="col-6 d-flex justify-content-start ps-5">
                        <button type="button" class="btn btn-primary w-25" id="galerieButton">Galerie</button>
                    </div>
                \`;
               document.getElementById("carouselButton").addEventListener("click", function(){
                    let carouselHtml = \`
                        <div class="d-flex flex-column align-items-center">
                            <div id="carousel" class="carousel slide w-50 mx-auto vh-50" data-bs-ride="carousel">
                                <div class="carousel-inner"">
                    \`;


                    let first = true;
                    document.querySelectorAll("#table tbody tr").forEach(row => {
                        if(row.dataset.type == "IMAGE"){
                            const imgSrc = row.dataset.src;
                            const img_td = row.querySelectorAll("td");
                            let img_name = img_td[0].textContent;
                            let img_alt = img_td.length === 2 ? img_td[1].textContent : "";
                            carouselHtml += \`
                                <div class="carousel-item \${first ? 'active' : ''}">
                                    <div class="ratio ratio-16x9">
                                        <img src="\${imgSrc}" class="img-fluid" alt="\${img_alt}">
                                        <div class="carousel-caption d-none d-md-block">
                                            <h5>\${img_name}</h5>
                                            <p>\${img_alt}</p>
                                        </div>
                                    </div>
                                </div>\`;
                        }
                        else{
                            const videoSrc = row.dataset.src;
                            const video_td = row.querySelectorAll("td");
                            let video_name = video_td[0].textContent;
                            carouselHtml += \`
                                <div class="carousel-item \${first ? 'active' : ''}">
                                    <video src="\${videoSrc}" controls class="d-block w-100 h-100"> </video>
                                    <div class="carousel-caption d-none d-md-block">
                                        <h5>\${video_name}</h5>
                                    </div>
                                </div>\`;
                        }
                        first = false;
                    });

                    carouselHtml += \`
                            </div>
                            <button class="carousel-control-prev" type="button" data-bs-target="#carousel" data-bs-slide="prev">
                                <span class="carousel-control-prev-icon" aria-hidden="true"></span>
                                <span class="visually-hidden">Previous</span>
                            </button>
                            <button class="carousel-control-next" type="button" data-bs-target="#carousel" data-bs-slide="next">
                                <span class="carousel-control-next-icon" aria-hidden="true"></span>
                                <span class="visually-hidden">Next</span>
                            </button>
                        </div>\`;

                    view.innerHTML = carouselHtml;
                    showBackButton();
                });


                document.getElementById("galerieButton").addEventListener("click", function(){
                    let gallerieHtml = "<div class='row row-cols-2 g-3 justify-content-center'>";
                    
                    document.querySelectorAll("#table tbody tr").forEach(row => {
                    if(row.dataset.type == "IMAGE"){
                        const imgSrc = row.dataset.src;
                        const img_td = row.querySelectorAll("td");
                        let img_name = img_td[0].textContent;
                        let img_alt = img_td.length === 2 ? img_td[1].textContent : "";
                        if (imgSrc) {
                            gallerieHtml += \`
                                <div class="col ratio ratio-16x9">
                                    <img src="\${imgSrc}" class="img-fluid" alt="\${img_alt}">
                                </div>
                            \`;
                        }
                    }
                    else{
                        const videoSrc = row.dataset.src;
                        if (videoSrc) {
                            gallerieHtml += \`
                            <div class="col-6">
                                 <div class="ratio ratio-16x9">
                                    <video src="\${videoSrc}" controls class="w-100 h-100"> </video>
                                </div>
                            </div>
                            \`;
                        }
                    }
                    });

                    gallerieHtml += "</div>";
                    view.innerHTML = gallerieHtml;
                    showBackButton();
                });
            }
            showOriginalButtons();
        });
    </script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
EOF
