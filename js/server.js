HOST = null; // localhost
PORT = 8001;

var fu = require("./fu"),
    sys = require("sys"),
    url = require("url"),
    qs = require("querystring");

fu.listen(PORT, HOST);

fu.get("/index.html", fu.staticHandler("../index.html"));
fu.get("/css/style.css", fu.staticHandler("../css/style.css"));
fu.get("/js/processing.js", fu.staticHandler("../js/processing.js"));
fu.get("/js/jsOAuth-1.3.1.js", fu.staticHandler("../js/jsOAuth-1.3.1.js"));



