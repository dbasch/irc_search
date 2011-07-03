(function($){
    if(!$.Indextank){
        $.Indextank = new Object();
    };
    
    $.Indextank.InstantLinks = function(el, options){
        // To avoid scope issues, use 'base' instead of 'this'
        // to reference this class from internal events and functions.
        var base = this;
        
        // Access to jQuery and DOM versions of element
        base.$el = $(el);
        base.el = el;
        
        // Add a reverse reference to the DOM object
        base.$el.data("Indextank.InstantLinks", base);

        base.options = $.extend({},$.Indextank.InstantLinks.defaultOptions, options);

        base.init = function(){
            // Put your initialization code here
            var ize = $(base.el.form).data("Indextank.Ize");

            base.$el.autocomplete({
                select: function( event, ui ) {
                /*
                  alert(base.options.fieldUrl);
                  alert(ui.item);
                  alert(ui.item[base.options.fieldUrl]);
                  */
                  event.target.value = ui.item.value;
                  window.location.href = ui.item[base.options.fieldUrl];
                },
                source: function ( request, responseCallback ) {
                  $.ajax( {
                      url: ize.apiurl + "/v1/indexes/" + ize.indexName + "/autocomplete",
                      dataType: "jsonp",
                      data: { query: request.term, field: base.options.fieldName },
                      success: function( data ) {
                          base.$el.bind("Indextank.AjaxSearch.success", function(e, data) {
                              responseCallback(data.results);
                          });
                          base.$el.trigger( "Indextank.AjaxSearch.runQuery", [data.suggestions] );
                      }
                  } );
                },
                minLength: base.options.minLength,
                delay: base.options.delay
            })
            .data( "autocomplete" )._renderItem = function( ul, item ) {
	            return $("<li></li>")
                .data( "item", item )
                .addClass("result")
                .append( $("<img />").attr("src", item[base.options.fieldThumbnail])
                  .css("float", "left")
                  .css("width", "50px")
                  .css("height", "50px"))
                .append( $("<a></a>").attr("href", item[base.options.fieldUrl]).html(item[base.options.fieldName]) )
                .appendTo( ul );
            };
        };
        
        // Run initializer
        base.init();
    };
    
    $.Indextank.InstantLinks.defaultOptions = {
        fieldName: "name",
        fieldUrl: "url",
        fieldThumbnail: "thumbnail",
        minLength: 2,
        delay: 100,
    };

    $.fn.indextank_InstantLinks = function(options){
        return this.each(function(){
            var itemName = options.name;
            var itemUrl = options.url;
            var itemThumbnail = options.thumbnail;

            var ajaxOptions = {
              queryField: itemName,
              fields : itemName+","+itemThumbnail+","+itemUrl,
              listeners: $(this),
              rewriteQuery: function(q) {
                var query = "";
                for (i in q) {
                  query += "(" + q[i] + ") OR ";
                }
                query += "(" + q[0] + ")";
                return query;
              }
            };
            (new $.Indextank.AjaxSearch(this,  ajaxOptions));
            (new $.Indextank.InstantLinks(this));
        });
    };
    
})(jQuery);
