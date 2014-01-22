
window.soso = window.soso || {};
soso.maps = soso.maps || {};

(function() {
   function getScript(src) {
        document.write('<' + 'script src="' + src + '"' +' type="text/javascript\"><' + '/script>');
    }
    soso.maps.__load = function(apiLoad){
        delete soso.maps.__load;
        apiLoad(["http://api.map.soso.com/","v2.0.9","",1389318706324,true,"","20130701"], loadScriptTime);
    };
    var loadScriptTime = (new Date).getTime();
    getScript("http://api.map.soso.com/v2/0/9/main.js");
})();