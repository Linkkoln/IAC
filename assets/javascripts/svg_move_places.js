var svgDoc;
var el_id = 0;
var el_svg;
var el_init_x, el_init_y, el_x, _el_y;
var dx = 0;
var dy = 0;

function coordTransform(screenPoint, someSvgObject) {
    var CTM = someSvgObject.getScreenCTM();
    return screenPoint.matrixTransform( CTM.inverse() ); // Return the point in the coordinate system associated with someSvgObject.
}

function coordEvtTransform(evt) {
    var svgElement = document.getElementById('floor_plan_svg'); // Required for Firefox.
    // Create a new SVG point object so that we can (ultimately) access its matrixTransform() method in function coordinateTransform().
    var point = svgElement.createSVGPoint();
    point.x = evt.pageX; // Transfer the screen coordinates of the mouse to the SVG point object.
    point.y = evt.pageY;
    t_point = coordTransform(point, svgElement);
    t_point.x = t_point.x.toFixed(0);
    t_point.y = t_point.y.toFixed(0);
    return t_point
}

function getTransform(el) {
    var point = svgElement.createSVGPoint();
    var xforms = el.transform.baseVal; // An SVGTransformList
    var firstXForm = xforms.getItem(0);       // An SVGTransform
    if (firstXForm.type == SVGTransform.SVG_TRANSFORM_TRANSLATE){
        point.x = firstXForm.matrix.e.toFixed(0);
        point.y = firstXForm.matrix.f.toFixed(0);
    }
    return point
}

function setTransform(el, pointx, pointy) {
    el.transform.baseVal.getItem(0).setTranslate(pointx,pointy);
}

function initMove(evt) {
    evt.preventDefault();
    if ( window.svgDocument == null ) {
        svgDoc = evt.target.ownerDocument;
    }
}

function selectElement(evt, id){
    evt.preventDefault();
    // Выяснить evt.target == el
    el_id = id;
    el_svg = evt.target;
    var mp = coordEvtTransform(evt);
    var transform = el_svg.getAttribute('transform');
    var parts  = /translate\(\s*([^\s,)]+)[ ,]*([^\s,)]+)/.exec(transform);
    el_init_x = parts[1];
    el_init_y = parts[2];
    dx = el_init_x - mp.x;
    dy = el_init_y - mp.y;
}

function drag(evt){
    evt.preventDefault();
    if (el_id != 0){
        var point = coordEvtTransform(evt);
        el_x = point.x + dx;
        el_y = point.y + dy;
        setTransform(el_svg, el_x, el_y);
    }
}

function deselect(){
    el_id = 0;
    //Сохраняем изменения в базу, если вернулась ошибка, то откатываем изменения
    var token = $("meta[name='csrf-token']").attr("content");
    var floor_id = $('.map').data('floor');
    var data_id = el_svg.getAttribute('data-id');
    $.ajax({ //Перемещение существующего
        type: "PUT",
        url: "/floors/"+floor_id+"/places/"+data_id + "?&authenticity_token=" + token,
        data: {place: {point_x: el_x,  point_y: el_y}, ajax: "json"},
        error: function() { setTransform(el, el_init_x, el_init_y)}
    });
}

window.onload = function() {
    $('use.svg_place').hover(function(){
        var floor_id = $('.map').data('floor');
        var place_id = this.getAttribute('data-id');
        var token = $("meta[name='csrf-token']").attr("content");
        window.location.href = "/floors/"+floor_id+"/places/"+place_id+"/edit";
    });
};