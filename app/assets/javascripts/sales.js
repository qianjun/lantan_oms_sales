function get_valid_code(obj){           //获取验证码
    var mobile = $.trim($("#mobilephone").val());
    var openid = $.trim($("#open_id").val());
    if(mobile==""){
        alert("请输入手机号码!");
    }else if(is_phone(mobile)==false){
        alert("请输入正确的手机号码!");
    }else{
        $("#get_valid_code_button").css("background", "grey");
        $("#get_valid_code_button").attr("disabled", "disabled");
        var sec = 30;
        var time = setInterval(function(){
            if(sec > 0){
                $("#get_valid_code_button").text(sec+"秒后重新获取");
            }else{
                clearInterval(time);
                $("#get_valid_code_button").text("获取验证码");
                $("#get_valid_code_button").css("background", "#415ac4");
                $("#get_valid_code_button").removeAttr("disabled");
            }
            sec = sec - 1;
        },1000);
        $.ajax({
            type: "post",
            url: "/sales/get_valid_code",
            dataType: "json",
            data: {
                mobile : mobile,
                openid : openid
            },
            success :function(data){
                if(data.status==0){
                    alert("您已经参加该活动，请关注下次！");
                }
            }
        })
    }
}
  
function reg_valid(obj){    //注册验证
    var phone = $.trim($("#mobilephone").val());
    var num = $.trim($("#num").val());
    var code = $.trim($("#valid_code").val());
    if(phone==""){
        alert("请输入手机号码!");
    }else if(is_phone(phone)==false){
        alert("请输入正确的手机号码!");
    }else if(num=="" || num.length != 7){
        alert("请输入车牌号!");
    }else if(code==""){
        alert("请输入验证码!");
    }else{
        $(obj).parents("form").submit();
    }
}

function old_customer_get_valid_code(obj, mobile, c_id){  //老用户获取验证码
    $("#get_valid_code_button").css("background", "grey");
    $("#get_valid_code_button").attr("disabled", "disabled");
    var sec = 30;
    var time = setInterval(function(){
        if(sec > 0){
            $("#get_valid_code_button").text(sec+"秒后重新获取");
        }else{
            clearInterval(time);
            $("#get_valid_code_button").text("获取验证码");
            $("#get_valid_code_button").css("background", "#415ac4");
            $("#get_valid_code_button").removeAttr("disabled");
        }
        sec = sec - 1;
    },1000);
    $.ajax({
        type: "post",
        url: "/sales/get_valid_code",
        dataType: "json",
        data: {
            mobile : mobile,
            c_id : c_id
        },
        success :function(data){
            if(data.status==0){
                alert("您已经参加该活动，请关注下次！");
            }
        }
    })
}


function old_customer_valid(obj){
    var code = $.trim($("#valid_code").val());
    if(code==""){
        alert("请输入验证码!");
    }else{
        $(obj).parents("form").submit();
    }
}
function is_phone(str){    //验证是否是手机号
    var flag = true;
    if(str=="" || isNaN(str)){
        flag = false;
    }else{
        var phoneReg =/^1[3456789]\d{9}$/;
        if(phoneReg.test(str)==false){
            flag = false;
        }
    }
    return flag;
}


//设置ajax请求 request_ajax(url,data,type,data_type)
function request_ajax(url){
    var data = arguments[1] ?  arguments[1] : null;
    var type = arguments[2] ?  arguments[2] : "get";
    var data_type = arguments[3] ?  arguments[3] : "script";
    $.ajax({
        type:type,
        url:url,
        dataType: data_type,
        data: data,
        success:function(data){
            arguments[4]
        }
    })
}

function check_bind(){
    var phone = $("#phone").val();
    var car_num = $("#car_num").val();
    if(is_phone(phone)==false || phone.length != 11 ){
        return false
    }
    if (car_num == "" || car_num.length != 7){
        return false
    }
    $("#bind_user").submit();
}

//加减产品
function operate_one(type,tag_name){
    var num = parseInt($(tag_name).html());
    if (type == "add"){
        $(tag_name).html(num+1)
        cal_price(tag_name,type)
    }else{
        if (num > 1){
            $(tag_name).html(num-1)
            cal_price(tag_name,type)
        }
    }
}


function add_cart(openid,store_id,btn_types){
    var url = "/stores/"+store_id+"/carts";
    var target_num = $("#num").html();
    var target_id = $("#target_id").val();
    var target_types = $("#target_types").val();
    var target_price = $("#target_price").html();
    var data = {
        openid:openid,
        btn_types : btn_types,
        target :{
            store_id: store_id,
            target_id: target_id,
            target_types: target_types,
            target_num : target_num,
            target_price : target_price
        }
    }
    $.ajax({
        type: "post",
        url: url,
        dataType: "json",
        data: data,
        success :function(data){
            if (data.status == 0){
                if (data.types == "add_action"){
                    alert("添加成功！");
                }
                else{
                    window.location.href = '/stores/'+data.store_id+"/carts?openid="+data.openid;
                }
            }
            if (data.status == 1){
                window.location.href =  '/stores/'+ data.store_id +'/bind_user';
            }
            if (data.status == 2){
                alert("数据错误");
            }
        }
    })
}


function toggle_show(ele){
    $('.card_surplus table').css('display','none');
    $("#"+ele).css("display","");
}


function cal_price(ele,types){
    var price = parseInt($(ele.replace("num","price")).html());
    var total = parseInt($(ele.replace("num","total")).html());
    if (types == "add"){
        $(ele.replace("num","total")).html(total+price);
       
    }else{
        $(ele.replace("num","total")).html(total-price);       
    }
    if($(ele).parent().parent().attr("class") == 'product_choise'){
        cal_total_price();
    }

}

function cal_total_price(){
    var selected_prods = $(".product_choise");
    var sum = 0;
    for(var i=0;i<selected_prods.length;i++){
        var price = $(selected_prods[i]).find(".sign span").eq(1).html();
        var num = $(selected_prods[i]).find("#price span").html();
        sum += (price*num)
    }
    $("#money").html(sum);
}

function select_prod(e){
    $(e).parent().parent().toggleClass('product_choise');
    cal_total_price();
}

function select_all_prod(select_value){
    $(".shopping_one_prduct tr :checkbox").attr("checked",select_value);
    $(".shopping_one_prduct tr").toggleClass('product_choise');
    cal_total_price();
    $("#select_all,#select_none").toggle();
}

function del_prod(store_id,openid){
    var selected_prods = $(".product_choise");
    var url = "/stores/"+store_id+"/carts/1"
    if (selected_prods.length >= 1){
        if (confirm("确定删除选中的产品吗？")){
            $.ajax({
                type: "delete",
                url: url,
                dataType: "json",
                data: {
                    del_prods : add_select(selected_prods)[0],
                    openid : openid
                },
                success :function(data){
                    if(data.status == 0){
                        alert("删除成功");
                        window.location.reload();
                    }else{
                        alert("删除失败");
                    }
                }
            })
        }
    }else{
        alert("请选择要删除的产品！")
    }
}



function submit_select(store_id,openid){
    var selected_prods = $(".product_choise");
    var url = "/stores/"+store_id+"/orders";
    var total_price = $("#money").html();
    var car_num = $("#car_num option:selected").val();
    if (selected_prods.length >= 1 && parseInt(car_num)>0){
        if (confirm("合计金额："+ total_price+"元,确定为车牌："+ $("#car_num option:selected").text()+"提交选中的项目吗？")){
            var select = add_select(selected_prods);
            $.ajax({
                type: "post",
                url: url,
                dataType: "json",
                data: {
                    submit_prods : select[0],
                    subit_num : select[1],
                    car_num_id : car_num,
                    openid : openid
                },
                success :function(data){
                    if(data.status == 0){
                        alert("提交订单成功");
                        window.location.reload();
                    }else{
                        alert("删除失败");
                    }
                }
            })
        }
    }else{
        alert("请选择项目");
    }
}

function add_select(selected_prods){
    var submit_prods = {};
    var prod_num = {};
    for(var i=0;i<selected_prods.length;i++){
        var types_id = selected_prods[i].id.split("_");
        var num = $("#num_"+selected_prods[i].id).html();
        submit_prods[types_id[0]] == null ? submit_prods[types_id[0]]=[types_id[1]] : submit_prods[types_id[0]].push(types_id[1])
        prod_num[selected_prods[i].id] = num
    }
    return [submit_prods,prod_num]
}
