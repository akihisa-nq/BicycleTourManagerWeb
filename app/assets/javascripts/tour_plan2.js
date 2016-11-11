function load_tour_plan_node_info_on_edit(url) {
    $.ajax({
        type: "GET",
        url: url,
        dataType: 'json'
    }).done(function (response, textStatus, jqXHR) {
        $.each(response, function (index, node) {
            var pos = new google.maps.LatLng(node.position.lat, node.position.lon);

            var mapOptions = {
                zoom: 16,
                mapTypeId: google.maps.MapTypeId.ROADMAP,
                center: pos
            };
            var map = new google.maps.Map(document.getElementById("map_" + node.id), mapOptions);

            {
                var pointarray = [];
                $.each(node.near_line, function (index2, pt) {
                    pointarray.push(new google.maps.LatLng(pt.lat, pt.lon));
                });
                new google.maps.Polyline({
                    path: pointarray,
                    strokeColor: "#0000ff",
                    strokeWeight: 5,
                    map: map
                });
            }

            {
                var markerOptions = {
                    map: map,
                    position: pos
                };
                new google.maps.Marker(markerOptions);
            }
        });
    });
}
