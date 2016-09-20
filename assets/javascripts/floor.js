/**
 * Created by ruby on 07.05.16.
 */
//function $(v) { return (document.getElementById(v));  }


var DragManager = new function() {

    /**
     * составной объект для хранения информации о переносе:
     * {
    *   elem - элемент, на котором была зажата мышь
    *   avatar - аватар
    *   downX/downY - координаты, на которых был mousedown
    *   shiftX/shiftY - относительный сдвиг курсора от угла элемента
    * }
    */

    var dragObject = {};

    var self = this;

    function onMouseDown(e) {

        if (e.which != 1) return;

        var elem = e.target.closest('.place');
        if (!elem) return;

        dragObject.new = elem.classList.contains("base");
        dragObject.elem = elem;

        // запомним, что элемент нажат на текущих координатах pageX/pageY
        dragObject.downX = e.pageX;
        dragObject.downY = e.pageY;

        return false;
    }

    function onMouseMove(e) {
        if (!dragObject.elem) return; // элемент не зажат

        if (!dragObject.avatar) { // если перенос не начат...
            var moveX = e.pageX - dragObject.downX;
            var moveY = e.pageY - dragObject.downY;

            // если мышь передвинулась в нажатом состоянии недостаточно далеко
            if (Math.abs(moveX) < 3 && Math.abs(moveY) < 3) {
                return;
            }

            // начинаем перенос
            dragObject.avatar = createAvatar(e); // создать аватар
            if (!dragObject.avatar) { // отмена переноса, нельзя "захватить" за эту часть элемента
                dragObject = {};
                return;
            }

            // аватар создан успешно
            // создать вспомогательные свойства shiftX/shiftY
            var coords = getCoords(dragObject.elem);
            dragObject.shiftX = dragObject.downX - coords.left;
            dragObject.shiftY = dragObject.downY - coords.top;

            startDrag(e); // отобразить начало переноса
        }

        // отобразить перенос объекта при каждом движении мыши
        dragObject.avatar.style.left = e.pageX - dragObject.shiftX + 'px';
        dragObject.avatar.style.top = e.pageY - dragObject.shiftY + 'px';

        return false;
    }

    function onMouseUp(e) {
        if (dragObject.avatar) { // если перенос идет
            finishDrag(e);
        }

        // перенос либо не начинался, либо завершился
        // в любом случае очистим "состояние переноса" dragObject
        dragObject = {};
    }

    function finishDrag(e) {
        var dropElem = findDroppable(e);

        if (!dropElem) {
            self.onDragCancel(dragObject);
        } else {
            self.onDragEnd(dragObject, dropElem);
        }
    }

    function createAvatar(e) {

        // запомнить старые свойства, чтобы вернуться к ним при отмене переноса
        var avatar;
        if (dragObject.new) {
            avatar = dragObject.elem.cloneNode(true);
            avatar.classList.remove("base");
        } else {
            avatar = dragObject.elem;
            var old = {
                parent: avatar.parentNode,
                nextSibling: avatar.nextSibling,
                position: avatar.style.position || '',
                left: avatar.style.left || avatar.offsetLeft + "px" || '',
                top: avatar.style.top || avatar.offsetTop + "px"|| '',
                zIndex: avatar.style.zIndex || ''
            };
        }



        // функция для отмены переноса
        avatar.rollback = function() {
            if (dragObject.new) {
                document.body.removeChild(avatar)
            } else {
                old.parent.insertBefore(avatar, old.nextSibling);
                avatar.style.position = old.position;
                avatar.style.left = old.left ;
                avatar.style.top = old.top;
                avatar.style.zIndex = old.zIndex
            }
        };
        return avatar;
    }

    function startDrag(e) {
        var avatar = dragObject.avatar;

        // инициировать начало переноса
        document.body.appendChild(avatar);
        avatar.style.zIndex = 9999;
        avatar.style.position = 'absolute';
    }

    function findDroppable(event) {
        // спрячем переносимый элемент
        dragObject.avatar.hidden = true;

        // получить самый вложенный элемент под курсором мыши
        var elem = document.elementFromPoint(event.clientX, event.clientY);

        // показать переносимый элемент обратно
        dragObject.avatar.hidden = false;

        if (elem == null) {
            // такое возможно, если курсор мыши "вылетел" за границу окна
            return null;
        }

        return elem.closest('.droppable');
    }

    document.onmousemove = onMouseMove;
    document.onmouseup = onMouseUp;
    document.onmousedown = onMouseDown;

    this.onDragEnd = function(dragObject, dropElem) {};
    this.onDragCancel = function(dragObject) {};
};


function getCoords(elem) { // кроме IE8-
    var box = elem.getBoundingClientRect();

    return {
        top: box.top + pageYOffset,
        left: box.left + pageXOffset
    };

}


DragManager.onDragCancel = function(dragObject) {
    dragObject.avatar.rollback();
};

DragManager.onDragEnd = function(dragObject, dropElem) {
    //Сохраняем изменения в базу, если вернулась ошибка, то откатываем изменения
    var avatar = dragObject.avatar;
    var token = $("meta[name='csrf-token']").attr("content");
    var floor_id = $('.map').data('floor');
    var data_id = avatar.getAttribute('data-id');
    if (dropElem.classList.contains("map")){ // Бросили над картой
        var m_c = getCoords(dropElem);
        var a_c = getCoords(avatar);
        var left = Math.round(a_c.left - m_c.left);
        var top  = Math.round(a_c.top  - m_c.top);
        //TODO Реализовать удаление существующего элемента

        if (dragObject.new) {
            $.ajax({ //Создание нового
                type: "POST",
                url: "/floors/"+floor_id+"/places" + "?&authenticity_token=" + token,
                data: { place: {
                    name: prompt("Введите наименование"),
                    category: data_id,
                    point_x:  left,
                    point_y:  top
                }, ajax: "json"},
                success: function(data) {updatePlace(data, avatar, dropElem)},
                error: function() { dragObject.avatar.rollback()}
            });
        } else {
            $.ajax({ //Перемещение существующего
                type: "PUT",
                url: "/floors/"+floor_id+"/places/"+data_id + "?&authenticity_token=" + token,
                data: {place: {point_x: left,  point_y: top}, ajax: "json"},
                success: function(result) {updatePlace(result, avatar, dropElem)},
                error: function() { dragObject.avatar.rollback()}
            });
        }
    } else if (dropElem.classList.contains("trash")){ // Поместили в корзину
        if (confirm("Точка будет удалена. Вы уверены")) {
            $.ajax({ //Перемещение существующего
                type: "DELETE",
                url: "/floors/"+floor_id+"/places/"+data_id+"?&authenticity_token="+token,
                data: {ajax: "json"},
                success: function(result) {
                    document.body.removeChild(avatar)
                },
                error: function(result) {
                    dragObject.avatar.rollback()
                }
            });
        }
    }

};

function updatePlace(data, avatar, dropElem){
    var place = data.place;
    dropElem.appendChild(avatar);
    avatar.style.position = '';
    avatar.style.zIndex = '';
    avatar.setAttribute('data-id', place.id);
    avatar.style.left = place.point_x + "px";
    avatar.style.top = place.point_y + "px";
    avatar.innerHTML = "<p>"+place.name+"</p>";
}

/*
function agent(v) {return (Math.max(navigator.userAgent.toLowerCase().indexOf(v), 0));}

function xy(e, v) { return (v ? (agent('msie') ? event.clientY + document.body.scrollTop : e.pageY) : (agent('msie') ? event.clientX + document.body.scrollTop : e.pageX));}
function dragOBJ(d, e)
{
    function drag(e)
    {
        if (!stop) {
            // if(stop==1) return;
            var map = $('.map')[0];
            var dx = xy(e) + oX - eX;
            var dy = xy(e, 1) + oY - eY;
            d.style.left = (tY = dx + 'px');
            d.style.top = (tX = dy + 'px');
            var r = Array(map.offsetTop+56,map.offsetLeft+10,map.offsetWidth+5,map.offsetHeight+5);
            if(dy <r[0]) d.style.top = r[0]+'px';
            if(dy >r[0]+r[3]-50) d.style.top =r[0]+r[3]-50+'px';
            if(dx < r[1]) d.style.left = r[1] + 'px';
            if(dx >r[1]+r[2]-50) d.style.left =r[1]+r[2]-50+'px';
        }
    }
    var oX = parseInt(d.style.left),
        oY = parseInt(d.style.top),
        eX = xy(e),
        eY = xy(e, 1),
        tX, tY, stop;
    document.onmousemove = drag;
    document.onmouseup = function()
    { stop = 1;
        document.onmousemove = '';
        document.onmouseup = '';
    };
};
window.onload = function ()
{
    InitArray();
    showArr(arm,"arm");
    showArr(mon,"monitor");
    showArr(prt,"printer");
};

function showArr(array,typ)
{
    if(array)
    {
        for($i=0;$i<array.length;$i++)
        {
            if(array[$i][1]()==1)
            {
                var divElem = document.createElement("div");
                divElem.className = typ;
                divElem.setAttribute("style","left:"+array[$i][2]()+"px; top: "+array[$i][3]()+"px;");
                divElem.setAttribute("id","event");
                divElem.setAttribute("onmousedown","dragOBJ(this,event); return false;");
                divElem.innerHTML = "<p style=\"color: red;background: #E5D3BD;border: 1px solid #E81E25;\">"+array[$i][0]()+"</p>";
                Maps0.appendChild(divElem);
            }
        }
    }
}


function CreateMove(obj)
{
    var divElem = document.createElement("div");
    var p_type_id = obj.getAttribute('data-id');
    var p_type_name = obj.getAttribute('class');
    var p_name = p_type_name;
    var map = $('.map');
    divElem.className = p_type_name;
    divElem.setAttribute("style","left: 0px; top: 0px;");
    divElem.setAttribute("id","event");
    divElem.setAttribute("onmousedown","dragOBJ(this,event); return false;");
    divElem.innerHTML = "<p>"+p_name+"</p>";
    divElem.setAttribute("style","left: "+obj.offsetLeft+"px; top: "+obj.offsetTop+"px;");
    map.append(divElem);
    dragOBJ(divElem,event);
}

function addObject(e,type)
{
    var divElem = document.createElement("div");
    var CurrrClass = "arm";
    if(type==1) CurrrClass = "printer";
    if(type==2) CurrrClass = "monitor";
    if(type==3) CurrrClass = "scaner";
    divElem.className = CurrrClass;
    divElem.setAttribute("style","left: 0px; top: 0px;");
    divElem.setAttribute("id","event");
    divElem.setAttribute("onmousedown","dragOBJ(this,event); return false;");
    divElem.innerHTML = type;
    map.appendChild(divElem);
    return divElem;
}
 */