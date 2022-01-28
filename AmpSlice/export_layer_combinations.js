// Adapted to export images as CSS Layers by CarlosCanto


if (app.documents.length>0) {
    main();
}
else alert('Cancelled by user');


function main() {
    var document = app.activeDocument;
    var afile = document.fullName;
    var filename = afile.name.split('.')[0];


    var folder = afile.parent.selectDlg("Export Layer Combinations");


    if(folder != null)
    {
        var activeABidx = document.artboards.getActiveArtboardIndex();
        var activeAB = document.artboards[activeABidx]; // get active AB
        var abBounds = activeAB.artboardRect;// left, top, right, bottom


        //showAllLayers();
        // var docBounds = document.visibleBounds;
        // activeAB.artboardRect = docBounds;


        // var options = new ExportOptionsPNG24();
        // options.antiAliasing = true;
        // options.transparency = true;
        // options.artBoardClipping = true;
        // options.horizontalScale = 1000.0;
        // options.verticalScale = 1000.0;

        var options = new ExportOptionsJPEG();
        var type = ExportType.JPEG;
        options.antiAliasing = true;
        options.qualitySetting = 80;

        options.horizontalScale = 50.0; // this is a percentage, so 50 = half size
        options.verticalScale = 50.0;

        var layerGroups = [
          [4],
          [2,4],
          [3],
          [1,3],
          [0,1,3]
        ];

        for(var i = 0; i < layerGroups.length; i++){
            hideAllLayers();
            var layersToShow = layerGroups[i];
            for(var j = 0; j < layersToShow.length; j++){
                var layerI = layersToShow[j]
                document.layers[layerI].visible = true;
            }
            var file = new File(folder.fsName + '/' +filename+ '-' + i +".jpg");
            document.exportFile(file,type,options);
        }

        showAllLayers();
    }


    function hideAllLayers()
    {
        forEach(document.layers, function(layer) {
            layer.visible = false;
        });
    }


    function showAllLayers()
    {
        forEach(document.layers, function(layer) {
            layer.visible = true;
        });
    }


    function forEach(collection, fn)
    {
        var n = collection.length;
        for(var i=0; i<n; ++i)
        {
            fn(collection[i]);
        }
    }
}
