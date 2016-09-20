/**
 * Created by ruby on 07.05.15.
 */

function ff(t,a)
{
    var namecard = t.name.replace(/(restored|killed)\[([^\]]*)\]/g,"$2");
    var send   = +document.getElementById("send["+namecard+"]").innerHTML;

    var row = document.getElementById("cartridge-"+namecard).getElementsByTagName('input');

    var restored,killed;
    for( var i=0; i<row.length; i++)
    {
        if(row[i].name == "restored["+namecard+"]") restored = row[i];
        if(row[i].name == "killed["+namecard+"]")   killed   = row[i];
    }
    if (restored.value > restored.max) restored.value = restored.max;
    if (killed.value   > killed.max)   killed.value   = killed.max;
    if(a==0) killed.max   = send - restored.value;
    else     restored.max = send - killed.value;

    document.getElementById("filled["+namecard+"]").innerHTML = send - restored.value - killed.value;

    // Подсчет сумм по столбцам
    var cartridges = document.getElementById("cartridges").getElementsByTagName('input');
    var sum_restored = 0, sum_killed = 0;
    for( i=0; i<cartridges.length; i++)
    {
        if(cartridges[i].name.indexOf("restored[") == 0) sum_restored = sum_restored + Number(cartridges[i].value);
        if(cartridges[i].name.indexOf("killed[")   == 0) sum_killed   = sum_killed   + Number(cartridges[i].value);
    }

    var sum_send = +document.getElementById("sum_send").innerHTML;
    document.getElementById("sum_send").innerHTML     = sum_send;
    document.getElementById("sum_filled").innerHTML   = sum_send - (sum_restored + sum_killed);
    document.getElementById("sum_restored").innerHTML = sum_restored;
    document.getElementById("sum_killed").innerHTML   = sum_killed;
}