var elements = document.querySelectorAll('._zs.fwb')

var data = Array.prototype.map.call(elements, function(el){
    var link = el.querySelector('a');
    return {
        name: link.innerText,
        url: link.href
    };
});

var usernames = data.map(function(item){
    var url = item.url.split('&ref')[0].split('?ref')[0].split('facebook.com/')[1]
    if ( /profile\.php/.test(url) ) {
        return url.split('php?id=')[1];
    }
    else {
        return url;
    }
});
