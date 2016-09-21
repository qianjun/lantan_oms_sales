(function($){
    $.extend($.fn,{
        shoping:function(options){
            var self=this,
            $shop=$('.buy_car'),
            $num=$('.buy_car_num');
            var S={
                init:function(){
                    $(self).data('click',true).live('click',this.addShoping);
                },
                clickOnBody:function(e){
                    if(!$(e.target).hasClass('J-shoping-close')){
                        e.stopPropagation(); //阻止冒泡
                    };
                },
                addShoping:function(e){
                    e.stopPropagation();
                    var $target=$(e.target),
                    id=$target.attr('id'),
                    dis=$target.data('click'),
                    x = $target.offset().left + 30,
                    y = $target.offset().top + 10,
                    X = $shop.offset().left+$shop.width()/2-$target.width()/2+10,
                    Y = $shop.offset().top;
                    if(dis){
                        if ($('#floatOrder').length <= 0) {
                            var src = $("#animate_img").attr("src");
                            $('body').append('<div id="floatOrder"><img src="/assets/default.png" width="50" height="50" /></div');
                        };
                        var $obj=$('#floatOrder');
                        if(!$obj.is(':animated')){
                            $obj.css({
                                'left': x,
                                'top': y
                            }).animate({
                                'left': X,
                                'top': Y-80
                            },500,function() {
                                $obj.stop(false, false).animate({
                                    'top': Y-20,
                                    'opacity':0
                                },500,function(){
                                    $obj.fadeOut(300,function(){	
                                        var num=Number($num.text());
                                        $num.text(num+1);
                                    });
                                });
                            });
                        }
                    }
                }
            };
            S.init();
        }
    });
})(jQuery);

