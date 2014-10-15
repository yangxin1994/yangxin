(function($){
  // var Wi = [ 7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2, 1 ];    // 加权因子   
  // var ValideCode = [ 1, 0, 10, 9, 8, 7, 6, 5, 4, 3, 2 ];            // 身份证验证位值.10代表X   
  // function IdCardValidate(idCard) { 
  //     idCard = trim(idCard.replace(/ /g, ""));               //去掉字符串头尾空格                     
  //     if (idCard.length == 15) {   
  //         return isValidityBrithBy15IdCard(idCard);       //进行15位身份证的验证    
  //     } else if (idCard.length == 18) {   
  //         var a_idCard = idCard.split("");                // 得到身份证数组   
  //         if(isValidityBrithBy18IdCard(idCard)&&isTrueValidateCodeBy18IdCard(a_idCard)){   //进行18位身份证的基本验证和第18位的验证
  //             return true;   
  //         }else {   
  //             return false;   
  //         }   
  //     } else {   
  //         return false;   
  //     }   
  // }   
  // /**  
  //  * 判断身份证号码为18位时最后的验证位是否正确  
  //  * @param a_idCard 身份证号码数组  
  //  * @return  
  //  */  
  // function isTrueValidateCodeBy18IdCard(a_idCard) {   
  //     var sum = 0;                             // 声明加权求和变量   
  //     if (a_idCard[17].toLowerCase() == 'x') {   
  //         a_idCard[17] = 10;                    // 将最后位为x的验证码替换为10方便后续操作   
  //     }   
  //     for ( var i = 0; i < 17; i++) {   
  //         sum += Wi[i] * a_idCard[i];            // 加权求和   
  //     }   
  //     valCodePosition = sum % 11;                // 得到验证码所位置   
  //     if (a_idCard[17] == ValideCode[valCodePosition]) {   
  //         return true;   
  //     } else {   
  //         return false;   
  //     }   
  // }   
  // /**  
  //   * 验证18位数身份证号码中的生日是否是有效生日  
  //   * @param idCard 18位书身份证字符串  
  //   * @return  
  //   */  
  // function isValidityBrithBy18IdCard(idCard18){   
  //     var year =  idCard18.substring(6,10);   
  //     var month = idCard18.substring(10,12);   
  //     var day = idCard18.substring(12,14);   
  //     var temp_date = new Date(year,parseFloat(month)-1,parseFloat(day));   
  //     // 这里用getFullYear()获取年份，避免千年虫问题   
  //     if(temp_date.getFullYear()!=parseFloat(year)   
  //           ||temp_date.getMonth()!=parseFloat(month)-1   
  //           ||temp_date.getDate()!=parseFloat(day)){   
  //             return false;   
  //     }else{   
  //         return true;   
  //     }   
  // }   
  //   /**  
  //    * 验证15位数身份证号码中的生日是否是有效生日  
  //    * @param idCard15 15位书身份证字符串  
  //    * @return  
  //    */  
  //   function isValidityBrithBy15IdCard(idCard15){   
  //       var year =  idCard15.substring(6,8);   
  //       var month = idCard15.substring(8,10);   
  //       var day = idCard15.substring(10,12);   
  //       var temp_date = new Date(year,parseFloat(month)-1,parseFloat(day));   
  //       // 对于老身份证中的你年龄则不需考虑千年虫问题而使用getYear()方法   
  //       if(temp_date.getYear()!=parseFloat(year)   
  //               ||temp_date.getMonth()!=parseFloat(month)-1   
  //               ||temp_date.getDate()!=parseFloat(day)){   
  //                 return false;   
  //         }else{   
  //             return true;   
  //         }   
  //   }   
  // //去掉字符串头尾空格   
  // function trim(str) {   
  //     return str.replace(/(^\s*)|(\s*$)/g, "");   
  // }
  // /**  
  //  * 通过身份证判断是男是女  
  //  * @param idCard 15/18位身份证号码   
  //  * @return 'female'-女、'male'-男  
  //  */  
  // function maleOrFemalByIdCard(idCard){   
  //     idCard = trim(idCard.replace(/ /g, ""));        // 对身份证号码做处理。包括字符间有空格。   
  //     if(idCard.length==15){   
  //         if(idCard.substring(14,15)%2==0){   
  //             return 'female';   
  //         }else{   
  //             return 'male';   
  //         }   
  //     }else if(idCard.length ==18){   
  //         if(idCard.substring(14,17)%2==0){   
  //             return 'female';   
  //         }else{   
  //             return 'male';   
  //         }   
  //     }else{   
  //         return null;   
  //     } 
  // }

  function checkCardId(socialNo){
    if(!socialNo) return false;
    if (socialNo.length != 15 && socialNo.length != 18) return false;
      
    var area={11:"北京",12:"天津",13:"河北",14:"山西",15:"内蒙古",21:"辽宁",22:"吉林",23:"黑龙江",31:"上海",32:"江苏",33:"浙江",34:"安徽",35:"福建",36:"江西",37:"山东",41:"河南",42:"湖北",43:"湖南",44:"广东",45:"广西",46:"海南",50:"重庆",51:"四川",52:"贵州",53:"云南",54:"西藏",61:"陕西",62:"甘肃",63:"青海",64:"宁夏",65:"新疆",71:"台湾",81:"香港",82:"澳门",91:"国外"}; 
       
    if(area[parseInt(socialNo.substr(0,2))]==null) return false;
          
    if (socialNo.length == 15) {
      pattern= /^\d{15}$/;
      if (pattern.exec(socialNo)==null) return false;
      var birth = parseInt("19" + socialNo.substr(6,2));
      var month = socialNo.substr(8,2);
      var day = parseInt(socialNo.substr(10,2));
      switch(month) {
        case '01':
        case '03':
        case '05':
        case '07':
        case '08':
        case '10':
        case '12':
          if(day>31) return false;
          break;
        case '04':
        case '06':
        case '09':
        case '11':
          if(day>30) return false;
          break;
        case '02':
          if((birth % 4 == 0 && birth % 100 != 0) || birth % 400 == 0) {
            if(day>29) return false;
          } else {
            if(day>28) return false;
          }
          break;
        default:
          return false;
      }
      var nowYear = new Date().getYear();
      if(nowYear - parseInt(birth)<15 || nowYear - parseInt(birth)>100) return false;
      return true;
    }
      
    var Wi = [7,9,10,5,8,4,2,1,6,3,7,9,10,5,8,4,2,1];
    var lSum = 0;
    var nNum = 0;
    var nCheckSum = 0;
    
    for (i = 0; i < 17; ++i) {
      if ( socialNo.charAt(i) < '0' || socialNo.charAt(i) > '9' ) {
        return false;
      } else {
        nNum = socialNo.charAt(i) - '0';
      }
      lSum += nNum * Wi[i];
    }
    
    if( socialNo.charAt(17) == 'X' || socialNo.charAt(17) == 'x') {
      lSum += 10*Wi[17];
    } else if ( socialNo.charAt(17) < '0' || socialNo.charAt(17) > '9' ) {
      return false;
    } else {
      lSum += ( socialNo.charAt(17) - '0' ) * Wi[17];
    }
    
    if ( (lSum % 11) == 1 ) {
      return true;
    } else {
        return false;
    }
      
  }

  $.idcard = $.idcard || {
    isValid : function(card) {
      // return IdCardValidate(card);
      return checkCardId(card);
    }
  };
})(jQuery);



