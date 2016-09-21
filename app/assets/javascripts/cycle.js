var C = function(e_id,cycle_num){
    this.box = $("#"+e_id);
    this.left = this.box.find(".left");
    this.right = this.box.find(".right");
    this.mask = this.box.find(".mask");
    this.text = this.box.find(".text");
    this.d = 0;
    this.max_num = cycle_num;
    this.A = null;
    this.init();
}
C.prototype = {
    init : function(){
        var T = this;
        this.A = window.setInterval(function(){
            T.change()
        },80);
    },
    change : function(){
        if(parseInt(this.d)>this.max_num){
            window.clearInterval(this.A);
            this.A = null;
            return;
        }
        if(this.d>180){
            this.right.show();
            this.mask.hide();
        }
        this.d += 1;
        this.text.text(this.d/3.6);
        this.left.css({
            "-webkit-transform":"rotate("+this.d*3.6+"deg)",
            "-moz-transform":"rotate("+this.d*3.6+"deg)"
        })
     
    }
}