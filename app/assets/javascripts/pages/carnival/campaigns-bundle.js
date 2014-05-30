jQuery(function($) {
    //顶部下拉菜单
    function pullDown(obj) {
        var oBox = $(obj)[0];
        oBox.onmouseover = function() {
            this.children[1].style.display = 'block';
            this.children[0].className = 'link active';
        };
        oBox.onmouseout = function() {
            this.children[1].style.display = 'none';
            this.children[0].className = 'link';
        };
    };
    pullDown('.questions');
    pullDown('.share');
    //滚动公告
    var oDiv = $('.bulletin')[0];
    var oUl = oDiv.children[0];
    oUl.innerHTML += oUl.innerHTML;
    var timer = null;
    run();

    function run() {
        clearInterval(timer);
        timer = setInterval(function() {
            if (oUl.offsetTop <= -oUl.offsetHeight / 2) {
                oUl.style.top = 0;
            };
            oUl.style.top = oUl.offsetTop - 1 + 'px';
            if (oUl.offsetTop % 40) {} else {
                clearInterval(timer);
                setTimeout(run, 5000);
            };
        }, 30);
    };
});